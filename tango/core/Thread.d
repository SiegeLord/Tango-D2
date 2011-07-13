/**
 * The thread module provides support for thread creation and management.
 *
 * If AtomicSuspendCount is used for speed reasons all signals are sent together.
 * When debugging gdb funnels all signals through one single handler, and if
 * the signals arrive quickly enough they will be coalesced in a single signal,
 * (discarding the second) thus it is possible to loose signals, which blocks
 * the program. Thus when debugging it is better to use the slower SuspendOneAtTime
 * version.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly, Fawzi.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly, Fawzi Mohamed
 */
module tango.core.Thread;

import tango.core.sync.Atomic;
debug(Thread)
    import tango.stdc.stdio : printf;


// this should be true for most architectures
version = StackGrowsDown;
version(darwin){
    version=AtomicSuspendCount;
}
version(linux){
    version=AtomicSuspendCount;
}

public
{
//    import tango.core.TimeSpan;
}
private
{
    import tango.core.Exception;

    extern (C) void  _d_monitorenter(Object);
    extern (C) void  _d_monitorexit(Object);

    //
    // exposed by compiler runtime
    //
    extern (C) void* rt_stackBottom();
    extern (C) void* rt_stackTop();


    void* getStackBottom()
    {
        return rt_stackBottom();
    }


    void* getStackTop()
    {
        version( D_InlineAsm_X86 )
        {
            asm
            {
                naked;
                mov EAX, ESP;
                ret;
            }
        }
        else
        {
            return rt_stackTop();
        }
    }

    version(D_InlineAsm_X86){
        uint getEBX(){
            uint retVal;
            asm{
                mov retVal,EBX;
            }
            return retVal;
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Thread Entry Point and Signal Handlers
////////////////////////////////////////////////////////////////////////////////


version( Win32 )
{
    private
    {
        import tango.stdc.stdint : uintptr_t; // for _beginthreadex decl below
        import tango.sys.win32.UserGdi;

        const DWORD TLS_OUT_OF_INDEXES  = 0xFFFFFFFF;

        //
        // avoid multiple imports via tango.sys.windows.process
        //
        extern (Windows) alias uint function(void*) btex_fptr;
        extern (C) uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*);


        //
        // entry point for Windows threads
        //
        extern (Windows) uint thread_entryPoint( void* arg )
        {
            Thread  obj = cast(Thread) arg;
            assert( obj );
            scope( exit ) Thread.remove( obj );

            assert( obj.m_curr is &obj.m_main );
            obj.m_main.bstack = getStackBottom();
            obj.m_main.tstack = obj.m_main.bstack;
            Thread.add( &obj.m_main );
            Thread.setThis( obj );

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and Thread.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Win32 but it should be followed for the sake
            //       of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            try
            {
                obj.run();
            }
            catch( Object o )
            {
                obj.m_unhandled = o;
            }
            return 0;
        }


        //
        // copy of the same-named function in phobos.std.thread--it uses the
        // Windows naming convention to be consistent with GetCurrentThreadId
        //
        HANDLE GetCurrentThreadHandle()
        {
            const uint DUPLICATE_SAME_ACCESS = 0x00000002;

            HANDLE curr = GetCurrentThread(),
                   proc = GetCurrentProcess(),
                   hndl;

            DuplicateHandle( proc, curr, proc, &hndl, 0, TRUE, DUPLICATE_SAME_ACCESS );
            return hndl;
        }
    }
}
else version( Posix )
{
    private
    {
        import tango.stdc.posix.semaphore;
        import tango.stdc.posix.pthread;
        import tango.stdc.posix.signal;
        import tango.stdc.posix.time;
        import tango.stdc.errno;

        extern (C) int getErrno();

        version( GNU )
        {
            import gcc.builtins;
        }


        //
        // entry point for POSIX threads
        //
        extern (C) void* thread_entryPoint( void* arg )
        {
            Thread  obj = cast(Thread) arg;
            assert( obj );
            scope( exit )
            {
                // NOTE: isRunning should be set to false after the thread is
                //       removed or a double-removal could occur between this
                //       function and thread_suspendAll.
                Thread.remove( obj );
                obj.m_isRunning = false;
            }

            static extern (C) void thread_cleanupHandler( void* arg )
            {
                Thread  obj = cast(Thread) arg;
                assert( obj );

                // NOTE: If the thread terminated abnormally, just set it as
                //       not running and let thread_suspendAll remove it from
                //       the thread list.  This is safer and is consistent
                //       with the Windows thread code.
                obj.m_isRunning = false;
            }

            // NOTE: Using void to skip the initialization here relies on
            //       knowledge of how pthread_cleanup is implemented.  It may
            //       not be appropriate for all platforms.  However, it does
            //       avoid the need to link the pthread module.  If any
            //       implementation actually requires default initialization
            //       then pthread_cleanup should be restructured to maintain
            //       the current lack of a link dependency.
            version( linux )
            {
                pthread_cleanup cleanup = void;
                cleanup.push( &thread_cleanupHandler, cast(void*) obj );
            }
            else version( darwin )
            {
                pthread_cleanup cleanup = void;
                cleanup.push( &thread_cleanupHandler, cast(void*) obj );
            }
            else version( solaris )
            {
                pthread_cleanup cleanup = void;
                cleanup.push( &thread_cleanupHandler, cast(void*) obj );
            }
            else
            {
                pthread_cleanup_push( &thread_cleanupHandler, cast(void*) obj );
            }

            // NOTE: For some reason this does not always work for threads.
            //obj.m_main.bstack = getStackBottom();
            version( D_InlineAsm_X86 )
            {
                static void* getBasePtr()
                {
                    asm
                    {
                        naked;
                        mov EAX, EBP;
                        ret;
                    }
                }

                obj.m_main.bstack = getBasePtr();
            }
            else version( StackGrowsDown )
                obj.m_main.bstack = &obj + 1;
            else
                obj.m_main.bstack = &obj;
            obj.m_main.tstack = obj.m_main.bstack;
            assert( obj.m_curr == &obj.m_main );
            Thread.add( &obj.m_main );
            Thread.setThis( obj );

            // NOTE: No GC allocations may occur until the stack pointers have
            //       been set and Thread.getThis returns a valid reference to
            //       this thread object (this latter condition is not strictly
            //       necessary on Win32 but it should be followed for the sake
            //       of consistency).

            // TODO: Consider putting an auto exception object here (using
            //       alloca) forOutOfMemoryError plus something to track
            //       whether an exception is in-flight?

            try
            {
                obj.run();
            }
            catch( Throwable o )
            {
                obj.m_unhandled = o;
            }
            return null;
        }


        //
        // used to track the number of suspended threads
        //
        version(AtomicSuspendCount){
            int suspendCount;
        } else {
            sem_t   suspendCount;
        }


        extern (C) void thread_suspendHandler( int sig )
        in
        {
            assert( sig == SIGUSR1 );
        }
        body
        {
            version( LDC)
            {
                version(X86)
                {
                    uint eax,ecx,edx,ebx,ebp,esi,edi;
                    asm
                    {
                        mov eax[EBP], EAX      ;
                        mov ecx[EBP], ECX      ;
                        mov edx[EBP], EDX      ;
                        mov ebx[EBP], EBX      ;
                        mov ebp[EBP], EBP      ;
                        mov esi[EBP], ESI      ;
                        mov edi[EBP], EDI      ;
                    }
                }
                else version (X86_64)
                {
                    ulong rax,rbx,rcx,rdx,rbp,rsi,rdi,rsp,r8,r9,r10,r11,r12,r13,r14,r15;
                    asm
                    {
                        movq rax[RBP], RAX        ;
                        movq rbx[RBP], RBX        ;
                        movq rcx[RBP], RCX        ;
                        movq rdx[RBP], RDX        ;
                        movq rbp[RBP], RBP        ;
                        movq rsi[RBP], RSI        ;
                        movq rdi[RBP], RDI        ;
                        movq rsp[RBP], RSP        ;
                        movq r8 [RBP], R8         ; 
                        movq r9 [RBP], R9         ; 
                        movq r10[RBP], R10        ;
                        movq r11[RBP], R11        ;
                        movq r12[RBP], R12        ;
                        movq r13[RBP], R13        ;
                        movq r14[RBP], R14        ;
                        movq r15[RBP], R15        ;
                    }
                }
                else
                {
                    static assert( false, "Architecture not supported." );
                }
            }
            else version( D_InlineAsm_X86 )
            {
                asm
                {
                    pushad;
                }
            }
            else version( GNU )
            {
                __builtin_unwind_init();
            }
            else version ( D_InlineAsm_X86_64 )
            {
                asm
                {
                    // Not sure what goes here, pushad is invalid in 64 bit code
                    push RAX ;
                    push RBX ;
                    push RCX ;
                    push RDX ;
                    push RSI ;
                    push RDI ;
                    push RBP ;
                    push R8  ;
                    push R9  ;
                    push R10 ;
                    push R11 ;
                    push R12 ;
                    push R13 ;
                    push R14 ;
                    push R15 ;
                    push EAX ;   // 16 byte align the stack
                }
            }
            else
            {
                static assert( false, "Architecture not supported." );
            }

            // NOTE: Since registers are being pushed and popped from the stack,
            //       any other stack data used by this function should be gone
            //       before the stack cleanup code is called below.
            {
                Thread  obj = Thread.getThis();

                // NOTE: The thread reference returned by getThis is set within
                //       the thread startup code, so it is possible that this
                //       handler may be called before the reference is set.  In
                //       this case it is safe to simply suspend and not worry
                //       about the stack pointers as the thread will not have
                //       any references to GC-managed data.
                if( obj && !obj.m_lock )
                {
                    obj.m_curr.tstack = getStackTop();
                }

                sigset_t    sigres = void;
                int         status;

                status = sigfillset( &sigres );
                assert( status == 0 );

                status = sigdelset( &sigres, SIGUSR2 );
                assert( status == 0 );

                version (AtomicSuspendCount){
                    auto oldV=flagAdd(suspendCount,1);
                } else {
                    status = sem_post( &suspendCount );
                    assert( status == 0 );
                }

                // here one could do some work (like scan the current stack in this thread...)

                sigsuspend( &sigres );

                if( obj && !obj.m_lock )
                {
                    obj.m_curr.tstack = obj.m_curr.bstack;
                }
            }

            version( LDC)
            {
                // nothing to pop
            }
            else version( D_InlineAsm_X86 )
            {
                asm
                {
                    popad;
                }
            }
            else version( GNU )
            {
                // registers will be popped automatically
            }
            else version ( D_InlineAsm_X86_64 )
            {
                asm
                {
                    // Not sure what goes here, popad is invalid in 64 bit code
                    pop EAX ;   // 16 byte align the stack
                    pop R15 ;
                    pop R14 ;
                    pop R13 ;
                    pop R12 ;
                    pop R11 ;
                    pop R10 ;
                    pop R9  ;
                    pop R8  ;
                    pop RBP ;
                    pop RDI ;
                    pop RSI ;
                    pop RDX ;
                    pop RCX ;
                    pop RBX ;
                    pop RAX ;
                }
            }
            else
            {
                static assert( false, "Architecture not supported." );
            }
        }


        extern (C) void thread_resumeHandler( int sig )
        in
        {
            assert( sig == SIGUSR2 );
        }
        body
        {
            int status;
            version (AtomicSuspendCount){
                auto oldV=flagAdd(suspendCount,-1);
            } else {
                status = sem_post( &suspendCount );
            }
            assert( status == 0 );
        }
    }
    
    alias void function(int) sHandler;
    sHandler _thread_abortHandler=null;
    
    extern (C) void thread_abortHandler( int sig ){
        if (_thread_abortHandler!is null){
            _thread_abortHandler(sig);
        } else {
            exit(-1);
        }
    }
    
    extern (C) void setthread_abortHandler(sHandler f){
        _thread_abortHandler=f;
    }

}
else
{
    // NOTE: This is the only place threading versions are checked.  If a new
    //       version is added, the module code will need to be searched for
    //       places where version-specific code may be required.  This can be
    //       easily accomlished by searching for 'Windows' or 'Posix'.
    static assert( false, "Unknown threading implementation." );
}


////////////////////////////////////////////////////////////////////////////////
// Thread
////////////////////////////////////////////////////////////////////////////////


/**
 * This class encapsulates all threading functionality for the D
 * programming language.  As thread manipulation is a required facility
 * for garbage collection, all user threads should derive from this
 * class, and instances of this class should never be explicitly deleted.
 * A new thread may be created using either derivation or composition, as
 * in the following example.
 *
 * Example:
 * -----------------------------------------------------------------------------
 * class DerivedThread : Thread
 * {
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private :
 *     void run()
 *     {
 *         printf( "Derived thread running.\n" );
 *     }
 * }
 *
 * void threadFunc()
 * {
 *     printf( "Composed thread running.\n" );
 * }
 *
 * // create instances of each type
 * Thread derived = new DerivedThread();
 * Thread composed = new Thread( &threadFunc );
 *
 * // start both threads
 * derived.start();
 * composed.start();
 * -----------------------------------------------------------------------------
 */
class Thread
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a thread object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  fn must not be null.
     */
    this( void function() fn, size_t sz = 0 )
    in
    {
        assert( fn );
    }
    body
    {
        m_fn   = fn;
        m_sz   = sz;
        m_call = Call.FN;
        m_curr = &m_main;
    }


    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  dg must not be null.
     */
    this( void delegate() dg, size_t sz = 0 )
    in
    {
        assert( dg );
    }
    body
    {
        m_dg   = dg;
        m_sz   = sz;
        m_call = Call.DG;
        m_curr = &m_main;
    }


    /**
     * Cleans up any remaining resources used by this object.
     */
    ~this()
    {
        if( m_addr == m_addr.init )
        {
            return;
        }

        version( Win32 )
        {
            m_addr = m_addr.init;
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version( Posix )
        {
            pthread_detach( m_addr );
            m_addr = m_addr.init;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Starts the thread and invokes the function or delegate passed upon
     * construction.
     *
     * In:
     *  This routine may only be called once per thread instance.
     *
     * Throws:
     *  ThreadException if the thread fails to start.
     */
    final void start()
    in
    {
        assert( !next && !prev );
    }
    body
    {
        version( Win32 ) {} else
        version( Posix )
        {
            pthread_attr_t  attr;

            if( pthread_attr_init( &attr ) )
                throw new ThreadException( "Error initializing thread attributes" );
            if( m_sz && pthread_attr_setstacksize( &attr, m_sz ) )
                throw new ThreadException( "Error initializing thread stack size" );
            if( pthread_attr_setdetachstate( &attr, PTHREAD_CREATE_JOINABLE ) )
                throw new ThreadException( "Error setting thread joinable" );
        }

        // NOTE: This operation needs to be synchronized to avoid a race
        //       condition with the GC.  Without this lock, the thread
        //       could start and allocate memory before being added to
        //       the global thread list, preventing it from being scanned
        //       and causing memory to be collected that is still in use.
        synchronized( slock )
        {
            volatile multiThreadedFlag = true;
            version( Win32 )
            {
                m_hndl = cast(HANDLE) _beginthreadex( null, m_sz, &thread_entryPoint, cast(void*) this, 0, &m_addr );
                if( cast(size_t) m_hndl == 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            else version( Posix )
            {
                m_isRunning = true;
                scope( failure ) m_isRunning = false;
                if( pthread_create( &m_addr, &attr, &thread_entryPoint, cast(void*) this ) != 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            add( this );
        }
    }


    /**
     * Waits for this thread to complete.  If the thread terminated as the
     * result of an unhandled exception, this exception will be rethrown.
     *
     * Params:
     *  rethrow = Rethrow any unhandled exception which may have caused this
     *            thread to terminate.
     *
     * Throws:
     *  ThreadException if the operation fails.
     *  Any exception not handled by the joined thread.
     *
     * Returns:
     *  Any exception not handled by this thread if rethrow = false, null
     *  otherwise.
     */
    final Object join( bool rethrow = true )
    {
        if(!isRunning())
            return null;

        version( Win32 )
        {
            if( WaitForSingleObject( m_hndl, INFINITE ) != WAIT_OBJECT_0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: m_addr must be cleared before m_hndl is closed to avoid
            //       a race condition with isRunning.  The operation is labeled
            //       volatile to prevent compiler reordering.
            volatile m_addr = m_addr.init;
            CloseHandle( m_hndl );
            m_hndl = m_hndl.init;
        }
        else version( Posix )
        {
            if( pthread_join( m_addr, null ) != 0 )
                throw new ThreadException( "Unable to join thread" );
            // NOTE: pthread_join acts as a substitute for pthread_detach,
            //       which is normally called by the dtor.  Setting m_addr
            //       to zero ensures that pthread_detach will not be called
            //       on object destruction.
            volatile m_addr = m_addr.init;
        }
        if( m_unhandled )
        {
            if( rethrow )
                throw m_unhandled;
            return m_unhandled;
        }
        return null;
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Properties
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Gets the user-readable label for this thread.
     *
     * Returns:
     *  The name of this thread.
     */
    final char[] name()
    {
        synchronized( this )
        {
            return m_name;
        }
    }


    /**
     * Sets the user-readable label for this thread.
     *
     * Params:
     *  val = The new name of this thread.
     */
    final void name( char[] val )
    {
        synchronized( this )
        {
            m_name = val.dup;
        }
    }


    /**
     * Gets the daemon status for this thread.  While the runtime will wait for
     * all normal threads to complete before tearing down the process, daemon
     * threads are effectively ignored and thus will not prevent the process
     * from terminating.  In effect, daemon threads will be terminated
     * automatically by the OS when the process exits.
     *
     * Returns:
     *  true if this is a daemon thread.
     */
    final bool isDaemon()
    {
        synchronized( this )
        {
            return m_isDaemon;
        }
    }


    /**
     * Sets the daemon status for this thread.  While the runtime will wait for
     * all normal threads to complete before tearing down the process, daemon
     * threads are effectively ignored and thus will not prevent the process
     * from terminating.  In effect, daemon threads will be terminated
     * automatically by the OS when the process exits.
     *
     * Params:
     *  val = The new daemon status for this thread.
     */
    final void isDaemon( bool val )
    {
        synchronized( this )
        {
            m_isDaemon = val;
        }
    }


    /**
     * Tests whether this thread is running.
     *
     * Returns:
     *  true if the thread is running, false if not.
     */
    final bool isRunning()
    {
        if( m_addr == m_addr.init )
        {
            return false;
        }

        version( Win32 )
        {
            uint ecode = 0;
            GetExitCodeThread( m_hndl, &ecode );
            return ecode == STILL_ACTIVE;
        }
        else version( Posix )
        {
            // NOTE: It should be safe to access this value without
            //       memory barriers because word-tearing and such
            //       really isn't an issue for boolean values.
            return m_isRunning;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Thread Priority Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * The minimum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the minimum valid priority for the scheduling policy of
     * the process.
     */
    static const int PRIORITY_MIN;


    /**
     * The maximum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the minimum valid priority for the scheduling policy of
     * the process.
     */
    static const int PRIORITY_MAX;


    /**
     * Gets the scheduling priority for the associated thread.
     *
     * Returns:
     *  The scheduling priority of this thread.
     */
    final int priority()
    {
        version( Win32 )
        {
            return GetThreadPriority( m_hndl );
        }
        else version( Posix )
        {
            int         policy;
            sched_param param;

            if( pthread_getschedparam( m_addr, &policy, &param ) )
                throw new ThreadException( "Unable to get thread priority" );
            return param.sched_priority;
        }
    }


    /**
     * Sets the scheduling priority for the associated thread.
     *
     * Params:
     *  val = The new scheduling priority of this thread.
     */
    final void priority( int val )
    {
        version( Win32 )
        {
            if( !SetThreadPriority( m_hndl, val ) )
                throw new ThreadException( "Unable to set thread priority" );
        }
        else version( Posix )
        {
            // NOTE: pthread_setschedprio is not implemented on linux, so use
            //       the more complicated get/set sequence below.
            //if( pthread_setschedprio( m_addr, val ) )
            //    throw new ThreadException( "Unable to set thread priority" );

            int         policy;
            sched_param param;

            if( pthread_getschedparam( m_addr, &policy, &param ) )
                throw new ThreadException( "Unable to set thread priority" );
            param.sched_priority = val;
            if( pthread_setschedparam( m_addr, policy, &param ) )
                throw new ThreadException( "Unable to set thread priority" );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended,
     *           in seconds.  Sub-second durations are specified as fractional
     *           values.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( 0.05 ); // sleep for 50 milliseconds
     * Thread.sleep( 5 );    // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( double period )
    in
    {
        // NOTE: The fractional value added to period is to correct fp error.
        assert( period * 1000 + 0.1 < uint.max - 1 );
    }
    body
    {
        version( Win32 )
        {
            Sleep( cast(uint)( period * 1000 + 0.1 ) );
        }
        else version( Posix )
        {
            timespec tin  = void;
            timespec tout = void;

            period += 0.000_000_000_1;

            if( tin.tv_sec.max < period )
            {
                tin.tv_sec  = tin.tv_sec.max;
                tin.tv_nsec = 0;
            }
            else
            {
                tin.tv_sec  = cast(typeof(tin.tv_sec))  period;
                tin.tv_nsec = cast(typeof(tin.tv_nsec)) ((period % 1.0) * 1_000_000_000);
            }

            while( true )
            {
                if( !nanosleep( &tin, &tout ) )
                    return;
                if( getErrno() != EINTR )
                    throw new ThreadException( "Unable to sleep for specified duration" );
                tin = tout;
            }
        }
    }


    /+
    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( TimeSpan.milliseconds( 50 ) ); // sleep for 50 milliseconds
     * Thread.sleep( TimeSpan.seconds( 5 ) );       // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( TimeSpan period )
    in
    {
        assert( period.milliseconds < uint.max - 1 );
    }
    body
    {
        version( Win32 )
        {
            Sleep( cast(uint)( period.milliseconds ) );
        }
        else version( Posix )
        {
            timespec tin  = void;
            timespec tout = void;

            if( tin.tv_sec.max < period.seconds )
            {
                tin.tv_sec  = tin.tv_sec.max;
                tin.tv_nsec = 0;
            }
            else
            {
                tin.tv_sec  = cast(typeof(tin.tv_sec))  period.seconds;
                tin.tv_nsec = cast(typeof(tin.tv_nsec)) period.nanoseconds % 1_000_000_000;
            }

            while( true )
            {
                if( !nanosleep( &tin, &tout ) )
                    return;
                if( getErrno() != EINTR )
                    throw new ThreadException( "Unable to sleep for specified duration" );
                tin = tout;
            }
        }
    }


    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended,
     *           in seconds.  Sub-second durations are specified as fractional
     *           values.  Please note that because period is a floating-point
     *           number, some accuracy may be lost for certain intervals.  For
     *           this reason, the TimeSpan overload is preferred in instances
     *           where an exact interval is required.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( 0.05 ); // sleep for 50 milliseconds
     * Thread.sleep( 5 );    // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( double period )
    {
      sleep( TimeSpan.interval( period ) );
    }
    +/


    /**
     * Forces a context switch to occur away from the calling thread.
     */
    static void yield()
    {
        version( Win32 )
        {
            // NOTE: Sleep(1) is necessary because Sleep(0) does not give
            //       lower priority threads any timeslice, so looping on
            //       Sleep(0) could be resource-intensive in some cases.
            Sleep( 1 );
        }
        else version( Posix )
        {
            sched_yield();
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Thread Accessors
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Provides a reference to the calling thread.
     *
     * Returns:
     *  The thread object representing the calling thread.  The result of
     *  deleting this object is undefined.
     */
    static Thread getThis()
    {
        // NOTE: This function may not be called until thread_init has
        //       completed.  See thread_suspendAll for more information
        //       on why this might occur.
        version( Win32 )
        {
            return cast(Thread) TlsGetValue( sm_this );
        }
        else version( Posix )
        {
            return cast(Thread) pthread_getspecific( sm_this );
        }
    }


    /**
     * Provides a list of all threads currently being tracked by the system.
     *
     * Returns:
     *  An array containing references to all threads currently being
     *  tracked by the system.  The result of deleting any contained
     *  objects is undefined.
     */
    static Thread[] getAll()
    {
        Thread[] buf;
        while(1){
            if (buf) delete buf;
            buf = new Thread[sm_tlen];
            synchronized( slock )
            {
                size_t   pos = 0;
                if (buf.length<sm_tlen) {
                    continue;
                } else {
                    buf.length=sm_tlen;
                }
                foreach( Thread t; Thread )
                {
                    buf[pos++] = t;
                }
                return buf;
            }
        }
    }


    /**
     * Operates on all threads currently being tracked by the system.  The
     * result of deleting any Thread object is undefined.
     *
     * Params:
     *  dg = The supplied code as a delegate.
     *
     * Returns:
     *  Zero if all elemented are visited, nonzero if not.
     */
    static int opApply( int delegate( ref Thread ) dg )
    {
        synchronized( slock )
        {
            int ret = 0;

            for( Thread t = sm_tbeg; t; t = t.next )
            {
                ret = dg( t );
                if( ret )
                    break;
            }
            return ret;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Local Storage Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Indicates the number of local storage pointers available at program
     * startup.  It is recommended that this number be at least 64.
     */
    static const uint LOCAL_MAX = 64;


    /**
     * Reserves a local storage pointer for use and initializes this location
     * to null for all running threads.
     *
     * Returns:
     *  A key representing the array offset of this memory location.
     */
    static uint createLocal()
    {
        synchronized( slock )
        {
            foreach( uint key, ref bool set; sm_local )
            {
                if( !set )
                {
                    //foreach( Thread t; sm_tbeg ) Bug in GDC 0.24 SVN (r139)
                    for( Thread t = sm_tbeg; t; t = t.next )
                    {
                        t.m_local[key] = null;
                    }
                    set = true;
                    return key;
                }
            }
            throw new ThreadException( "No more local storage slots available" );
        }
    }


    /**
     * Marks the supplied key as available and sets the associated location
     * to null for all running threads.  It is assumed that any key passed
     * to this function is valid.  The result of calling this function for
     * a key which is still in use is undefined.
     *
     * Params:
     *  key = The key to delete.
     */
    static void deleteLocal( uint key )
    {
        synchronized( slock )
        {
            sm_local[key] = false;
            // foreach( Thread t; sm_tbeg ) Bug in GDC 0.24 SVN (r139)
            for( Thread t = sm_tbeg; t; t = t.next )
            {
                t.m_local[key] = null;
            }
        }
    }


    /**
     * Loads the value stored at key within a thread-local static array.  It is
     * assumed that any key passed to this function is valid.
     *
     * Params:
     *  key = The location which holds the desired data.
     *
     * Returns:
     *  The data associated with the supplied key.
     */
    static void* getLocal( uint key )
    {
        return getThis().m_local[key];
    }


    /**
     * Stores the supplied value at key within a thread-local static array.  It
     * is assumed that any key passed to this function is valid.
     *
     * Params:
     *  key = The location to store the supplied data.
     *  val = The data to store.
     *
     * Returns:
     *  A copy of the data which has just been stored.
     */
    static void* setLocal( uint key, void* val )
    {
        return getThis().m_local[key] = val;
    }


    ////////////////////////////////////////////////////////////////////////////
    // Static Initalizer
    ////////////////////////////////////////////////////////////////////////////


    /**
     * This initializer is used to set thread constants.  All functional
     * initialization occurs within thread_init().
     */
    static this()
    {
        version( Win32 )
        {
            PRIORITY_MIN = -15;
            PRIORITY_MAX =  15;
        }
        else version( Posix )
        {
            int         policy;
            sched_param param;
            pthread_t   self = pthread_self();

            int status = pthread_getschedparam( self, &policy, &param );
            assert( status == 0 );

            PRIORITY_MIN = sched_get_priority_min( policy );
            assert( PRIORITY_MIN != -1 );

            PRIORITY_MAX = sched_get_priority_max( policy );
            assert( PRIORITY_MAX != -1 );
        }
    }


private:
    //
    // Initializes a thread object which has no associated executable function.
    // This is used for the main thread initialized in thread_init().
    //
    this()
    {
        m_call = Call.NO;
        m_curr = &m_main;
    }


    //
    // Thread entry point.  Invokes the function or delegate passed on
    // construction (if any).
    //
    final void run()
    {
        switch( m_call )
        {
        case Call.FN:
            m_fn();
            break;
        case Call.DG:
            m_dg();
            break;
        default:
            break;
        }
    }


private:
    //
    // The type of routine passed on thread construction.
    //
    enum Call
    {
        NO,
        FN,
        DG
    }


    //
    // Standard types
    //
    version( Win32 )
    {
        alias uint TLSKey;
        alias uint ThreadAddr;
    }
    else version( Posix )
    {
        alias pthread_key_t TLSKey;
        alias pthread_t     ThreadAddr;
    }


    //
    // Local storage
    //
    static bool[LOCAL_MAX]  sm_local;
    static TLSKey           sm_this;

    void*[LOCAL_MAX]        m_local;


    //
    // Standard thread data
    //
    version( Win32 )
    {
        HANDLE          m_hndl;
    }
    public ThreadAddr          m_addr;
    Call                m_call;
    char[]              m_name;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }
    size_t              m_sz;
    version( Posix )
    {
        bool            m_isRunning;
    }
    bool                m_isDaemon;
    public Throwable              m_unhandled;


private:
    ////////////////////////////////////////////////////////////////////////////
    // Storage of Active Thread
    ////////////////////////////////////////////////////////////////////////////


    //
    // Sets a thread-local reference to the current thread object.
    //
    static void setThis( Thread t )
    {
        version( Win32 )
        {
            TlsSetValue( sm_this, cast(void*) t );
        }
        else version( Posix )
        {
            pthread_setspecific( sm_this, cast(void*) t );
        }
    }


private:
    ////////////////////////////////////////////////////////////////////////////
    // Thread Context and GC Scanning Support
    ////////////////////////////////////////////////////////////////////////////


    final void pushContext( Context* c )
    in
    {
        assert( !c.within );
    }
    body
    {
        c.within = m_curr;
        m_curr = c;
    }


    final void popContext()
    in
    {
        assert( m_curr && m_curr.within );
    }
    body
    {
        Context* c = m_curr;
        m_curr = c.within;
        c.within = null;
    }


    public final Context* topContext()
    in
    {
        assert( m_curr );
    }
    body
    {
        return m_curr;
    }


    public static struct Context
    {
        void*           bstack,
                        tstack;
        Context*        within;
        Context*        next,
                        prev;
    }


    Context             m_main;
    Context*            m_curr;
    bool                m_lock;

    version( Win32 )
    {
        uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
    }


private:
    ////////////////////////////////////////////////////////////////////////////
    // GC Scanning Support
    ////////////////////////////////////////////////////////////////////////////


    // NOTE: The GC scanning process works like so:
    //
    //          1. Suspend all threads.
    //          2. Scan the stacks of all suspended threads for roots.
    //          3. Resume all threads.
    //
    //       Step 1 and 3 require a list of all threads in the system, while
    //       step 2 requires a list of all thread stacks (each represented by
    //       a Context struct).  Traditionally, there was one stack per thread
    //       and the Context structs were not necessary.  However, Fibers have
    //       changed things so that each thread has its own 'main' stack plus
    //       an arbitrary number of nested stacks (normally referenced via
    //       m_curr).  Also, there may be 'free-floating' stacks in the system,
    //       which are Fibers that are not currently executing on any specific
    //       thread but are still being processed and still contain valid
    //       roots.
    //
    //       To support all of this, the Context struct has been created to
    //       represent a stack range, and a global list of Context structs has
    //       been added to enable scanning of these stack ranges.  The lifetime
    //       (and presence in the Context list) of a thread's 'main' stack will
    //       be equivalent to the thread's lifetime.  So the Ccontext will be
    //       added to the list on thread entry, and removed from the list on
    //       thread exit (which is essentially the same as the presence of a
    //       Thread object in its own global list).  The lifetime of a Fiber's
    //       context, however, will be tied to the lifetime of the Fiber object
    //       itself, and Fibers are expected to add/remove their Context struct
    //       on construction/deletion.


    //
    // All use of the global lists should synchronize on this lock.
    //
    static Object slock()
    {
        return Thread.classinfo;
    }


    static Context*     sm_cbeg;
    static size_t       sm_clen;

    static Thread       sm_tbeg;
    static size_t       sm_tlen;

    //
    // Used for ordering threads in the global thread list.
    //
    Thread              prev;
    Thread              next;


    ////////////////////////////////////////////////////////////////////////////
    // Global Context List Operations
    ////////////////////////////////////////////////////////////////////////////


    //
    // Add a context to the global context list.
    //
    static void add( Context* c )
    in
    {
        assert( c );
        assert( !c.next && !c.prev );
    }
    body
    {
        synchronized( slock )
        {
            if( sm_cbeg )
            {
                c.next = sm_cbeg;
                sm_cbeg.prev = c;
            }
            sm_cbeg = c;
            ++sm_clen;
        }
    }


    //
    // Remove a context from the global context list.
    //
    static void remove( Context* c )
    in
    {
        assert( c );
        assert( c.next || c.prev );
    }
    body
    {
        synchronized( slock )
        {
            if( c.prev )
                c.prev.next = c.next;
            if( c.next )
                c.next.prev = c.prev;
            if( sm_cbeg == c )
                sm_cbeg = c.next;
            --sm_clen;
        }
        // NOTE: Don't null out c.next or c.prev because opApply currently
        //       follows c.next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this function,
        //       however, a context should never be re-added to the list anyway
        //       and having next and prev be non-null is a good way to
        //       ensure that.
    }


    ////////////////////////////////////////////////////////////////////////////
    // Global Thread List Operations
    ////////////////////////////////////////////////////////////////////////////


    //
    // Add a thread to the global thread list.
    //
    static void add( Thread t )
    in
    {
        assert( t );
        assert( !t.next && !t.prev );
        assert( t.isRunning );
    }
    body
    {
        synchronized( slock )
        {
            if( sm_tbeg )
            {
                t.next = sm_tbeg;
                sm_tbeg.prev = t;
            }
            sm_tbeg = t;
            ++sm_tlen;
        }
    }


    //
    // Remove a thread from the global thread list.
    //
    static void remove( Thread t )
    in
    {
        assert( t );
        assert( t.next || t.prev );
    }
    body
    {
        synchronized( slock )
        {
            // NOTE: When a thread is removed from the global thread list its
            //       main context is invalid and should be removed as well.
            //       It is possible that t.m_curr could reference more
            //       than just the main context if the thread exited abnormally
            //       (if it was terminated), but we must assume that the user
            //       retains a reference to them and that they may be re-used
            //       elsewhere.  Therefore, it is the responsibility of any
            //       object that creates contexts to clean them up properly
            //       when it is done with them.
            remove( &t.m_main );

            if( t.prev )
                t.prev.next = t.next;
            if( t.next )
                t.next.prev = t.prev;
            if( sm_tbeg == t )
                sm_tbeg = t.next;
            --sm_tlen;
        }
        // NOTE: Don't null out t.next or t.prev because opApply currently
        //       follows t.next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this function,
        //       however, a thread should never be re-added to the list anyway
        //       and having next and prev be non-null is a good way to
        //       ensure that.
    }
}


////////////////////////////////////////////////////////////////////////////////
// GC Support Routines
////////////////////////////////////////////////////////////////////////////////


/**
 * Initializes the thread module.  This function must be called by the
 * garbage collector on startup and before any other thread routines
 * are called.
 */
extern (C) void thread_init()
{
    // NOTE: If thread_init itself performs any allocations then the thread
    //       routines reserved for garbage collector use may be called while
    //       thread_init is being processed.  However, since no memory should
    //       exist to be scanned at this point, it is sufficient for these
    //       functions to detect the condition and return immediately.

    version( Win32 )
    {
        Thread.sm_this = TlsAlloc();
        assert( Thread.sm_this != TLS_OUT_OF_INDEXES );
        Fiber.sm_this = TlsAlloc();
        assert( Thread.sm_this != TLS_OUT_OF_INDEXES );
    }
    else version( Posix )
    {
        int         status;
        sigaction_t sigusr1 = void;
        sigaction_t sigusr2 = void;
        sigaction_t sigabrt = void;

        // This is a quick way to zero-initialize the structs without using
        // memset or creating a link dependency on their static initializer.
        (cast(byte*) &sigusr1)[0 .. sigaction_t.sizeof] = 0;
        (cast(byte*) &sigusr2)[0 .. sigaction_t.sizeof] = 0;
        (cast(byte*) &sigabrt)[0 .. sigaction_t.sizeof] = 0;

        // NOTE: SA_RESTART indicates that system calls should restart if they
        //       are interrupted by a signal, but this is not available on all
        //       Posix systems, even those that support multithreading.
        static if( is( typeof( SA_RESTART ) ) )
            sigusr1.sa_flags = SA_RESTART;
        else
            sigusr1.sa_flags   = 0;
        sigusr1.sa_handler = &thread_suspendHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr1.sa_mask );
        assert( status == 0 );
        status = sigdelset( &sigusr1.sa_mask , SIGABRT);
        assert( status == 0 );

        // NOTE: Since SIGUSR2 should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        sigusr2.sa_flags   = 0;
        sigusr2.sa_handler = &thread_resumeHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr2.sa_mask );
        assert( status == 0 );
        status = sigdelset( &sigusr2.sa_mask , SIGABRT);
        assert( status == 0 );

        status = sigaction( SIGUSR1, &sigusr1, null );
        assert( status == 0 );

        status = sigaction( SIGUSR2, &sigusr2, null );
        assert( status == 0 );

        // NOTE: SA_RESTART indicates that system calls should restart if they
        //       are interrupted by a signal, but this is not available on all
        //       Posix systems, even those that support multithreading.
        static if( is( typeof( SA_RESTART ) ) )
            sigabrt.sa_flags = SA_RESTART;
        else
            sigabrt.sa_flags   = 0;
        sigabrt.sa_handler = &thread_abortHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigabrt.sa_mask );
        assert( status == 0 );
        
        status = sigaction( SIGABRT, &sigabrt, null );
        assert( status == 0 );

        version(AtomicSuspendCount){
            suspendCount=0;
        } else {
            status = sem_init( &suspendCount, 0, 0 );
        }
        assert( status == 0 );

        status = pthread_key_create( &Thread.sm_this, null );
        assert( status == 0 );
        status = pthread_key_create( &Fiber.sm_this, null );
        assert( status == 0 );
    }

    thread_attachThis();
}


/**
 * Registers the calling thread for use with Tango.  If this routine is called
 * for a thread which is already registered, the result is undefined.
 */
extern (C) void thread_attachThis()
{
    version( Win32 )
    {
        Thread          thisThread  = new Thread();
        Thread.Context* thisContext = &thisThread.m_main;
        assert( thisContext == thisThread.m_curr );

        thisThread.m_addr  = GetCurrentThreadId();
        thisThread.m_hndl  = GetCurrentThreadHandle();
        thisContext.bstack = getStackBottom();
        thisContext.tstack = thisContext.bstack;

        thisThread.m_isDaemon = true;

        Thread.setThis( thisThread );
    }
    else version( Posix )
    {
        Thread          thisThread  = new Thread();
        Thread.Context* thisContext = thisThread.m_curr;
        assert( thisContext == &thisThread.m_main );

        thisThread.m_addr  = pthread_self();
        thisContext.bstack = getStackBottom();
        thisContext.tstack = thisContext.bstack;

        thisThread.m_isRunning = true;
        thisThread.m_isDaemon  = true;

        Thread.setThis( thisThread );
    }

    Thread.add( thisThread );
    Thread.add( thisContext );
}


/**
 * Deregisters the calling thread from use with Tango.  If this routine is
 * called for a thread which is already registered, the result is undefined.
 */
extern (C) void thread_detachThis()
{
    Thread.remove( Thread.getThis() );
}


/**
 * Joins all non-daemon threads that are currently running.  This is done by
 * performing successive scans through the thread list until a scan consists
 * of only daemon threads.
 */
extern (C) void thread_joinAll()
{

    while( true )
    {
        Thread nonDaemon = null;

        foreach( t; Thread )
        {
            if( !t.isDaemon )
            {
                nonDaemon = t;
                break;
            }
        }
        if( nonDaemon is null )
            return;
        nonDaemon.join();
    }
}


/**
 * Performs intermediate shutdown of the thread module.
 */
static ~this()
{
    // NOTE: The functionality related to garbage collection must be minimally
    //       operable after this dtor completes.  Therefore, only minimal
    //       cleanup may occur.

    for( Thread t = Thread.sm_tbeg; t; t = t.next )
    {
        if( !t.isRunning )
            Thread.remove( t );
    }
}


// Used for needLock below
private bool multiThreadedFlag = false;


/**
 * This function is used to determine whether the the process is
 * multi-threaded.  Optimizations may only be performed on this
 * value if the programmer can guarantee that no path from the
 * enclosed code will start a thread.
 *
 * Returns:
 *  True if Thread.start() has been called in this process.
 */
extern (C) bool thread_needLock()
{
    return multiThreadedFlag;
}


// Used for suspendAll/resumeAll below
private uint suspendDepth = 0;

/**
 * Suspend all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function may be called multiple times, and must
 * be followed by a matching number of calls to thread_resumeAll before
 * processing is resumed.
 *
 * Throws:
 *  ThreadException if the suspend operation fails for a running thread.
 */
extern (C) void thread_suspendAll()
{
    int suspendedCount=0;
    /**
     * Suspend the specified thread and load stack and register information for
     * use by thread_scanAll.  If the supplied thread is the calling thread,
     * stack and register information will be loaded but the thread will not
     * be suspended.  If the suspend operation fails and the thread is not
     * running then it will be removed from the global thread list, otherwise
     * an exception will be thrown.
     *
     * Params:
     *  t = The thread to suspend.
     *
     * Throws:
     *  ThreadException if the suspend operation fails for a running thread.
     */
    void suspend( Thread t )
    {
        version( Win32 )
        {
            if( t.m_addr != GetCurrentThreadId() && SuspendThread( t.m_hndl ) == 0xFFFFFFFF )
            {
                if( !t.isRunning )
                {
                    Thread.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to suspend thread" );
            }

            CONTEXT context = void;
            context.ContextFlags = CONTEXT_INTEGER | CONTEXT_CONTROL;

            if( !GetThreadContext( t.m_hndl, &context ) )
                throw new ThreadException( "Unable to load thread context" );
            if( !t.m_lock )
                t.m_curr.tstack = cast(void*) context.Esp;
            // edi,esi,ebp,esp,ebx,edx,ecx,eax
            t.m_reg[0] = context.Edi;
            t.m_reg[1] = context.Esi;
            t.m_reg[2] = context.Ebp;
            t.m_reg[3] = context.Esp;
            t.m_reg[4] = context.Ebx;
            t.m_reg[5] = context.Edx;
            t.m_reg[6] = context.Ecx;
            t.m_reg[7] = context.Eax;
        }
        else version( Posix )
        {
            if( t.m_addr != pthread_self() )
            {
                if( pthread_kill( t.m_addr, SIGUSR1 ) != 0 )
                {
                    if( !t.isRunning )
                    {
                        Thread.remove( t );
                        return;
                    }
                    throw new ThreadException( "Unable to suspend thread" );
                }
                version (AtomicSuspendCount){
                    ++suspendedCount;
                    version(AtomicSuspendCount){
                        version(SuspendOneAtTime){ // when debugging suspending all threads at once might give "lost" signals
                            int icycle=0;
                            suspendLoop: while (flagGet(suspendCount)!=suspendedCount){
                                for (size_t i=1000;i!=0;--i){
                                    if (flagGet(suspendCount)==suspendedCount) break suspendLoop;
                                    if (++icycle==100_000){
                                        debug(Thread)
                                            printf("waited %d cycles for thread suspension,  suspendCount=%d, should be %d\nAtomic ops do not work?\nContinuing wait...\n",icycle,suspendCount,suspendedCount);
                                    }
                                    Thread.yield();
                                }
                                Thread.sleep(0.0001);
                            }
                        }
                    }
                    
                } else {
                    sem_wait( &suspendCount );
                    // shouldn't the return be checked and maybe a loop added for further interrupts
                    // as in Semaphore.d ?
                }
            }
            else if( !t.m_lock )
            {
                t.m_curr.tstack = getStackTop();
            }
        }
    }


    // NOTE: We've got an odd chicken & egg problem here, because while the GC
    //       is required to call thread_init before calling any other thread
    //       routines, thread_init may allocate memory which could in turn
    //       trigger a collection.  Thus, thread_suspendAll, thread_scanAll,
    //       and thread_resumeAll must be callable before thread_init completes,
    //       with the assumption that no other GC memory has yet been allocated
    //       by the system, and thus there is no risk of losing data if the
    //       global thread list is empty.  The check of Thread.sm_tbeg
    //       below is done to ensure thread_init has completed, and therefore
    //       that calling Thread.getThis will not result in an error.  For the
    //       short time when Thread.sm_tbeg is null, there is no reason
    //       not to simply call the multithreaded code below, with the
    //       expectation that the foreach loop will never be entered.
    if( !multiThreadedFlag && Thread.sm_tbeg )
    {
        if( ++suspendDepth == 1 ) {
            suspend( Thread.getThis() );
        }
        return;
    }
    _d_monitorenter(Thread.slock);
    {
        if( ++suspendDepth > 1 )
            return;
        // NOTE: I'd really prefer not to check isRunning within this loop but
        //       not doing so could be problematic if threads are termianted
        //       abnormally and a new thread is created with the same thread
        //       address before the next GC run.  This situation might cause
        //       the same thread to be suspended twice, which would likely
        //       cause the second suspend to fail, the garbage collection to
        //       abort, and Bad Things to occur.
        for( Thread t = Thread.sm_tbeg; t; t = t.next )
        {
            if( t.isRunning ){
                suspend( t );
            } else
                Thread.remove( t );
        }

        version( Posix )
        {
            version(AtomicSuspendCount){
                int icycle=0;
                suspendLoop2: while (flagGet(suspendCount)!=suspendedCount){
                    for (size_t i=1000;i!=0;--i){
                        if (flagGet(suspendCount)==suspendedCount) break suspendLoop2;
                        if (++icycle==1000_000){
                            debug(Thread)
                                printf("waited %d cycles for thread suspension,  suspendCount=%d, should be %d\nAtomic ops do not work?\nContinuing wait...\n",icycle,suspendCount,suspendedCount);
                        }
                        Thread.yield();
                    }
                    Thread.sleep(0.0001);
                }
            }
        }
    }
}


/**
 * Resume all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function must be called once for each preceding
 * call to thread_suspendAll before the threads are actually resumed.
 *
 * In:
 *  This routine must be preceded by a call to thread_suspendAll.
 *
 * Throws:
 *  ThreadException if the resume operation fails for a running thread.
 */
extern (C) void thread_resumeAll()
in
{
    assert( suspendDepth > 0 );
}
body
{
    version(AtomicSuspendCount) version(SuspendOneAtTime) auto suspendedCount=flagGet(suspendCount);
    /**
     * Resume the specified thread and unload stack and register information.
     * If the supplied thread is the calling thread, stack and register
     * information will be unloaded but the thread will not be resumed.  If
     * the resume operation fails and the thread is not running then it will
     * be removed from the global thread list, otherwise an exception will be
     * thrown.
     *
     * Params:
     *  t = The thread to resume.
     *
     * Throws:
     *  ThreadException if the resume fails for a running thread.
     */
    void resume( Thread t )
    {
        version( Win32 )
        {
            if( t.m_addr != GetCurrentThreadId() && ResumeThread( t.m_hndl ) == 0xFFFFFFFF )
            {
                if( !t.isRunning )
                {
                    Thread.remove( t );
                    return;
                }
                throw new ThreadException( "Unable to resume thread" );
            }

            if( !t.m_lock )
                t.m_curr.tstack = t.m_curr.bstack;
            t.m_reg[0 .. $] = 0;
        }
        else version( Posix )
        {
            if( t.m_addr != pthread_self() )
            {
                if( pthread_kill( t.m_addr, SIGUSR2 ) != 0 )
                {
                    if( !t.isRunning )
                    {
                        Thread.remove( t );
                        return;
                    }
                    throw new ThreadException( "Unable to resume thread" );
                }
                version (AtomicSuspendCount){
                    version(SuspendOneAtTime){ // when debugging suspending all threads at once might give "lost" signals
                        --suspendedCount;
                        int icycle=0;
                        recoverLoop: while(flagGet(suspendCount)>suspendedCount){
                            for (size_t i=1000;i!=0;--i){
                                if (flagGet(suspendCount)==suspendedCount) break recoverLoop;
                                if (++icycle==100_000){
                                    debug(Thread)
                                        printf("waited %d cycles for thread recover,  suspendCount=%d, should be %d\nAtomic ops do not work?\nContinuing wait...\n",icycle,suspendCount,suspendedCount);
                                }
                                Thread.yield();
                            }
                            Thread.sleep(0.0001);
                        }
                    }
                } else {
                    sem_wait( &suspendCount );
                    // shouldn't the return be checked and maybe a loop added for further interrupts
                    // as in Semaphore.d ?
                }
            }
            else if( !t.m_lock )
            {
                t.m_curr.tstack = t.m_curr.bstack;
            }
        }
    }


    // NOTE: See thread_suspendAll for the logic behind this.
    if( !multiThreadedFlag && Thread.sm_tbeg )
    {
        if( --suspendDepth == 0 )
            resume( Thread.getThis() );
        return;
    }

    {
        scope(exit) _d_monitorexit(Thread.slock);
        if( --suspendDepth > 0 )
            return;
        {
            for( Thread t = Thread.sm_tbeg; t; t = t.next )
            {
                resume( t );
            }
            version(AtomicSuspendCount){
                int icycle=0;
                recoverLoop2: while(flagGet(suspendCount)>0){
                    for (size_t i=1000;i!=0;--i){
                        Thread.yield();
                        if (flagGet(suspendCount)==0) break recoverLoop2;
                        if (++icycle==100_000){
                            debug(Thread)
                                printf("waited %d cycles for thread recovery,  suspendCount=%d, should be %d\nAtomic ops do not work?\nContinuing wait...\n",icycle,suspendCount,0);
                        }
                    }
                    Thread.sleep(0.0001);
                }
            }
        }
    }
}


private alias void delegate( void*, void* ) scanAllThreadsFn;


/**
 * The main entry point for garbage collection.  The supplied delegate
 * will be passed ranges representing both stack and register values.
 *
 * Params:
 *  scan        = The scanner function.  It should scan from p1 through p2 - 1.
 *  curStackTop = An optional pointer to the top of the calling thread's stack.
 *
 * In:
 *  This routine must be preceded by a call to thread_suspendAll.
 */
extern (C) void thread_scanAll( scanAllThreadsFn scan, void* curStackTop = null )
in
{
    assert( suspendDepth > 0 );
}
body
{
    Thread  thisThread  = null;
    void*   oldStackTop = null;

    if( curStackTop && Thread.sm_tbeg )
    {
        thisThread  = Thread.getThis();
        if( thisThread && (!thisThread.m_lock) )
        {
            oldStackTop = thisThread.m_curr.tstack;
            thisThread.m_curr.tstack = curStackTop;
        }
    }

    scope( exit )
    {
        if( curStackTop && Thread.sm_tbeg )
        {
            if( thisThread && (!thisThread.m_lock) )
            {
                thisThread.m_curr.tstack = oldStackTop;
            }
        }
    }

    // NOTE: Synchronizing on Thread.slock is not needed because this
    //       function may only be called after all other threads have
    //       been suspended from within the same lock.
    for( Thread.Context* c = Thread.sm_cbeg; c; c = c.next )
    {
        version( StackGrowsDown )
        {
            // NOTE: We can't index past the bottom of the stack
            //       so don't do the "+1" for StackGrowsDown.
            if( c.tstack && c.tstack < c.bstack )
                scan( c.tstack, c.bstack );
        }
        else
        {
            if( c.bstack && c.bstack < c.tstack )
                scan( c.bstack, c.tstack + 1 );
        }
    }
    version( Win32 )
    {
        for( Thread t = Thread.sm_tbeg; t; t = t.next )
        {
            scan( &t.m_reg[0], &t.m_reg[0] + t.m_reg.length );
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Thread Local
////////////////////////////////////////////////////////////////////////////////


/**
 * This class encapsulates the operations required to initialize, access, and
 * destroy thread local data.
 */
class ThreadLocal( T )
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes thread local storage for the indicated value which will be
     * initialized to def for all threads.
     *
     * Params:
     *  def = The default value to return if no value has been explicitly set.
     */
    this( T def = T.init )
    {
        m_def = def;
        m_key = Thread.createLocal();
    }


    ~this()
    {
        Thread.deleteLocal( m_key );
    }


    ////////////////////////////////////////////////////////////////////////////
    // Accessors
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Gets the value last set by the calling thread, or def if no such value
     * has been set.
     *
     * Returns:
     *  The stored value or def if no value is stored.
     */
    T val()
    {
        Wrap* wrap = cast(Wrap*) Thread.getLocal( m_key );

        return wrap ? wrap.val : m_def;
    }


    /**
     * Copies newval to a location specific to the calling thread, and returns
     * newval.
     *
     * Params:
     *  newval = The value to set.
     *
     * Returns:
     *  The value passed to this function.
     */
    T val( T newval )
    {
        Wrap* wrap = cast(Wrap*) Thread.getLocal( m_key );

        if( wrap is null )
        {
            wrap = new Wrap;
            Thread.setLocal( m_key, wrap );
        }
        wrap.val = newval;
        return newval;
    }


private:
    //
    // A wrapper for the stored data.  This is needed for determining whether
    // set has ever been called for this thread (and therefore whether the
    // default value should be returned) and also to flatten the differences
    // between data that is smaller and larger than (void*).sizeof.  The
    // obvious tradeoff here is an extra per-thread allocation for each
    // ThreadLocal value as compared to calling the Thread routines directly.
    //
    struct Wrap
    {
        T   val;
    }


    T       m_def;
    uint    m_key;
}


////////////////////////////////////////////////////////////////////////////////
// Thread Group
////////////////////////////////////////////////////////////////////////////////


/**
 * This class is intended to simplify certain common programming techniques.
 */
class ThreadGroup
{
    /**
     * Creates and starts a new Thread object that executes fn and adds it to
     * the list of tracked threads.
     *
     * Params:
     *  fn = The thread function.
     *
     * Returns:
     *  A reference to the newly created thread.
     */
    final Thread create( void function() fn )
    {
        Thread t = new Thread( fn );

        t.start();
        synchronized( this )
        {
            m_all[t] = t;
        }
        return t;
    }


    /**
     * Creates and starts a new Thread object that executes dg and adds it to
     * the list of tracked threads.
     *
     * Params:
     *  dg = The thread function.
     *
     * Returns:
     *  A reference to the newly created thread.
     */
    final Thread create( void delegate() dg )
    {
        Thread t = new Thread( dg );

        t.start();
        synchronized( this )
        {
            m_all[t] = t;
        }
        return t;
    }


    /**
     * Add t to the list of tracked threads if it is not already being tracked.
     *
     * Params:
     *  t = The thread to add.
     *
     * In:
     *  t must not be null.
     */
    final void add( Thread t )
    in
    {
        assert( t );
    }
    body
    {
        synchronized( this )
        {
            m_all[t] = t;
        }
    }


    /**
     * Removes t from the list of tracked threads.  No operation will be
     * performed if t is not currently being tracked by this object.
     *
     * Params:
     *  t = The thread to remove.
     *
     * In:
     *  t must not be null.
     */
    final void remove( Thread t )
    in
    {
        assert( t );
    }
    body
    {
        synchronized( this )
        {
            m_all.remove( t );
        }
    }


    /**
     * Operates on all threads currently tracked by this object.
     */
    final int opApply( int delegate( ref Thread ) dg )
    {
        synchronized( this )
        {
            int ret = 0;

            // NOTE: This loop relies on the knowledge that m_all uses the
            //       Thread object for both the key and the mapped value.
            foreach( Thread t; m_all.keys )
            {
                ret = dg( t );
                if( ret )
                    break;
            }
            return ret;
        }
    }


    /**
     * Iteratively joins all tracked threads.  This function will block add,
     * remove, and opApply until it completes.
     *
     * Params:
     *  rethrow = Rethrow any unhandled exception which may have caused the
     *            current thread to terminate.
     *
     * Throws:
     *  Any exception not handled by the joined threads.
     */
    final void joinAll( bool rethrow = true )
    {
        synchronized( this )
        {
            // NOTE: This loop relies on the knowledge that m_all uses the
            //       Thread object for both the key and the mapped value.
            foreach( Thread t; m_all.keys )
            {
                t.join( rethrow );
            }
        }
    }


private:
    Thread[Thread]  m_all;
}


////////////////////////////////////////////////////////////////////////////////
// Fiber Platform Detection and Memory Allocation
////////////////////////////////////////////////////////////////////////////////


private
{
    version( D_InlineAsm_X86 )
    {
        version( X86_64 )
        {
            // Shouldn't an x64 compiler be setting D_InlineAsm_X86_64 instead?
        }
        else
        {
            version( Win32 )
                version = AsmX86_Win32;
            else version( Posix )
                version = AsmX86_Posix;
        }
    }
    else version( D_InlineAsm_X86_64 )
    {
        version( Posix )
            version = AsmX86_64_Posix;
    }
    else version( PPC )
    {
        version( Posix )
            version = AsmPPC_Posix;
    }

    version( Posix )
    {
        import tango.stdc.posix.unistd;   // for sysconf
        import tango.stdc.posix.sys.mman; // for mmap
        import tango.stdc.posix.stdlib;   // for malloc, valloc, free

        version( AsmX86_Win32 ) {} else
        version( AsmX86_Posix ) {} else
        version( AsmX86_64_Posix ) {} else
        version( AsmPPC_Posix ) {} else
        {
            // NOTE: The ucontext implementation requires architecture specific
            //       data definitions to operate so testing for it must be done
            //       by checking for the existence of ucontext_t rather than by
            //       a version identifier.  Please note that this is considered
            //       an obsolescent feature according to the POSIX spec, so a
            //       custom solution is still preferred.
            import tango.stdc.posix.ucontext;
            static assert( is( ucontext_t ), "Unknown fiber implementation");
        }
    }
    const size_t PAGESIZE;
}

static this()
{
    static if( is( typeof( GetSystemInfo ) ) )
    {
        SYSTEM_INFO info;
        GetSystemInfo( &info );

        PAGESIZE = info.dwPageSize;
        assert( PAGESIZE < int.max );
    }
    else static if( is( typeof( sysconf ) ) &&
                    is( typeof( _SC_PAGESIZE ) ) )
    {
        PAGESIZE = cast(size_t) sysconf( _SC_PAGESIZE );
        assert( PAGESIZE < int.max );
    }
    else
    {
        version( PPC )
            PAGESIZE = 8192;
        else
            PAGESIZE = 4096;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Fiber Entry Point and Context Switch
////////////////////////////////////////////////////////////////////////////////


private
{
    extern (C) void fiber_entryPoint()
    {
        Fiber   obj = Fiber.getThis();
        assert( obj );

        assert( Thread.getThis().m_curr is obj.m_ctxt );
        volatile Thread.getThis().m_lock = false;
        obj.m_ctxt.tstack = obj.m_ctxt.bstack;
        obj.m_state = Fiber.State.EXEC;

        try
        {
            obj.run();
        }
        catch( Throwable o )
        {
            obj.m_unhandled = o;
        }

        static if( is( ucontext_t ) )
          obj.m_ucur = &obj.m_utxt;

        obj.m_state = Fiber.State.TERM;
        obj.switchOut();
    }


  // NOTE: If AsmPPC_Posix is defined then the context switch routine will
  //       be defined externally until GDC supports inline PPC ASM.
  version( AsmPPC_Posix )
    extern (C) void fiber_switchContext( void** oldp, void* newp );
  else
    extern (C) void fiber_switchContext( void** oldp, void* newp )
    {
        // NOTE: The data pushed and popped in this routine must match the
        //       default stack created by Fiber.initStack or the initial
        //       switch into a new context will fail.

        version( AsmX86_Win32 )
        {
            asm
            {
                naked;

                // save current stack state
                push EBP;
                mov  EBP, ESP;
                push EAX;
                push dword ptr FS:[0];
                push dword ptr FS:[4];
                push dword ptr FS:[8];
                push EBX;
                push ESI;
                push EDI;

                // store oldp again with more accurate address
                mov EAX, dword ptr 8[EBP];
                mov [EAX], ESP;
                // load newp to begin context switch
                mov ESP, dword ptr 12[EBP];

                // load saved state from new stack
                pop EDI;
                pop ESI;
                pop EBX;
                pop dword ptr FS:[8];
                pop dword ptr FS:[4];
                pop dword ptr FS:[0];
                pop EAX;
                pop EBP;

                // 'return' to complete switch
                ret;
            }
        }
        else version( AsmX86_Posix )
        {
            asm
            {
                naked;

                // save current stack state
                push EBP;
                mov  EBP, ESP;
                push EAX;
                push EBX;
                push ECX;
                push ESI;
                push EDI;

                // store oldp again with more accurate address
                mov EAX, dword ptr 8[EBP];
                mov [EAX], ESP;
                // load newp to begin context switch
                mov ESP, dword ptr 12[EBP];

                // load saved state from new stack
                pop EDI;
                pop ESI;
                pop ECX;
                pop EBX;
                pop EAX;
                pop EBP;

                // 'return' to complete switch
                ret;
            }
        }
        else version( AsmX86_64_Posix )
        {
            version( DigitalMars ) const dmdgdc = true;
            else version (GNU) const dmdgdc = true;
            else const dmdgdc = false;
            
            static if (dmdgdc == true) asm
            {
                naked;

                // save current stack state
                push RBP;
                mov RBP, RSP;
                push RBX;
                push R12;
                push R13;
                push R14;
                push R15;
                sub RSP, 4;
                stmxcsr [RSP];
                sub RSP, 4;
                //version(SynchroFloatExcept){
                    fstcw [RSP];
                    fwait;
                //} else {
                //    fnstcw [RSP];
                //    fnclex;
                //}

                // store oldp again with more accurate address
                mov [RDI], RSP;
                // load newp to begin context switch
                mov RSP, RSI;

                // load saved state from new stack
                fldcw [RSP];
                add RSP, 4;
                ldmxcsr [RSP];
                add RSP, 4;
                pop R15;
                pop R14;
                pop R13;
                pop R12;

                pop RBX;
                pop RBP;

                // 'return' to complete switch
                ret;

            }
            else asm
            {
                naked;

                // save current stack state
                pushq RBP;
                mov RBP, RSP;
                pushq RBX;
                pushq R12;
                pushq R13;
                pushq R14;
                pushq R15;
                sub RSP, 4;
                stmxcsr [RSP];
                sub RSP, 4;
                //version(SynchroFloatExcept){
                    fstcw [RSP];
                    fwait;
                //} else {
                //    fnstcw [RSP];
                //    fnclex;
                //}

                // store oldp again with more accurate address
                mov [RDI], RSP;
                // load newp to begin context switch
                mov RSP, RSI;

                // load saved state from new stack
                fldcw [RSP];
                add RSP, 4;
                ldmxcsr [RSP];
                add RSP, 4;
                popq R15;
                popq R14;
                popq R13;
                popq R12;

                popq RBX;
                popq RBP;

                // 'return' to complete switch
                ret;
            }
        }
        else static if( is( ucontext_t ) )
        {
            Fiber   cfib = Fiber.getThis();
            void*   ucur = cfib.m_ucur;

            *oldp = &ucur;
            swapcontext( **(cast(ucontext_t***) oldp),
                          *(cast(ucontext_t**)  newp) );
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Fiber
////////////////////////////////////////////////////////////////////////////////

private char[] ptrToStr(size_t addr,char[]buf){
    enum char[] digits="0123456789ABCDEF".dup;
    enum{ nDigits=size_t.sizeof*2 }
    if (nDigits>buf.length) assert(0);
    char[] res=buf[0..nDigits];
    size_t addrAtt=addr;
    for (int i=nDigits;i!=0;--i){
        res[i-1]=digits[addrAtt&0xF];
        addrAtt>>=4;
    }
    return res;
}

/**
 * This class provides a cooperative concurrency mechanism integrated with the
 * threading and garbage collection functionality.  Calling a fiber may be
 * considered a blocking operation that returns when the fiber yields (via
 * Fiber.yield()).  Execution occurs within the context of the calling thread
 * so synchronization is not necessary to guarantee memory visibility so long
 * as the same thread calls the fiber each time.  Please note that there is no
 * requirement that a fiber be bound to one specific thread.  Rather, fibers
 * may be freely passed between threads so long as they are not currently
 * executing.  Like threads, a new fiber thread may be created using either
 * derivation or composition, as in the following example.
 *
 * Example:
 * ----------------------------------------------------------------------
 * class DerivedFiber : Fiber
 * {
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private :
 *     void run()
 *     {
 *         printf( "Derived fiber running.\n" );
 *     }
 * }
 *
 * void fiberFunc()
 * {
 *     printf( "Composed fiber running.\n" );
 *     Fiber.yield();
 *     printf( "Composed fiber running.\n" );
 * }
 *
 * // create instances of each type
 * Fiber derived = new DerivedFiber();
 * Fiber composed = new Fiber( &fiberFunc );
 *
 * // call both fibers once
 * derived.call();
 * composed.call();
 * printf( "Execution returned to calling context.\n" );
 * composed.call();
 *
 * // since each fiber has run to completion, each should have state TERM
 * assert( derived.state == Fiber.State.TERM );
 * assert( composed.state == Fiber.State.TERM );
 * ----------------------------------------------------------------------
 *
 * Authors: Based on a design by Mikola Lysenko.
 */

class Fiber
{
    static class Scheduler
    {
        alias void* Handle;

        enum Type {Read=1, Write=2, Accept=3, Connect=4, Transfer=5}

        void pause (uint ms) {}

        void ready (Fiber fiber) {}

        void open (Handle fd, char[] name) {}

        void close (Handle fd, char[] name) {}

        void await (Handle fd, Type t, uint timeout) {}
        
        void spawn (char[] name, void delegate() dg, size_t stack=8192) {}    
    }

    struct Event                        // scheduler support 
    {  
        uint             idx;           // support for timer removal
        Fiber            next;          // linked list of elapsed fibers
        void*            data;          // data to exchange
        ulong            clock;         // request timeout duration
        Scheduler.Handle handle;        // IO request handle
        Scheduler        scheduler;     // associated scheduler (may be null)
    }
/+
    final override int opCmp (Object o)
    {   
        throw new Exception ("Invalid opCmp in Fiber");

        auto other = cast(Fiber) cast(void*) o;
        if (other)
           {
           auto x = cast(long) event.clock - cast(long) other.event.clock;
           return (x < 0 ? -1 : x is 0 ? 0 : 1);
           }
        return 1;
    }
+/

    final static Scheduler scheduler ()
    {
        return getThis.event.scheduler;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    /**
     * Initializes an empty fiber object
     *
     * (useful to reset it)
     */
    this(size_t sz){
        m_dg    = null;
        m_fn    = null;
        m_call  = Call.NO;
        m_state = State.TERM;
        m_unhandled = null;
        
        allocStack( sz );
    }

    /**
     * Initializes a fiber object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     *  sz = The stack size for this fiber.
     *
     * In:
     *  fn must not be null.
     */
    this( void function() fn, size_t sz = PAGESIZE)
    in
    {
        assert( fn );
    }
    body
    {
        m_fn    = fn;
        m_call  = Call.FN;
        m_state = State.HOLD;
        allocStack( sz );
        initStack();
    }


    /**
     * Initializes a fiber object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     *  sz = The stack size for this fiber.
     *
     * In:
     *  dg must not be null.
     */
    this( void delegate() dg, size_t sz = PAGESIZE, Scheduler s = null )
    in
    {
        assert( dg );
    }
    body
    {
        event.scheduler = s;

        m_dg    = dg;
        m_call  = Call.DG;
        m_state = State.HOLD;
        allocStack(sz);
        initStack();
    }


    /**
     * Cleans up any remaining resources used by this object.
     */
    ~this()
    {
        // NOTE: A live reference to this object will exist on its associated
        //       stack from the first time its call() method has been called
        //       until its execution completes with State.TERM.  Thus, the only
        //       times this dtor should be called are either if the fiber has
        //       terminated (and therefore has no active stack) or if the user
        //       explicitly deletes this object.  The latter case is an error
        //       but is not easily tested for, since State.HOLD may imply that
        //       the fiber was just created but has never been run.  There is
        //       not a compelling case to create a State.INIT just to offer a
        //       means of ensuring the user isn't violating this object's
        //       contract, so for now this requirement will be enforced by
        //       documentation only.
        freeStack();
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Transfers execution to this fiber object.  The calling context will be
     * suspended until the fiber calls Fiber.yield() or until it terminates
     * via an unhandled exception.
     *
     * Params:
     *  rethrow = Rethrow any unhandled exception which may have caused this
     *            fiber to terminate.
     *
     * In:
     *  This fiber must be in state HOLD.
     *
     * Throws:
     *  Any exception not handled by the joined thread.
     *
     * Returns:
     *  Any exception not handled by this fiber if rethrow = false, null
     *  otherwise.
     */
    final Object call( bool rethrow = true )
    in
    {
        assert( m_state == State.HOLD );
    }
    body
    {
        Fiber   cur = getThis();

        static if( is( ucontext_t ) )
          m_ucur = cur ? &cur.m_utxt : &Fiber.sm_utxt;

        setThis( this );
        this.switchIn();
        setThis( cur );

        static if( is( ucontext_t ) )
          m_ucur = null;

        // NOTE: If the fiber has terminated then the stack pointers must be
        //       reset.  This ensures that the stack for this fiber is not
        //       scanned if the fiber has terminated.  This is necessary to
        //       prevent any references lingering on the stack from delaying
        //       the collection of otherwise dead objects.  The most notable
        //       being the current object, which is referenced at the top of
        //       fiber_entryPoint.
        if( m_state == State.TERM )
        {
            m_ctxt.tstack = m_ctxt.bstack;
        }
        if( m_unhandled )
        {
            Throwable obj  = m_unhandled;
            m_unhandled = null;
            if( rethrow )
                throw obj;
            return obj;
        }
        return null;
    }


    /**
     * Resets this fiber so that it may be re-used with the same function.
     * This routine may only be
     * called for fibers that have terminated, as doing otherwise could result
     * in scope-dependent functionality that is not executed.  Stack-based
     * classes, for example, may not be cleaned up properly if a fiber is reset
     * before it has terminated.
     *
     * In:
     *  This fiber must be in state TERM, and have a valid function/delegate.
     */
    final void reset()
    in
    {
        assert( m_call != Call.NO );
        assert( m_state == State.TERM );
        assert( m_ctxt.tstack == m_ctxt.bstack );
    }
    body
    {
        m_state = State.HOLD;
        initStack();
        m_unhandled = null;
    }

    /**
     * Reinitializes a fiber object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     *
     * In:
     *  This fiber must be in state TERM.
     *  fn must not be null.
     */
    final void reset( void function() fn )
    in
    {
        assert( fn );
        assert( m_state == State.TERM );
        assert( m_ctxt.tstack == m_ctxt.bstack );
    }
    body
    {
        m_fn    = fn;
        m_call  = Call.FN;
        m_state = State.HOLD;
        initStack();
        m_unhandled = null;
    }


    /**
     * Reinitializes a fiber object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     *
     * In:
     *  This fiber must be in state TERM.
     *  dg must not be null.
     */
    final void reset( void delegate() dg )
    in
    {
        assert( dg );
        assert( m_state == State.TERM );
        assert( m_ctxt.tstack == m_ctxt.bstack );
    }
    body
    {
        m_dg    = dg;
        m_call  = Call.DG;
        m_state = State.HOLD;
        initStack();
        m_unhandled = null;
    }
    
    /**
     * Clears the fiber from all references to a previous call (unhandled exceptions, delegate)
     *
     * In:
     *  This fiber must be in state TERM.
     */
    final void clear()
    in
    {
        assert( m_state == State.TERM );
        assert( m_ctxt.tstack == m_ctxt.bstack );
    }
    body
    {
        if (m_state != State.TERM){
            char[20] buf;
            throw new Exception("Fiber@"~ptrToStr(cast(size_t)cast(void*)this,buf).idup~" in unexpected state "~ptrToStr(m_state,buf).idup,__FILE__,__LINE__);
        }
        if (m_ctxt.tstack != m_ctxt.bstack){
            char[20] buf;
            throw new Exception("Fiber@"~ptrToStr(cast(size_t)cast(void*)this,buf).idup~" bstack="~ptrToStr(cast(size_t)cast(void*)m_ctxt.bstack,buf).idup~" != tstack="~ptrToStr(cast(size_t)cast(void*)m_ctxt.tstack,buf).idup,__FILE__,__LINE__);
        }
        m_dg    = null;
        m_fn    = null;
        m_call  = Call.NO;
        m_state = State.TERM;
        m_unhandled = null;
    }
    

    ////////////////////////////////////////////////////////////////////////////
    // General Properties
    ////////////////////////////////////////////////////////////////////////////


    /**
     * A fiber may occupy one of three states: HOLD, EXEC, and TERM.  The HOLD
     * state applies to any fiber that is suspended and ready to be called.
     * The EXEC state will be set for any fiber that is currently executing.
     * And the TERM state is set when a fiber terminates.  Once a fiber
     * terminates, it must be reset before it may be called again.
     */
    enum State
    {
        HOLD,   ///
        EXEC,   ///
        TERM    ///
    }


    /**
     * Gets the current state of this fiber.
     *
     * Returns:
     *  The state of this fiber as an enumerated value.
     */
    final State state()
    {
        return m_state;
    }
    
    size_t stackSize(){
        return m_size;
    }


    ////////////////////////////////////////////////////////////////////////////
    // Actions on Calling Fiber
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Forces a context switch to occur away from the calling fiber.
     */
    final void cede ()
    {
        assert( m_state == State.EXEC );

        static if( is( ucontext_t ) )
                   m_ucur = &m_utxt;

        m_state = State.HOLD;
        switchOut();
        m_state = State.EXEC;
    }


    /**
     * Forces a context switch to occur away from the calling fiber.
     */
    static void yield()
    {
        Fiber cur = getThis;
        assert( cur, "Fiber.yield() called with no active fiber" );
        if (cur.event.scheduler)
            cur.event.scheduler.pause (0);
        else
          cur.cede;
    }

    /**
     * Forces a context switch to occur away from the calling fiber and then
     * throws obj in the calling fiber.
     *
     * Params:
     *  obj = The object to throw.
     *
     * In:
     *  obj must not be null.
     */
    static void yieldAndThrow( Throwable obj )
    in
    {
        assert( obj );
    }
    body
    {
        Fiber cur = getThis();
        assert( cur, "Fiber.yield(obj) called with no active fiber" );
        cur.m_unhandled = obj;
        if (cur.event.scheduler)
            cur.event.scheduler.pause (0);
        else
           cur.cede;
    }


    ////////////////////////////////////////////////////////////////////////////
    // Fiber Accessors
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Provides a reference to the calling fiber or null if no fiber is
     * currently active.
     *
     * Returns:
     *  The fiber object representing the calling fiber or null if no fiber
     *  is currently active.  The result of deleting this object is undefined.
     */
    static Fiber getThis()
    {
        version( Win32 )
        {
            return cast(Fiber) TlsGetValue( sm_this );
        }
        else version( Posix )
        {
            return cast(Fiber) pthread_getspecific( sm_this );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Static Initialization
    ////////////////////////////////////////////////////////////////////////////


    static this()
    {
        version( Win32 )
        {
            sm_this = TlsAlloc();
            assert( sm_this != TLS_OUT_OF_INDEXES );
        }
        else version( Posix )
        {
            int status;

            status = pthread_key_create( &sm_this, null );
            assert( status == 0 );

          static if( is( ucontext_t ) )
          {
            status = getcontext( &sm_utxt );
            assert( status == 0 );
          }
        }
    }


private:
    //
    // Initializes a fiber object which has no associated executable function.
    //
    this()
    {
        m_call = Call.NO;
    }


    //
    // Fiber entry point.  Invokes the function or delegate passed on
    // construction (if any).
    //
    final void run()
    {
        switch( m_call )
        {
        case Call.FN:
            m_fn();
            break;
        case Call.DG:
            m_dg();
            break;
        default:
            break;
        }
    }


private:
    //
    // The type of routine passed on fiber construction.
    //
    enum Call
    {
        NO,
        FN,
        DG
    }


    //
    // Standard fiber data
    //
    Call                m_call;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }
    bool                m_isRunning;
    Throwable              m_unhandled;
    State               m_state;
    char[]              m_name;
public:
    Event               event;


private:
    ////////////////////////////////////////////////////////////////////////////
    // Stack Management
    ////////////////////////////////////////////////////////////////////////////


    //
    // Allocate a new stack for this fiber.
    //
    final void allocStack( size_t sz )
    in
    {
        assert( !m_pmem && !m_ctxt );
    }
    body
    {
        // adjust alloc size to a multiple of PAGESIZE
        sz += PAGESIZE - 1;
        sz -= sz % PAGESIZE;

        // NOTE: This instance of Thread.Context is dynamic so Fiber objects
        //       can be collected by the GC so long as no user level references
        //       to the object exist.  If m_ctxt were not dynamic then its
        //       presence in the global context list would be enough to keep
        //       this object alive indefinitely.  An alternative to allocating
        //       room for this struct explicitly would be to mash it into the
        //       base of the stack being allocated below.  However, doing so
        //       requires too much special logic to be worthwhile.
        m_ctxt = new Thread.Context;

        static if( is( typeof( VirtualAlloc ) ) )
        {
            // reserve memory for stack
            m_pmem = VirtualAlloc( null,
                                   sz + PAGESIZE,
                                   MEM_RESERVE,
                                   PAGE_NOACCESS );
            if( !m_pmem )
            {
                throw new FiberException( "Unable to reserve memory for stack" );
            }

            version( StackGrowsDown )
            {
                void* stack = m_pmem + PAGESIZE;
                void* guard = m_pmem;
                void* pbase = stack + sz;
            }
            else
            {
                void* stack = m_pmem;
                void* guard = m_pmem + sz;
                void* pbase = stack;
            }

            // allocate reserved stack segment
            stack = VirtualAlloc( stack,
                                  sz,
                                  MEM_COMMIT,
                                  PAGE_READWRITE );
            if( !stack )
            {
                throw new FiberException( "Unable to allocate memory for stack" );
            }

            // allocate reserved guard page
            guard = VirtualAlloc( guard,
                                  PAGESIZE,
                                  MEM_COMMIT,
                                  PAGE_READWRITE | PAGE_GUARD );
            if( !guard )
            {
                throw new FiberException( "Unable to create guard page for stack" );
            }

            m_ctxt.bstack = pbase;
            m_ctxt.tstack = pbase;
            m_size = sz;
        }
        else
        {   static if( is( typeof( mmap ) ) )
            {
                m_pmem = mmap( null,
                               sz,
                               PROT_READ | PROT_WRITE,
                               MAP_PRIVATE | MAP_ANON,
                               -1,
                               0 );
                if( m_pmem == MAP_FAILED )
                    m_pmem = null;
            }
            else static if( is( typeof( valloc ) ) )
            {
                m_pmem = valloc( sz );
            }
            else static if( is( typeof( malloc ) ) )
            {
                m_pmem = malloc( sz );
            }
            else
            {
                m_pmem = null;
            }

            if( !m_pmem )
            {
                throw new FiberException( "Unable to allocate memory for stack" );
            }

            version( StackGrowsDown )
            {
                m_ctxt.bstack = m_pmem + sz;
                m_ctxt.tstack = m_pmem + sz;
            }
            else
            {
                m_ctxt.bstack = m_pmem;
                m_ctxt.tstack = m_pmem;
            }
            m_size = sz;
        }

        Thread.add( m_ctxt );
    }


    //
    // Free this fiber's stack.
    //
    final void freeStack()
    in
    {
        assert( m_pmem && m_ctxt );
    }
    body
    {
        // NOTE: Since this routine is only ever expected to be called from
        //       the dtor, pointers to freed data are not set to null.

        // NOTE: m_ctxt is guaranteed to be alive because it is held in the
        //       global context list.
        Thread.remove( m_ctxt );

        static if( is( typeof( VirtualAlloc ) ) )
        {
            VirtualFree( m_pmem, 0, MEM_RELEASE );
        }
        else static if( is( typeof( mmap ) ) )
        {
            munmap( m_pmem, m_size );
        }
        else static if( is( typeof( valloc ) ) )
        {
            free( m_pmem );
        }
        else static if( is( typeof( malloc ) ) )
        {
            free( m_pmem );
        }
        delete m_ctxt;
    }


    //
    // Initialize the allocated stack.
    //
    final void initStack()
    in
    {
        assert( m_ctxt.tstack && m_ctxt.tstack == m_ctxt.bstack );
        assert( cast(size_t) m_ctxt.bstack % (void*).sizeof == 0 );
    }
    body
    {
        void* pstack = m_ctxt.tstack;
        scope( exit )  m_ctxt.tstack = pstack;

        void push( size_t val )
        {
            version( StackGrowsDown )
            {
                pstack -= size_t.sizeof;
                *(cast(size_t*) pstack) = val;
            }
            else
            {
                pstack += size_t.sizeof;
                *(cast(size_t*) pstack) = val;
            }
        }

        // NOTE: On OS X the stack must be 16-byte aligned according to the
        // IA-32 call spec.
        version( darwin )
        {
             pstack = cast(void*)(cast(uint)(pstack) - (cast(uint)(pstack) & 0x0F));
        }

        version( AsmX86_Win32 )
        {
            push( cast(size_t) &fiber_entryPoint );                 // EIP
            push( 0xFFFFFFFF );                                     // EBP
            push( 0x00000000 );                                     // EAX
            push( 0xFFFFFFFF );                                     // FS:[0]
            version( StackGrowsDown )
            {
                push( cast(size_t) m_ctxt.bstack );                 // FS:[4]
                push( cast(size_t) m_ctxt.bstack - m_size );        // FS:[8]
            }
            else
            {
                push( cast(size_t) m_ctxt.bstack );                 // FS:[4]
                push( cast(size_t) m_ctxt.bstack + m_size );        // FS:[8]
            }
            push( 0x00000000 );                                     // EBX
            push( 0x00000000 );                                     // ESI
            push( 0x00000000 );                                     // EDI
        }
        else version( AsmX86_Posix )
        {
            push( 0x00000000 );                                     // strange pre EIP
            push( cast(size_t) &fiber_entryPoint );                 // EIP
            push( (cast(size_t)pstack)+8 );                         // EBP
            push( 0x00000000 );                                     // EAX
            push( getEBX() );                                       // EBX used for PIC code
            push( 0x00000000 );                                     // ECX just to have it aligned...
            push( 0x00000000 );                                     // ESI
            push( 0x00000000 );                                     // EDI
        }
        else version( AsmX86_64_Posix )
        {
            push( 0x00000000 );                                     // strange pre EIP
            push( cast(size_t) &fiber_entryPoint );                 // RIP
            push( (cast(size_t)pstack)+8 );                         // RBP
            push( 0x00000000_00000000 );                            // RBX
            push( 0x00000000_00000000 );                            // R12
            push( 0x00000000_00000000 );                            // R13
            push( 0x00000000_00000000 );                            // R14
            push( 0x00000000_00000000 );                            // R15
            push( 0x00001f80_0000037f );                            // MXCSR (32 bits), unused (16 bits) , x87 control (16 bits)
        }
        else version( AsmPPC_Posix )
        {
            version( StackGrowsDown )
            {
                pstack -= int.sizeof * 5;
            }
            else
            {
                pstack += int.sizeof * 5;
            }

            push( cast(size_t) &fiber_entryPoint );     // link register
            push( 0x00000000 );                         // control register
            push( 0x00000000 );                         // old stack pointer

            // GPR values
            version( StackGrowsDown )
            {
                pstack -= int.sizeof * 20;
            }
            else
            {
                pstack += int.sizeof * 20;
            }

            assert( (cast(uint) pstack & 0x0f) == 0 );
        }
        else static if( is( ucontext_t ) )
        {
            getcontext( &m_utxt );
            // patch from #1707 - thanks to jerdfelt
            //m_utxt.uc_stack.ss_sp   = m_ctxt.bstack;
            m_utxt.uc_stack.ss_sp   = m_pmem;
            m_utxt.uc_stack.ss_size = m_size;
            makecontext( &m_utxt, &fiber_entryPoint, 0 );
            // NOTE: If ucontext is being used then the top of the stack will
            //       be a pointer to the ucontext_t struct for that fiber.
            push( cast(size_t) &m_utxt );
        }
    }


    public Thread.Context* m_ctxt;
    public size_t          m_size;
    void*           m_pmem;

    static if( is( ucontext_t ) )
    {
        // NOTE: The static ucontext instance is used to represent the context
        //       of the main application thread.
        static ucontext_t   sm_utxt = void;
        ucontext_t          m_utxt  = void;
        ucontext_t*         m_ucur  = null;
    }


private:
    ////////////////////////////////////////////////////////////////////////////
    // Storage of Active Fiber
    ////////////////////////////////////////////////////////////////////////////


    //
    // Sets a thread-local reference to the current fiber object.
    //
    static void setThis( Fiber f )
    {
        version( Win32 )
        {
            TlsSetValue( sm_this, cast(void*) f );
        }
        else version( Posix )
        {
            pthread_setspecific( sm_this, cast(void*) f );
        }
    }


    static Thread.TLSKey    sm_this;


private:
    ////////////////////////////////////////////////////////////////////////////
    // Context Switching
    ////////////////////////////////////////////////////////////////////////////


    //
    // Switches into the stack held by this fiber.
    //
    final void switchIn()
    {
        Thread  tobj = Thread.getThis();
        void**  oldp = &tobj.m_curr.tstack;
        void*   newp = m_ctxt.tstack;

        // NOTE: The order of operations here is very important.  The current
        //       stack top must be stored before m_lock is set, and pushContext
        //       must not be called until after m_lock is set.  This process
        //       is intended to prevent a race condition with the suspend
        //       mechanism used for garbage collection.  If it is not followed,
        //       a badly timed collection could cause the GC to scan from the
        //       bottom of one stack to the top of another, or to miss scanning
        //       a stack that still contains valid data.  The old stack pointer
        //       oldp will be set again before the context switch to guarantee
        //       that it points to exactly the correct stack location so the
        //       successive pop operations will succeed.
        *oldp = getStackTop();
        volatile tobj.m_lock = true;
        tobj.pushContext( m_ctxt );

        fiber_switchContext( oldp, newp );

        // NOTE: As above, these operations must be performed in a strict order
        //       to prevent Bad Things from happening.
        tobj.popContext();
        volatile tobj.m_lock = false;
        tobj.m_curr.tstack = tobj.m_curr.bstack;
    }


    //
    // Switches out of the current stack and into the enclosing stack.
    //
    final void switchOut()
    {
        Thread  tobj = Thread.getThis();
        void**  oldp = &m_ctxt.tstack;
        void*   newp = tobj.m_curr.within.tstack;

        // NOTE: The order of operations here is very important.  The current
        //       stack top must be stored before m_lock is set, and pushContext
        //       must not be called until after m_lock is set.  This process
        //       is intended to prevent a race condition with the suspend
        //       mechanism used for garbage collection.  If it is not followed,
        //       a badly timed collection could cause the GC to scan from the
        //       bottom of one stack to the top of another, or to miss scanning
        //       a stack that still contains valid data.  The old stack pointer
        //       oldp will be set again before the context switch to guarantee
        //       that it points to exactly the correct stack location so the
        //       successive pop operations will succeed.
        *oldp = getStackTop();
        volatile tobj.m_lock = true;

        fiber_switchContext( oldp, newp );

        // NOTE: As above, these operations must be performed in a strict order
        //       to prevent Bad Things from happening.
        tobj=Thread.getThis();
        volatile tobj.m_lock = false;
        tobj.m_curr.tstack = tobj.m_curr.bstack;
    }
}

extern(C){
    void thread_yield(){
        Thread.yield();
    }
    
    void thread_sleep(double period){
        Thread.sleep(period);
    }
}

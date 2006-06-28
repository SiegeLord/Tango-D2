/**
 * The thread module provides support for thread creation and management.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Thread;


/**
 * All exceptions thrown from this module derive from this class.
 */
class ThreadException : Exception
{
    this( char[] msg )
    {
        super( msg );
    }
}


// this should be true for most architectures
version = StackGrowsDown;


public
{
    import tango.core.Interval;
}
private
{
     // import tango.stdc.string; // for memset
     extern (C) void* memset(void* s, int c, size_t n);
}


version( Win32 )
{
    private
    {
        import tango.os.windows.c.minwin;

        //
        // decls not in minwin
        //
        extern (Windows)
        {
            DWORD TlsAlloc();
            PVOID TlsGetValue(DWORD);
            BOOL TlsSetValue(DWORD,PVOID);

            const DWORD STILL_ACTIVE        = 0x103;
            const DWORD TLS_OUT_OF_INDEXES  = 0xFFFFFFFF;
       }

        //
        // avoid multiple imports via tango.os.windows.process
        //
        extern (Windows) alias uint function(void*) btex_fptr;

        version( X86 )
        {
            extern (C) ulong _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*);
        }
        else
        {
            extern (C) uint _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*);
        }


        //
        // entry point for Windows threads
        //
        extern (Windows) uint threadFunc( void* arg )
        {
	        Thread  obj = cast(Thread) arg;
	        assert( obj );
	        scope( exit ) Thread.remove( obj );

	        // maybe put an auto exception object here (using alloca)
            // for OutOfMemoryError plus something to track whether
            // an exception is in-flight?

            obj.m_bstack = getStackBottom();
            obj.m_tstack = obj.m_bstack;
            TlsSetValue( Thread.sm_this, obj );

	        try
	        {
	            obj.run();
	        }
	        catch
	        {
	            // error should really print to stderr
	        }
	        return 0;
        }


        //
        // copy of the same-named function in phobos.std.thread,
        // it uses the Windows naming convention to be consistent
        // with GetCurrentThreadId
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


        void* getStackBottom()
        {
            asm
            {
                naked;
                mov	EAX, FS:4;
                ret;
            }
        }


        void* getStackTop()
        {
            asm
            {
        	    naked;
                mov EAX, ESP;
                ret;
            }
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
        import tango.stdc.posix.unistd;
        import tango.stdc.posix.time;

        version( darwin )
            import tango.os.darwin.c.darwin;
        else
            import tango.os.linux.c.linux;

        //
        // entry point for POSIX threads
        //
        extern (C) void* threadFunc( void* arg )
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

            // maybe put an auto exception object here (using alloca)
            // for OutOfMemoryError plus something to track whether
            // an exception is in-flight?

	        static extern (C) void cleanupHandler( void* arg )
	        {
                Thread  obj = Thread.getThis();
                assert( obj );

                // NOTE: If the thread terminated abnormally, just set it as
                //       not running and let thread_suspendAll remove it from
                //       the thread list.  This is safer and is consistent
                //       with the Windows thread code.
                obj.m_isRunning = false;
	        }

            obj.m_bstack = getStackBottom();
	        obj.m_tstack = obj.m_bstack;
	        pthread_setspecific( obj.sm_this, obj );

	        pthread_cleanup cleanup;
	        cleanup.push( &cleanupHandler, obj );

	        try
	        {
	            obj.run();
	        }
	        catch
	        {
	            // error should really print to stderr
	        }
	        return null;
        }


        //
        // used to track the number of suspended threads
        //
        sem_t   suspendCount;


        extern (C) void suspendHandler( int sig )
        in
        {
            assert( sig == SIGUSR1 );
        }
        body
        {
            version( X86 )
            {
                asm
                {
                    pushad;
                }
            }
            // TODO: darwin/ppc support
            //else version( PPC )
            //{
            //    __builtin_unwind_init();
            //}
            else
            {
                static assert( false );
            }

            // NOTE: Since registers are being pushed and popped from the stack,
            //       any other stack data used by this function should be gone
            //       before the stack cleanup code is called below.
            {
                Thread  obj = Thread.getThis();
                assert( obj );

                obj.m_tstack = getStackTop();

                sigset_t    sigres;
                int         status;

                status = sigfillset( &sigres );
                assert( status == 0 );

                status = sigdelset( &sigres, SIGUSR2 );
                assert( status == 0 );

                status = sem_post( &suspendCount );
                assert( status == 0 );

                sigsuspend( &sigres );

                obj.m_tstack = obj.m_bstack;
            }

            version( X86 )
            {
	            asm
	            {
    	            popad;
	            }
	        }
            // TODO: darwin/ppc support
            //else version( PPC )
            //{
            //    __builtin_unwind_init();
            //}
	        else
	        {
	            static assert( false );
	        }
        }


        extern (C) void resumeHandler( int sig )
        in
        {
            assert( sig == SIGUSR2 );
        }
        body
        {

        }


        // NOTE: this may not work on all versions of linux,
        //       but apparently the Windows implementation
        //       does not work in Linux (according to DMD revs)
        void* getStackBottom()
        {
            version( darwin )
                return _d_gcc_query_stack_origin();
            else
                return __libc_stack_end;
        }


        void* getStackTop()
        {
            version( X86 )
            {
            	asm
            	{   naked;
            	    mov EAX, ESP;
            	    ret;
            	}
            }
            else
            {
                static assert( false );
            }
        }
    }
}
else
{
    // NOTE: This is the only place threading versions are checked.  If a new
    //       version is added, the module code will need to be searched for
    //       places where version-specific code may be required.  This can be
    //       easily accomlished by searching for 'Windows' or 'Posix'.

    // Unknown threading implementation
    static assert( false );
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
 * ----------------------------------------------------------------------
 *
 * class DerivedThread : Thread
 * {
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
 *
 * // wait for the threads to complete
 * derived.join();
 * composed.join();
 *
 * ----------------------------------------------------------------------
 */
class Thread
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a thread object which has no associated executable
     * function.
     */
    this()
    {
        m_call = Call.NO;
    }


    /**
     * Initialized a thread object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     */
    this( void function() fn )
    {
        m_fn   = fn;
        m_call = Call.FN;
    }


    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     */
    this( void delegate() dg )
    {
        m_dg   = dg;
        m_call = Call.DG;
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Starts the thread with run() as the target method.  The default
     * behavior of this is to run the function or delegate passed upon
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
        assert( !m_next && !m_prev );
    }
    body
    {
        synchronized( slock )
        {
            version( Win32 )
            {
                m_hndl = cast(HANDLE) _beginthreadex( null, 0, &threadFunc, this, 0, &m_addr );
                if( cast(size_t) m_hndl == 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            else version( Posix )
            {
                m_isRunning = true;
                scope( failure ) m_isRunning = false;

                if( pthread_create( &m_addr, null, &threadFunc, this ) != 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            multiThreadedFlag = true;
            add( this );
        }
    }


    /**
     * Waits for this thread to complete.
     *
     * Throws:
     *  ThreadException if the operation fails.
     */
    final void join()
    {
        version( Win32 )
        {
            if( WaitForSingleObject( m_hndl, INFINITE ) != WAIT_OBJECT_0 )
                throw new ThreadException( "Unable to join thread" );
        }
        else version( Posix )
        {
            if( pthread_join( m_addr, null ) != 0 )
                throw new ThreadException( "Unable to join thread" );
        }
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
     *  n = The new name for this thread.
     */
    final void name( char[] n )
    {
        synchronized( this )
        {
            m_name = n.dup;
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
        if( !m_addr )
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
    // Actions on Calling Thread
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Suspends the calling thread for at least the supplied time.
     *
     * Params:
     *  interval = The minimum duration the calling thread should be
     *             suspended.
     */
    static void sleep( Interval interval )
    {
        version( Win32 )
        {
            Sleep( interval / Interval.milli );
        }
        else version( Posix )
        {
            usleep( interval );
        }
    }


    /**
     * Suspends the calling thread until interrupted.
     */
    static void sleep()
    {
        version( Win32 )
        {
            Sleep( INFINITE );
        }
        else version( Posix )
        {
            // BUG: This implementation will effectively ignore SIGALARM
            //      and other interrupts.
            do
            {
                sleep( uint.max );
            } while( true );
        }
    }


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
        synchronized( slock )
        {
            size_t   pos = 0;
            Thread[] buf = new Thread[sm_len];

            foreach( Thread t; Thread )
            {
                buf[pos++] = t;
            }
            return buf;
        }
    }


    /**
     * Operates on all threads currently being tracked by the system.  The
     * result of deleting any Thread object is undefined.
     *
     * Params:
     *
     * dg = The supplied code as a delegate.
     *
     * Returns:
     *  Zero if all elemented are visited, nonzero if not.
     */
    static int opApply( int delegate( inout Thread ) dg )
    {
        synchronized( slock )
        {
            int ret = 0;

            for( Thread t = sm_all; t; t = t.m_next )
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
    const uint LOCAL_MAX = 64;


    /**
     * Reserves a local storage pointer for use and initializes this
     * location to null for all running threads.
     *
     * Returns:
     *  A key representing the array offset of this memory location.
     */
    static uint createLocal()
    {
        synchronized( slock )
        {
            foreach( uint key, inout ubyte set; sm_local )
            {
                if( !set )
                {
                    foreach( Thread t; sm_all )
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
            foreach( Thread t; sm_all )
            {
                t.m_local[key] = null;
            }
        }
    }


    /**
     * Gets the data associated with the supplied key value.  It is assumed
     * that any key passed to this function is valid.
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
     * Stores the supplied value in the specified location.  It is assumed
     * that any key passed to this function is valid.
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


protected:
    /**
     * This is the entry point for the newly invoked thread.  Default
     * behavior is to call the function or delegate passed on object
     * construction.  This function may be overridden to create custom
     * thread objects via subclassing.
     */
    void run()
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
    // The type of function pointer passed on thread construction.
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
    static ubyte[LOCAL_MAX] sm_local;
    static TLSKey           sm_this;

    void*[LOCAL_MAX]        m_local;


    //
    // Standard thead data
    //
    version( Win32 )
    {
        HANDLE          m_hndl;
    }
    ThreadAddr          m_addr;
    Call                m_call;
    char[]              m_name;
    union
    {
        void function() m_fn;
        void delegate() m_dg;
    }
    version( Posix )
    {
        bool            m_isRunning;
    }


private:
    ////////////////////////////////////////////////////////////////////////////
    // Global Thread List
    ////////////////////////////////////////////////////////////////////////////


    //
    // All use of the global thread list should synchronize on this lock.
    //
    static Object slock()
    {
        return Thread.classinfo;
    }


    //
    // Add a thread to the global thread list.
    //
    static void add( Thread t )
    in
    {
        assert( !t.m_next && !t.m_prev );
        assert( t.isRunning );
    }
    body
    {
        synchronized( slock )
        {
            if( sm_all )
            {
                t.m_next = sm_all;
                sm_all.m_prev = t;
            }
            sm_all = t;
            ++sm_len;
        }
    }


    //
    // Remove a thread from the global thread list.
    //
    static void remove( Thread t )
    in
    {
        assert( t.m_next || t.m_prev );
        assert( !t.isRunning );
    }
    body
    {
        synchronized( slock )
        {
            if( t.m_prev )
                t.m_prev.m_next = t.m_next;
            if( t.m_next )
                t.m_next.m_prev = t.m_prev;
            if( sm_all == t )
                sm_all = t.m_next;
            --sm_len;
        }
        // NOTE: Don't null out t.m_next or t.m_prev because opApply currently
        //       follows t.m_next after removing a node.  This could be easily
        //       addressed by simply returning the next node from this function,
        //       however, a thread should never be re-added to the list anyway
        //       and having m_next and m_prev be non-null is a good way to
        //       ensure that.

        // NOTE: Cleanup of any thread resources should occur as soon as the
        //       thread is detected to no longer be running, and this seemed
        //       like the most reasonable place to do so.
        version( Win32 )
        {
            CloseHandle( t.m_hndl );
            t.m_hndl = t.m_hndl.init;
            t.m_addr = t.m_addr.init;
        }
        else version( Posix )
        {
            pthread_detach( t.m_addr );
            t.m_addr = t.m_addr.init;
        }
    }


    //
    // Global thread list data
    //
    static Thread       sm_all;
    static size_t       sm_len;

    Thread              m_prev;
    Thread              m_next;


private:
    ////////////////////////////////////////////////////////////////////////////
    // GC Scanning Support
    ////////////////////////////////////////////////////////////////////////////


    void*               m_bstack,
                        m_tstack;

    version( Win32 )
    {
        uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
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

        Thread main   = new Thread();
        main.m_addr   = GetCurrentThreadId();
        main.m_hndl   = GetCurrentThreadHandle();
        main.m_bstack = getStackBottom();
        main.m_tstack = main.m_bstack;
        TlsSetValue( Thread.sm_this, main );
    }
    else version( Posix )
    {
        int         status;
        sigaction_t sigusr1,
                    sigusr2;

        // NOTE: SA_RESTART indicates that system calls should restart if they
        //       are interrupted by a signal, but this is not available on all
        //       Posix systems, even those that support multithreading.
        static if( is( typeof( SA_RESTART ) ) )
            sigusr1.sa_flags = SA_RESTART;
        else
        sigusr1.sa_flags   = 0;
        sigusr1.sa_handler = &suspendHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr1.sa_mask );
        assert( status == 0 );

        // NOTE: Since SIGUSR2 should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        sigusr2.sa_flags   = 0;
        sigusr2.sa_handler = &resumeHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &sigusr2.sa_mask );
        assert( status == 0 );

        status = sigaction( SIGUSR1, &sigusr1, null );
        assert( status == 0 );

        status = sigaction( SIGUSR2, &sigusr2, null );
        assert( status == 0 );

        status = sem_init( &suspendCount, 0, 0 );
        assert( status == 0 );

        status = pthread_key_create( &Thread.sm_this, null );
        assert( status == 0 );

        Thread main      = new Thread();
        main.m_addr      = pthread_self();
        main.m_bstack    = getStackBottom();
        main.m_tstack    = main.m_bstack;
        main.m_isRunning = true;

        status = pthread_setspecific( Thread.sm_this, main );
        assert( status == 0 );
    }

    Thread.add( main );
}


/**
 * Performs intermediate shutdown of the thread module.
 */
static ~this()
{
    // NOTE: The functionality related to garbage collection must be minimally
    //       operable after this dtor completes.  Therefore, only minimal
    //       cleanup may occur.

    for( Thread t = Thread.sm_all; t; t = t.m_next ) // foreach( Thread t; Thread )
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

	        CONTEXT context;
	        context.ContextFlags = CONTEXT_INTEGER | CONTEXT_CONTROL;

	        if( !GetThreadContext( t.m_hndl, &context ) )
	            throw new ThreadException( "Unable to load thread context" );
            t.m_tstack = cast(void*) context.Esp;
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
                // NOTE: It's really not ideal to wait for each thread to signal
                //       individually -- rather, it would be better to suspend
                //       them all and wait once at the end.  However, semaphores
                //       don't really work this way, and the obvious alternative
                //       (looping on an atomic suspend count) requires either
                //       the atomic module (which only works on x86) or
                //       other specialized functionality.
                sem_wait( &suspendCount );
            }
            else
            {
                t.m_tstack = getStackTop();
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
    //       global thread list is empty.  The check of Thread.sm_all below is
    //       done to ensure thread_init has completed, and therefore that
    //       calling Thread.getThis will not result in an error.  For the
    //       short time when Thread.sm_all is null, there is no reason not to
    //       simply call the multithreaded code below, with the expectation
    //       that the foreach loop will never be entered.
    if( !multiThreadedFlag && Thread.sm_all )
    {
        if( ++suspendDepth == 1 )
            suspend( Thread.getThis() );
        return;
    }
    synchronized( Thread.slock )
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
        for( Thread t = Thread.sm_all; t; t = t.m_next ) // foreach( Thread t; Thread )
        {
            if( t.isRunning )
                suspend( t );
            else
                Thread.remove( t );
        }

        version( Posix )
        {
            // wait on semaphore -- see note in suspend for
            // why this is currently not implemented
        }
    }
}


/**
 * Resume all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function must be called once for each preceding
 * call to thread_suspendAll before the threads are actually resumed.
 *
 * In:
 *  assert( suspendDepth > 0 );
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

            t.m_tstack = t.m_bstack;
            memset( &t.m_reg[0], 0, uint.sizeof * t.m_reg.length );
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
            }
            else
            {
                t.m_tstack = t.m_bstack;
            }
        }
    }


    // NOTE: See thread_suspendAll for the logic behind this.
    if( !multiThreadedFlag && Thread.sm_all )
    {
        if( --suspendDepth == 0 )
            resume( Thread.getThis() );
        return;
    }
    synchronized( Thread.slock )
    {
        if( --suspendDepth > 0 )
            return;

        for( Thread t = Thread.sm_all; t; t = t.m_next ) // foreach( Thread t; Thread )
        {
            resume( t );
        }
    }
}


private alias void delegate( void*, void* ) scanAllThreadsFn;


/**
 * The main entry point for garbage collection.  The supplied delegate
 * will be passed ranges representing both stack and register values.
 *
 * Params:
 *  fn          = The scanner function.  It should scan from p1 through p2 - 1.
 *  curStackTop = An optional pointer to the top of the calling thread's stack.
 */
extern (C) void thread_scanAll( scanAllThreadsFn fn, void* curStackTop = null )
in
{
    assert( suspendDepth > 0 );
}
body
{
    Thread  thisThread  = null;
    void*   oldStackTop = null;

    if( curStackTop && Thread.sm_all )
    {
        thisThread  = Thread.getThis();
        oldStackTop = thisThread.m_tstack;
        thisThread.m_tstack = curStackTop;
    }

    scope( exit )
    {
        if( curStackTop && Thread.sm_all )
            thisThread.m_tstack = oldStackTop;
    }

    //
    // NOTE: Synchronizing on Thread.slock is not needed because this
    //       function may only be called after all other threads have
    //       been suspended from within the same lock.
    //
    for( Thread t = Thread.sm_all; t; t = t.m_next )
    {
        version( StackGrowsDown )
        {
            // NOTE: We can't index past the bottom of the stack
            //       so don't do the "+1" for StackGrowsDown.
            if( t.m_tstack && t.m_tstack < t.m_bstack )
                fn( t.m_tstack, t.m_bstack );
        }
        else
        {
            if( t.m_bstack && t.m_bstack < t.m_tstack )
                fn( t.m_bstack, t.m_tstack + 1 );
        }
        version( Win32 )
        {
            fn( &t.m_reg[0], &t.m_reg[0] + t.m_reg.length );
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// ThreadGroup
////////////////////////////////////////////////////////////////////////////////


/**
 * This class is intended to simplify certain common programming techniques.
 */
class ThreadGroup
{
    /**
     * Creates and starts a new Thread object that executes fn and
     * adds it to the list of tracked threads.
     *
     * Params:
     *  fn = The thread function.
     *
     * Returns:
     *  A reference to the newly created thread.
     */
    Thread create( void function() fn )
    {
        Thread t = new Thread( fn );

        t.start();
        synchronized
        {
            m_all[t] = t;
        }
        return t;
    }


    /**
     * Creates and stats a new Thread object that executes dg and
     * adds it to the list of tracked threads.
     *
     * Params:
     *  dg = The thread function.
     *
     * Returns:
     *  A reference to the newly created thread.
     */
    Thread create( void delegate() dg )
    {
        Thread t = new Thread( dg );

        t.start();
        synchronized
        {
            m_all[t] = t;
        }
        return t;
    }


    /**
     * Add t to the list of tracked threads if it is not already being
     * tracked.
     *
     * Params:
     *  t = The thread to add.
     *
     * In:
     *  assert( t );
     */
    void add( Thread t )
    in
    {
        assert( t );
    }
    body
    {
        synchronized
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
     *  assert( t );
     */
    void remove( Thread t )
    in
    {
        assert( t );
    }
    body
    {
        synchronized
        {
            m_all.remove( t );
        }
    }


    /**
     * Operates on all threads currently tracked by this object.
     */
    int opApply( int delegate( inout Thread ) dg )
    {
        synchronized
        {
            int ret = 0;

            // NOTE: This loop relies on the knowledge that m_all uses the
            //       Thread object for both the key and the mapped value.
            foreach( Thread t; m_all.keys ) // foreach( Thread t; m_all )
            {
                ret = dg( t ); // ret = dg( t );
                if( ret )
                    break;
            }
            return ret;
        }
    }


    /**
     * Iteratively joins all tracked threads.  This function
     * will block add, remove, and opApply until it completes.
     *
     * Params:
     *  preserve = Preserve thread references.
     */
    void joinAll( bool preserve = true )
    {
        synchronized
        {
            // NOTE: This loop relies on the knowledge that m_all uses the
            //       Thread object for both the key and the mapped value.
            foreach( Thread t; m_all.keys ) // foreach( Thread t; m_all )
            {
                t.join();
                if( !preserve )
                    m_all.remove( t );
            }
        }
    }


private:
    Thread[Thread]  m_all;
}
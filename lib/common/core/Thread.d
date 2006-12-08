/**
 * The thread module provides support for thread creation and management.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Thread;


// this should be true for most architectures
version = StackGrowsDown;


public
{
    import tango.core.Interval;
}
private
{
    //
    // exposed by compiler runtime
    //
    extern (C) void* cr_stackBottom();
    extern (C) void* cr_stackTop();


    void* getStackBottom()
    {
        return cr_stackBottom();
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
            return cr_stackTop();
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
        import tango.sys.windows.minwin;

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
        // avoid multiple imports via tango.sys.windows.process
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
        extern (Windows) uint thread_entryPoint( void* arg )
        {
            Thread  obj = cast(Thread) arg;
            assert( obj );
            scope( exit ) Thread.remove( obj );

            obj.m_main.bstack = getStackBottom();
            obj.m_main.tstack = obj.m_main.bstack;
            assert( obj.m_curr == &obj.m_main );
            Thread.add( &obj.m_main );

            TlsSetValue( Thread.sm_this, obj );

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
        import tango.stdc.posix.unistd;
        import tango.stdc.posix.time;

        version( GCC )
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

            mixin pthread_cleanup cleanup;
            cleanup.push( &thread_cleanupHandler, obj );

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

            pthread_setspecific( obj.sm_this, obj );

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
            return null;
        }


        //
        // used to track the number of suspended threads
        //
        sem_t   suspendCount;


        extern (C) void thread_suspendHandler( int sig )
        in
        {
            assert( sig == SIGUSR1 );
        }
        body
        {
            version( D_InlineAsm_X86 )
            {
                asm
                {
                    pushad;
                }
            }
            else version( GCC )
            {
                __builtin_unwind_init();
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
                if( obj !is null )
                {
                    obj.m_curr.tstack = getStackTop();
                }

                sigset_t    sigres = void;
                int         status;

                status = sigfillset( &sigres );
                assert( status == 0 );

                status = sigdelset( &sigres, SIGUSR2 );
                assert( status == 0 );

                status = sem_post( &suspendCount );
                assert( status == 0 );

                sigsuspend( &sigres );

                if( obj !is null )
                {
                    obj.m_curr.tstack = obj.m_curr.bstack;
                }
            }

            version( D_InlineAsm_X86 )
            {
                asm
                {
                    popad;
                }
            }
            else version( GCC )
            {
                // registers will be popped automatically
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

        }
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
// Thread Exception
////////////////////////////////////////////////////////////////////////////////


/**
 * All exceptions thrown from the Thread class derive from this class.
 */
class ThreadException : Exception
{
    this( char[] msg )
    {
        super( msg );
    }
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
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private:
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
     * Initializes a thread object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     */
    this( void function() fn )
    in
    {
        assert( fn !is null );
    }
    body
    {
        m_fn   = fn;
        m_call = Call.FN;
        m_curr = &m_main;
    }


    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     */
    this( void delegate() dg )
    in
    {
        assert( dg !is null );
    }
    body
    {
        m_dg   = dg;
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
        // NOTE: This operation needs to be synchronized to avoid a race
        //       condition with the GC.  Without this lock, the thread
        //       could start and allocate memory before being added to
        //       the global thread list, preventing it from being scanned
        //       and causing memory to be collected that is still in use.
        synchronized( slock )
        {
            version( Win32 )
            {
                m_hndl = cast(HANDLE) _beginthreadex( null, 0, &thread_entryPoint, this, 0, &m_addr );
                if( cast(size_t) m_hndl == 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            else version( Posix )
            {
                m_isRunning = true;
                scope( failure ) m_isRunning = false;

                if( pthread_create( &m_addr, null, &thread_entryPoint, this ) != 0 )
                    throw new ThreadException( "Error creating thread" );
            }
            multiThreadedFlag = true;
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
     */
    final void join( bool rethrow = true )
    {
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
        if( rethrow && m_unhandled !is null )
        {
            throw m_unhandled;
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
    // Actions on Calling Thread
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Suspends the calling thread for at least the supplied time, up to
     * a maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  interval = The minimum duration the calling thread should be
     *             suspended.
     */
    static void sleep( /*Interval*/ ulong interval )
    {
        const MAXMILLIS = uint.max - 1;

        version( Win32 )
        {
            interval /= Interval.milli;
            Sleep( MAXMILLIS < interval ? MAXMILLIS : cast(uint) interval );
        }
        else version( Posix )
        {
            alias tango.stdc.posix.unistd.sleep psleep;

            if( interval <= uint.max )
            {
                usleep( cast(uint) interval );
            }
            else if( interval / Interval.milli <= MAXMILLIS )
            {
                interval /= Interval.second;
                psleep( cast(uint) interval );
            }
            else
            {
                psleep( MAXMILLIS / 1000 );
            }
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
            // NOTE: Posix does not have an unbounded sleep routine, but
            //       uint.max seconds is long enough to be sufficient.
            tango.stdc.posix.unistd.sleep( uint.max );
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
            Thread[] buf = new Thread[sm_tlen];

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
            foreach( uint key, inout bool set; sm_local )
            {
                if( !set )
                {
                    foreach( Thread t; sm_tbeg )
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
            foreach( Thread t; sm_tbeg )
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
    Object              m_unhandled;


private:
    ////////////////////////////////////////////////////////////////////////////
    // Thread Context and GC Scanning Support
    ////////////////////////////////////////////////////////////////////////////


    static struct Context
    {
        void*           bstack,
                        tstack;
        Context*        within;
        Context*        next,
                        prev;
    }


    Context             m_main;
    Context*            m_curr;

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
        assert( c !is null );
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
        assert( c !is null );
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
        assert( t !is null );
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
        assert( t !is null );
        assert( t.next || t.prev );
        version( Win32 )
        {
            // NOTE: This doesn't work for Posix as m_isRunning must be set to
            //       false after the thread is removed during normal execution.
            assert( !t.isRunning );
        }
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

        Thread          mainThread  = new Thread();
        Thread.Context* mainContext = &mainThread.m_main;
        assert( mainContext == mainThread.m_curr );

        mainThread.m_addr    = GetCurrentThreadId();
        mainThread.m_hndl    = GetCurrentThreadHandle();
        mainContext.bstack = getStackBottom();
        mainContext.tstack = mainContext.bstack;

        TlsSetValue( Thread.sm_this, mainThread );
    }
    else version( Posix )
    {
        int         status;
        sigaction_t sigusr1 = void;
        sigaction_t sigusr2 = void;

        // This is a quick way to zero-initialize the structs without using
        // memset or creating a link dependency on their static initializer.
        (cast(byte*) &sigusr1)[0 .. sigaction_t.sizeof] = 0;
        (cast(byte*) &sigusr2)[0 .. sigaction_t.sizeof] = 0;

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

        // NOTE: Since SIGUSR2 should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        sigusr2.sa_flags   = 0;
        sigusr2.sa_handler = &thread_resumeHandler;
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

        Thread          mainThread  = new Thread();
        Thread.Context* mainContext = mainThread.m_curr;
        assert( mainContext == &mainThread.m_main );

        mainThread.m_addr    = pthread_self();
        mainContext.bstack = getStackBottom();
        mainContext.tstack = mainContext.bstack;

        mainThread.m_isRunning = true;

        status = pthread_setspecific( Thread.sm_this, mainThread );
        assert( status == 0 );
    }

    Thread.add( mainThread );
    Thread.add( mainContext );
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
                // NOTE: It's really not ideal to wait for each thread to signal
                //       individually -- rather, it would be better to suspend
                //       them all and wait once at the end.  However, semaphores
                //       don't really work this way, and the obvious alternative
                //       (looping on an atomic suspend count) requires either
                //       the atomic module (which only works on x86) or other
                //       specialized functionality.  It would also be possible
                //       to simply loop on sem_wait at the end, but I'm not
                //       convinced that this would be much faster than the
                //       current approach.
                sem_wait( &suspendCount );
            }
            else
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
        for( Thread t = Thread.sm_tbeg; t; t = t.next )
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
            }
            else
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
    synchronized( Thread.slock )
    {
        if( --suspendDepth > 0 )
            return;

        for( Thread t = Thread.sm_tbeg; t; t = t.next )
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
 *  scan        = The scanner function.  It should scan from p1 through p2 - 1.
 *  curStackTop = An optional pointer to the top of the calling thread's stack.
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
        oldStackTop = thisThread.m_curr.tstack;
        thisThread.m_curr.tstack = curStackTop;
    }

    scope( exit )
    {
        if( curStackTop && Thread.sm_tbeg )
        {
            thisThread.m_curr.tstack = oldStackTop;
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
// ThreadGroup
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
     * Creates and starts a new Thread object that executes dg and adds it to
     * the list of tracked threads.
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
     * Add t to the list of tracked threads if it is not already being tracked.
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
            foreach( Thread t; m_all.keys )
            {
                ret = dg( t ); // ret = dg( t );
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
    void joinAll( bool rethrow = true )
    {
        synchronized
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

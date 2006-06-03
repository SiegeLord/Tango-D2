/*
 *  Copyright (C) 2005-2006 Sean Kelly
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/**
 * The thread module provides support for thread creation and management.
 *
 * Design Issues:
 *
 * One design goal of Ares is to avoid forcing the use of a particular
 * programming style, so long as allowing such flexibility does not
 * compromise the overall API design.  This goal was realized here by
 * allowing threads to be created in the familiar C style (ie. by
 * composition), or by derivation, similar to the Java style.  Composition
 * is further supported by virtue of the thread local storage facility,
 * which allows for thread local data to be stored by the main thread as
 * well as by user threads.
 *
 * Future Directions:
 *
 * Support for lightwewight user threads is a long-term consideration,
 * though the design of this module is largely settled for now.
 */
module tango.core.thread;


/**
 * All exceptions thrown from this module derive from this class.
 */
class ThreadError : Exception
{
    this( char[] msg )
    {
        super( msg );
    }
}


// this should be true for most architectures
version = StackGrowsDown;


private
{
    import tango.stdc.string; // for memset
}


version( Win32 )
{
    private
    {
        import tango.os.windows.c.process;
        import tango.os.windows.c.windows;
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
 * protected:
 *     void run()
 *     {
 *         printf( "Derived thread running.\n" );
 *     }
 * }
 *
 * void threadFunc()
 * {
 *     printf( "Ccomposed thread running!\n" );
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
     *  ThreadError if the thread fails to start.
     */
    final void start();


    /**
     * Waits for this thread to complete.
     *
     * Throws:
     *  ThreadError if the operation fails.
     */
    final void join();


    ////////////////////////////////////////////////////////////////////////////
    // General Properties
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Gets the user-readable label for this thread.
     *
     * Returns:
     *  The name of this thread.
     */
    final char[] name();


    /**
     * Sets the user-readable label for this thread.
     *
     * Params:
     *  n = The new name for this thread.
     */
    final void name( char[] n );


    /**
     * Tests whether this thread is running.  This function should be
     * callable from anywhere within the application without a risk of
     * deadlock.
     *
     * Returns:
     *  true if the thread is running, false if not.
     */
    final bool isRunning();


    ////////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Suspends the calling thread for at least the supplied time.
     *
     * Params:
     *  milliseconds = The minimum duration the calling thread should be
     *                 suspended.
     */
    static void sleep( uint milliseconds );


    /**
     * Forces a context switch to occur away from the calling thread.
     */
    static void yield();


    ////////////////////////////////////////////////////////////////////////////
    // Thread Accessors
    ////////////////////////////////////////////////////////////////////////////


    /**
     * The calling thread.
     *
     * Returns:
     *  The thread object representing the calling thread.  The result of
     *  deleting this object is undefined.
     */
    static Thread getThis();


    /**
     * This function is not intended to be used by the garbage collector,
     * so memory allocation is allowed.
     *
     * Returns:
     *  An array containing references to all threads currently being
     *  tracked by the system.  The result of deleting any contained
     *  objects is undefined.
     */
    static Thread[] getAll();


    /**
     * Operates on all threads currently tracked by the system.
     *
     * Params:
     *
     * dg = The supplied code as a delegate.
     *
     * Returns:
     *  Zero if all elemented are visited, nonzero if not.
     */
    static int opApply( int delegate( inout Thread ) dg );


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
    static uint createLocal();


    /**
     * Marks the supplied key as available and sets the associated location
     * to null for all running threads.  It is assumed that any key passed
     * to this function is valid.  The result of calling this function for
     * a key which is still in use is undefined.
     *
     * Params:
     *  key = The key to delete.
     */
    static void deleteLocal( uint key );


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
    void run();


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
    static Object slock();


    //
    // Add a thread to the global thread list.
    //
    static void add( Thread t );


    //
    // Remove a thread from the global thread list.
    //
    static void remove( Thread t );


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
 * garbage collector on startup and before any other thread routines.
 * are called.
 *
 * Please note that if thread_init itself performs any allocations then
 * the thread routines reserved for garbage collector use may be called
 * while thread_init is being processed.  However, since no memory should
 * exist to be scanned at this point, it is sufficient for these functions
 * to detect the condition and return immediately.
 */
extern (C) void thread_init();


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


/**
 * Suspend all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function may be called multiple times, and must
 * be followed by a matching number of calls to thread_resumeAll before
 * processing is resumed.
 *
 * Throws:
 *  ThreadException if the suspend operation fails for a running thread.
 */
extern (C) void thread_suspendAll();


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
extern (C) void thread_resumeAll();


private alias void delegate( void*, void* ) scanAllThreadsFn;


/**
 * The main entry point for garbage collection.  The supplied delegate
 * will be passed ranges representing both stack and register values.
 *
 * Params:
 *  fn          = The scanner function.  It should scan from p1 through p2 - 1.
 *  curStackTop = An optional pointer to the top of the calling thread's stack.
 */
extern (C) void thread_scanAll( scanAllThreadsFn fn, void* curStackTop = null );


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
    Thread create( void function() fn );


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
    Thread create( void delegate() dg );


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
    void add( Thread t );


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
    void remove( Thread t );


    /**
     * Operates on all threads currently tracked by this object.
     */
    int opApply( int delegate( inout Thread ) dg );


    /**
     * Iteratively joins all tracked threads.  This function
     * will block add, remove, and opApply until it completes.
     *
     * Params:
     *  preserve = Preserve thread references.
     */
    void joinAll( bool preserve = true );


private:
    Thread[Thread]  m_all;
}
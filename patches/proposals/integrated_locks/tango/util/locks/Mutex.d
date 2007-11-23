/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Mutex;

public import tango.core.Type;

private import tango.util.locks.LockException;
private import tango.sys.Common;
private import tango.text.convert.Integer;

extern (C)
{
    void _d_monitorenter(Object h);
    void _d_monitorexit(Object h);
    void* _d_monitorget(Object h);
}


version (Posix)
{
    private import tango.stdc.posix.pthread;
    private import tango.stdc.errno;


    /**
     * Mutex wrapper that's only valid for threads in the same process.
     * This implementation is optimized for locking threads that are in the
     * same process. It maps to a $(D_CODE CRITICAL_SECTION) on Windows and to
     * a $(D_CODE pthread_mutex_t) on UNIX. Mutexes on Windows are always
     * recursive, even if the $(D_CODE NonRecursive) mutex type is used.
     */
    public class Mutex
    {
        /**
         * Accessor for the underlying mutex implementation.
         */
        package override pthread_mutex_t* mutex()
        {
            // DMD's intrinsic function gives us access to the Object's mutex 
            // implementation.
            return cast(pthread_mutex_t*) _d_monitorget(this);
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        public void acquire()
        {
            _d_monitorenter(this);
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        public bool tryAcquire()
        {
            int rc = pthread_mutex_trylock(mutex());

            if (rc == 0)
            {
                return true;
            }
            else if (rc == EBUSY)
            {
                return false;
            }
            else
            {
                checkError(rc, __FILE__, __LINE__);
                return false;
            }
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        public void release()
        {
            _d_monitorexit(this);
        }

        /**
         * Check the $(D_PARAM errorCode) argument against possible values
         * of $(D_CODE SysError.lastCode()) and throw an exception with the
         * description of the error.
         *
         * Params:
         * errorCode    = SysError.lastCode() value; must not be 0.
         * file         = name of the source file where the check is being
         *                made; you would normally use __FILE__ for this
         *                parameter.
         * line         = line number of the source file where this method
         *                was called; you would normally use __LINE__ for
         *                this parameter.
         *
         * Throws:
         * AlreadyLockedException when the mutex has already been locked by
         * another thread; DeadlockException when the mutex has already
         * been locked by the calling thread; InvalidMutexException when the
         * mutex has not been properly initialized; MutexOwnerException when
         * the calling thread does not own the mutex; LockException for any
         * of the other cases in which $(D_PARAM errorCode) is not 0.
         */
        protected final void checkError(uint errorCode, char[] file, uint line)
        in
        {
            assert(errorCode != 0, "checkError() was called with errorCode == 0");
        }
        body
        {
            switch (errorCode)
            {
                case EBUSY:
                    throw new AlreadyLockedException(file, line);
                    // break;
                case EDEADLK:
                    throw new DeadlockException(file, line);
                    // break;
                case EINVAL:
                    throw new InvalidMutexException(file, line);
                    // break;
                case EPERM:
                    throw new MutexOwnerException(file, line);
                    // break;
                default:
                    char[16] tmp;

                    throw new LockException("Unknown mutex error " ~ format(tmp, errorCode) ~
                                            ": " ~ SysError.lookup(errorCode), file, line);
                    // break;
            }
        }
    }


    // Not all POSIX-compatible platforms implement the pthread_mutex_timedlock() API.
    static if (is(pthread_mutex_timedlock))
    {
        /**
         * Mutex class that can wait to acquire a lock for a specified timeout.
         */
        public class TimedMutex: Mutex
        {
            /**
             * Conditionally acquire lock, waiting for the specified amount
             * of time.
             *
             * Params:
             * timeout  = interval specifying the relative timeout.
             *
             * Returns: true if the mutex was acquired, false if not.
             */
            public bool tryAcquire(Interval timeout)
            {
                int rc;
                timespec ts;

                rc = pthread_mutex_timedlock(mutex(), toTimespec(&ts, toAbsoluteTime(timeout)));
                if (rc == 0)
                {
                    return true;
                }
                else if (rc == ETIMEDOUT)
                {
                    return false;
                }
                else
                {
                    checkError(rc, __FILE__, __LINE__);
                    return false;
                }
            }
        }
    }


    /**
     * Convert a time interval into a C timespec struct.
     */
    package final timespec* toTimespec(timespec* ts, Interval interval)
    in
    {
        assert(ts !is null);
    }
    body
    {
        ts.tv_sec = cast(typeof(ts.tv_sec)) interval;
        ts.tv_nsec = cast(typeof(ts.tv_nsec)) ((interval - cast(Interval) ts.tv_sec) * 1_000_000_000);

        return ts;
    }

    /**
     * Convert a timeval to an Interval.
     */
    package final Interval toInterval(inout timeval tv)
    {
        return (cast(Interval) tv.tv_sec) + (cast(Interval) tv.tv_usec / 1_000_000);
    }

    /**
    * Converts the interval from the a relative time to an absolute time
    * (i.e. to the number of seconds since Jan 1, 1970 at 00:00:00
    * plus the given interval).
    *
    * Remarks:
    * On platforms that do not provide the current system time with
    * microsecond precision, the value will only have a 1-second precision.
    */
    package final Interval toAbsoluteTime(Interval interval)
    {
        timeval tv;

        gettimeofday(&tv, null);

        return toInterval(tv) + interval;
    }
}
else version (Windows)
{
    import tango.sys.Common;

    extern (Windows) BOOL TryEnterCriticalSection(LPCRITICAL_SECTION);


    /**
     * Mutex wrapper that's only valid for threads in the same process.
     * This implementation is optimized for locking threads that are in the
     * same process. It maps to a $(D_CODE CRITICAL_SECTION) on Windows and to
     * a $(D_CODE pthread_mutex_t) on UNIX. Mutexes on Windows are always
     * recursive, even if the $(D_CODE NonRecursive) mutex type is used.
     */
    public class Mutex
    {
        /**
         * Accessor to the underlying mutex implementation.
         */
        package override CRITICAL_SECTION* mutex()
        {
            // DMD's intrinsic function gives us access to the Object's mutex 
            // implementation.
            return cast(CRITICAL_SECTION*) _d_monitorget(this);
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        public void acquire()
        {
            _d_monitorenter(this);
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        public bool tryAcquire()
        {
            return (TryEnterCriticalSection(mutex()) != FALSE);
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        public void release()
        {
            _d_monitorexit(this);
        }
    }


    /**
     * Recursive mutex class that uses the Windows API.
     */
    public class TimedMutex
    {
        package HANDLE _mutex;

        /**
         * Initialize the mutex.
         */
        public this()
        {
            _mutex = CreateMutexA(null, FALSE, null);
            if (_mutex == cast(HANDLE) NULL)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Implicitly destroy the mutex.
         */
        public ~this()
        {
            CloseHandle(_mutex);
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        public void acquire()
        {
            DWORD result = WaitForSingleObject(_mutex, INFINITE);

            if (result != WAIT_OBJECT_0)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        public bool tryAcquire()
        {
            return tryAcquire(cast(Interval) 0);
        }

        /**
         * Conditionally acquire lock, waiting for the specified amount
         * of time.
         *
         * Params:
         * timeout  = interval specifying the relative timeout.
         *
         * Returns: true if the mutex was acquired, false if not.
         */
        public bool tryAcquire(Interval timeout)
        {
            DWORD result = WaitForSingleObject(_mutex, cast(DWORD) (timeout != Interval.max ?
                                                                    (cast(DWORD) timeout * 1000.0) :
                                                                    INFINITE));

            if (result == WAIT_OBJECT_0)
            {
                return true;
            }
            else if (result == WAIT_TIMEOUT)
            {
                return false;
            }
            else
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
                return false;
            }
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        public void release()
        {
            if (ReleaseMutex(_mutex) != 0)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Check the $(D_PARAM errorCode) argument against possible values
         * of $(D_CODE SysError.lastCode()) and throw an exception with the
         * description of the error.
         *
         * Params:
         * errorCode    = SysError.lastCode() value; must not be 0.
         * file         = name of the source file where the check is being
         *                made; you would normally use __FILE__ for this
         *                parameter.
         * line         = line number of the source file where this method
         *                was called; you would normally use __LINE__ for
         *                this parameter.
         *
         * Throws:
         * AccessDeniedException when the caller does not have permissions to
         * use the mutex; LockException for any of the other cases in which
         * $(D_PARAM errorCode) is not 0.
         */
        protected void checkError(uint errorCode, char[] file, uint line)
        in
        {
            char[10] tmp;

            assert(errorCode != 0, "checkError() was called with SysError.lastCode() == 0 on file " ~
                                   file ~ ":" ~ format(tmp, line));
        }
        body
        {
            switch (errorCode)
            {
                case ERROR_ACCESS_DENIED:
                    throw new AccessDeniedException(file, line);
                    // break;
                default:
                    char[10] tmp;

                    throw new LockException("Unknown mutex error " ~ format(tmp, errorCode) ~
                                            ": " ~ SysError.lookup(errorCode), file, line);
                    // break;
            }
        }
    }
}
else
{
    static assert(false, "Mutexes are not supported on this platform");
}


/**
 * Exception-safe locking mechanism that wraps a Mutex.
 *
 * This class is meant to be used within a method or function (or any other
 * block that defines a scope). It performs automatic aquisition and release
 * of a synchronization object.
 *
 * Examples:
 * ---
 * void method1(Mutex mutex)
 * {
 *     ScopedLock lock(mutex);
 *
 *     if (!doSomethingProtectedByMutex())
 *     {
 *         // As the ScopedLock is an scope class, it will be destroyed when
 *         // method1() goes out of scope and inside its destructor it will
 *         // release the Mutex.
 *         throw Exception("The mutex will be released when method1() returns");
 *     }
 * }
 * ---
 */
public scope class ScopedLock
{
    private Mutex _mutex;
    private bool _acquired;

    /**
     * Initialize the lock, optionally acquiring the mutex.
     *
     * Params:
     * mutex            = Mutex that will be acquired on construction of an
     *                    instance of this class and released upon its
     *                    destruction.
     * acquireInitially = indicates whether the Mutex should be acquired
     *                    inside this method or not.
     *
     * Remarks:
     * The pattern implemented by this class is also called guard.
     */
    public this(Mutex mutex, bool acquireInitially = true)
    {
        _mutex = mutex;

        if (acquireInitially)
        {
            _mutex.acquire();
        }
        _acquired = acquireInitially;
    }

    /**
     * Release the underlying Mutex (it if had been acquired and not
     * previously released) and destroy the scoped lock.
     */
    public ~this()
    {
        release();
    }

    /**
     * Acquire the underlying mutex.
     *
     * Remarks:
     * If the mutex had been previously acquired this method doesn't do
     * anything.
     */
    public final void acquire()
    {
        if (!_acquired)
        {
            _mutex.acquire();
            _acquired = true;
        }
    }

    /**
     * Release the underlying mutex.
     *
     * Remarks:
     * If the mutex had not been previously acquired this method doesn't do
     * anything.
     */
    public final void release()
    {
        if (_acquired)
        {
            _mutex.release();
            _acquired = false;
        }
    }
}

// Not all platforms have support for timed mutexes.
static if (is(TimedMutex))
{
    /**
    * Exception-safe locking mechanism that wraps a TimedMutex.
    *
    * This class is meant to be used within a method or function (or any other
    * block that defines a scope). It performs automatic aquisition and release
    * of a synchronization object.
    *
    * Examples:
    * ---
    * void method1(TimedMutex mutex)
    * {
    *     ScopedTimedLock lock(mutex);
    *
    *     if (!doSomethingProtectedByMutex())
    *     {
    *         // As the ScopedTimedLock is an scope class, it will be destroyed
    *         // when method1() goes out of scope and inside its destructor it
    *         // will release the Mutex.
    *         throw Exception("The mutex will be released when method1() returns");
    *     }
    * }
    * ---
    */
    public scope class ScopedTimedLock
    {
        private TimedMutex _mutex;
        private bool _acquired;

        /**
        * Initialize the lock, optionally acquiring the mutex.
        *
        * Params:
        * mutex            = TimedMutex that will be acquired on construction
        *                    of an instance of this class and released upon its
        *                    destruction.
        * acquireInitially = indicates whether the TimedMutex should be acquired
        *                    inside this method or not.
        *
        * Remarks:
        * The pattern implemented by this class is also called guard.
        */
        public this(TimedMutex mutex, bool acquireInitially = true)
        {
            _mutex = mutex;

            if (acquireInitially)
            {
                _mutex.acquire();
            }
            _acquired = acquireInitially;
        }

        /**
        * Initialize the lock and try to acquire the TimedMutex for the
        * specified amount of time.
        */
        public this(TimedMutex mutex, Interval timeout)
        {
            _mutex = mutex;

            if (!_mutex.tryAcquire(timeout))
            {
                throw new MutexTimeoutException(__FILE__, __LINE__);
            }
            _acquired = true;
        }

        /**
        * Release the underlying Mutex (it if had been acquired and not
        * previously released) and destroy the scoped lock.
        */
        public ~this()
        {
            release();
        }

        /**
        * Acquire the underlying mutex.
        *
        * Remarks:
        * If the mutex had been previously acquired this method doesn't do
        * anything.
        */
        public final void acquire()
        {
            if (!_acquired)
            {
                _mutex.acquire();
                _acquired = true;
            }
        }

        /**
        * Conditionally acquire the mutex waiting a maximum amount of time
        * to do it.
        *
        * Remarks:
        * Trying to acquire a TimedMutex more than once will always result in
        * failure, even if the TimedMutex was recursive.
        */
        public final bool tryAcquire(Interval timeout)
        {
            bool success = false;

            if (!_acquired)
            {
                success = _mutex.tryAcquire(timeout);
                _acquired = success;
            }
            return success;
        }

        /**
        * Release the underlying mutex.
        *
        * Remarks:
        * If the mutex had not been previously acquired this method doesn't do
        * anything.
        */
        public final void release()
        {
            if (_acquired)
            {
                _mutex.release();
                _acquired = false;
            }
        }
    }
}


/**
 * Wrapper class that provides a mutex interface to any
 * Object's monitor.
 */
public class MutexProxy: Mutex
{
    private Object _object;

    /**
     * Accessor for the underlying mutex implementation.
     */
    version (Windows)
    {
        package override CRITICAL_SECTION* mutex()
        {
            // DMD's intrinsic function gives us access to the Object's mutex 
            // implementation.
            return cast(CRITICAL_SECTION*) _d_monitorget(_object);
        }
    }
    else version (Posix)
    {
        package override pthread_mutex_t* mutex()
        {
            // DMD's intrinsic function gives us access to the Object's mutex 
            // implementation.
            return cast(pthread_mutex_t*) _d_monitorget(_object);
        }
    }

    /**
     * Constructor
     */
    public this(Object object)
    {
        _object = object;
    }

    /**
     * Acquire lock ownership (wait on queue if necessary).
     */
    public void acquire()
    {
        _d_monitorenter(_object);
    }

    /**
     * Release lock and unblock a thread at head of queue.
     */
    public void release()
    {
        _d_monitorexit(_object);
    }
}


debug (UnitTest)
{
    private import tango.util.locks.LockException;
    private import tango.core.Thread;
    private import tango.io.Stdout;
    private import tango.text.convert.Integer;
    debug (mutex)
    {
        private import tango.util.log.Log;
        private import tango.util.log.ConsoleAppender;
        private import tango.util.log.DateLayout;
    }

    /**
    * Example program for the tango.util.locks.Mutex module.
    */
    unittest
    {
        debug (mutex)
        {
            scope Logger log = Log.getLogger("mutex");

            log.addAppender(new ConsoleAppender(new DateLayout()));

            log.info("Mutex test");
        }

        testLocking();
        testObjectLocking();
        testRecursive();
    }

    /**
     * Create several threads that acquire and release a mutex several times.
     */
    void testLocking()
    {
        const uint MaxThreadCount   = 10;
        const uint LoopsPerThread   = 1000;

        debug (mutex)
        {
            Logger log = Log.getLogger("mutex.locking");
        }

        Mutex   mutex = new Mutex();
        uint    lockCount = 0;

        void mutexLockingThread()
        {
            try
            {
                for (uint i; i < LoopsPerThread; i++)
                {
                    mutex.acquire();
                    lockCount++;
                    mutex.release();
                }
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught inside mutex testing thread:\n{0}\n", e.toString());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught inside mutex testing thread:\n{0}\n", e.toString());
            }
        }

        ThreadGroup group = new ThreadGroup();
        Thread      thread;
        char[10]    tmp;

        for (uint i = 0; i < MaxThreadCount; i++)
        {
            thread = new Thread(&mutexLockingThread);
            thread.name = "thread-" ~ format(tmp, i);

            debug (mutex)
                log.trace("Created thread " ~ thread.name);
            thread.start();

            group.add(thread);
        }

        debug (mutex)
            log.trace("Waiting for threads to finish");
        group.joinAll();

        if (lockCount == MaxThreadCount * LoopsPerThread)
        {
            debug (mutex)
                log.info("The Mutex locking test was successful");
        }
        else
        {
            debug (mutex)
            {
                log.error("Mutex locking is not working properly: "
                        "the number of times the mutex was acquired is incorrect");
                assert(false);
            }
            else
            {
                assert(false,"Mutex locking is not working properly: "
                            "the number of times the mutex was acquired is incorrect");
            }
        }
    }

    /**
     * Create several threads that acquire and release an Object's implicit mutex 
     * several times.
     */
    void testObjectLocking()
    {
        const uint MaxThreadCount   = 10;
        const uint LoopsPerThread   = 1000;

        debug (mutex)
        {
            Logger log = Log.getLogger("mutex.proxy.locking");
        }

        class DummyObject {}

        DummyObject dummy   = new DummyObject();
        MutexProxy  mutex   = new MutexProxy(dummy);
        uint        lockCount = 0;

        void mutexProxyLockingThread()
        {
            try
            {
                for (uint i; i < LoopsPerThread; i++)
                {
                    if (i % 2 == 0)
                    {
                        mutex.acquire();
                        lockCount++;
                        mutex.release();
                    }
                    else
                    {
                        synchronized (dummy)
                        {
                            lockCount++;
                        }
                    }
                }
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught inside ObjectMutex testing thread:\n{0}\n", e.toString());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught inside ObjectMutex testing thread:\n{0}\n", e.toString());
            }
        }

        ThreadGroup group = new ThreadGroup();
        Thread      thread;
        char[10]    tmp;

        for (uint i = 0; i < MaxThreadCount; i++)
        {
            thread = new Thread(&mutexProxyLockingThread);
            thread.name = "thread-" ~ format(tmp, i);

            debug (mutex)
                log.trace("Created thread " ~ thread.name);
            thread.start();

            group.add(thread);
        }

        debug (mutex)
            log.trace("Waiting for threads to finish");
        group.joinAll();

        if (lockCount == MaxThreadCount * LoopsPerThread)
        {
            debug (mutex)
                log.info("The MutexProxy locking test was successful");
        }
        else
        {
            debug (mutex)
            {
                log.error("MutexProxy locking is not working properly: "
                        "the number of times the mutex was acquired is incorrect");
                assert(false);
            }
            else
            {
                assert(false,"MutexProxy locking is not working properly: "
                            "the number of times the mutex was acquired is incorrect");
            }
        }
    }

    /**
     * Test that recursive mutexes actually do what they're supposed to do.
     */
    void testRecursive()
    {
        const uint LoopsPerThread   = 1000;

        debug (mutex)
        {
            Logger log = Log.getLogger("mutex.recursive");
        }

        Mutex   mutex = new Mutex();
        uint    lockCount = 0;

        try
        {
            for (uint i = 0; i < LoopsPerThread; i++)
            {
                mutex.acquire();
                lockCount++;
            }
        }
        catch (LockException e)
        {
            Stderr.formatln("Lock exception caught in recursive mutex test:\n{0}\n", e.toString());
        }
        catch (Exception e)
        {
            Stderr.formatln("Unexpected exception caught in recursive mutex test:\n{0}\n", e.toString());
        }

        for (uint i = 0; i < lockCount; i++)
        {
            mutex.release();
        }

        if (lockCount == LoopsPerThread)
        {
            debug (mutex)
                log.info("The recursive Mutex test was successful");
        }
        else
        {
            debug (mutex)
            {
                log.error("Recursive mutexes are not working: "
                        "the number of times the mutex was acquired is incorrect");
                assert(false);
            }
            else
            {
                assert(false, "Recursive mutexes are not working: "
                            "the number of times the mutex was acquired is incorrect");
            }
        }
    }
}

/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Mutex;

public import tango.core.Interval;

private import tango.util.locks.LockException;
private import tango.text.convert.Format;


version (Posix)
{
    private import tango.stdc.posix.pthread;
    private import tango.stdc.errno;
    private import tango.sys.TimeConverter;

    /**
     * Mutex wrapper that maps to a <CRITICAL_SECTION> on Windows and to a
     * <pthread_mutex_t> on UNIX. This implementation is optimized for locking
     * threads that are in the same process.
     */
    public class Mutex
    {
        enum Type: int
        {
            NonRecursive    = PTHREAD_MUTEX_NORMAL,
            ErrorChecking   = PTHREAD_MUTEX_ERRORCHECK,
            Recursive       = PTHREAD_MUTEX_RECURSIVE
        }

        package pthread_mutex_t _mutex;


        /**
         * Initialize the mutex.
         *
         * Params:
         * mutexType    = type of mutex; it can be one of NonRecursive,
         *                ErrorChecking, Recursive. The default is Recursive.
         *
         * Remarks:
         * The mutex type is valid only for POSIX compatible platforms. On
         * Windows mutexes are always recursive. Error-checking mutexes are
         * not recursive, but they provide deadlock detection (i.e. an
         * exception is thrown when the mutex is acquired more than once on
         * the same thread).
         */
        public this(Type mutexType = Type.Recursive)
        {
            int rc;
            pthread_mutexattr_t attr;

            rc = pthread_mutexattr_init(&attr);
            if (rc == 0)
            {
                pthread_mutexattr_settype(&attr, cast(int) mutexType);

                rc = pthread_mutex_init(&_mutex, &attr);
                if (rc != 0)
                {
                    checkError(rc, __FILE__, __LINE__);
                }
                pthread_mutexattr_destroy(&attr);
            }
            else
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Implicitly destroy the mutex.
         */
        public ~this()
        {
            int rc = pthread_mutex_destroy(&_mutex);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        public void acquire()
        {
            int rc = pthread_mutex_lock(&_mutex);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        public bool tryAcquire()
        {
            int rc = pthread_mutex_trylock(&_mutex);

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
            }
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        public void release()
        {
            // Releasing a mutex will never throw an exception.
            pthread_mutex_unlock(&_mutex);
        }

        /**
         * Check the 'errorCode' argument against possible errno values and
         * throw an exception with the description of the error.
         *
         * Params:
         * errorCode    = errno value; must not be 0.
         * file         = name of the source file where the check is being
         *                made; you would normally use __FILE__ for this
         *                parameter.
         * line         = line number of the source file where this method
         *                was called; you would normally use __LINE__ for
         *                this parameter.
         *
         * Throws:
         * AlreadyLockedException when the mutex has already been locked by
         * another thread (EBUSY); DeadlockException when the mutex has already
         * been locked by the calling thread (EDEADLK); InvalidMutexException
         * when the mutex has not been properly initialized (EINVAL);
         * MutexOwnerException when the calling thread does not own the mutex
         * (EPERM); LockException for any of the other cases in which errno is
         * not 0.
         */
        protected final void checkError(int errorCode, char[] file, uint line)
        in
        {
            assert(errorCode != 0,
                   Formatter.convert("checkError() was called with errorCode == 0 on file {0}:{1}",
                                     file, line));
        }
        body
        {
            switch (errorCode)
            {
                case EBUSY:
                    throw new AlreadyLockedException(file, line);
                    break;
                case EDEADLK:
                    throw new DeadlockException(file, line);
                    break;
                case EINVAL:
                    throw new InvalidMutexException(file, line);
                    break;
                case EPERM:
                    throw new MutexOwnerException(file, line);
                    break;
                default:
                    throw new LockException(Formatter.convert("Unknown mutex error {0}: {1}",
                                                              errorCode, SysError.lookup(errorCode)), file, line);
                    break;
            }
        }
    }

    version (linux)
    {
        /**
         * Mutex class that can wait to acquire a lock for a specified timeout.
         */
        public class TimedMutex: Mutex
        {
            /**
             * Initialize the mutex.
             *
             * Params:
             * mutexType    = type of mutex; it can be one of NonRecursive,
             *                ErrorChecking, Recursive. The default is Recursive.
             *
             * Remarks:
             * The mutex type is valid only for POSIX compatible platforms. On
             * Windows mutexes are always recursive.
             */
            public this(Type mutexType = Type.Recursive)
            {
                super(mutexType);
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
                int rc;
                timespec ts;

                rc = pthread_mutex_timedlock(&_mutex, toTimespec(&ts, toAbsoluteTime(timeout)));
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
                }
            }
        }
    }
}
else version (Windows)
{
    import tango.sys.Common;

    extern (Windows) BOOL TryEnterCriticalSection(LPCRITICAL_SECTION);


    /**
     * Mutex wrapper that's only valid for threads in the same process.
     * This implementation is optimized for locking threads that are in the
     * same process. It maps to a <CRITICAL_SECTION> on Windows and to a
     * <pthread_mutex_t> on UNIX. Mutexes on Windows are always recursive,
     * even if the <NonRecursive> mutex type is used.
     */
    private class Mutex
    {
        enum Type: int
        {
            Recursive,
            NonRecursive,
            ErrorChecking
        }

        package CRITICAL_SECTION _mutex;

        /**
         * Initialize the mutex.
         *
         * Params:
         * mutexType    = type of mutex; it can be one of NonRecursive,
         *                ErrorChecking, Recursive. The default is Recursive.
         *
         * Remarks:
         * The mutex type is valid only for POSIX compatible platforms. On
         * Windows mutexes are always recursive. Error-checking mutexes are
         * not recursive, but they provide deadlock detection (i.e. an
         * exception is thrown when the mutex is acquired more than once on
         * the same thread).
         */
        public this(Type mutexType = Type.Recursive)
        {
            InitializeCriticalSection(&_mutex);
        }

        /**
         * Implicitly destroy the mutex.
         */
        public ~this()
        {
            DeleteCriticalSection(&_mutex);
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        public void acquire()
        {
            EnterCriticalSection(&_mutex);
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        public bool tryAcquire()
        {
            return (TryEnterCriticalSection(&_mutex) != FALSE);
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        public void release()
        {
            LeaveCriticalSection(&_mutex);
        }
    }

    /**
     * Recursive mutex class that uses the Windows API.
     */
    private class TimedMutex
    {
        public alias Mutex.Type Type;

        package HANDLE _mutex;

        /**
         *
         */
        public this(Type mutexType = Type.Recursive)
        {
            _mutex = CreateMutexA(null, FALSE, null);
            if (_mutex == cast(HANDLE) NULL)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Implicitly destroy the mutex.
         */
        ~this()
        {
            CloseHandle(_mutex);
        }

        /**
         * Acquire lock ownership (wait on queue if necessary).
         */
        void acquire()
        {
            DWORD result = WaitForSingleObject(_mutex, INFINITE);

            if (result != WAIT_OBJECT_0)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally acquire lock (i.e., don't wait on queue).
         */
        bool tryAcquire()
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
        bool tryAcquire(Interval timeout)
        {
            DWORD result = WaitForSingleObject(_mutex, cast(DWORD) (timeout != Interval.infinity ?
                                                                    timeout / Interval.milli :
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
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Release lock and unblock a thread at head of queue.
         */
        void release()
        {
            if (ReleaseMutex(_mutex) != 0)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Check the result from the GetLastError() Windows function and
         * throw an exception with the description of the error.
         *
         * Params:
         * file     = name of the source file where the check is being made; you
         *            would normally use __FILE__ for this parameter.
         * line     = line number of the source file where this method was called;
         *            you would normally use __LINE__ for this parameter.
         *
         * Throws:
         * AccessDeniedException when the caller does not have permissions to
         * use the mutex; LockException for any of the other cases in which
         * GetLastError() is not 0.
         */
        protected void checkError(DWORD errorCode, char[] file, uint line)
        in
        {
            assert(errorCode != 0);
        }
        body
        {
            switch (errorCode)
            {
                case ERROR_ACCESS_DENIED:
                    throw new AccessDeniedException(file, line);
                    break;
                default:
                    throw new LockException(Formatter.convert("Unknown mutex error {0}: {1}",
                                                              errorCode, SysError.lookup(errorCode)), file, line);
                    break;
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
scope class ScopedLock
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
scope class ScopedTimedLock
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


debug (UnitTest)
{
    private import tango.core.Thread;
    private import tango.io.Stdout;

    /**
    * Test that non-recursive mutexes actually do what they're supposed to do.
    *
    * Remarks:
    * Windows only supports recursive mutexes.
    */
    void testNonRecursive()
    {
        version (Posix)
        {
            Mutex   mutex = new Mutex(Mutex.Type.NonRecursive);
            bool    couldLock;

            try
            {
                mutex.acquire();
                couldLock = mutex.tryAcquire();
                if (couldLock)
                {
                    mutex.release();
                }
                mutex.release();
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught when testing non-recursive mutexes:\n{0}\n", e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught when testing non-recursive mutexes:\n{0}\n", e.toUtf8());
            }

            assert(!couldLock, "Non-recursive mutexes are not working: "
                            "Mutex.tryAcquire() did not fail on an already acquired mutex");
        }
    }

    /**
    * Create several threads that acquire and release a mutex several times.
    */
    void testLocking()
    {
        const uint MaxThreadCount   = 10;
        const uint LoopsPerThread   = 1000;

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
                Stderr.formatln("Lock exception caught inside mutex testing thread:\n{0}\n", e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught inside mutex testing thread:\n{0}\n", e.toUtf8());
            }
        }

        auto group = new ThreadGroup();

        for (uint i = 0; i < MaxThreadCount; i++)
        {
            group.create(&mutexLockingThread);
        }

        group.joinAll();

        assert(lockCount == MaxThreadCount * LoopsPerThread,
            "Mutex locking is not working properly: the number of times the mutex was acquired is incorrect");
    }

    /**
    * Test that recursive mutexes actually do what they're supposed to do.
    */
    void testRecursive()
    {
        const uint LoopsPerThread   = 1000;

        Mutex   mutex = new Mutex(Mutex.Type.Recursive);
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
            Stderr.formatln("Lock exception caught in recursive mutex test:\n{0}\n", e.toUtf8());
        }
        catch (Exception e)
        {
            Stderr.formatln("Unexpected exception caught in recursive mutex test:\n{0}\n", e.toUtf8());
        }

        for (uint i = 0; i < lockCount; i++)
        {
            mutex.release();
        }

        assert(lockCount == LoopsPerThread,
            "Recursive mutexes are not working: the number of times the mutex was acquired is incorrect");
    }

    unittest
    {
        testNonRecursive();
        testLocking();
        testRecursive();
    }
}

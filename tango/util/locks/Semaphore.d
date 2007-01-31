/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Semaphore;

private import tango.util.locks.LockException;
private import tango.core.Interval;
private import tango.text.convert.Format;


version (Posix)
{
    private import tango.sys.TimeConverter;
    private import tango.stdc.posix.time;
    private import tango.stdc.posix.semaphore;
    private import tango.stdc.errno;


    /**
     * Wrapper for Dijkstra-style general semaphores that work only within
     * one process.
     */
    public class Semaphore
    {
        private sem_t _sem;

        /**
         * Initialize the semaphore, with initial value of <count>.
         */
        public this(int count)
        {
            int rc = sem_init(&_sem, 0, count);
            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Free all the resources allocated by the semaphore.
         */
        public ~this()
        {
            int rc = sem_destroy(&_sem);
            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Blocks the calling thread until the semaphore count is greater
         * than 0, at which point the count is atomically decremented.
         */
        public void acquire()
        {
            int rc = sem_wait(&_sem);
            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally decrement the semaphore if count is greater than 0
         * (i.e. it won't block).
         *
         * Returns: true if we could acquire the semaphore; false on failure
         *          (i.e. we "fail" if someone else already had the lock).
         */
        public bool tryAcquire()
        {
            int rc = sem_trywait(&_sem);

            switch (rc)
            {
                case 0:
                    return true;
                    break;

                case EAGAIN:
                    return false;
                    break;

                default:
                    checkError(rc, __FILE__, __LINE__);
                    break;
            }
        }

        version (linux)
        {
            /**
             * Conditionally decrement the semaphore if count is greater
             * than 0, waiting for the specified time.
             *
             * Returns: true if we could acquire the semaphore; false on failure
             *          (i.e. we "fail" if someone else already had the lock).
             */
            public bool tryAcquire(Interval timeout)
            {
                int rc;
                timespec ts;

                rc = sem_timedwait(&_sem, toTimespec(&ts, toAbsoluteTime(timeout)));

                switch (rc)
                {
                    case 0:
                        return true;
                        break;

                    case ETIMEDOUT:
                        return false;
                        break;

                    default:
                        checkError(rc, __FILE__, __LINE__);
                        break;
                }
            }
        }

        /**
         * Increment the semaphore by <count>, potentially unblocking waiting
         * threads.
         */
        public void release(uint count = 1)
        {
            for (uint i = 0; i < count; i++)
            {
                if (sem_post(&_sem) != 0)
                {
                    break;
                }
            }
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
         * AlreadyLockedException when the semaphore has already been locked
         * by another thread (EBUSY, EAGAIN); DeadlockException when the
         * semaphore has already been locked by the calling thread (EDEADLK);
         * InvalidSemaphoreException when the semaphore has not been properly
         * initialized (EINVAL); SempahoreOwnerException when the calling
         * thread does not own the mutex (EPERM); LockException for any of
         * the other cases in which errno is not 0.
         */
        protected void checkError(int errorCode, char[] file, uint line)
        in
        {
            assert(errorCode != 0,
                   Formatter.convert("checkError() was called with errorCode == 0 in file {0}:{1}",
                                     file, line));
        }
        body
        {
            switch (errorCode)
            {
                case EBUSY:
                case EAGAIN:
                    throw new AlreadyLockedException(file, line);
                    // break;
                case EDEADLK:
                    throw new DeadlockException(file, line);
                    // break;
                case EINVAL:
                    throw new InvalidSemaphoreException(file, line);
                    // break;
                case EPERM:
                    throw new SemaphoreOwnerException(file, line);
                    // break;
                case EINTR:
                    throw new InterruptedSystemCallException(file, line);
                    // break;
                default:
                    throw new LockException(Formatter.convert("Unknown sempahore error {0}: {1}",
                                                              errorCode, SysError.lookup(errorCode)), file, line);
                    // break;
            }
        }
    }
}
else version (Windows)
{
    public import tango.core.Interval;

    private import tango.sys.Common;


    /**
     * Wrapper for Dijkstra-style general semaphores that work only within
     * one process.
     */
    public class Semaphore
    {
        private HANDLE _sem;

        /**
         * Initialize the semaphore, with initial value of <count>.
         */
        public this(int count)
        {
            _sem = CreateSemaphoreA(null, cast(LONG) count, cast(LONG) int.max, null);
            if (_sem == cast(HANDLE) NULL)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Free all the resources allocated by the semaphore.
         */
        ~this()
        {
            CloseHandle(_sem);
        }

        /**
         * Blocks the calling thread until the semaphore count is greater
         * than 0, at which point the count is atomically decremented.
         */
        public void acquire()
        {
            DWORD result = WaitForSingleObject(_sem, INFINITE);

            if (result != WAIT_OBJECT_0)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally decrement the semaphore if count is greater than 0
         * (i.e. it won't block).
         *
         * Returns: true if we could acquire the semaphore; false on failure
         *          (i.e. we "fail" if someone else already had the lock).
         */
        public bool tryAcquire()
        {
            return tryAcquire(cast(Interval) 0);
        }

        /**
         * Conditionally decrement the semaphore if count is greater
         * than 0, waiting for the specified time.
         *
         * Returns: true if we could acquire the semaphore; false on failure
         *          (i.e. we "fail" if someone else already had the lock).
         */
        public bool tryAcquire(Interval timeout)
        {
            DWORD result = WaitForSingleObject(_sem,
                                               cast(DWORD) (timeout != Interval.infinity ?
                                                            cast(DWORD) (timeout / Interval.milli) :
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
                return false;
            }
        }

        /**
         * Increment the semaphore by <count>, potentially unblocking waiting
         * threads.
         */
        public void release(int count = 1)
        {
            if (ReleaseSemaphore(_sem, cast(LONG) count, null) != 0)
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
                    // break;
                default:
                    throw new LockException(Formatter.convert("Unknown semaphore error {0}: {1}",
                                                              errorCode, SysError.lookup(errorCode)), file, line);
                    // break;
            }
        }
    }
}
else
{
    static assert(false, "Semaphores are not supported on this platform");
}

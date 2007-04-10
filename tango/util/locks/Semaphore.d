/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Semaphore;

private import tango.util.locks.LockException;
private import tango.core.Type;
private import tango.sys.Common;
private import tango.text.convert.Integer;
private import tango.text.Util;


version (Posix)
{
    private import tango.util.locks.Mutex;

    private import tango.stdc.posix.time;
    private import tango.stdc.posix.semaphore;
    private import tango.stdc.errno;


    /**
     * Abstract wrapper for Dijkstra-style general semaphores.
     */
    public abstract class AbstractSemaphore
    {
        protected abstract sem_t* semaphore();

        /**
         * Blocks the calling thread until the semaphore count is greater
         * than 0, at which point the count is atomically decremented.
         */
        public void acquire()
        {
            int rc = sem_wait(semaphore());
            if (rc != 0)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Conditionally decrement the semaphore if its count is greater than 
         * 0 (i.e. it won't block).
         *
         * Returns: true if we could acquire the semaphore; false on failure
         *          (i.e. we "fail" if someone else already had the lock).
         */
        public bool tryAcquire()
        {
            int rc = sem_trywait(semaphore());

            if (rc == 0)
            {
                return true;
            }
            else
            {
                int errorCode = SysError.lastCode();

                if (errorCode == EAGAIN)
                {
                    return false;
                }
                else
                {
                    checkError(errorCode, __FILE__, __LINE__);
                    return false;
                }
            }
        }

        // Not all POSIX platforms have this API.
        static if (is(sem_timedwait))
        {
            /**
             * Conditionally decrement the semaphore if its count is greater
             * than 0, waiting for the specified $(D_PARAM timeout).
             *
             * Returns: true if we could acquire the semaphore; false on failure
             *          (i.e. we "fail" if someone else already had the lock).
             */
            public bool tryAcquire(Interval timeout)
            {
                int rc;
                timespec ts;

                rc = sem_timedwait(semaphore(), toTimespec(&ts, toAbsoluteTime(timeout)));

                if (rc == 0)
                {
                    return true;
                }
                else 
                {
                    int errorCode = SysError.lastCode();

                    if (errorCode == ETIMEDOUT)
                    {
                        return false;
                    }
                    else
                    {
                        checkError(errorCode, __FILE__, __LINE__);
                        return false;
                    }
                }
            }
        }

        /**
         * Increment the semaphore by $(D_PARAM count), potentially unblocking
         * waiting threads.
         */
        public void release(uint count = 1)
        {
            for (uint i = 0; i < count; i++)
            {
                if (sem_post(semaphore()) != 0)
                {
                    break;
                }
            }
        }

        /**
         * Check the $(D_PARAM errorCode) argument against possible values
         * of SysError.lastCode() and throw an exception with the description
         * of the error.
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
         * AlreadyLockedException when the semaphore has already been locked
         * by another thread; DeadlockException when the semaphore has already
         * been locked by the calling thread; InvalidSemaphoreException when
         * the semaphore has not been properly initialized;
         * SempahoreOwnerException when the calling thread does not own the
         * mutex; LockException for any of the other cases in which
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
            // FIXME: Add error messages for ProcessSemaphores
            switch (errorCode)
            {
                case EACCES:
                    throw new AccessDeniedException(file, line);
                    // break;

                case EEXIST:
                    throw new AlreadyExistsException(file, line);
                    // break;

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
                    char[10] tmp;

                    throw new LockException("Unknown semaphore error " ~ format(tmp, errorCode) ~
                                            ": " ~ SysError.lookup(errorCode), file, line);
                    // break;
            }
        }
    }



    /**
     * Wrapper for Dijkstra-style general semaphores that work only within
     * one process.
     */
    public class Semaphore: AbstractSemaphore
    {
        private sem_t _sem;

        /**
         * Accessor for the underlying semaphore implementation.
         */
        protected override sem_t* semaphore()
        {
            return &_sem;
        }

        /**
         * Initialize the semaphore, with initial value of $(D_PARAM count).
         */
        public this(int count)
        {
            int rc = sem_init(&_sem, 0, count);
            if (rc != 0)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
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
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }
    }

    /**
     * Wrapper for Dijkstra-style general semaphores that work across multiple
     * processes.
     */
    public scope class ProcessSemaphore: AbstractSemaphore
    {
        private sem_t*  _sem;
        private char[]  _name;
        private bool    _owner;

        /**
         * Accessor for the underlying semaphore implementation.
         */
        protected override sem_t* semaphore()
        {
            return _sem;
        }

        /**
         * Constructor used by the owner of the semaphore.
         */
        public this(char[] name, int count)
        in
        {
            assert(name.length > 0 && !contains(name, '/'));
        }
        body
        {
            _name = '/' ~ name ~ '\0';
            _owner = true;

            // By default, both the user and group have access to the semaphore
            _sem = sem_open(_name.ptr, O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH, count);
            if (_sem == SEM_FAILED)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Constructor used by processes that do not own the semaphore.
         */
        public this(char[] name)
        in
        {
            assert(name.length > 0 && !contains(name, '/'));
        }
        body
        {
            _name = '/' ~ name ~ '\0';
            _owner = false;

            _sem = sem_open(_name.ptr, 0);
            if (_sem == SEM_FAILED)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Destructor.
         */
        public ~this()
        {
            if (_sem !is null)
            {
                if (sem_close(_sem) == 0)
                {
                    if (_owner)
                    {
                        if (sem_unlink(_name.ptr) != 0)
                        {
                            checkError(SysError.lastCode(), __FILE__, __LINE__);
                        }
                    }
                }
                else
                {
                    checkError(SysError.lastCode(), __FILE__, __LINE__);
                }
            }
        }
    }
}
else version (Windows)
{
    /**
     * Wrapper for Dijkstra-style general semaphores.
     */
    public abstract class AbstractSemaphore
    {
        private HANDLE _sem;

        /**
         * Free all the resources allocated by the semaphore.
         */
        public ~this()
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
                checkError(SysError.lastCode(), __FILE__, __LINE__);
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
         * than 0, waiting for the specified $(D_PARAM timeout).
         *
         * Returns: true if we could acquire the semaphore; false on failure
         *          (i.e. we "fail" if someone else already had the lock).
         */
        public bool tryAcquire(Interval timeout)
        {
            DWORD result = WaitForSingleObject(_sem,
                                               cast(DWORD) (timeout != Interval.max ?
                                                            cast(DWORD) (timeout * 1000.0) :
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
         * Increment the semaphore by $(D_PARAM count), potentially unblocking waiting
         * threads.
         */
        public void release(int count = 1)
        {
            if (!ReleaseSemaphore(_sem, cast(LONG) count, null))
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Check the $(D_PARAM errorCode) argument against possible values
         * of SysError.lastCode() and throw an exception with the description
         * of the error.
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

                    throw new LockException("Unknown semaphore error " ~ format(tmp, errorCode) ~
                                            ": " ~ SysError.lookup(errorCode), file, line);
                    // break;
            }
        }
    }

    /**
     * Wrapper for Dijkstra-style general semaphores that work only within
     * one process.
     */
    public class Semaphore: AbstractSemaphore
    {
        /**
         * Initialize the semaphore, with initial value of $(D_PARAM count).
         */
        public this(int count)
        {
            _sem = CreateSemaphoreA(null, cast(LONG) count, cast(LONG) int.max, null);
            if (_sem == cast(HANDLE) NULL)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }
    }

    /**
     * Wrapper for Dijkstra-style general semaphores that work across multiple
     * processes.
     */
    public scope class ProcessSemaphore: AbstractSemaphore
    {
        private char[]  _name;

        /**
         * Constructor used by the owner of the semaphore.
         */
        public this(char[] name, int count)
        in
        {
            assert(name.length > 0 && !contains(name, '\\'));
        }
        body
        {
            _name = name ~ '\0';

            _sem = CreateSemaphoreA(null, cast(LONG) count, cast(LONG) int.max, _name.ptr);
            if (_sem == cast(HANDLE) NULL)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Constructor used by processes that do not own the semaphore.
         */
        public this(char[] name)
        in
        {
            assert(name.length > 0 && !contains(name, '/'));
        }
        body
        {
            _name = name ~ '\0';

            _sem = OpenSemaphoreA(EVENT_ALL_ACCESS, cast(BOOL) true, _name.ptr);
            if (_sem == cast(HANDLE) NULL)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }
    }
}
else
{
    static assert(false, "Semaphores are not supported on this platform");
}


debug (UnitTest)
{
    private import tango.util.locks.Mutex;
    private import tango.util.locks.LockException;
    private import tango.core.Thread;
    private import tango.io.Stdout;
    private import tango.text.convert.Integer;
    debug (semaphore)
    {
        private import tango.util.log.Log;
        private import tango.util.log.ConsoleAppender;
        private import tango.util.log.DateLayout;
    }

    unittest
    {
        const uint MaxThreadCount   = 10;

        debug (semaphore)
        {
            scope Logger log = Log.getLogger("semaphore");

            log.addAppender(new ConsoleAppender(new DateLayout()));

            log.info("Semaphore test");
        }

        // Semaphore used in the tests.  Start it "locked" (i.e., its initial
        // count is 0).
        Semaphore   sem = new Semaphore(MaxThreadCount - 1);
        Mutex       mutex = new Mutex();
        uint        count = 0;
        bool        passed = false;

        void semaphoreTestThread()
        {
            debug (semaphore)
            {
                scope Logger log = Log.getLogger("semaphore." ~ Thread.getThis().name());

                log.trace("Starting thread");
            }

            try
            {
                uint threadNumber;

                // 'count' is a resource shared by multiple threads, so we must
                // acquire the mutex before modifying it.
                mutex.acquire();
                // debug (semaphore)
                //     log.trace("Acquired mutex");
                threadNumber = ++count;
                // debug (semaphore)
                //     log.trace("Releasing mutex");
                mutex.release();

                // We wait for all the threads to finish counting.
                if (threadNumber < MaxThreadCount)
                {
                    sem.acquire();
                    debug (semaphore)
                        log.trace("Acquired semaphore");

                    while (true)
                    {
                        mutex.acquire();

                        if (count < MaxThreadCount + 1)
                        {
                            mutex.release();
                            Thread.yield();
                        }
                        else
                        {
                            mutex.release();
                            break;
                        }
                    }

                    debug (semaphore)
                        log.trace("Releasing semaphore");
                    sem.release();
                }
                else
                {
                    passed = !sem.tryAcquire();
                    if (passed)
                    {
                        debug (semaphore)
                            log.trace("Tried to acquire the semaphore too many times and failed: OK");
                    }
                    else
                    {
                        debug (semaphore)
                            log.error("Tried to acquire the semaphore too may times and succeeded: FAILED");

                        debug (semaphore)
                            log.trace("Releasing semaphore");
                        sem.release();
                    }
                    mutex.acquire();
                    count++;
                    mutex.release();
                }
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught in Semaphore test thread {0}:\n{1}\n",
                                Thread.getThis().name, e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught in Semaphore test thread {0}:\n{1}\n",
                                Thread.getThis().name, e.toUtf8());
            }
        }

        ThreadGroup group = new ThreadGroup();
        Thread      thread;
        char[10]    tmp;

        for (uint i = 0; i < MaxThreadCount; ++i)
        {
            thread = new Thread(&semaphoreTestThread);
            thread.name = "thread-" ~ format(tmp, i);

            group.add(thread);
            debug (semaphore)
                log.trace("Created thread " ~ thread.name);
            thread.start();
        }

        debug (semaphore)
            log.trace("Waiting for threads to finish");
        group.joinAll();

        if (passed)
        {
            debug (semaphore)
                log.info("The Semaphore test was successful");
        }
        else
        {
            debug (semaphore)
            {
                log.error("The Semaphore is not working properly: it allowed "
                        "to be acquired more than it should have done");
                assert(false);
            }
            else
            {
                assert(false, "The Semaphore is not working properly: it allowed "
                            "to be acquired more than it should have done");
            }
        }
    }
}
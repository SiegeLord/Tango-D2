/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Condition;

public import tango.util.locks.Mutex;
public import tango.core.Type;

private import tango.sys.Common;
private import tango.util.locks.LockException;
private import tango.text.convert.Integer;


/**
 * Condition variable wrapper, which allows threads to block until shared
 * data changes state.
 *
 * A condition variable enables threads to atomically block and test the
 * condition under the protection of a mutual exclusion lock (mutex) until
 * the condition is satisfied. That is, the mutex must have been held by
 * the thread before calling $(D_CODE wait()) or $(D_CODE notify()) /
 * $(D_CODE notifyAll()) on the condition. If the condition is false, a
 * thread blocks on a condition variable and atomically releases the mutex
 * that is waiting for the condition to change. If another thread changes
 * the condition, it may wake up waiting threads by signaling the associated
 * condition variable. The waiting threads, upon awakening, reacquire the
 * mutex and re-evaluate the condition.
 *
 * Remarks:
 * On POSIX-compatible platforms the $(D_CODE Condition) is implemented using a
 * $(D_CODE pthread_cond_t) from the pthread API. The Windows API (before
 * Windows Vista) does not provide a native condition variable, so it is
 * emulated with a mutex, a semaphore and an event. The Windows condition
 * variable emulation is based on the ACE_Condition template class from the
 * $(LINK2 http://www.cs.wustl.edu/~schmidt/ACE.html ACE framework).
 *
 * Examples:
 * ---
 * // Thread 1: method that waits for the condition to become true
 * bool method1(Condition cond, Mutex lock, Interval timeout)
 * {
 *     bool success = false;
 *
 *     lock.acquire();
 *     scope(exit)
 *         lock.release();
 *
 *     while (!conditionBeingWaitedFor)
 *     {
 *         success = cond.wait(timeout);
 *     }
 *     return success;
 * }
 *
 * // Thread 2: method that notifies the other thread that the condition
 * //           is true
 * void method2(Condition cond, Mutex lock)
 * {
 *     lock.acquire();
 *     scope(exit)
 *         lock.release();
 *
 *     conditionBeingWaitedFor = true;
 *     cond.notify();
 * }
 * ---
 */
version (Posix)
{
    private import tango.stdc.posix.pthread;
    private import tango.stdc.errno;


    class Condition
    {
        private pthread_cond_t  _cond;
        private Mutex           _externalMutex;

        /**
         * Initialize the condition variable.
         */
        public this(Mutex mutex)
        in
        {
            assert(mutex !is null);
        }
        body
        {
            _externalMutex = mutex;
            // pthread_cond_init() will never return an error on Linux.
            pthread_cond_init(&_cond, null);
        }

        /+ IMPORTANT:
           This method must remain commented out until the Mutex module that
           uses each object's implicit monitor is integrated into Tango.

        /**
         * Initialize the condition variable with a generic object.
         */
        public this(Object object)
        in
        {
            assert(object !is null);
        }
        body
        {
            this(cast(Mutex) new MutexProxy(object));
        }
        +/

        /**
         * Implicitly destroy the condition variable.
         */
        public ~this()
        {
            int rc = pthread_cond_destroy(&_cond);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Returns a reference to the underlying mutex;
         */
        public Mutex mutex()
        {
            return _externalMutex;
        }

        /**
         * Notify only $(B one) waiting thread that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void notify()
        {
            // pthread_cond_signal() will never return an error on Linux, but
            // it may on other platforms.
            int rc = pthread_cond_signal(&_cond);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Notify $(B all) waiting threads that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void notifyAll()
        {
            // pthread_cond_broadcast() will never return an error on Linux,
            // but it may on other platforms.
            int rc = pthread_cond_broadcast(&_cond);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Block until the condition is notified from another thread.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void wait()
        {
            // pthread_cond_wait() will never return an error on Linux,
            // but it may on other platforms.
            int rc = pthread_cond_wait(&_cond, _externalMutex.mutex());

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Block on the condition, or until the specified (relative) amount
         * of time has passed. If ($D_PARAM timeout) == $(D_CODE Interval.max)
         * there is no timeout.
         *
         * Returns: true if the condition was signaled; false if the timeout
         *          was reached.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public bool wait(Interval timeout)
        {
            if (timeout == Interval.max)
            {
                wait();
                return true;
            }
            else
            {
                int rc;
                timespec ts;

                rc = pthread_cond_timedwait(&_cond, _externalMutex.mutex(),
                                            toTimespec(&ts, toAbsoluteTime(timeout)));

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
         * been locked by the calling thread; InvalidMutexException
         * when the mutex has not been properly initialized;
         * MutexOwnerException when the calling thread does not own the mutex;
         * LockException for any of the other cases in which
         * $(D_PARAM errorCode) is not 0.
         */
        protected void checkError(uint errorCode, char[] file, uint line)
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
                case EINTR:
                    throw new InterruptedSystemCallException(file, line);
                    // break;
                case EINVAL:
                    throw new InvalidConditionException(file, line);
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
else version (Windows)
{
    private import tango.util.locks.Semaphore;
    private import tango.sys.Common;


    class Condition
    {
        private uint        _waitersCount = 0;
        private Mutex       _waitersLock;
        private Semaphore   _waitersQueue;
        private Event       _waitersDone;
        private bool        _wasBroadcast = false;
        private Mutex       _externalMutex;

        /**
         * Initialize the condition variable.
         */
        public this(Mutex mutex)
        in
        {
            assert(mutex !is null);
        }
        body
        {
            _wasBroadcast = 0;

            _waitersQueue = new Semaphore(0);
            scope(failure)
                delete _waitersQueue;

            _waitersLock = new Mutex();
            scope(failure)
                delete _waitersLock;

            _waitersDone = new Event();

            _externalMutex = mutex;
        }

        /+ IMPORTANT:
           This method must remain commented out until the Mutex module that
           uses each object's implicit monitor is integrated into Tango.

        /**
         * Initialize the condition variable with a generic Object to be used 
         * as a mutex.
         */
        public this(Object object)
        in
        {
            assert(object !is null);
        }
        body
        {
            this(cast(Mutex) new MutexProxy(object));
        }
        +/

        /**
         * Implicitly destroy the condition variable.
         */
        public ~this()
        {
            _externalMutex = null;
            delete _waitersDone;
            delete _waitersLock;
            delete _waitersQueue;
        }

        /**
         * Notify only $(B one) waiting thread that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void notify()
        {
            // If there aren't any waiters, then this is a no-op.  Note that
            // this function *must* be called with the 'externalMutex' held
            // since otherwise there is a race condition that can lead to the
            // lost wakeup bug... This is needed to ensure that the '_waitersCount'
            // value is not in an inconsistent internal state while being
            // updated by another thread.
            _waitersLock.acquire();
            bool hasWaiters = (_waitersCount > 0);
            _waitersLock.release();

            if (hasWaiters)
            {
                _waitersQueue.release();
            }
        }

        /**
         * Notify $(B all) waiting threads that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void notifyAll()
        {
            bool hasWaiters = false;

            // The <externalMutex> must be locked before this call is made.

            // This is needed to ensure that '_waitersCount' and '_wasBroadcast' are
            // consistent relative to each other.
            _waitersLock.acquire();

            if (_waitersCount > 0)
            {
                // We are broadcasting, even if there is just one waiter...
                // Record the fact that we are broadcasting.  This helps the
                // Condition.wait() method know how to optimize itself.  Be
                // sure to set this with the '_waitersLock' held.
                _wasBroadcast   = true;
                hasWaiters      = true;
            }
            _waitersLock.release();

            if (hasWaiters)
            {
                // FIXME: we need to find a way to leave everything in its
                //        previous state in case an exception is thrown by
                //        the following methods.

                // Wake up all the waiters.
                _waitersQueue.release(_waitersCount);
                // Wait for all the awakened threads to acquire their part of
                // the counting semaphore.
                _waitersDone.wait();

                // This is okay, even without the '_waitersLock' held, because
                // no other waiter threads can wake up to access it.
                _wasBroadcast = false;
            }
        }

        /**
         * Block until the condition is notified from another thread.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public void wait()
        {
            _waitersLock.acquire();
            _waitersCount++;
            _waitersLock.release();

            // We keep the lock held just long enough to increment the count of
            // waiters by one. Note that we can't keep it held across the call
            // to Semaphore.acquire() since that will deadlock other calls to
            // Condition.notify().
            _externalMutex.release();
            // We must always regain the <externalMutex>, even when errors
            // occur because that's the guarantee that we give to our callers.
            scope(exit)
                _externalMutex.acquire();

            // Wait to be awakened by a call to Condition.notify() or
            // Condition.notifyAll().
            _waitersQueue.acquire();
            // Make sure that we leave everything in its previous state
            // if anything fails.
            scope(failure)
                _waitersQueue.release();

            // Reacquire lock to avoid race conditions.
            _waitersLock.acquire();

            // We're ready to return, so there's one less waiter.
            _waitersCount--;
            // Make sure the waiters count is left consistent if an
            // exception is thrown
            scope(failure)
                _waitersCount++;

            bool isLastWaiter = (_wasBroadcast && _waitersCount == 0);
            // Release the lock so that other collaborating threads can
            // make progress.
            _waitersLock.release();

            if (isLastWaiter)
            {
                // Release the signaler/broadcaster if we're the last waiter.
                _waitersDone.signal();
            }
        }

        /**
         * Block on the condition, or until the specified (relative) amount
         * of time has passed. If $(D_PARAM timeout) == $(D_CODE Interval.max)
         * there is no timeout.
         *
         * Returns: true if the condition was signaled; false if the timeout
         *          was reached.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        public bool wait(Interval timeout)
        {
            bool success = true;

            // Handle the easy case first.
            if (timeout == Interval.max)
            {
                wait();
            }
            else
            {
                // Prevent race conditions on the <_waitersCount> count.
                _waitersLock.acquire();
                _waitersCount++;
                _waitersLock.release();

                // We keep the lock held just long enough to increment the
                // count of waiters by one. Note that we can't keep it held
                // across the call to Semaphore.tryAcquire() since that will
                // deadlock other calls to Condition.notify().
                _externalMutex.release();
                // We must always regain the <externalMutex>, even when errors
                // occur because that's the guarantee that we give to our callers.
                scope(exit)
                    _externalMutex.acquire();

                // Wait to be awakened by a Condition.notify() or
                // Condition.notifyAll().
                success = _waitersQueue.tryAcquire(timeout);

                // Reacquire lock to avoid race conditions.
                _waitersLock.acquire();
                _waitersCount--;
                bool isLastWaiter = (_wasBroadcast && _waitersCount == 0);
                _waitersLock.release();

                if (isLastWaiter)
                {
                    // Release the signaler/broadcaster if we're the
                    // last waiter.
                    _waitersDone.signal();
                }
            }
            return success;
        }
    }

    /**
     * A wrapper around the Win32 event locking mechanism.
     */
    private class Event
    {
        package HANDLE _event;

        /**
         * Initialize the event.
         */
        public this(bool manualReset = false, bool initialState = false)
        {
            _event = CreateEventA(null, cast(BOOL) manualReset, cast(BOOL) initialState, null);
            if (_event == cast(HANDLE) NULL)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Implicitly destroy the event.
         */
        public ~this()
        {
            CloseHandle(_event);
        }

        /**
         * If the Event was created with $(B manual reset) enabled then wakeup
         * all waiting threads and reset the event; if not ($(B auto reset))
         * wake up one waiting thread (if present) and reset event.
         */
        public void pulse()
        {
            if (!PulseEvent(_event))
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Set to nonsignaled state.
         */
        public void reset()
        {
            if (!ResetEvent(_event))
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * If $(B manual reset) was enabled, then wake up all waiting threads
         * and set the event to the signaled state. When in $(B auto reset))
         * mode, if no thread is waiting, set to signaled state. If one or
         * more threads are waiting, wake up one waiting thread and reset
         * the event
         */
        public void signal()
        {
            if (!SetEvent(_event))
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * If $(B manual reset) is enabled, sleep till the event becomes
         * signaled. The event remains signaled after $(D_CODE wait())
         * completes. If in $(B auto reset) mode, sleep till the event becomes
         * signaled. In this case the event will be reset after
         * $(D_CODE wait()) completes.
         */
        public void wait()
        {
            DWORD result = WaitForSingleObject(_event, INFINITE);

            if (result != WAIT_OBJECT_0)
            {
                checkError(SysError.lastCode(), __FILE__, __LINE__);
            }
        }

        /**
         * Same as $(D_CODE wait()) above, but this method can be timed.
         * $(D_PARAM timeout) is a relative timeout. If the timeout is equal to
         * $(D_CODE Interval.max) then this method behaves like the one
         * above.
         *
         * Returns: true if the event was signaled; false if the timeout
         *          was reached.
         */
        public bool wait(Interval timeout)
        {
            DWORD result = WaitForSingleObject(_event,
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

                    throw new LockException("Unknown event error " ~ format(tmp, errorCode) ~
                                            ": " ~ SysError.lookup(errorCode), file, line);
                    // break;
            }
        }
    }
}
else
{
    static assert(false, "Condition variables are not supported on this platform");
}

debug (UnitTest)
{
    private import tango.util.locks.LockException;
    private import tango.core.Thread;
    private import tango.text.convert.Integer;
    private import tango.io.Stdout;
    debug (condition)
    {
        private import tango.util.log.Log;
        private import tango.util.log.ConsoleAppender;
        private import tango.util.log.DateLayout;
    }

    unittest
    {
        debug (condition)
        {
            scope Logger log = Log.getLogger("condition");

            log.addAppender(new ConsoleAppender(new DateLayout()));

            log.info("Condition test");
        }

        testNotifyOne();
        testNotifyAll();
    }

    /**
     * Test for Condition.notify().
     */
    void testNotifyOne()
    {
        debug (condition)
        {
            Logger log = Log.getLogger("condition.notify-one");
        }

        scope Mutex     mutex   = new Mutex();
        scope Condition cond    = new Condition(mutex);
        int             waiting = 0;
        Thread          thread;

        void notifyOneTestThread()
        {
            debug (condition)
            {
                Logger log = Log.getLogger("condition.notify-one." ~ Thread.getThis().name());

                log.trace("Starting thread");
            }

            try
            {
                mutex.acquire();
                debug (condition)
                    log.trace("Acquired mutex");

                scope(exit)
                {
                    debug (condition)
                        log.trace("Releasing mutex");
                    mutex.release();
                }

                waiting++;

                while (waiting != 2)
                {
                    debug (condition)
                        log.trace("Waiting on condition variable");
                    cond.wait();
                }

                debug (condition)
                    log.trace("Condition variable was signaled");
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught in Condition test thread {0}:\n{1}",
                                Thread.getThis().name(), e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught in Condition test thread {0}:\n{1}",
                                Thread.getThis().name(), e.toUtf8());
            }
            debug (condition)
                log.trace("Exiting thread");
        }

        thread = new Thread(&notifyOneTestThread);
        thread.name = "thread-1";

        debug (condition)
            log.trace("Created thread " ~ thread.name);
        thread.start();

        try
        {
            // Poor man's barrier: wait until the other thread is waiting.
            while (true)
            {
                mutex.acquire();
                scope(exit)
                    mutex.release();

                if (waiting != 1)
                {
                    Thread.yield();
                }
                else
                {
                    break;
                }
            }

            mutex.acquire();
            debug (condition)
                log.trace("Acquired mutex");

            waiting++;

            debug (condition)
                log.trace("Notifying test thread");
            cond.notify();

            debug (condition)
                log.trace("Releasing mutex");
            mutex.release();

            thread.join();

            if (waiting == 2)
            {
                debug (condition)
                    log.info("The Condition notification test to one thread was successful");
            }
            else
            {
                debug (condition)
                {
                    log.error("The condition variable notification to one thread is not working");
                    assert(false);
                }
                else
                {
                    assert(false, "The condition variable notification to one thread is not working");
                }
            }
        }
        catch (LockException e)
        {
            Stderr.formatln("Lock exception caught in main thread:\n{0}", e.toUtf8());
        }
    }


    /**
     * Test for Condition.notifyAll().
     */
    void testNotifyAll()
    {
        const uint MaxThreadCount = 10;

        debug (condition)
        {
            Logger log = Log.getLogger("condition.notify-all");
        }

        scope Mutex     mutex   = new Mutex();
        scope Condition cond    = new Condition(mutex);
        int             waiting = 0;

        /**
         * This thread waits for a notification from the main thread.
         */
        void notifyAllTestThread()
        {
            debug (condition)
            {
                Logger log = Log.getLogger("condition.notify-all." ~ Thread.getThis().name());

                log.trace("Starting thread");
            }

            try
            {
                mutex.acquire();
                debug (condition)
                    log.trace("Acquired mutex");

                waiting++;

                while (waiting != MaxThreadCount + 1)
                {
                    debug (condition)
                        log.trace("Waiting on condition variable");
                    cond.wait();
                }

                debug (condition)
                    log.trace("Condition variable was signaled");

                debug (condition)
                    log.trace("Releasing mutex");
                mutex.release();
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught in Condition test thread {0}:\n{1}",
                                Thread.getThis().name(), e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught in Condition test thread {0}:\n{1}",
                                Thread.getThis().name(), e.toUtf8());
            }
            debug (condition)
                log.trace("Exiting thread");
        }

        ThreadGroup group = new ThreadGroup();
        Thread      thread;
        char[10]    tmp;

        for (uint i = 0; i < MaxThreadCount; ++i)
        {
            thread = new Thread(&notifyAllTestThread);
            thread.name = "thread-" ~ format(tmp, i);

            group.add(thread);
            debug (condition)
                log.trace("Created thread " ~ thread.name);
            thread.start();
        }

        try
        {
            // Poor man's barrier: wait until all the threads are waiting.
            while (true)
            {
                mutex.acquire();
                scope(exit)
                    mutex.release();

                if (waiting != MaxThreadCount)
                {
                    Thread.yield();
                }
                else
                {
                    break;
                }
            }

            mutex.acquire();
            debug (condition)
                log.trace("Acquired mutex");

            waiting++;

            debug (condition)
                log.trace("Notifying all threads");
            cond.notifyAll();

            debug (condition)
                log.trace("Releasing mutex");
            mutex.release();

            debug (condition)
                log.trace("Waiting for threads to finish");
            group.joinAll();

            if (waiting == MaxThreadCount + 1)
            {
                debug (condition)
                    log.info("The Condition notification test to many threads was successful");
            }
            else
            {
                debug (condition)
                {
                    log.error("The condition variable notification to many threads is not working");
                    assert(false);
                }
                else
                {
                    assert(false, "The condition variable notification to many threads is not working");
                }
            }
        }
        catch (LockException e)
        {
            Stderr.formatln("Lock exception caught in main thread:\n{0}", e.toUtf8());
        }
    }
}

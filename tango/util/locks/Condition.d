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
 * the thread before calling wait or notifyOne/notifyAll on the condition.
 * If the condition is false, a thread blocks on a condition variable and
 * atomically releases the mutex that is waiting for the condition to
 * change. If another thread changes the condition, it may wake up waiting
 * threads by signaling the associated condition variable. The waiting
 * threads, upon awakening, reacquire the mutex and re-evaluate the
 * condition.
 *
 * Remarks:
 * On POSIX-compatible platforms the Condition is implemented using a
 * pthread_cond_t from the pthread API.The Windows API (before Windows
 * Vista) does not provide a native condition variable, so it is emulated
 * with a mutex, a semaphore and an event. The Windows condition variable
 * emulation is based on the ACE_Condition template class from the
 * $LINK2(http://www.cs.wustl.edu/~schmidt/ACE.html ACE framework).
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
 *         success = cond.wait(lock, timeout);
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
 *     cond.notifyOne();
 * }
 * ---
 */
version (Posix)
{
    private import tango.stdc.posix.pthread;
    private import tango.stdc.errno;


    class Condition
    {
        pthread_cond_t _cond;

        /**
         * Initialize the condition variable.
         */
        public this()
        {
            // pthread_cond_init() will never return an error on Linux.
            pthread_cond_init(&_cond, null);
        }

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
         * Notify only $B(one) waiting thread that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void notifyOne()
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
         * Notify $B(all) waiting threads that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void notifyAll()
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
         * Block on the condition.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void wait(Mutex externalMutex)
        in
        {
            assert(externalMutex !is null);
        }
        body
        {
            // pthread_cond_wait() will never return an error on Linux,
            // but it may on other platforms.
            int rc = pthread_cond_wait(&_cond, &externalMutex._mutex);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Block on the condition, or until the specified (relative) amount
         * of time has passed. If $D_PARAM(timeout) == $D_CODE(Interval.max)
         * there is no timeout.
         *
         * Returns: true if the condition was signaled; false if the timeout
         *          was reached.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        bool wait(Mutex externalMutex, Interval timeout)
        in
        {
            assert(externalMutex !is null);
        }
        body
        {
            if (timeout == Interval.max)
            {
                wait(externalMutex);
                return true;
            }
            else
            {
                int rc;
                timespec ts;

                rc = pthread_cond_timedwait(&_cond, &externalMutex._mutex,
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
        protected void checkError(int errorCode, char[] file, uint line)
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

        /**
         * Initialize the condition variable.
         */
        public this()
        {
            _wasBroadcast = 0;

            _waitersQueue = new Semaphore(0);
            scope(failure)
                delete _waitersQueue;

            _waitersLock = new Mutex();
            scope(failure)
                delete _waitersLock;

            _waitersDone = new Event();
        }

        /**
         * Implicitly destroy the condition variable.
         */
        public ~this()
        {
            delete _waitersDone;
            delete _waitersLock;
            delete _waitersQueue;
        }

        /**
         * Notify only $B(one) waiting thread that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void notifyOne()
        {
            // If there aren't any waiters, then this is a no-op.  Note that
            // this function *must* be called with the <externalMutex> held
            // since otherwise there is a race condition that can lead to the
            // lost wakeup bug... This is needed to ensure that the <_waitersCount>
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
         * Notify $B(all) waiting threads that the condition is true.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void notifyAll()
        {
            bool hasWaiters = false;

            // The <externalMutex> must be locked before this call is made.

            // This is needed to ensure that <_waitersCount> and <_wasBroadcast> are
            // consistent relative to each other.
            _waitersLock.acquire();

            if (_waitersCount > 0)
            {
                // We are broadcasting, even if there is just one waiter...
                // Record the fact that we are broadcasting.  This helps the
                // Condition.wait() method know how to optimize itself.  Be
                // sure to set this with the <_waitersLock> held.
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

                // This is okay, even without the <_waitersLock> held, because
                // no other waiter threads can wake up to access it.
                _wasBroadcast = false;
            }
        }

        /**
         * Block on the condition.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        void wait(Mutex externalMutex)
        {
            _waitersLock.acquire();
            _waitersCount++;
            _waitersLock.release();

            // We keep the lock held just long enough to increment the count of
            // waiters by one. Note that we can't keep it held across the call
            // to Semaphore.acquire() since that will deadlock other calls to
            // Condition.notifyOne().
            externalMutex.release();
            // We must always regain the <externalMutex>, even when errors
            // occur because that's the guarantee that we give to our callers.
            scope(exit)
                externalMutex.acquire();

            // Wait to be awakened by a call to Condition.notifyOne() or
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
         * of time has passed. If $D_PARAM(timeout) == $D_CODE(Interval.max)
         * there is no timeout.
         *
         * Returns: true if the condition was signaled; false if the timeout
         *          was reached.
         *
         * Remarks:
         * The external mutex must be locked before calling this method.
         */
        bool wait(Mutex externalMutex, Interval timeout)
        {
            bool success = true;

            // Handle the easy case first.
            if (timeout == Interval.max)
            {
                wait(externalMutex);
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
                // deadlock other calls to Condition.notifyOne().
                externalMutex.release();
                // We must always regain the <externalMutex>, even when errors
                // occur because that's the guarantee that we give to our callers.
                scope(exit)
                    externalMutex.acquire();

                // Wait to be awakened by a Condition.notifyOne() or
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
                checkError(GetLastError(), __FILE__, __LINE__);
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
         * If the Event was created with $B(manual reset) enabled then wakeup
         * all waiting threads and reset the event; if not ($B(auto reset))
         * wake up one waiting thread (if present) and reset event.
         */
        public void pulse()
        {
            if (!PulseEvent(_event))
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Set to nonsignaled state.
         */
        public void reset()
        {
            if (!ResetEvent(_event))
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * If $B(manual reset) was enabled, then wake up all waiting threads
         * and set the event to the signaled state. When in $B(auto reset))
         * mode, if no thread is waiting, set to signaled state. If one or
         * more threads are waiting, wake up one waiting thread and reset
         * the event
         */
        public void signal()
        {
            if (!SetEvent(_event))
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * If $B(manual reset) is enabled, sleep till the event becomes
         * signaled. The event remains signaled after wait() completes.
         * If in $B(auto reset) mode, sleep till the event becomes signaled.
         * In this case the event will be reset after wait() completes.
         */
        public void wait()
        {
            DWORD result = WaitForSingleObject(_event, INFINITE);

            if (result != WAIT_OBJECT_0)
            {
                checkError(GetLastError(), __FILE__, __LINE__);
            }
        }

        /**
         * Same as wait() above, but this method can be timed. $D_PARAM(timeout)
         * is a relative timeout. If the timeout is equal to
         * $D_CODE(Interval.max) then this method behaves like the one
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
                checkError(GetLastError(), __FILE__, __LINE__);
                return false;
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
    private import tango.core.Thread;
    private import tango.math.Random;
    private import tango.io.Stdout;

    unittest
    {
        const uint MaxThreadCount   = 10;
        const uint LoopsPerThread   = 1000;

        Mutex       mutex           = new Mutex(Mutex.Type.NonRecursive);
        Condition   notEmpty        = new Condition();
        Condition   notFull         = new Condition();
        char[40]    queue           = '.';
        uint        count           = 0;
        Random      rand            = new Random();
        uint        producerCount   = MaxThreadCount;
        uint        consumerCount   = MaxThreadCount;

        debug (locks)
            Stdout.print("* Test condition variables using producer/consumer threads\n");

        // Producer thread
        void producer()
        {
            try
            {
                uint added;
                bool wasEmpty;

                for (uint i; i < LoopsPerThread; i++)
                {
                    mutex.acquire();
                    scope(exit)
                        mutex.release();

                    assert(count <= queue.length);

                    // Wait until we have space to add elements to the queue
                    while (count == queue.length && consumerCount > 0)
                    {
                        notFull.wait(mutex);
                    }

                    if (consumerCount > 0)
                    {
                        // We need to know whether the queue was empty to signal
                        // the consumer threads
                        wasEmpty = (count == 0);

                        // Insert a random amount of elements in the queue
                        added = rand.get(queue.length - count) + 1;
                        assert(added <= queue.length - count);
                        queue[count .. count + added] = 'X';
                        count += added;

                        // Signal the consumer threads if the queue was previously
                        // empty
                        if (wasEmpty)
                        {
                            // If the queue is half full we only wake up one thread;
                            // otherwise we wake up all the consumer threads.
                            if (count <= queue.length / 2)
                            {
                                notEmpty.notifyOne();
                            }
                            else
                            {
                                notEmpty.notifyAll();
                            }
                        }
                    }
                    else
                    {
                        // We let the consumer threads know that the number
                        // of producers has changed
                        producerCount--;
                        notEmpty.notifyAll();
                        break;
                    }
                }
            }
            catch (LockException e)
            {
                Stdout.convert("Lock exception caught inside producer thread:\n{0}\n",
                               e.toUtf8());
            }
            catch (Exception e)
            {
                Stdout.convert("Unexpected exception caught in producer thread:\n{0}\n",
                               e.toUtf8());
            }
        }

        // Consumer thread
        void consumer()
        {
            uint removed;
            bool wasFull;

            try
            {
                for (uint i; i < LoopsPerThread; i++)
                {
                    mutex.acquire();
                    scope(exit)
                        mutex.release();

                    // Wait until we have space to add elements to the queue
                    while (count == 0 && producerCount > 0)
                    {
                        notEmpty.wait(mutex);
                    }

                    if (producerCount > 0)
                    {
                        // We need to know whether the queue was full to signal
                        // the producer threads
                        wasFull = (count == queue.length);

                        // Insert a random amount of elements in the queue
                        removed = rand.get(count) + 1;
                        assert(removed <= count);
                        queue[count - removed .. count] = '.';
                        count -= removed;

                        // Signal the producer threads if the queue was previously
                        // full
                        if (wasFull)
                        {
                            // If the queue is more than half full we only wake up
                            // one thread; otherwise we wake up all the producer
                            // threads.
                            if (count >= queue.length / 2)
                            {
                                notFull.notifyOne();
                            }
                            else
                            {
                                notFull.notifyAll();
                            }
                        }
                    }
                    else
                    {
                        // We let the producer threads know that the number
                        // of consumers has changed
                        consumerCount--;
                        notFull.notifyAll();
                        break;
                    }
                }
            }
            catch (LockException e)
            {
                Stdout.convert("Lock exception caught inside consumer thread:\n{0}\n",
                               e.toUtf8());
            }
            catch (Exception e)
            {
                Stdout.convert("Unexpected exception caught in consumer thread:\n{0}\n",
                               e.toUtf8());
            }
        }


        scope ThreadGroup group = new ThreadGroup();

        for (uint i = 0; i < MaxThreadCount; i++)
        {
            group.create(&producer);
            group.create(&consumer);
        }

        group.joinAll();

        assert(producerCount == 0);
        assert(consumerCount == 0);

        delete notFull;
        delete notEmpty;
        delete mutex;
   }
}
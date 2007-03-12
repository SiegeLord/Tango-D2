/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.Barrier;


version (Posix)
{
    private import tango.util.locks.LockException;
    private import tango.stdc.posix.pthread;
    private import tango.stdc.errno;
    private import tango.sys.Common;
    private import tango.text.convert.Integer;


    /**
     * Implements "barrier synchronization".
     *
     * This class allows <count> number of threads to synchronize their
     * completion of (one round of) a task, which is known as "barrier
     * synchronization". After all the threads call <wait()> on the barrier
     * they are all atomically released and can begin a new round.
     */
    public class Barrier
    {
        private pthread_barrier_t _barrier;

        /**
         * Initialize the barrier to synchronize <count> threads.
         */
        public this(uint count)
        in
        {
            assert(count > 0, "The barrier count must be bigger than 0");
        }
        body
        {
            int rc = pthread_barrier_init(&_barrier, null, count);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Free all the resources allocated by the barrier.
         */
        public ~this()
        {
            int rc = pthread_barrier_destroy(&_barrier);

            if (rc != 0)
            {
                checkError(rc, __FILE__, __LINE__);
            }
        }

        /**
         * Block the caller until all <count> threads have called
         * Barrier.wait() and then allow all the caller threads to continue
         * in parallel.
         */
        public void wait()
        {
            int rc = pthread_barrier_wait(&_barrier);

            if (rc != 0 && rc != PTHREAD_BARRIER_SERIAL_THREAD)
            {
                checkError(rc, __FILE__, __LINE__);
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
         * AlreadyLockedException when the barrier cannot be destroyed because
         * it is already locked by another thread (EBUSY);
         * InvalidBarrierException when the barrier has not been properly
         * initialized (EINVAL); LockException for any of the other cases in
         * which errno is not 0.
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
                case EINVAL:
                    throw new InvalidBarrierException(file, line);
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
    private import tango.util.locks.Condition;


    /**
     * Implements "barrier synchronization".
     * This class allows <count> number of threads to synchronize their
     * completion of (one round of) a task, which is known as "barrier
     * synchronization". After all the threads call <wait()> on the barrier
     * they are all atomically released and can begin a new round.
     *
     * Remarks:
     * This implementation uses a "sub-barrier generation numbering" scheme
     * to avoid overhead and to ensure that all threads wait to leave the
     * barrier correct. This code is based on an article from SunOpsis Vol. 4,
     * No. 1 by Richard Marejka (richard.marejka@canada.sun.com).
     */
    public class Barrier
    {
        /**
         * Helper class used to keep track of each of the barrier "generations".
         */
        private struct SubBarrier
        {
            uint _runningThreads;
            Condition _finished;

            public void init(uint count)
            {
                _runningThreads = count;
                _finished = new Condition();
            }
        }

        /**
         * Indicates whether we are the first generation of waiters or the
         * next generation of waiters.
         */
        uint _currentGeneration = 0;
        /** Total number of threads that can be waiting at any one time. */
        uint _count;
        /** Serialize access to the barrier state. */
        Mutex _mutex;
        /**
         * We keep two SubBarrier's, one for the first "generation" of
         * waiters, and one for the next "generation" of waiters.  This
         * efficiently solves the problem of what to do if all the first
         * generation waiters don't leave the barrier before one of the
         * threads calls wait() again (i.e., starts up the next generation
         * barrier).
         */
        SubBarrier[2] _subBarrier;

        /**
         * Initialize the barrier to synchronize <count> threads.
         */
        public this(uint count)
        in
        {
            assert(count > 0, "The barrier count must be bigger than 0");
        }
        body
        {
            _count = count;
            _mutex = new Mutex();
            _subBarrier[0].init(_count);
            _subBarrier[1].init(_count);
        }

        /**
         * Free all the resources allocated by the barrier.
         */
        public ~this()
        {
            delete _subBarrier[1]._finished;
            delete _subBarrier[0]._finished;
            // delete _subBarrier;
            delete _mutex;;
        }

        /**
         * Block the caller until all <count> threads have called
         * Barrier.wait() and then allow all the caller threads to continue
         * in parallel.
         */
        public void wait()
        {
            _mutex.acquire();
            scope(exit)
                _mutex.release();

            SubBarrier* current = &_subBarrier[_currentGeneration];

            if (current._runningThreads == 1)
            {
              // We're the last running thread, so swap generations and tell
              // all the threads waiting on the barrier to continue on their
              // way.
              current._runningThreads = _count;
              // Swap generations.
              _currentGeneration = 1 - _currentGeneration;
              current._finished.notifyAll();
            }
            else
            {
                --current._runningThreads;

                // Block until all the other threads wait().
                while (current._runningThreads != _count)
                {
                    current._finished.wait(_mutex);
                }
            }
        }
    }
}
else
{
    static assert(false, "Barriers are not supported on this platform");
}


debug (UnitTest)
{
    private import tango.util.locks.Mutex;
    private import tango.core.Thread;
    private import tango.io.Stdout;
    private import tango.util.locks.LockException;

    unittest
    {
        const uint MaxThreadCount   = 100;
        const uint LoopsPerThread   = 100000;

        Barrier allDone = new Barrier(MaxThreadCount);
        Mutex   mutex = new Mutex();
        uint    count = 0;
        uint    correctCount = 0;

        void barrierTestThread()
        {
            try
            {
                for (uint i; i < LoopsPerThread; ++i)
                {
                    // 'count' is a resource shared by multiple threads, so we must
                    // acquire the mutex before modifying it.
                    mutex.acquire();
                    count++;
                    mutex.release();
                }

                // We wait for all the threads to finish counting.
                allDone.wait();

                // We make sure that all the threads exited the barrier after
                // *all* of them had finished counting.
                mutex.acquire();
                if (count == MaxThreadCount * LoopsPerThread)
                {
                    ++correctCount;
                }
                mutex.release();
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught inside Barrier test thread:\n{0}\n",
                                e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught inside Barrier test thread:\n{0}\n",
                                e.toUtf8());
            }
        }

        auto group = new ThreadGroup();

        for (uint i = 0; i < MaxThreadCount; ++i)
        {
            group.create(&barrierTestThread);
        }

        group.joinAll();

        if (count != MaxThreadCount * LoopsPerThread)
        {
            Stderr.formatln("The Barrier is not working properly: the counter has an incorrect value");
            assert(false);
        }
    }
}

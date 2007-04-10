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
     * This class allows $(D_PARAM count) number of threads to synchronize
     * their completion of (one round of) a task, which is known as "barrier
     * synchronization". After all the threads call wait() on the barrier they
     * are all atomically released and can begin a new round.
     */
    public class Barrier
    {
        private pthread_barrier_t _barrier;

        /**
         * Initialize the barrier to synchronize $(D_PARAM count) threads.
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
         * Block the caller until all $(D_PARAM count) threads have called
         * wait() and then allow all the caller threads to continue in
         * parallel.
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
         * AlreadyLockedException when the barrier cannot be destroyed because
         * it is already locked by another thread; InvalidBarrierException
         * when the barrier has not been properly initialized; LockException
         * for any of the other cases in which $(D_PARAM errorCode) is not 0.
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
     * This class allows $(D_PARAM count) number of threads to synchronize
     * their completion of (one round of) a task, which is known as "barrier
     * synchronization". After all the threads call wait() on the barrier they
     * are all atomically released and can begin a new round.
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

            public void init(uint count, Mutex mutex)
            {
                _runningThreads = count;
                _finished = new Condition(mutex);
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
         * threads calls wait() again (i.e., starts up the next  generation
         * barrier).
         */
        SubBarrier[2] _subBarrier;

        /**
         * Initialize the barrier to synchronize $(D_PARAM count) threads.
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
            _subBarrier[0].init(_count, _mutex);
            _subBarrier[1].init(_count, _mutex);
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
         * Block the caller until all $(D_PARAM count) threads have called
         * wait() and then allow all the caller threads to  continue in
         * parallel.
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
                    current._finished.wait();
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
    private import tango.util.locks.LockException;
    private import tango.core.Thread;
    private import tango.io.Stdout;
    private import tango.text.convert.Integer;
    debug (barrier)
    {
        private import tango.util.log.Log;
        private import tango.util.log.ConsoleAppender;
        private import tango.util.log.DateLayout;
    }

    unittest
    {
        const uint MaxThreadCount   = 100;
        const uint LoopsPerThread   = 10000;

        debug (barrier)
        {
            scope Logger log = Log.getLogger("barrier");

            log.addAppender(new ConsoleAppender(new DateLayout()));

            log.info("Barrier test");
        }

        Barrier barrier = new Barrier(MaxThreadCount);
        Mutex   mutex = new Mutex();
        uint    count = 0;
        uint    correctCount = 0;

        void barrierTestThread()
        {
            debug (barrier)
            {
                Logger log = Log.getLogger("barrier." ~ Thread.getThis().name());

                log.trace("Starting thread");
            }

            try
            {
                for (uint i; i < LoopsPerThread; ++i)
                {
                    // 'count' is a resource shared by multiple threads, so we must
                    // acquire the mutex before modifying it.
                    mutex.acquire();
                    // debug (barrier)
                    //     log.trace("Acquired mutex");
                    count++;
                    // debug (barrier)
                    //     log.trace("Releasing mutex");
                    mutex.release();
                }

                // We wait for all the threads to finish counting.
                debug (barrier)
                    log.trace("Waiting on barrier");
                barrier.wait();
                debug (barrier)
                    log.trace("Barrier was opened");

                // We make sure that all the threads exited the barrier after
                // *all* of them had finished counting.
                mutex.acquire();
                // debug (barrier)
                //     log.trace("Acquired mutex");
                if (count == MaxThreadCount * LoopsPerThread)
                {
                    ++correctCount;
                }
                // debug (barrier)
                //     log.trace("Releasing mutex");
                mutex.release();
            }
            catch (LockException e)
            {
                Stderr.formatln("Lock exception caught in Barrier test thread {0}:\n{1}\n",
                                Thread.getThis().name, e.toUtf8());
            }
            catch (Exception e)
            {
                Stderr.formatln("Unexpected exception caught in Barrier test thread {0}:\n{1}\n",
                                Thread.getThis().name, e.toUtf8());
            }
        }

        ThreadGroup group = new ThreadGroup();
        Thread      thread;
        char[10]    tmp;

        for (uint i = 0; i < MaxThreadCount; ++i)
        {
            thread = new Thread(&barrierTestThread);
            thread.name = "thread-" ~ format(tmp, i);

            group.add(thread);
            debug (barrier)
                log.trace("Created thread " ~ thread.name);
            thread.start();
        }

        debug (barrier)
            log.trace("Waiting for threads to finish");
        group.joinAll();

        if (count == MaxThreadCount * LoopsPerThread)
        {
            debug (barrier)
                log.info("The Barrier test was successful");
        }
        else
        {
            debug (barrier)
            {
                log.error("The Barrier is not working properly: the counter has an incorrect value");
                assert(false);
            }
            else
            {
                assert(false, "The Barrier is not working properly: the counter has an incorrect value");
            }
        }
    }
}

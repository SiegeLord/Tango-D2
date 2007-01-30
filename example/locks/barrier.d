/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.Barrier;
private import tango.util.locks.Mutex;
private import tango.util.locks.LockException;
private import tango.core.Thread;
private import tango.io.Stdout;


/**
 * Example program for the tango.util.locks.Barrier module.
 */
void main(char[][] args)
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
            Stderr.formatln("Lock exception caught inside Barrier test thread:\n{0}\n", e.toUtf8());
        }
        catch (Exception e)
        {
            Stderr.formatln("Unexpected exception caught inside Barrier test thread:\n{0}\n", e.toUtf8());
        }
    }

    auto group = new ThreadGroup();

    for (uint i = 0; i < MaxThreadCount; ++i)
    {
        group.create(&barrierTestThread);
    }

    group.joinAll();

    assert(count == MaxThreadCount * LoopsPerThread,
           "The Barrier is not working properly: the counter has an incorrect value");
}

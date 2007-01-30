/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.Mutex;
private import tango.util.locks.LockException;
private import tango.core.Thread;
private import tango.io.Stdout;


/**
 * Example program for the tango.util.locks.Mutex module.
 */
void main(char[][] args)
{
    testNonRecursive();
    testLocking();
    testRecursive();
}

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
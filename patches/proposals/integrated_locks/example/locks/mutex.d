/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module mutex;

private import tango.util.locks.Mutex;
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
void main(char[][] args)
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
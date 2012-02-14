/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
               Converted to use core.sync by Sean Kelly <sean@f4.ca>
*******************************************************************************/

private import tango.core.sync.Mutex;
private import tango.core.Exception;
private import tango.core.Thread;
private import tango.io.Stdout;
private import tango.text.convert.Integer;
debug (mutex)
{
    private import tango.util.log.Log;
    private import tango.util.log.AppendConsole;
    private import tango.util.log.LayoutDate;
}


/**
 * Example program for the tango.core.sync.Mutex module.
 */
void main(char[][] args)
{
    debug (mutex)
    {
        Logger log = Log.getLogger("mutex");

        log.add(new AppendConsole(new LayoutDate()));

        log.info("Mutex test");
    }

    testLocking();
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
                synchronized (mutex)
                {
                    lockCount++;
                }
            }
        }
        catch (tango.core.Exception.SyncException e)
        {
            Stderr.formatln("Sync exception caught inside mutex testing thread:\n{0}\n", e.toString());
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
        thread.name = "thread-" ~ format(tmp, i).idup;

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
 * Test that recursive mutexes actually do what they're supposed to do.
 */
void testRecursive()
{
    const uint LoopsPerThread   = 1000;

    debug (mutex)
    {
        Logger log = Log.getLogger("mutex.recursive");
    }

    Mutex   mutex = new Mutex;
    uint    lockCount = 0;

    try
    {
        for (uint i = 0; i < LoopsPerThread; i++)
        {
            mutex.lock();
            lockCount++;
        }
    }
    catch (tango.core.Exception.SyncException e)
    {
        Stderr.formatln("Sync exception caught in recursive mutex test:\n{0}\n", e.toString());
    }
    catch (Exception e)
    {
        Stderr.formatln("Unexpected exception caught in recursive mutex test:\n{0}\n", e.toString());
    }

    for (uint i = 0; i < lockCount; i++)
    {
        mutex.unlock();
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

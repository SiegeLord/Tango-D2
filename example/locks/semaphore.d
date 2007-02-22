/*******************************************************************************
  copyright:   Copyright (c) 2007 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.Semaphore;
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


/**
 * Example program for the tango.util.locks.Barrier module.
 */
void main(char[][] args)
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

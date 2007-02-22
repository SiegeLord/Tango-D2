/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.Condition;
private import tango.util.locks.Barrier;
private import tango.util.locks.LockException;
private import tango.core.Thread;
private import tango.io.Stdout;
debug (condition)
{
    private import tango.util.log.Log;
    private import tango.util.log.ConsoleAppender;
    private import tango.util.log.DateLayout;
}


void main(char[][] args)
{
    debug (condition)
    {
        scope Logger log = Log.getLogger("condition");

        log.addAppender(new ConsoleAppender(new DateLayout()));

        log.info("Condition test");
    }

    testNotifyOne();
}

void testNotifyOne()
{
    debug (condition)
    {
        Logger log = Log.getLogger("condition.notify-one");
    }

    scope Mutex     mutex   = new Mutex();
    scope Condition cond    = new Condition();
    int             value   = 0;
    bool            waiting = false;
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

            while (value == 0)
            {
                debug (condition)
                    log.trace("Waiting on condition variable");
                waiting = true;
                cond.wait(mutex);
            }

            debug (condition)
                log.trace("Condition variable was signaled");

            debug (condition)
                log.trace("Releasing mutex");
            mutex.release();

            while (!waiting)
            {
                Thread.yield();
            }

            // We notify the main thread that we're done
            mutex.acquire();
            debug (condition)
                log.trace("Acquired mutex");

            value++;
            debug (condition)
                log.trace("Notifying main thread");
            cond.notifyOne();

            debug (condition)
                log.trace("Releasing mutex");
            mutex.release();
        }
        catch (LockException e)
        {
            Stderr.formatln("Lock exception caught in thread {0}:\n{1}",
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
        // Wait for 50 ms until the other thread is waiting.
        while (!waiting)
        {
            Thread.yield();
        }
        waiting = false;

        mutex.acquire();
        debug (condition)
            log.trace("Acquired mutex");

        value++;
        debug (condition)
            log.trace("Notifying test thread");
        cond.notifyOne();

        debug (condition)
            log.trace("Releasing mutex");
        mutex.release();

        // Wait until the other thread tells us it's ready to exit.
        mutex.acquire();
        debug (condition)
            log.trace("Acquired mutex");

        while (value == 1)
        {
            debug (condition)
                log.trace("Waiting on condition variable");
            waiting = true;
            cond.wait(mutex);
        }
        debug (condition)
            log.trace("Releasing mutex");
        mutex.release();

        if (value == 2)
        {
            debug (condition)
                log.info("The Condition test was successful");
        }
        else
        {
            debug (condition)
            {
                log.error("The condition variable did not work properly with 1 thread");
                assert(false);
            }
            else
            {
                assert(false, "The condition variable did not work properly with 1 thread");
            }
        }
    }
    catch (LockException e)
    {
        Stderr.formatln("Lock exception caught in main thread:\n{0}", e.toUtf8());
    }
}

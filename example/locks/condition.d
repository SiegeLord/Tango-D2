/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.Condition;
private import tango.util.locks.Barrier;
private import tango.util.locks.LockException;
private import tango.core.Thread;
private import tango.math.Random;
private import tango.io.Stdout;
private import tango.text.convert.Format;
private import tango.text.convert.Sprint;
private import tango.stdc.posix.pthread;
private import tango.util.log.Log;
private import tango.util.log.ConsoleAppender;
private import tango.util.log.DateLayout;

const uint MaxThreadCount   = 10;
const uint LoopsPerThread   = 100;

// Shared "queue" between producer and consumer threads
private class SharedQueue
{
    private
    {
        char[40]    _queue = '.';
        uint        _count = 0;
    }

    public
    {
        uint length()
        {
            return _queue.length;
        }

        uint count()
        {
            return _count;
        }

        bool isEmpty()
        {
            return (_count == 0);
        }

        bool isFull()
        {
            return (_count == _queue.length);
        }

        void put(uint added)
        in
        {
            assert(added <= _queue.length - _count);
        }
        body
        {
            _queue[_count .. _count + added] = 'X';
            _queue[_count + added .. _queue.length] = '.';
            _count += added;
        }

        void get(uint removed)
        in
        {
            assert(removed <= _count);
        }
        body
        {
            _queue[_count - removed .. _count] = '.';
            _count -= removed;
        }

        char[] toUtf8()
        {
            return _queue;
        }
    }
}

// Common execution context for producer and consumer threads
private class Context
{
    public
    {
        Mutex       mutex;
        Condition   canProduce;
        Condition   canConsume;
        Barrier     allReady;
        Random      rand;
        SharedQueue queue;
        uint        producerCount   = MaxThreadCount;
        uint        consumerCount   = MaxThreadCount;
    }

    this()
    {
        mutex           = new Mutex(Mutex.Type.NonRecursive);
        canProduce      = new Condition();
        canConsume      = new Condition();
        allReady        = new Barrier(MaxThreadCount * 2);
        rand            = new Random();
        queue           = new SharedQueue();
    }

    ~this()
    {
        delete allReady;
        delete canConsume;
        delete canProduce;
        delete mutex;
    }
}



// Producer thread
class ProducerThread: Thread
{
    private Context _ctx;

    this(Context ctx)
    {
        super(&run);

        _ctx = ctx;
    }

    private void run()
    {
        Logger          log     = Log.getLogger("cond." ~ Thread.getThis().name);
        Sprint!(char)   sprint  = new Sprint!(char)(256);

        log.info(sprint("Started thread"));
        try
        {
            _ctx.allReady.wait();

            for (uint i = 0; i < LoopsPerThread; i++)
            {
                _ctx.mutex.acquire();
                log.trace("mutex.acquire()");
                try
                {
                    assert(_ctx.queue.count <= _ctx.queue.length);

                    // Wait until we have space to add elements to the queue
                    while (_ctx.queue.isFull() && _ctx.consumerCount > 0)
                    {
                        log.trace("canProduce.wait(mutex)");
                        _ctx.canProduce.wait(_ctx.mutex);
                    }

                    if (_ctx.consumerCount > 0)
                    {
                        // Insert a random amount of elements in the queue
                        _ctx.queue.put(_ctx.rand.get(_ctx.queue.length - _ctx.queue.count) + 1);

                        log.info(sprint("[{0,2}] {1,40} (producers={2}; consumers={3})\r",
                                        _ctx.queue.count, _ctx.queue, _ctx.producerCount, _ctx.consumerCount));

                        // Signal the consumer threads that we have added
                        // elements to the queue
                        log.trace("canConsume.notifyOne()");
                        _ctx.canConsume.notifyOne();
                    }
                    else
                    {
                        break;
                    }
                }
                finally
                {
                    log.trace("mutex.release()");
                    _ctx.mutex.release();
                }
                Thread.yield();
            }

            _ctx.mutex.acquire();
            log.trace("mutex.acquire()");
            try
            {
                // We let the consumer threads know that the number
                // of producers has changed
                _ctx.producerCount--;
                log.trace(sprint("Leaving producer thread (producers={0}; consumers={1})",
                                 _ctx.producerCount, _ctx.consumerCount));
            }
            finally
            {
                log.trace("mutex.release()");
                _ctx.mutex.release();
            }
        }
        catch (LockException e)
        {
            log.error(sprint("Lock exception caught: {0}", e.toUtf8()));
        }
        catch (Exception e)
        {
            log.error(sprint("Unexpected exception caught: {0}", e.toUtf8()));
        }
    }
}

// Consumer thread
private class ConsumerThread: Thread
{
    private Context _ctx;

    this(Context ctx)
    {
        super(&run);

        _ctx = ctx;
    }

    private void run()
    {
        Logger          log     = Log.getLogger("cond." ~ Thread.getThis().name);
        Sprint!(char)   sprint  = new Sprint!(char)(256);
        bool            finished = false;

        _ctx.allReady.wait();

        try
        {
            while (!finished)
            {
                _ctx.mutex.acquire();
                log.trace("mutex.acquire()");

                try
                {
                    // Wait until there are elements to remove from the queue
                    while (_ctx.queue.isEmpty() && _ctx.producerCount > 0)
                    {
                        log.trace("canConsume.wait(mutex)");
                        _ctx.canConsume.wait(_ctx.mutex);
                    }

                    if (_ctx.producerCount > 0)
                    {
                        // Remove a random amount of elements in the queue
                        _ctx.queue.get(_ctx.rand.get(_ctx.queue.count) + 1);

                        log.info(sprint("[{0,2}] {1,40} (producers={2}; consumers={3})\r",
                                        _ctx.queue.count, _ctx.queue, _ctx.producerCount, _ctx.consumerCount));

                        // Signal the producer threads that we have consumed
                        // elements from the queue
                        log.trace("canProduce.notifyOne()");
                        _ctx.canProduce.notifyOne();
                    }
                    else
                    {
                        // We let the producer threads know that the number
                        // of consumers has changed
                        _ctx.consumerCount--;
                        log.trace(sprint("Leaving consumer thread (producers={0}; consumers={1})",
                                         _ctx.producerCount, _ctx.consumerCount));
                        finished = true;
                    }
                }
                finally
                {
                    log.trace("mutex.release()");
                    _ctx.mutex.release();
                }
                Thread.yield();
            }
        }
        catch (LockException e)
        {
            log.error(sprint("Lock exception caught: {0}", e.toUtf8()));
        }
        catch (Exception e)
        {
            log.error(sprint("Unexpected exception caught: {0}", e.toUtf8()));
        }
    }
}

void main(char[][] args)
{
    scope Context   ctx = new Context();
    scope Logger    log = Log.getLogger("cond");

    log.addAppender(new ConsoleAppender(new DateLayout()));

    log.info("Test condition variables using producer/consumer threads");

    ThreadGroup     producerGroup = new ThreadGroup();
    ThreadGroup     consumerGroup = new ThreadGroup();
    Thread          thread;
    Sprint!(char)   sprint  = new Sprint!(char)(256);
    bool            finished = false;

    for (uint i = 0; i < MaxThreadCount; i++)
    {
        thread = new ConsumerThread(ctx);
        thread.name = Formatter.convert("cons-{0:00}", i);
        thread.start();
        log.info(sprint("Started thread: {0}", thread.name));
        consumerGroup.add(thread);

        thread = new ProducerThread(ctx);
        thread.name = Formatter.convert("prod-{0:00}", i);
        thread.start();
        log.info(sprint("Started thread: {0}", thread.name));
        producerGroup.add(thread);
    }

    thread = null;

    producerGroup.joinAll();
    assert(ctx.producerCount == 0);
    log.info("All the producer threads have finished");

    while (!finished)
    {
        log.trace(sprint("mutex.acquire() (producers={0}, consumers={1})",
                         ctx.producerCount, ctx.consumerCount));
        ctx.mutex.acquire();

        try
        {
            if (ctx.consumerCount > 0)
            {
                log.trace(sprint("canConsume.notifyAll() (producers={0}, consumers={1})",
                                 ctx.producerCount, ctx.consumerCount));
                ctx.canConsume.notifyAll();
            }
            else
            {
                finished = true;
            }
        }
        finally
        {
            log.trace(sprint("mutex.release() (producers={0}, consumers={1})",
                             ctx.producerCount, ctx.consumerCount));
            ctx.mutex.release();
            Thread.sleep(Interval.milli * 50);
        }
    }

    consumerGroup.joinAll();
    assert(ctx.consumerCount == 0);
    log.info("All the consumer threads have finished");
}

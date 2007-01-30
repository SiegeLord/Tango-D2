/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.util.locks.ReadWriteMutex;
private import tango.util.locks.Mutex;
private import tango.core.Thread;


/**
 * Example program for the tango.util.locks.ReadWriteMutex module.
 */
void main(char[][] args)
{
    const uint ReaderThreads    = 100;
    const uint WriterThreads    = 20;
    const uint LoopsPerReader   = 10000;
    const uint LoopsPerWriter   = 1000;
    const uint CounterIncrement = 3;

    ReadWriteMutex  rwlock = new ReadWriteMutex();
    Mutex           mutex = new Mutex();
    uint            readCount = 0;
    uint            passed = 0;
    uint            failed = 0;

    void mutexReaderThread()
    {
        for (uint i = 0; i < LoopsPerReader; ++i)
        {
            // All the reader threads acquire the mutex for reading and when they are
            // all done
            rwlock.acquireRead();

            for (uint j = 0; j < CounterIncrement; ++j)
            {
                mutex.acquire();
                ++readCount;
                mutex.release();
            }

            rwlock.release();
        }
    }

    void mutexWriterThread()
    {
        for (uint i = 0; i < LoopsPerWriter; ++i)
        {
            rwlock.acquireWrite();

            mutex.acquire();
            if (readCount % 3 == 0)
            {
                ++passed;
            }
            mutex.release();

            rwlock.release();
        }
    }

    auto group = new ThreadGroup();

    for (uint i = 0; i < ReaderThreads; ++i)
    {
        group.create(&mutexReaderThread);
    }

    for (uint i = 0; i < WriterThreads; ++i)
    {
        group.create(&mutexWriterThread);
    }

    group.joinAll();

    assert(passed == WriterThreads * LoopsPerWriter,
           "The ReadWriteMutex is not working properly: the counter has an incorrect value");
}

/*******************************************************************************

        copyright:      Copyright (c) 2008 Steven Schveighoffer.
                        All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2008: Initial release

        author:         schveiguy

*******************************************************************************/

module tango.io.device.ThreadPipe;

private import tango.core.Exception;

private import tango.io.device.Conduit;

private import tango.core.sync.Condition;

/**
 * Conduit to support a data stream between 2 threads.  One creates a
 * ThreadPipe, then uses the OutputStream and the InputStream from it to
 * communicate.  All traffic is automatically synchronized, so one just uses
 * the streams like they were normal device streams.
 *
 * It works by maintaining a circular buffer, where data is written to, and
 * read from, in a FIFO fashion.
 * ---
 * auto tc = new ThreadPipe;
 * void outFunc()
 * {
 *   Stdout.copy(tc.input);
 * }
 *
 * auto t = new Thread(&outFunc);
 * t.start();
 * tc.write("hello, thread!");
 * tc.close();
 * t.join();
 * ---
 */
class ThreadPipe : Conduit
{
    private bool _closed;
    private size_t _readIdx, _remaining;
    private void[] _buf;
    private Mutex _mutex;
    private Condition _condition;

    /**
     * Create a new ThreadPipe with the given buffer size.
     *
     * Params:
     * bufferSize = The size to allocate the buffer.
     */
    this(size_t bufferSize=(1024*16))
    {
        _buf = new ubyte[bufferSize];
        _closed = false;
        _readIdx = _remaining = 0;
        _mutex = new Mutex;
        _condition = new Condition(_mutex);
    }

    /**
     * Implements IConduit.bufferSize.
     *
     * Returns the appropriate buffer size that should be used to buffer the
     * ThreadPipe.  Note that this is simply the buffer size passed in, and
     * since all the ThreadPipe data is in memory, buffering doesn't make
     * much sense.
     */
    size_t bufferSize()
    {
        return _buf.length;
    }

    /**
     * Implements IConduit.toString
     *
     * Returns "&lt;thread conduit&gt;"
     */
    char[] toString()
    {
        return "<threadpipe>";
    }

    /**
     * Returns true if there is data left to be read, and the write end isn't
     * closed.
     */
    override bool isAlive()
    {
        synchronized(_mutex)
        {
            return !_closed || _remaining != 0;
        }
    }

    /**
     * Return the number of bytes remaining to be read in the circular buffer.
     */
    size_t remaining()
    {
        synchronized(_mutex)
            return _remaining;
    }

    /**
     * Return the number of bytes that can be written to the circular buffer.
     */
    size_t writable()
    {
        synchronized(_mutex)
            return _buf.length - _remaining;
    }

    /**
     * Close the write end of the conduit.  Writing to the conduit after it is
     * closed will return Eof.
     *
     * The read end is not closed until the buffer is empty.
     */
    void stop()
    {
        //
        // close write end.  The read end can stay open until the remaining
        // bytes are read.
        //
        synchronized(_mutex)
        {
            _closed = true;
            _condition.notifyAll();
        }
    }

    /**
     * This does nothing because we have no clue whether the members have been
     * collected, and detach is run in the destructor.  To stop communications,
     * use stop().
     *
     * TODO: move stop() functionality to detach when it becomes possible to
     * have fully-owned members
     */
    void detach()
    {
    }

    /**
     * Implements InputStream.read.
     *
     * Read from the conduit into a target array.  The provided dst will be
     * populated with content from the stream.
     *
     * Returns the number of bytes read, which may be less than requested in
     * dst. Eof is returned whenever an end-of-flow condition arises.
     */
    size_t read(void[] dst)
    {
        //
        // don't block for empty read
        //
        if(dst.length == 0)
            return 0;
        synchronized(_mutex)
        {
            //
            // see if any remaining data is present
            //
            size_t r;
            while((r = _remaining) == 0 && !_closed)
                _condition.wait();

            //
            // read all data that is available
            //
            if(r == 0)
                return Eof;
            if(r > dst.length)
                r = dst.length;

            auto result = r;

            //
            // handle wrapping
            //
            if(_readIdx + r >= _buf.length)
            {
                size_t x = _buf.length - _readIdx;
                dst[0..x] = _buf[_readIdx..$];
                _readIdx = 0;
                _remaining -= x;
                r -= x;
                dst = dst[x..$];
            }

            dst[0..r] = _buf[_readIdx..(_readIdx + r)];
            _readIdx = (_readIdx + r) % _buf.length;
            _remaining -= r;
            _condition.notifyAll();
            return result;
        }
    }

    /**
     * Implements InputStream.clear().
     *
     * Clear any buffered content.
     */
    ThreadPipe clear()
    {
        synchronized(_mutex)
        {
            if(_remaining != 0)
            {
                /*
                 * this isn't technically necessary, but we do it because it
                 * preserves the most recent data first
                 */
                _readIdx = (_readIdx + _remaining) % _buf.length;
                _remaining = 0;
                _condition.notifyAll();
            }
        }
        return this;
    }

    /**
     * Implements OutputStream.write.
     *
     * Write to stream from a source array. The provided src content will be
     * written to the stream.
     *
     * Returns the number of bytes written from src, which may be less than
     * the quantity provided. Eof is returned when an end-of-flow condition
     * arises.
     */
    size_t write(void[] src)
    {
        //
        // don't block for empty write
        //
        if(src.length == 0)
            return 0;
        synchronized(_mutex)
        {
            size_t w;
            while((w = _buf.length - _remaining) == 0 && !_closed)
                _condition.wait();

            if(_closed)
                return Eof;

            if(w > src.length)
                w = src.length;

            auto writeIdx = (_readIdx + _remaining) % _buf.length;

            auto result = w;

            if(w + writeIdx >= _buf.length)
            {
                auto x = _buf.length - writeIdx;
                _buf[writeIdx..$] = src[0..x];
                writeIdx = 0;
                w -= x;
                _remaining += x;
                src = src[x..$];
            }
            _buf[writeIdx..(writeIdx + w)] = src[0..w];
            _remaining += w;
            _condition.notifyAll();
            return result;
        }
    }
}

debug(UnitTest)
{
    import tango.core.Thread;

    unittest
    {
        uint[] source = new uint[1000];
        foreach(i, ref x; source)
            x = i;

        ThreadPipe tp = new ThreadPipe(16);
        void threadA()
        {
            void[] sourceBuf = source;
            while(sourceBuf.length > 0)
            {
                sourceBuf = sourceBuf[tp.write(sourceBuf)..$];
            }
            tp.stop();
        }
        Thread a = new Thread(&threadA);
        a.start();
        int readval;
        int last = -1;
        size_t nread;
        while((nread = tp.read((&readval)[0..1])) == readval.sizeof)
        {
            assert(readval == last + 1);
            last = readval;
        }
        assert(nread == tp.Eof);
        a.join();
    }
}

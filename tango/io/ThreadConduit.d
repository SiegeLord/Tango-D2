/**
 * copyright:      Copyright (c) 2008 Steven Schveighoffer. All rights reserved
 *
 * license:        BSD style: $(LICENSE)
 *
 * version:        Initial release: June 2008
 *
 * author:         schveiguy
 */
module tango.io.ThreadConduit;

private import tango.core.sync.Condition;
private import tango.core.Exception;

public import tango.io.model.IConduit;

/**
 * Conduit to support a data stream between 2 threads.  One creates a
 * ThreadConduit, then uses the OutputStream and the InputStream from it to
 * communicate.  All traffic is automatically synchronized, so one just uses
 * the streams like they were normal device streams.
 *
 * It works by maintaining a circular buffer, where data is written to, and
 * read from, in a FIFO fashion.
 * -----------
 * auto tc = new ThreadConduit;
 * void outFunc()
 * {
 *   Stdout.copy(tc.input)
 * }
 *
 * auto t = new Thread(&outFunc);
 * t.start();
 * tc.output.write("hello, thread!");
 * tc.close();
 * t.join();
 */
class ThreadConduit : IConduit
{
    private bool _closed;
    private uint _readIdx, _writeIdx;
    private void[] _buf;
    private Mutex _mutex;
    private Condition _condition;

    /**
     * Create a new ThreadConduit with the given buffer size.
     *
     * Params:
     * bufferSize = the size to allocate the buffer. 
     */
    this(uint bufferSize=(1024*16))
    {
        _buf = new void[bufferSize];
        _closed = false;
        _readIdx = _writeIdx = 0;
        _mutex = new Mutex;
        _condition = new Condition(_mutex);
    }

    /**
     * Implements IConduit.input (covariant)
     */
    ThreadConduit input()
    {
        return this;
    }

    /**
     * Implements IConduit.output (covariant)
     */
    ThreadConduit output()
    {
        return this;
    }

    /**
     * Implements IConduit.bufferSize
     *
     * Returns the appropriate buffer size that should be used to buffer the
     * ThreadConduit.  Note that this is simply the buffer size passed in, and
     * since all the ThreadConduit data is in memory, buffering doesn't make
     * much sense.
     */
    uint bufferSize()
    {
        return _buf.length;
    }

    /**
     * Implements IConduit.toString
     *
     * Returns "<thread conduit>"
     */
    char[] toString()
    {
        return "<thread conduit>";
    }

    /**
     * Returns true if there is data left to be read, and the write end isn't
     * closed.
     */
    bool isAlive()
    {
        synchronized(_mutex)
        {
            return !_closed || remaining != 0;
        }
    }

    /**
     * Return the number of bytes remaining to be read in the circular buffer
     */
    uint remaining()
    {
        synchronized(_mutex)
        {
            if(_writeIdx < _readIdx)
                return _writeIdx + _buf.length - _readIdx;
            else
                return _writeIdx - _readIdx;
        }
    }

    /**
     * Return the number of bytes that can be written to the circular buffer
     *
     * Note that we leave 1 byte for a marker to know whether the read pointer
     * is ahead or behind the write pointer.
     */
    uint writable()
    {
        return _buf.length - remaining - 1;
    }

    /**
     * Close the write end of the conduit.  Writing to the conduit after it is
     * closed will return Eof.
     *
     * The read end is not closed until the buffer is empty.
     */
    void detach()
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
     * Throw an IOException with the given message.
     */
    void error(char[] msg)
    {
        throw new IOException(msg);
    }

    /**
     * Implements InputStream.conduit and OutputStream.conduit (covariant)
     */
    ThreadConduit conduit()
    {
        return this;
    }

    /**
     * Close the write end of the conduit.  Same as detach()
     */
    void close()
    {
        detach();
    }

    /**
     * Implements InputStream.read
     *
     * Read from the conduit into a target array.  The provided dst will be
     * populated with content from the stream.
     *
     * Returns the number of bytes read, which may be less than requested in
     * dst. Eof is returned whenever an end-of-flow condition arises.
     */
    uint read(void[] dst)
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
            uint r;
            while((r = remaining) == 0 && !_closed)
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
                uint x = _buf.length - _readIdx;
                dst[0..x] = _buf[_readIdx..$];
                _readIdx = 0;
                r -= x;
                dst = dst[x..$];
            }

            dst[0..r] = _buf[_readIdx..(_readIdx + r)];
            _readIdx += r;
            _condition.notifyAll();
            return result;
        }
    }

    /**
     * Implements InputStream.load
     *
     * Load the bits from a stream, and return them all in an array. The dst
     * array can be provided as an option, which will be expanded as necessary
     * to consume the input.
     *
     * Returns an array representing the content, and throws IOException on
     * error
     */
    void[] load(void[] dst = null)
    {
        //
        // copied from Conduit.load
        //
        auto chunk = 0;
        auto index = 0;

        while (chunk != Eof)
        {
            if (dst.length - index < 1024)
                dst.length = dst.length + 16 * 1024;

            chunk = read (dst[index .. $]);
            index += chunk;
        } 

        return dst [0 .. index - chunk];
    }

    /**
     * Implements InputStream.clear()
     *
     * Clear any buffered content
     */
    ThreadConduit clear()
    {
        synchronized(_mutex)
        {
            if(_readIdx != _writeIdx)
            {
                _condition.notifyAll();
                _readIdx = _writeIdx;
            }
        }
        return this;
    }

    /**
     * Implements OutputStream.write
     *
     * Write to stream from a source array. The provided src content will be
     * written to the stream.
     *
     * Returns the number of bytes written from src, which may be less than
     * the quantity provided. Eof is returned when an end-of-flow condition
     * arises.
     */
    uint write(void[] src)
    {
        //
        // don't block for empty write
        //
        if(src.length == 0)
            return 0;
        synchronized(_mutex)
        {
            uint w;
            while((w = writable) == 0 && !_closed)
                _condition.wait();

            if(_closed)
                return Eof;

            if(w > src.length)
                w = src.length;

            auto result = w;

            if(w + _writeIdx >= _buf.length)
            {
                auto x = _buf.length - _writeIdx;
                _buf[_writeIdx..$] = src[0..x];
                _writeIdx = 0;
                w -= x;
                src = src[x..$];
            }
            _buf[_writeIdx..(_writeIdx + w)] = src[0..w];
            _writeIdx += w;
            _condition.notifyAll();
            return result;
        }
    }

    /**
     * Implements OutputStream.copy
     *
     * Transfer the content of another stream to this one. Returns a reference
     * to this class, and throws IOException on failure.
     */
    ThreadConduit copy(InputStream src)
    {
        //
        // copied from Conduit
        //
        uint len = 0;
        auto tmp = new void [bufferSize];
        while ((len = src.read(tmp)) != IConduit.Eof)
        {
            auto p = tmp.ptr;
            for (uint j; len > 0; len -= j, p += j)
                if ((j = write (p[0..len])) is IConduit.Eof)
                    error ("ThreadConduit.copy :: Eof while writing to: "~toString);
        }
        delete tmp;
        return this;
    }

    /**
     * Implements OutputStream.flush
     *
     * Since there is no callable sink, this is a noop.
     */
    ThreadConduit flush()
    {
        return this;
    }
}

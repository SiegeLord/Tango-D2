/*******************************************************************************
 * 
 *      copyright:      Copyright (c) 2011 mta`chrono. All rights reserved
 *
 *      license:        BSD style: $(LICENSE)
 * 
 *      version         Nov 2011: Initial release
 * 
 *      author          mta`chrono
 * 
 * This file is part of the tango software library. Distributed under the terms
 * of the Boost Software License, Version 1.0. See LICENSE.TXT for more info.
 * 
 * A Circular Buffer is explained here: http://en.wikipedia.org/wiki/Circular_buffer
 * 
 * 
 *    Explanation:
 *
 *       this.buffer.length      - the length of the internal buffer
 *       this.buffer.ptr         - points to begin of the internal buffer
 *       +======-------------+   - visualisation of the internal buffer (= data, - free)
 *       this.end                - a write call will write data to this location
 *       this.begin              - a read call will read data upon this location
 *
 *
 *    Case 1 - The Buffer is empty
 *
 *       this.begin                An empty buffer is determined that both
 *       v                         pointer actually point to the same location
 *       +-------------------+     of the buffer.
 *       ^
 *       this.end
 *
 *    Case 2 - The Buffer is full
 *
 *            this.begin           The buffer is full if only one slot is
 *            v                    empty. So the buffer can never written
 *       +===-===============+     fully full.
 *           ^
 *           this.end
 *
 *    Case 3 - Begin is ahead of end
 *
 *                   this.begin    this.begin > this.end. The space left
 *                   v             empty is the space between this.end
 *       +==---------========+     and this.begin. the other parts are filled
 *          ^                      with data.
 *          this.end
 *
 *    Case 4 - End is ahead of begin
 *
 *                   this.end      this.end > this.begin. The space between
 *                   v             them is considered to be filled with data.
 *       +--=========--------+
 *          ^
 *          this.begin
 * 
 *******************************************************************************/
module tango.io.CircularBuffer;

private import  tango.io.device.Device;

/*******************************************************************************
 * A circular buffer can be used like any other Device's of tango. Here is
 * small example of what you can do with a circular buffer.
 * 
 * The default size of a CircularBuffer is 1024 bytes
 * 
 * ---
 * auto buffer = new CircularBuffer();  
 * buffer.write("hello world");
 * 
 * // use read method
 * char data[] = new char[11];
 * buffer.read(data);
 * 
 * // use text method
 * buffer.write("hello world");
 * data = buffer.text(11);
 * 
 * // get all with text method
 * data = buffer.text();
 * ---
 * 
 * You can also create a larger / smaller buffer.
 * ---
 * auto buffer = new CircularBuffer(100);
 * buffer.write("hello world");
 * 
 * // copy all to stdout
 * Stdout.copy(buffer);
 * Stdout.newline;
 * ---
 * 
 *******************************************************************************/
class CircularBuffer : Device
{
    /*
     * private variables
     */
    private byte[] buffer;
    private byte* begin;
    private byte* end;
    
    /**
     * create a new circular buffer
     * 
     * params:
     *  size = the size of the internally allocated memory default is 1024 bytes
     */
    this(size_t size = 1024)
    {
        // allocate internal buffer
        this.buffer = new byte[size + 1];
        
        // initialize begin and end of valid data
        this.begin = this.buffer.ptr;
        this.end = this.buffer.ptr;
    }
    
    /**
     * returns the number of by bytes available to read.
     */
    public size_t bytesAvailable()
    out(result)
    {
        assert(result < this.buffer.length, "there is to much data available");
    }
    body
    {
        // the data around it is filled with data
        if(this.begin > this.end)
            return this.buffer.length - (this.begin - this.end);
        
        // the data between it is considered to be valud
        else if(this.end > this.begin)
            return this.end - this.begin;
        
        // buffer is empty, nothing to read
        return 0;
    }
     
    /**
     * returns the number of data available in the buffer.
     */
    public size_t spaceAvailable()
    out(result)
    {
        assert(result < this.buffer.length, "available returned a too big value");
    }
    body
    {
        // writer is ahead of reader CASE 4
        if(this.end > this.begin)
            return this.buffer.length - (this.end - this.begin) - 1;
            
        // reader is ahead of writer CASE 3
        if(this.end < this.begin)
            return (this.begin - this.end) - 1;
        
        // buffer is empty CASE 1
        return this.buffer.length - 1;
    }
    
    /**
     * writes the data to the internal buffer. if src.length is larger than the
     * amout of free space in the buffer, only a part of it is actuall written.
     * the buffer will not attempt to overwrite itself. the number of written data
     * is returned.
     * 
     * params:
     *  src = the data you're goging to write.
     * 
     * returns:
     *  the number of written bytes or Eof.
     */
    override size_t write (const(void)[] src)
    {
        // some pointer initialisation
        auto source = cast(byte*)src.ptr;
        auto bytes = src.length;
        auto target = this.end;
        auto next = this.end + 1;
        
        // while there're bytes to write
        while(bytes)
        {
            // next is outside of buffer, set it to begin
            if((this.buffer.ptr + this.buffer.length) < next)
                next = this.buffer.ptr;
            
            // check if buffer is full
            if(next == this.begin)
                break;
            
            // copy one byte
            *target = *source;
            target = next;
            source++;
            next++;
            bytes--;
        }
        
        // calc written bytes
        size_t written = src.length - bytes;
        if(!written)
            return this.Eof;
        
        // save pointer of last write call
        this.end = target;
        
        // return written bytes
        return written;
    }
    
    /**
     * read data from the internal buffer and returns the total amount
     * of data that could be read or Eof if nothing was red.
     * 
     * params:
     *  dst = a preallocated buffer which will be filled with data
     * 
     * returns:
     *  total num of bytes or Eof.
     */
    override size_t read (void[] dst)
    {
        // some pointer initialisation
        auto source = this.begin;
        auto bytes = dst.length;
        auto target = cast(byte*)dst.ptr;
        
        // while there're available bytes
        while(bytes)
        {
            // check if buffer is full
            if(source == this.end)
                break;
            
            // copy one byte
            *target = *source;
            target++;
            source++;
            bytes--;
            
            // next is outside of buffer, set it to begin
            if((this.buffer.ptr + this.buffer.length) < source)
                source = this.buffer.ptr;
        }
        
        // calc red bytes
        size_t red = dst.length - bytes;
        if(!red)
            return this.Eof;
        
        // save pointer of last read call
        this.begin = source;
        
        // return red bytes
        return red;
    }
    
    /**
     * checks if the buffer is still valid
     */
    debug invariant()
    {
        // calculate pointers to begin and end of buffer
        auto buffer_begin = this.buffer.ptr;
        auto buffer_end = this.buffer.ptr + this.buffer.length;
        
        // reader and writer must point to valid memory inside buffer
        assert(buffer_begin <= this.begin && this.begin <= buffer_end, "this.begin does not point to valid data.");
        assert(buffer_begin <= this.end && this.end <= buffer_end, "this.begin does not point to valid data.");
    }
}

// unittest
unittest
{
    // instantiate a small buffer
    auto buffer = new CircularBuffer(15);
    
    // test 1
    buffer.write("1");
    assert("1" == buffer.text(1));

    // test 3, 7, 15
    buffer.write("3");
    buffer.write("7");
    buffer.write("15");
    assert("3715" == buffer.text(4));
    assert(buffer.bytesAvailable() + buffer.spaceAvailable() == 15);

    // test 31, 63, 127, 255
    buffer.write("31");
    buffer.write("63");
    buffer.write("127");
    buffer.write("255");
    assert("3" == buffer.text(1));
    assert("16312" == buffer.text(5));
    assert("7255" == buffer.text(4));
    assert(buffer.bytesAvailable() + buffer.spaceAvailable() == 15);
    
    // test 2047
    buffer.write("2047");
    assert("2047" == buffer.text(4));

    // test 32767
    buffer.write("32767");
    assert("32767" == buffer.text(5));

    // test 65535
    buffer.write("65535");
    assert("65535" == buffer.text(5));
    assert(buffer.bytesAvailable() + buffer.spaceAvailable() == 15);
}

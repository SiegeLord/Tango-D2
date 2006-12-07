/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004      
                        Outback release: December 2006
        
        author:         Kris

*******************************************************************************/

module tango.io.protocol.Reader;

private import  tango.io.Buffer;

private import  tango.text.convert.Type;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

public  import  tango.io.protocol.model.IReader;

/*******************************************************************************

        Reader base-class. Each reader operates upon an IBuffer, which is
        provided at construction time. Readers are simple converters
        of data, and have reasonably rigid rules regarding data format. For
        example, each request for data expects the content to be available;
        nd exception is thrown where this is not the case. If the data is
        arranged in a more relaxed fashion, consider using IBuffer directly
        instead.

        All readers support the full set of native data types, plus a full
        selection of array types. The latter can be configured to produce
        either a copy (.dup) of the buffer content, or a slice. See class
        NullAllocator, SimpleAllocator, BufferAllocator and SliceAllocator
        for more on this topic. Note that a NullAllocator disables memory
        management for arrays, and the application is expected to take on
        that role.

        Readers support Java-esque get() notation. However, the Tango
        style is to place IO elements within their own parenthesis, like
        so:
        
        ---
        int count;
        char[] verse;
        
        read (verse) (count);
        ---

        Note that each element read is distict; this style is affectionately
        known as "whisper". The code below illustrates basic operation upon a
        memory buffer:
        
        ---
        auto buf = new Buffer (256);

        // map same buffer into both reader and writer
        auto read = new Reader (buf);
        auto write = new Writer (buf);

        int i = 10;
        long j = 20;
        double d = 3.14159;
        char[] c = "fred";

        // write data using whisper syntax
        write (c) (i) (j) (d);

        // read them back again
        read (c) (i) (j) (d);

        
        // same thing again, but using put() syntax instead
        write.put(c).put(i).put(j).put(d);
        read.get(c).get(i).get(j).get(d);
        ---

        Note that certain Readers, such as the basic binary implementation, 
        expect to retrieve the number of array elements from the source. For
        example: when reading an array from a file, the number of elements 
        is read from the file also, and the configurable memory-manager is
        invoked to provide the array space. If content is not arranged in
        such a manner you may read array content directly either through the
        use of NullAllocator (to disable memory management) or by accessing
        buffer content directly via the methods exposed there e.g.

        ---
        void[10] data;
                
        getBuffer.get (data);
        ---

        Readers may also be used with any class implementing the IReadable
        interface. See PickleReader for an example of how this can be used
        
*******************************************************************************/

class Reader : IReader, IReader.Allocator
{       
        // the buffer associated with this reader. Note that this
        // should not change over the lifetime of the reader, since
        // it is assumed to be immutable elsewhere 
        protected IBuffer       buffer;         

        // memory-manager for array requests
        private Allocator       memory;

        /***********************************************************************
        
                Construct a Reader upon the provided buffer

        ***********************************************************************/

        this (IBuffer buffer)
        {
                this.buffer = buffer;

                setAllocator (this);
        }

        /***********************************************************************
                
                Construct a Reader upon the buffer associated with the
                given conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (new Buffer (conduit));
        }

        /***********************************************************************
        
                Return the buffer associated with this reader

        ***********************************************************************/

        final IBuffer getBuffer ()
        {
                return buffer;
        }
        
        /***********************************************************************
        
                Get the allocator to use for array management. Arrays are
                generally allocated by the IReader, via configured manager.
                A number of Allocator classes are available to manage memory
                when reading array content, including a NullAllocator which
                hands responsibility over to the application instead. 

                Gaining access to the allocator can expose some additional
                controls. For example, some allocators benefit from a reset
                operation after each data 'record' has been processed.

        ***********************************************************************/

        final Allocator getAllocator ()
        {
                return memory;
        }

        /***********************************************************************
        
                Set the allocator to use for array management. Arrays are
                generally allocated by the IReader, so you generally cannot
                read into an array slice (for example). Instead, a number
                of Allocators are available to manage memory allocation
                when reading array content. 

                By default, an IReader will allocate each array from the 
                heap. You can change that behavior by calling this method
                with an Allocator of choice. For instance, there 
                is a BufferAllocator which will slice an array directly 
                from the buffer where possible. Also available is the 
                record-oriented SliceAllocator, which slices memory from 
                within a pre-allocated heap area, and should be reset by
                the client code after each record has been read (to avoid 
                unnecessary growth). There is also a NullAlocator, which
                disables internal memory management and turns responsiblity
                over to the application instead. In the latter case, array
                slices provided by the application are populated.

                See module ArrayAllocator for more information

        ***********************************************************************/

        final void setAllocator (Allocator memory) 
        {
                this.memory = memory;
                memory.bind (this);
        }

        /***********************************************************************
        
                Extract a readable class from the current read-position
                
        ***********************************************************************/

        final IReader get (IReadable x) 
        {
                if (x is null)
                    buffer.error ("Reader.get :: attempt to read a null IReadable object");
                
                x.read (this); 
                return this;
        }

        /***********************************************************************

                Extract a boolean value from the current read-position  
                
        ***********************************************************************/

        final IReader get (inout bool x)
        {
                return read (&x, x.sizeof, Type.Bool);
        }

        /***********************************************************************

                Extract an unsigned byte value from the current read-position   
                                
        ***********************************************************************/

        final IReader get (inout ubyte x) 
        {       
                return read (&x, x.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Extract a byte value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout byte x)
        {
                return read (&x, x.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Extract an unsigned short value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout ushort x)
        {
                return read (&x, x.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Extract a short value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout short x)
        {
                return read (&x, x.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Extract a unsigned int value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout uint x)
        {
                return read (&x, x.sizeof, Type.UInt);
        }

        /***********************************************************************
        
                Extract an int value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout int x)
        {
                return read (&x, x.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Extract an unsigned long value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout ulong x)
        {
                return read (&x, x.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Extract a long value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout long x)
        {
                return read (&x, x.sizeof, Type.Long);
        }

        /***********************************************************************
        
                Extract a float value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout float x)
        {
                return read (&x, x.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Extract a double value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout double x)
        {
                return read (&x, x.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Extract a real value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout real x)
        {
                return read (&x, x.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Extract a char value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout char x)
        {
                return read (&x, x.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Extract a wide char value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout wchar x)
        {
                return read (&x, x.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Extract a double char value from the current read-position
                
        ***********************************************************************/

        final IReader get (inout dchar x)
        {
                return read (&x, x.sizeof, Type.Utf32);
        }

        /***********************************************************************

                Extract an boolean array from the current read-position   
                                
        ***********************************************************************/

        final IReader get (inout bool[] x) 
        {
                return readArray (cast(void[]*) &x, bool.sizeof, Type.Bool);
        }

        /***********************************************************************

                Extract an unsigned byte array from the current read-position   
                                
        ***********************************************************************/

        final IReader get (inout ubyte[] x) 
        {
                return readArray (cast(void[]*) &x, ubyte.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Extract a byte array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout byte[] x)
        {
                return readArray (cast(void[]*) &x, byte.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Extract an unsigned short array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout ushort[] x)
        {
                return readArray (cast(void[]*) &x, ushort.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Extract a short array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout short[] x)
        {
                return readArray (cast(void[]*) &x, short.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Extract a unsigned int array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout uint[] x)
        {
                return readArray (cast(void[]*) &x, uint.sizeof, Type.UInt);
        } 

        /***********************************************************************
        
                Extract an int array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout int[] x)
        {
                return readArray (cast(void[]*) &x, int.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Extract an unsigned long array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout ulong[] x)
        {
                return readArray (cast(void[]*) &x, ulong.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Extract a long array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout long[] x)
        {
                return readArray (cast(void[]*) &x,long.sizeof, Type.Long);
        }

        /***********************************************************************
        
                Extract a float array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout float[] x)
        {
                return readArray (cast(void[]*) &x, float.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Extract a double array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout double[] x)
        {
                return readArray (cast(void[]*) &x, double.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Extract a real array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout real[] x)
        {
                return readArray (cast(void[]*) &x, real.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Extract a char array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout char[] x)
        {
                return readArray (cast(void[]*) &x, char.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Extract a wchar array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout wchar[] x)
        {
                return readArray (cast(void[]*) &x, wchar.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Extract a dchar array from the current read-position
                
        ***********************************************************************/

        final IReader get (inout dchar[] x)
        {
                return readArray (cast(void[]*) &x, dchar.sizeof, Type.Utf32);
        }

        /***********************************************************************

                Read an array from the current buffer position. We typically
                expect a leading integer, indicating how many elements follow.
                This policy can be overridden by configuring the reader with a
                NullAllocator, which requires the application to manage array
                memory instead. See module ArrayAllocator for more info

        ***********************************************************************/

        protected IReader readArray (void[]* x, uint width, uint type)
        {
                uint bytes;

                if (memory.isManaged)
                   {
                   uint count;
                   get (count);
                   bytes = count * width;
                   *x = memory.allocate (bytes) [0 .. count]; 
                   }
                else
                   bytes = x.length * width;
                
                return read (x.ptr, bytes, type);
        }

        /***********************************************************************

                Transfer a stream of bytes into a destination. Note that
                the Reader/Writer protocol expects all requested data to be
                available, and an exception is thrown where this is not the
                case. Use Buffer directly where this is not applicable, or
                a combination of Reader & Buffer access (they stay in synch)

                All Reader requests are funneled through here -- so override
                this method to mutate content as it is read from the buffer.
                For an example, see EndianReader
        
        ***********************************************************************/

        protected IReader read (void *dst, uint bytes, uint type)
        {
                while (bytes)
                      {
                      // get as much as there is available in the buffer
                      auto available = buffer.readable();
                      
                      // cap bytes read
                      if (available > bytes)
                          available = bytes;

                      // copy them over
                      dst[0..available] = buffer.get (available);

                      // bump counters
                      dst += available;
                      bytes -= available;

                      // if we need more, prime the input by reading
                      if (bytes && (buffer.fill is IConduit.Eof))
                          buffer.error ("Reader.read :: unexpected end of input");
                      }
                return this;
        }


        
        /************************ Allocator methods ***************************/


        /***********************************************************************

                Is memory managed by this allocator? If so, an integer will
                be read from the input representing the array length, and
                the allocator will be used to provide array space. If not,
                the array length is assumed to be provided by the target
                array itself (application managed); both the integer and
                allocator are ignored

        ***********************************************************************/

        bool isManaged ()
        {
                return true;
        }

        /***********************************************************************
        
                default Allocator method: do nothing
                                        
        ***********************************************************************/

        protected final void reset ()
        {
        }

        /***********************************************************************
        
                default Allocator method: do nothing
                                        
        ***********************************************************************/

        protected final void bind (IReader reader)
        {
        }

        /***********************************************************************
        
                default Allocator method: use heap memory
                                        
        ***********************************************************************/

        protected final void[] allocate (uint bytes)
        {       
                return new void [bytes];
        }
}


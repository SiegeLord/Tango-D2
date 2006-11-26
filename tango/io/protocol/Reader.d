/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.protocol.Reader;

public  import  tango.io.Buffer;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

public  import  tango.io.protocol.model.IReader;


private import  tango.text.convert.Type;

private import  tango.io.Exception;

/*******************************************************************************

        Reader base-class. Each reader operates upon an IBuffer, which is
        provided at construction time. Said buffer is intended to remain 
        consistent over the reader lifetime.

        All readers support the full set of native data types, plus a full
        selection of array types. The latter can be configured to produce
        either a copy (.dup) of the buffer content, or a slice. See class
        SimpleAllocator, BufferAllocator and SliceAllocator for more on 
        this topic.

        Readers support a C++ iostream type syntax, along with Java-esque 
        get() notation. However, the Tango style is to place IO elements 
        within their own parenthesis, like so:
        
                int count;
                char[] verse;

                read (verse) (count);

        Note that each element is distict; this enables "strong typing", 
        which should catch any typo errors at compile-time. The style is
        affectionately called "whisper".

        The code below illustrates basic operation upon a memory buffer:
        
        ---
        Buffer buf = new Buffer (256);

        // map same buffer into both reader and writer
        IReader read = new Reader (buf);
        IWriter write = new Writer (buf);

        int i = 10;
        long j = 20;
        double d = 3.14159;
        char[] c = "fred";

        // write data types out
        write (c) (i) (j) (d);

        // read them back again
        read (c) (i) (j) (d);

        // reset
        buf.clear();

        // same thing again, but using iostream syntax instead
        write << c << i << j << d;

        // read them back again
        read >> c >> i >> j >> d;

        // reset
        buf.clear();

        // same thing again, but using put() syntax instead
        write.put(c).put(i).put(j).put(d);
        read.get(c).get(i).get(j).get(d);

        ---

        Note that certain Readers, such as the basic binary implementation, 
        expect to retrieve the number of array elements from the source. 
        For example; when reading an array from a file, the number of elements 
        is read from the file also. If the content is not arranged in such a 
        manner, you may specify how many elements to read via a second argument:

        ---
                read (myArray, 11);
        ---

        Readers may also be used with any class implementing the IReadable
        interface. See PickleReader for an example of how this can be put
        to good use.

        Lastly, each Reader may be configured with a text decoder. These
        decoders convert between an internal text representation, and the
        char/wchar/dchar representaion. BufferCodec.d contains classes for
        handling utf8, utf16, and utf32. The icu.UTango module has support
        for a wide variety of converters.
        
*******************************************************************************/

class Reader : IReader, IArrayAllocator 
{       
        // the buffer associated with this reader. Note that this
        // should not change over the lifetime of the reader, since
        // it is assumed to be immutable elsewhere 
        protected IBuffer               buffer;         

        // memory-manager for array requests
        private IArrayAllocator         memory;

        // string decoder
        protected AbstractDecoder       decoder;
        private IBuffer.Converter       textDecoder;

        // current decoder type (reset via setDecoder)
        private   int                   decoderType = Type.Raw;


        /***********************************************************************
        
                Construct a Reader upon the provided buffer

        ***********************************************************************/

        this (IBuffer buffer)
        {
                this.buffer = buffer;
                textDecoder = &read;

                setAllocator (this);

                version (IOTextText)
                        {
                        Buffer.Style s = buffer.getStyle;
                        if (s != Buffer.Mixed)
                            if ((s == Buffer.Text) ^ isTextBased())
                                 buffer.error ("text/binary mismatch between Reader and Buffer");
                        }
        }

        /***********************************************************************
                
                Construct a Reader upon the buffer associated with the
                given conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (new Buffer(conduit));
        }

        /***********************************************************************
        
                Return the buffer associated with this reader

        ***********************************************************************/

        final IBuffer getBuffer ()
        {
                return buffer;
        }
        
        /***********************************************************************
        
                Is this Reader text oriented?

        ***********************************************************************/

        bool isTextBased()
        {
                return false;
        }

        /***********************************************************************
        
                Return the allocator associated with this reader. See 
                ArrayAllocator for more information.

        ***********************************************************************/

        final IArrayAllocator getAllocator ()
        {
                return memory;
        }

        /***********************************************************************
        
                Set the allocator to use for array management. Arrays are
                always allocated by the IReader. That is, you cannot read
                data into an array slice (for example). Instead, a number
                of IArrayAllocator classes are available to manage memory
                allocation when reading array content. 

                By default, an IReader will allocate each array from the 
                heap. You can change that behavior by calling this method
                with an IArrayAllocator of choice. For instance, there 
                is a BufferAllocator which will slice an array directly 
                from the buffer where possible. Also available is the 
                record-oriented SliceAllocator, which slices memory from 
                within a pre-allocated heap area, and should be reset by
                the client code after each record has been read (to avoid 
                unnecessary growth).

                See ArrayAllocator for more information.

        ***********************************************************************/

        final void setAllocator (IArrayAllocator memory) 
        {
                memory.bind (this);
                this.memory = memory;
        }

        /***********************************************************************
        
                Bind an IDecoder to the writer. Decoders are intended to
                be used as a conversion mechanism between various character
                representations (encodings).

        ***********************************************************************/

        final void setDecoder (AbstractDecoder d) 
        {
                d.bind (buffer);
                textDecoder = &d.decoder;
                decoderType = d.type;
                decoder = d;
        }

        /***********************************************************************
        
                Return the current decoder type (Type.Raw if not set)

        ***********************************************************************/

        final int getDecoderType ()
        {
                return decoderType;
        }

        /***********************************************************************
        
                Wait for something to arrive in the buffer. This may stall
                the current thread forever, although usage of SocketConduit 
                will take advantage of the timeout facilities provided there.

        ***********************************************************************/

        final void wait ()
        {       
                buffer.get (1, false);
        }

        /***********************************************************************
        
                Extract a readable class from the current read-position
                
        ***********************************************************************/

        final IReader get (IReadable x) 
        {
                assert (x);
                x.read (this); 
                return this;
        }

        /***********************************************************************

                Extract a boolean value from the current read-position  
                
        ***********************************************************************/

        IReader get (inout bool x)
        {
                read (&x, x.sizeof, Type.Bool);
                return this;
        }

        /***********************************************************************

                Extract an unsigned byte value from the current read-position   
                                
        ***********************************************************************/

        IReader get (inout ubyte x) 
        {       
                read (&x, x.sizeof, Type.UByte);
                return this;
        }

        /***********************************************************************
        
                Extract a byte value from the current read-position
                
        ***********************************************************************/

        IReader get (inout byte x)
        {
                read (&x, x.sizeof, Type.Byte);
                return this;
        }

        /***********************************************************************
        
                Extract an unsigned short value from the current read-position
                
        ***********************************************************************/

        IReader get (inout ushort x)
        {
                read (&x, x.sizeof, Type.UShort);
                return this;
        }

        /***********************************************************************
        
                Extract a short value from the current read-position
                
        ***********************************************************************/

        IReader get (inout short x)
        {
                read (&x, x.sizeof, Type.Short);
                return this;
        }

        /***********************************************************************
        
                Extract a unsigned int value from the current read-position
                
        ***********************************************************************/

        IReader get (inout uint x)
        {
                read (&x, x.sizeof, Type.UInt);
                return this;
        }

        /***********************************************************************
        
                Extract an int value from the current read-position
                
        ***********************************************************************/

        IReader get (inout int x)
        {
                read (&x, x.sizeof, Type.Int);
                return this;
        }

        /***********************************************************************
        
                Extract an unsigned long value from the current read-position
                
        ***********************************************************************/

        IReader get (inout ulong x)
        {
                read (&x, x.sizeof, Type.ULong);
                return this;
        }

        /***********************************************************************
        
                Extract a long value from the current read-position
                
        ***********************************************************************/

        IReader get (inout long x)
        {
                read (&x, x.sizeof, Type.Long);
                return this;
        }

        /***********************************************************************
        
                Extract a float value from the current read-position
                
        ***********************************************************************/

        IReader get (inout float x)
        {
                read (&x, x.sizeof, Type.Float);
                return this;
        }

        /***********************************************************************
        
                Extract a double value from the current read-position
                
        ***********************************************************************/

        IReader get (inout double x)
        {
                read (&x, x.sizeof, Type.Double);
                return this;
        }

        /***********************************************************************
        
                Extract a real value from the current read-position
                
        ***********************************************************************/

        IReader get (inout real x)
        {
                read (&x, x.sizeof, Type.Real);
                return this;
        }

        /***********************************************************************
        
                Extract a char value from the current read-position
                
        ***********************************************************************/

        IReader get (inout char x)
        {
                textDecoder (&x, x.sizeof, Type.Utf8);
                return this;
        }

        /***********************************************************************
        
                Extract a wide char value from the current read-position
                
        ***********************************************************************/

        IReader get (inout wchar x)
        {
                textDecoder (&x, x.sizeof, Type.Utf16);
                return this;
        }

        /***********************************************************************
        
                Extract a double char value from the current read-position
                
        ***********************************************************************/

        IReader get (inout dchar x)
        {
                textDecoder (&x, x.sizeof, Type.Utf32);
                return this;
        }

        /***********************************************************************

                Extract an unsigned byte array from the current read-position   
                                
        ***********************************************************************/

        IReader get (inout ubyte[] x, uint elements = uint.max) 
        {
                memory.allocate (cast(void[]*) &x, count(elements)*ubyte.sizeof, 
                                 ubyte.sizeof, Type.UByte, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a byte array from the current read-position
                
        ***********************************************************************/

        IReader get (inout byte[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*byte.sizeof, 
                                 byte.sizeof, Type.Byte, &read);
                return this;
        }

        /***********************************************************************
        
                Extract an unsigned short array from the current read-position
                
        ***********************************************************************/

        IReader get (inout ushort[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*ushort.sizeof, 
                                 ushort.sizeof, Type.UShort, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a short array from the current read-position
                
        ***********************************************************************/

        IReader get (inout short[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*short.sizeof, 
                                 short.sizeof, Type.Short, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a unsigned int array from the current read-position
                
        ***********************************************************************/

        IReader get (inout uint[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*uint.sizeof, 
                                 uint.sizeof, Type.UInt, &read);
                return this;
        }

        /***********************************************************************
        
                Extract an int array from the current read-position
                
        ***********************************************************************/

        IReader get (inout int[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*int.sizeof, 
                                 int.sizeof, Type.Int, &read);
                return this;
        }

        /***********************************************************************
        
                Extract an unsigned long array from the current read-position
                
        ***********************************************************************/

        IReader get (inout ulong[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*ulong.sizeof, 
                                 ulong.sizeof, Type.ULong, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a long array from the current read-position
                
        ***********************************************************************/

        IReader get (inout long[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*long.sizeof, 
                                 long.sizeof, Type.Long, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a float array from the current read-position
                
        ***********************************************************************/

        IReader get (inout float[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*float.sizeof, 
                                 float.sizeof, Type.Float, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a double array from the current read-position
                
        ***********************************************************************/

        IReader get (inout double[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*double.sizeof, 
                                 double.sizeof, Type.Double, &read);
                return this;
        }

        /***********************************************************************
        
                Extract a real array from the current read-position
                
        ***********************************************************************/

        IReader get (inout real[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*real.sizeof, 
                                 real.sizeof, Type.Real, &read);
                return this;
        }

        /***********************************************************************
        
        ***********************************************************************/

        IReader get (inout char[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*char.sizeof, 
                                 char.sizeof, Type.Utf8, textDecoder);
                return this;
        }

        /***********************************************************************
        
        ***********************************************************************/

        IReader get (inout wchar[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*wchar.sizeof, 
                                 wchar.sizeof, Type.Utf16, textDecoder);
                return this;
        }

        /***********************************************************************
        
        ***********************************************************************/

        IReader get (inout dchar[] x, uint elements = uint.max)
        {
                memory.allocate (cast(void[]*) &x, count(elements)*dchar.sizeof, 
                                 dchar.sizeof, Type.Utf32, textDecoder);
                return this;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected uint read (void *dst, uint bytes, uint type)
        {
                uint i = bytes;
                while (i)
                      {
                      // get as much as there is available in the buffer
                      uint available = buffer.readable();
                      
                      // cap bytes read
                      if (available > i)
                          available = i;

                      // copy them over
                      dst[0..available] = buffer.get (available);

                      // bump counters
                      dst += available;
                      i -= available;

                      // if we need more, prime the input by reading
                      if (i)
                          if (buffer.fill () == IConduit.Eof)
                              buffer.error ("end of input");
                      }
                return bytes;
        }

        /***********************************************************************
        
                Read and return an integer from the input stream. This is
                used to extract the element count of a subsequent array.

        ***********************************************************************/

        private uint count (uint elements)
        {
                if (elements == uint.max)
                    get (elements);
                return elements;
        }


        /******************** IArrayAllocator methods *************************/


        /***********************************************************************
        
                IArrayAllocator method
                                        
        ***********************************************************************/

        protected final void reset ()
        {
        }

        /***********************************************************************
        
                IArrayAllocator method
                                        
        ***********************************************************************/

        protected final void bind (IReader reader)
        {
        }

        /***********************************************************************
        
                IArrayAllocator method
                                        
        ***********************************************************************/

        protected final bool isMutable (void* x)
        {
                return true;
        }
        
        /***********************************************************************
        
                IArrayAllocator method
                                        
        ***********************************************************************/

        protected final void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {       
                void[] tmp = new void [bytes];
                *x = tmp [0 .. decoder (tmp, bytes, type) / width];
        }
}

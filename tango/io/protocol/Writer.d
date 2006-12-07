/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004
                        Outback release: December 2006
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.Writer;

private import  tango.io.Buffer,
                tango.io.FileConst;

private import  tango.text.convert.Type;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

public  import  tango.io.protocol.model.IWriter;

/*******************************************************************************

        Writer base-class. Writers provide the means to append formatted 
        data to an IBuffer, and expose a convenient method of handling a
        variety of data types. In addition to writing native types such
        as integer and char[], writers also process any class which has
        implemented the IWritable interface (one method).

        All writers support the full set of native data types, plus their
        fundamental array variants. Operations may be chained back-to-back.

        Writers support a Java-esque put() notation. However, the Tango style
        is to place IO elements within their own parenthesis, like so:

        ---
        write (count) (" green bottles");
        ---

        Note that each written element is distict; this style is affectionately
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

        // write data types out
        write (c) (i) (j) (d);

        // read them back again
        read (c) (i) (j) (d);


        // same thing again, but using put() syntax instead
        write.put(c).put(i).put(j).put(d);
        read.get(c).get(i).get(j).get(d);

        ---

        Writers may also be used with any class implementing the IWritable
        interface. See PickleReader for an example of how this can be used.

        Note that 'newlines' are emitted via the standard "\n" approach. 
        However, one might consider using the newline() method instead:
        doing so allows subclasses to intercept newlines more efficiently
        
*******************************************************************************/

class Writer : IWriter
{     
        // the buffer associated with this writer. Note that this
        // should not change over the lifetime of the reader, since
        // it is assumed to be immutable elsewhere 
        protected IBuffer buffer;

        /***********************************************************************
        
                Construct a Writer upon the provided IBuffer. All formatted
                output will be directed to this buffer.

        ***********************************************************************/

        this (IBuffer buffer)
        {
                this.buffer = buffer;
        }
     
        /***********************************************************************
        
                Construct a Writer on the buffer associated with the given
                conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (new Buffer (conduit));
        }

        /***********************************************************************
        
                Return the associated buffer

        ***********************************************************************/

        final IBuffer getBuffer ()
        {     
                return buffer;
        }

        /***********************************************************************
        
                Flush the output of this writer. Returns false if the 
                operation failed, true otherwise.

        ***********************************************************************/

        final IWriter flush ()
        {  
                buffer.flush;
                return this;
        }

        /***********************************************************************
        
                Output a newline. Do this indirectly so that it can be 
                intercepted by subclasses.

        ***********************************************************************/

        IWriter newline ()
        {
                return put (cast(char[]) FileConst.NewlineString);
        }

        /***********************************************************************
        
                Flush this writer. This is a convenience method used by
                the "whisper" syntax.
                
        ***********************************************************************/

        final IWriter put () 
        {
                return flush;
        }

        /***********************************************************************
        
                Write a class to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (IWritable x) 
        {
                if (x is null)
                    buffer.error ("Writer.put :: attempt to write a null IWritable object");
                
                x.write (this); 
                return this;
        }

        /***********************************************************************
        
                Write a boolean value to the current buffer-position    
                
        ***********************************************************************/

        final IWriter put (bool x)
        {
                return write (&x, x.sizeof, Type.Bool);
        }

        /***********************************************************************
        
                Write an unsigned byte value to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (ubyte x)
        {
                return write (&x, x.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Write a byte value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (byte x)
        {
                return write (&x, x.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Write an unsigned short value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ushort x)
        {
                return write (&x, x.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Write a short value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (short x)
        {
                return write (&x, x.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Write a unsigned int value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (uint x)
        {
                return write (&x, x.sizeof, Type.UInt);
        }

        /***********************************************************************
        
                Write an int value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (int x)
        {
                return write (&x, x.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Write an unsigned long value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ulong x)
        {
                return write (&x, x.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Write a long value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (long x)
        {
                return write (&x, x.sizeof, Type.Long);
        }

        /***********************************************************************
        
                Write a float value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (float x)
        {
                return write (&x, x.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Write a double value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (double x)
        {
                return write (&x, x.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Write a real value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (real x)
        {
                return write (&x, x.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Write a char value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (char x)
        {
                return write (&x, x.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Write a wchar value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (wchar x)
        {
                return write (&x, x.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Write a dchar value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (dchar x)
        {
                return write (&x, x.sizeof, Type.Utf32);
        }

        /***********************************************************************
        
                Write a boolean array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (bool[] x)
        {
                return writeArray (x, x.length, x.length * bool.sizeof, Type.Bool);
        }

        /***********************************************************************
        
                Write a byte array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (byte[] x)
        {
                return writeArray (x, x.length, x.length * byte.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Write an unsigned byte array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (ubyte[] x)
        {
                return writeArray (x, x.length, x.length * ubyte.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Write a short array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (short[] x)
        {
                return writeArray (x, x.length, x.length * short.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Write an unsigned short array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ushort[] x)
        {
                return writeArray (x, x.length, x.length * ushort.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Write an int array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (int[] x)
        {
                return writeArray (x, x.length, x.length * int.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Write an unsigned int array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (uint[] x)
        {
                return writeArray (x, x.length, x.length * uint.sizeof, Type.UInt);
        }

        /***********************************************************************
        
                Write a long array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (long[] x)
        {
                return writeArray (x, x.length, x.length * long.sizeof, Type.Long);
        }

        /***********************************************************************
         
                Write an unsigned long array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ulong[] x)
        {
                return writeArray (x, x.length, x.length * ulong.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Write a float array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (float[] x)
        {
                return writeArray (x, x.length, x.length * float.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Write a double array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (double[] x)
        {
                return writeArray (x, x.length, x.length * double.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Write a real array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (real[] x)
        {
                return writeArray (x, x.length, x.length * real.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Write a char array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (char[] x) 
        {
                return writeArray (x, x.length, x.length * char.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Write a wchar array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (wchar[] x) 
        {
                return writeArray (x, x.length, x.length * wchar.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Write a dchar array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (dchar[] x)
        {
                return writeArray (x, x.length, x.length * dchar.sizeof, Type.Utf32);
        }

        /***********************************************************************
        
                Dump array content into the buffer. Note that the default
                behaviour is to prefix with the element count 

        ***********************************************************************/

        protected IWriter writeArray (void* src, uint elements, uint bytes, uint type)
        {
                put (elements);
                return write (src, bytes, type);
        }

        /***********************************************************************
        
                Dump content into the buffer

        ***********************************************************************/

        protected IWriter write (void* src, uint bytes, uint type)
        {
                buffer.append (src [0 .. bytes]);
                return this;
        }
}

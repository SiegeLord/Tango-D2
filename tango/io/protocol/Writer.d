/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004    
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.Writer;

private import  tango.convert.Type;

private import  tango.io.Exception;

private import  tango.io.Buffer;

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

        Writers support a C++ iostream type syntax, along with Java-esque 
        put() notation. However, the Mango style is to place IO elements 
        within their own parenthesis, like so:
        
                write (count) (" green bottles");

        Note that each element is distict; this enables "strong typing", 
        which should catch any typo errors at compile-time. The style is
        affectionately called "whisper".

        The code below illustrates basic operation upon a memory buffer:
        
        ---
        Buffer buf = new Buffer (256);

        // map same buffer into both reader and writer
        IReader read = new Reader(buf);
        IWriter write = new Writer(buf);

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

        Writers may also be used with any class implementing the IWritable
        interface. See PickleReader for an example of how this can be put
        to good use.

        Note that 'newlines' are emitted via the standard "\n" approach. 
        However, one might consider using the public CR element instead.

        Writers also support formatted output via the DisplayWriter module,
        which has full support for printf() syntax:

        ---
        Stdout.println ("%d green bottles", 10);
        ---
        
        Lastly, each Writer may be configured with a text encoder. These
        encoders convert between an internal text representation, and the
        char/wchar/dchar representaion. BufferCodec.d contains classes for
        handling utf8, utf16, and utf32. The icu.UMango module has support
        for a wide variety of converters. Stdout is pre-configured with
        utf16 & utf8 encoders for Win32 and Posix respectively.
        
*******************************************************************************/

class Writer : IWriter
{     
        alias newline                   cr;    

        // the buffer associated with this writer. Note that this
        // should not change over the lifetime of the reader, since
        // it is assumed to be immutable elsewhere 
        protected IBuffer               buffer;

        // should arrays be prefixed with a length?
        private   bool                  prefixArray;

        // String encoder
        private   IBuffer.Converter     textEncoder;

        // current encoder type (reset via setEncoder)
        private   int                   encoderType = Type.Raw;


        /***********************************************************************
        
                Construct a Writer upon the provided IBuffer. All formatted
                output will be directed to this buffer.

        ***********************************************************************/

        this (IBuffer buffer)
        {
                this.buffer = buffer;

                Buffer.Style s = buffer.getStyle;
                if (s != Buffer.Mixed)
                    if ((s == Buffer.Text) ^ isTextBased())
                         error ("text/binary mismatch between Writer and Buffer");
                prefixArray = cast(bool) !isTextBased;
        }
     
        /***********************************************************************
        
                Construct a Writer on the buffer associated with the given
                conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (new Buffer(conduit));
        }

        /***********************************************************************
        
        ***********************************************************************/

        final void error (char[] msg)
        {
                buffer.error (msg);
        }

        /***********************************************************************
        
                Return the associated buffer

        ***********************************************************************/

        final IBuffer getBuffer ()
        {     
                return buffer;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final IConduit conduit ()
        {
                return buffer.getConduit();
        }

        /***********************************************************************
        
                Bind an IEncoder to the writer. Encoders are intended to
                be used as a conversion mechanism between various character
                representations (encodings). Each writer may be configured 
                with a distinct encoder.

        ***********************************************************************/

        final void setEncoder (AbstractEncoder e) 
        {
                e.bind (buffer);
                encoderType = e.type;
                textEncoder = &e.encoder;
        }

        /***********************************************************************
        
                Return the current encoder type (Type.Raw if not set)

        ***********************************************************************/

        final int getEncoderType ()
        {
                return encoderType;
        }

        /***********************************************************************
        
                Is this Writer text oriented?

        ***********************************************************************/

        bool isTextBased()
        {
                return false;
        }

        /***********************************************************************
        
                Flush the output of this writer. Returns false if the 
                operation failed, true otherwise.

        ***********************************************************************/

        IWriter flush ()
        {  
                buffer.flush ();
                return this;
        }

        /***********************************************************************
        
                Output a newline. Do this indirectly so that it can be 
                intercepted by subclasses.

        ***********************************************************************/

        IWriter newline ()
        {
                return put (CR);
        }

        /***********************************************************************
        
                Flush this writer. This is a convenience method used by
                the "whisper" syntax.
                
        ***********************************************************************/

        IWriter put () 
        {
                return flush ();
        }

        /***********************************************************************
        
                Write a class to the current buffer-position
                
        ***********************************************************************/

        IWriter put (IWritable x) 
        {
                assert (x);
                x.write (this); 
                return this;
        }

        /***********************************************************************
        
                Write a boolean value to the current buffer-position    
                
        ***********************************************************************/

        IWriter put (bool x)
        {
                return write (&x, x.sizeof, Type.Bool);
        }

        /***********************************************************************
        
                Write an unsigned byte value to the current buffer-position     
                                
        ***********************************************************************/

        IWriter put (ubyte x)
        {
                return write (&x, x.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Write a byte value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (byte x)
        {
                return write (&x, x.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Write an unsigned short value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (ushort x)
        {
                return write (&x, x.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Write a short value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (short x)
        {
                return write (&x, x.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Write a unsigned int value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (uint x)
        {
                return write (&x, x.sizeof, Type.UInt);
        }

        /***********************************************************************
        
                Write an int value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (int x)
        {
                return write (&x, x.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Write an unsigned long value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (ulong x)
        {
                return write (&x, x.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Write a long value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (long x)
        {
                return write (&x, x.sizeof, Type.Long);
        }

        /***********************************************************************
        
                Write a float value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (float x)
        {
                return write (&x, x.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Write a double value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (double x)
        {
                return write (&x, x.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Write a real value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (real x)
        {
                return write (&x, x.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Write a char value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (char x)
        {
                return encode (&x, char.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Write a wchar value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (wchar x)
        {
                return encode (&x, wchar.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Write a dchar value to the current buffer-position
                
        ***********************************************************************/

        IWriter put (dchar x)
        {
                return encode (&x, dchar.sizeof, Type.Utf32);
        }

        /***********************************************************************
        
                Write a byte array to the current buffer-position     
                                
        ***********************************************************************/

        IWriter put (byte[] x)
        {
                return write (x, length (x.length) * byte.sizeof, Type.Byte);
        }

        /***********************************************************************
        
                Write an unsigned byte array to the current buffer-position     
                                
        ***********************************************************************/

        IWriter put (ubyte[] x)
        {
                return write (x, length (x.length) * ubyte.sizeof, Type.UByte);
        }

        /***********************************************************************
        
                Write a short array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (short[] x)
        {
                return write (x, length (x.length) * short.sizeof, Type.Short);
        }

        /***********************************************************************
        
                Write an unsigned short array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (ushort[] x)
        {
                return write (x, length (x.length) * ushort.sizeof, Type.UShort);
        }

        /***********************************************************************
        
                Write an int array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (int[] x)
        {
                return write (x, length (x.length) * int.sizeof, Type.Int);
        }

        /***********************************************************************
        
                Write an unsigned int array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (uint[] x)
        {
                return write (x, length (x.length) * uint.sizeof, Type.UInt);
        }

        /***********************************************************************
        
                Write a long array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (long[] x)
        {
                return write (x, length (x.length) * long.sizeof, Type.Long);
        }

        /***********************************************************************
        
                Write an unsigned long array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (ulong[] x)
        {
                return write (x, length (x.length) * ulong.sizeof, Type.ULong);
        }

        /***********************************************************************
        
                Write a float array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (float[] x)
        {
                return write (x, length (x.length) * float.sizeof, Type.Float);
        }

        /***********************************************************************
        
                Write a double array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (double[] x)
        {
                return write (x, length (x.length) * double.sizeof, Type.Double);
        }

        /***********************************************************************
        
                Write a real array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (real[] x)
        {
                return write (x, length (x.length) * real.sizeof, Type.Real);
        }

        /***********************************************************************
        
                Write a char array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (char[] x) 
        {
                return encode (x.ptr, length(x.length) * char.sizeof, Type.Utf8);
        }

        /***********************************************************************
        
                Write a wchar array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (wchar[] x) 
        {
                return encode (x.ptr, length(x.length) * wchar.sizeof, Type.Utf16);
        }

        /***********************************************************************
        
                Write a dchar array to the current buffer-position
                
        ***********************************************************************/

        IWriter put (dchar[] x)
        {
                return encode (x.ptr, length(x.length) * dchar.sizeof, Type.Utf32);
        }

        /***********************************************************************
        
                Dump content into the buffer. This is intercepted by a 
                variety of subclasses 

        ***********************************************************************/

        protected IWriter write (void* src, uint bytes, int type)
        {
                buffer.append (src [0 .. bytes]);
                return this;
        }

        /***********************************************************************
        
                Handle text output. This is intended to be intercepted
                by subclasses, though they should always pump content
                through here to take advantage of configured encoding

        ***********************************************************************/

        protected IWriter encode (void* src, uint bytes, int type)
        {
                if (textEncoder)
                    textEncoder (src, bytes, type);
                else
                   buffer.append (src [0 .. bytes]);
                return this;
        }

        /***********************************************************************
        
                Emit the length of an array: used for raw binary output
                of arrays. Array lengths are written into the buffer as
                a guide for when reading it back again
                
        ***********************************************************************/

        private final uint length (uint len)
        {
                if (prefixArray)
                    put (len);
                return len;
        }
}


/*******************************************************************************

        A class to handle newline output. One might reasonably expect to 
        emit a char[] for newlines; FileConst.NewlineString for example.
        Turns out that it's much more efficient to intercept line-breaks
        when they're implemented in a more formal manner (such as this).

        For example, ColumnWriter() and TextWriter() both must intercept 
        newline output so they can adjust formatting appropriately. It is 
        much more efficient for such writers to intercept the IWritable 
        put() method instead of scanning each char[] for the various \\n 
        combinations.
        
        Please use the INewlineWriter interface for emitting newlines.

*******************************************************************************/

private import tango.io.FileConst;

class NewlineWriter : INewlineWriter
{
        private char[]  fmt;

        /***********************************************************************

                Construct a default newline, using the char[] defined 
                by FileConst.NewlineString
        
        ***********************************************************************/

        this ()
        {
                version (Posix)
                         this (cast(char[]) FileConst.NewlineString);
                else
                   this (cast(char[]) FileConst.NewlineString);                   
        }

        /***********************************************************************
        
                Construct a newline using the provided character array

        ***********************************************************************/

        this (char[] fmt)
        {
                this.fmt = fmt;
        }

        /***********************************************************************
        
                Write this newline through the provided writer. This makes
                NewlineWriter IWritable compatible.

        ***********************************************************************/

        void write (IWriter w)
        {
                w.put (fmt);
        }     
}


/*******************************************************************************

        public newline adaptor

*******************************************************************************/

public static NewlineWriter CR;

static this ()
{
        CR = new NewlineWriter;
}


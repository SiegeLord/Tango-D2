/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

        These classes represent a simple means of reading and writing
        discrete data types as binary values, with an option to invert
        the endian order of numeric values.

        Arrays are treated as untyped byte streams, with an optional
        length-prefix, and should otherwise be explicitly managed at
        the application level. We'll add additional support for arrays
        and aggregates in future.

*******************************************************************************/

module tango.io.stream.DataStream;

private import tango.io.Buffer;

private import tango.core.ByteSwap;

private import tango.io.device.Conduit;

/*******************************************************************************

        A simple way to read binary data from an arbitrary InputStream,
        such as a file:
        ---
        auto input = new DataInput (new FileInput("path"));
        auto x = input.getInt;
        auto y = input.getDouble;
        auto l = input.read (buffer);           // read raw data directly
        auto s = cast(char[]) input.get;        // read length, allocate space
        input.close;
        ---

*******************************************************************************/

class DataInput : InputFilter, Buffered
{
        public alias array      get;            /// old name alias
        public alias boolean   getBool;         /// ditto
        public alias int8      getByte;         /// ditto
        public alias int16     getShort;        /// ditto
        public alias int32     getInt;          /// ditto
        public alias int64     getLong;         /// ditto
        public alias float32   getFloat;        /// ditto
        public alias float64   getDouble;       /// ditto

        public enum                             /// endian variations
        {
                Native  = 0,
                Network = 1,
                Big     = 1,
                Little  = 2
        }

        private bool            flip;
        private IBuffer         input;
        private Allocate        allocator;

        private alias void[] delegate (uint) Allocate;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, uint buffer=uint.max)
        {
                super (input = Buffer.share (stream, buffer));
                allocator = (uint bytes){return new void[bytes];};
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Set the array allocator

        ***********************************************************************/

        final DataInput allocate (Allocate allocate)
        {
                allocator = allocate;
                return this;
        }

        /***********************************************************************

                Extended ctor with explicit endian translation

        ***********************************************************************/

        final DataInput endian (int e)
        {
                version (BigEndian)
                         flip = e is Little;
                   else
                      flip = e is Network;
                return this;
        }

        /***********************************************************************

                Override this to give back a useful chaining reference

        ***********************************************************************/

        final override DataInput clear ()
        {
                host.clear;
                return this;
        }

        /***********************************************************************

                Read an array back into a user-provided workspace. The
                space must be sufficiently large enough to house all of
                the array, and the actual number of bytes is returned.

                Note that the size of the array is written as an integer
                prefixing the array content itself.  Use read(void[]) to 
                eschew this prefix.

        ***********************************************************************/
        
        final override uint array (void[] dst)
        {
                auto len = int32;
                if (len > dst.length)
                    conduit.error ("DataInput.readArray :: dst array is too small");
                input.readExact (dst.ptr, len);
                return len;
        }

        /***********************************************************************

                Read an array back from the source, with the assumption
                it has been written using DataOutput.put() or otherwise
                prefixed with an integer representing the total number
                of bytes within the array content. That's *bytes*, not
                elements.

                An array of the appropriate size is allocated either via
                the provided delegate, or from the heap, populated and
                returned to the caller. Casting the return value to an
                appropriate type will adjust the number of elements as
                required:
                ---
                auto text = cast(char[]) input.get;
                ---
                

        ***********************************************************************/

        final void[] array ()
        {
                auto len = int32;
                auto dst = allocator (len);
                input.readExact (dst.ptr, len);
                return dst;
        }

        /***********************************************************************

        ***********************************************************************/

        final bool boolean ()
        {
                bool x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final byte int8 ()
        {
                byte x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final short int16 ()
        {
                short x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final int int32 ()
        {
                int x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap32(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final long int64 ()
        {
                long x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap64(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final float float32 ()
        {
                float x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap32(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final double float64 ()
        {
                double x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap64(&x, x.sizeof);
                return x;
        }

}


/*******************************************************************************

        A simple way to write binary data to an arbitrary OutputStream,
        such as a file:
        ---
        auto output = new DataOutput (new FileOutput("path"));
        output.int32   (1024);
        output.float64 (3.14159);
        output.array   ("string with length prefix");
        output.write   ("raw array, no prefix");
        output.close;
        ---

*******************************************************************************/

class DataOutput : OutputFilter, Buffered
{       
        public alias array      put;            /// old name alias
        public alias boolean    putBool;        /// ditto
        public alias int8       putByte;        /// ditto
        public alias int16      putShort;       /// ditto
        public alias int32      putInt;         /// ditto
        public alias int64      putLong;        /// ditto
        public alias float32    putFloat;       /// ditto
        public alias float64    putFloat;       /// ditto

        public enum                             /// endian variations
        {
                Native  = 0,
                Network = 1,
                Big     = 1,
                Little  = 2
        }

        private bool    flip;
        private IBuffer output;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, uint buffer=uint.max)
        {
                super (output = Buffer.share (stream, buffer));
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Extended ctor with explicit endian translation

        ***********************************************************************/

        final DataOutput endian (int e)
        {
                version (BigEndian)
                         flip = e is Little;
                   else
                      flip = e is Network;
                return this;
        }

        /***********************************************************************

                Write an array to the target stream. Note that the size 
                of the array is written as an integer prefixing the array 
                content itself. Use write(void[]) to eschew this prefix.

        ***********************************************************************/

        final uint array (void[] src)
        {
                auto len = src.length;
                putInt (len);
                output.append (src.ptr, len);
                return len;
        }

        /***********************************************************************

        ***********************************************************************/

        final void boolean (bool x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void int8 (byte x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void int16 (short x)
        {
                if (flip)
                    ByteSwap.swap16 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void int32 (int x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, uint.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void int64 (long x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void float32 (float x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void float64 (double x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;

        unittest
        {
                auto buf = new Buffer(32);

                auto output = new DataOutput (buf);
                output.array ("blah blah");
                output.int32 (1024);

                auto input = new DataInput (buf);
                assert (input.array(new char[9]) is 9);
                assert (input.int32 is 1024);
        }
}


/*******************************************************************************

*******************************************************************************/

debug (DataStream)
{
        import tango.io.Buffer;
        import tango.io.Stdout;

        void main()
        {
                auto buf = new Buffer(64);

                auto output = new DataOutput (buf);
                output.array ("blah blah");
                output.int32 (1024);

                auto input = new DataInput (buf);
                assert (input.array.length is 9);
                assert (input.int32 is 1024);
        }
}

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

module tango.io.stream.Meta;

private import tango.io.Buffer;

private import tango.core.Traits,
               tango.core.ByteSwap;

private import tango.io.device.Conduit;

/*******************************************************************************

        A simple way to read binary data from an arbitrary InputStream,
        such as a file:
        ---
        auto input = new MetaInput (new FileInput("path"));
        int x;
        double y;
        char[] s;
        input.read (x, y, s);
        auto l = input.read (buffer);           // read raw data directly
        input.close;
        ---

*******************************************************************************/

class MetaInput : InputFilter, Buffered
{
        public enum
        {
                Native,
                Network,
                Little
        }

        private bool            flip;
        private IBuffer         input;
        private Allocate        allocator;

        private alias void[] delegate (size_t) Allocate;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, size_t buffer=size_t.max)
        {
                super (input = Buffer.share (stream, buffer));
                allocator = (size_t bytes){return new void[bytes];};
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Set the endian style

        ***********************************************************************/

        final MetaInput endian (int e)
        {
                version (BigEndian)
                         flip = e is Little;
                   else
                      flip = e is Network;
                return this;
        }

        /***********************************************************************

                Set the array allocator

        ***********************************************************************/

        final MetaInput allocate (Allocate allocate)
        {
                allocator = allocate;
                return this;
        }

        /***********************************************************************

                Override this to give back a useful chaining reference

        ***********************************************************************/

        final override MetaInput clear ()
        {
                source.clear;
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

        final override size_t get (void[] dst)
        {
                typeof([].length) len;
                convert (len);
                if (len > dst.length)
                    conduit.error ("MetaInput.readArray :: dst array is too small");
                input.readExact (dst.ptr, len);
                return len;
        }

        /***********************************************************************

                Read an array back from the source, with the assumption
                it has been written using MetaOutput.put() or otherwise
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

        final void[] get ()
        {
                typeof([].length) len;
                convert (len);
                auto dst = allocator (len);
                input.readExact (dst.ptr, len);
                return dst;
        }

        /***********************************************************************

        ***********************************************************************/

        final void convert(T) (ref T x)
        {
                input.readExact (&x, T.sizeof);
                if (flip)
                   {
                   static if (T.sizeof == 2)
                              ByteSwap.swap16 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 4)
                              ByteSwap.swap32 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 8)
                              ByteSwap.swap64 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 10)
                              ByteSwap.swap80 (&x, T.sizeof);
                   else
                   static if (T.sizeof != 1)
                              pragma (msg, "unexpected byteswap type: "~T.stringof);
                   }
        }

        /***********************************************************************

        ***********************************************************************/

        template read(T, R...)
        {
                void read(ref T t, ref R r)
                {
                        static if (isCharType!(T)       ||
                                  isIntegerType!(T)     ||
                                  isRealType!(T))
                                  convert (t);
                        else
                        static if (isStaticArrayType!(T))
                                   get (t);
                        else
                        static if (isDynamicArrayType!(T))
                                   t = cast(T) get();
                        else
                           pragma (msg, "unexpected meta type: "~T.stringof);
                        
                        static if (r.length)    // if more arguments
                                   read(r);     // do the rest of the arguments
            }
        }
}


/*******************************************************************************

        A simple way to write binary data to an arbitrary OutputStream,
        such as a file:
        ---
        auto output = new MetaOutput (new FileOutput("path"));
        output.write (1024, 3.14159, "string with length prefix");
        output.write ("raw array, no prefix");
        output.flush.close;
        ---

*******************************************************************************/

class MetaOutput : OutputFilter, Buffered
{       
        public enum
        {
                Native,
                Network,
                Little
        }

        private bool    flip;
        private IBuffer output;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, size_t buffer=size_t.max)
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

                Set the endian style

        ***********************************************************************/

        final MetaOutput endian (int e)
        {
                version (BigEndian)
                         flip = e is Little;
                   else
                      flip = e is Network;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final void convert(T) (T x)
        {
                if (flip)
                   {
                   static if (T.sizeof == 2)
                              ByteSwap.swap16 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 4)
                              ByteSwap.swap32 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 8)
                              ByteSwap.swap64 (&x, T.sizeof);
                   else
                   static if (T.sizeof == 10)
                              ByteSwap.swap80 (&x, T.sizeof);
                   else
                   static if  (T.sizeof != 1)
                               pragma (msg, "unexpected byteswap type: "~T.stringof);
                   }
                output.append (&x, T.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        template write(T, R...)
        {
                void write(T t, R r)
                {
                        static if (isCharType!(T)       ||
                                   isIntegerType!(T)    ||
                                   isRealType!(T))
                                   convert(t);
                        else
                        static if (isStaticArrayType!(T) ||
                                   isDynamicArrayType!(T))
                                  {
                                  convert(t.length);
                                  output.append (t);
                                  }
                        else
                           pragma (msg, "unexpected meta type: "~T.stringof);

                        static if (r.length)    // if more arguments
                                   write(r);    // do the rest of the arguments
                }
        }
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;

        unittest
        {
        }
}


/*******************************************************************************

*******************************************************************************/

debug (MetaStream)
{
        import tango.io.Buffer;
        import tango.io.Stdout;

        void main()
        {
                struct Foo
                {
                  int a;
                  float b;
                  real r;

                  void read (MetaInput i)
                  {
                          i.read (a, b, r);
                  }

                  void write (MetaOutput o)
                  {
                          o.write (a, b, r);
                  }
                }
                Foo foo;

                auto buf = new Buffer(256);
                auto output = new MetaOutput (buf);
                output.write ("foob foob", 1024,'c', "foo"d, 3.14, 'z');

                Stdout (cast(char[])buf.slice).newline;

                auto input = new MetaInput (buf);
                char[] c;
                int x = 10;
                input.read (c, x);
                assert (c.length is 9);
                assert (x is 1024);
        }
}

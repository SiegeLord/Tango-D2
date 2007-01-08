/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.PrintProtocol;

private import  tango.io.Buffer;

private import  tango.text.convert.Format;

private import  tango.io.protocol.model.IProtocol;

/*******************************************************************************

*******************************************************************************/

class PrintProtocol : IProtocol
{
        protected IBuffer buffer_;

        // 
        private static TypeInfo[] revert = 
        [
                typeid(void), // byte.sizeof,
                typeid(bool), // bool.sizeof,
                typeid(byte), // byte.sizeof,
                typeid(ubyte), // ubyte.sizeof,
                typeid(short), // short.sizeof,
                typeid(ushort), // ushort.sizeof,
                typeid(int), // int.sizeof,
                typeid(uint), // uint.sizeof,
                typeid(long), // long.sizeof,
                typeid(ulong), // ulong.sizeof,
                typeid(float), // float.sizeof,
                typeid(double), // double.sizeof,
                typeid(real), // real.sizeof,
                typeid(char), // char.sizeof,
                typeid(wchar), // wchar.sizeof,
                typeid(dchar), // dchar.sizeof,
                typeid(void*), // (void*).sizeof,
                typeid(Object), // (Object*).sizeof,
        ];

        /***********************************************************************

        ***********************************************************************/

        this (IBuffer buffer)
        {
                this.buffer_ = buffer;
        }

        /***********************************************************************

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (new Buffer (conduit));
        }

        /***********************************************************************

        ***********************************************************************/

        IBuffer buffer ()
        {
                return buffer_;
        }

        /***********************************************************************

        ***********************************************************************/

        void[] read (void* dst, uint bytes, Type type)
        {
                throw new Exception ("PrintProtocol is write only");
                return null;
        }
        
        /***********************************************************************

        ***********************************************************************/

        void[] readArray (void* dst, uint bytes, Type type, Allocator alloc)
        {
                return read (dst, bytes, type);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void write (void* src, uint bytes, Type type)
        {
                switch (type)
                       {
                       case Type.Utf8:
                       case Type.Utf16:
                       case Type.Utf32:
                            buffer_.append (src, bytes);
                            break;

                       default:
                            char[256] output = void;
                            char[256] convert = void;
                            auto result = Formatter.Result (output, convert);
                            auto ti = revert [type];
                            auto s = Formatter (result, ti, src);
                            buffer_.append (s.ptr, s.length);
                            break;
                       }
        }
        
        /***********************************************************************

        ***********************************************************************/

        void writeArray (void* src, uint bytes, Type type)
        {
                switch (type)
                       {
                       case Type.Utf8:
                       case Type.Utf16:
                       case Type.Utf32:
                            buffer_.append (src, bytes);
                            break;

                       default:
                            char[256] output = void;
                            char[256] convert = void;
                            auto ti = revert [type];
                            auto result = Formatter.Result (output, convert);

                            auto width = ti.tsize();
                            assert ((bytes % width) is 0, "invalid arg[] length");

                            buffer_.append ("[");
                            while (bytes)
                                  {
                                  auto s = Formatter (result, ti, src);
                                  buffer_.append (s.ptr, s.length);
                                  bytes -= width;
                                  src += width;
                                  if (bytes > 0)
                                      buffer_.append (", ");
                                  }
                            buffer_.append ("]");
                            break;
                       }
        }
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        class Writer
        {
                IBuffer   buffer;
                IProtocol protocol;

                this (IConduit conduit)
                {
                        this (new Buffer (conduit));
                }

                this (IBuffer buffer)
                {
                        this (new PrintProtocol (buffer));
                }

                this (IProtocol protocol)
                {
                        this.protocol = protocol;
                        this.buffer   = protocol.buffer;
                }

                void write (int x)
                {
                        protocol.write (&x, x.sizeof, protocol.Type.Int);
                }


                void write (char[] x)
                {
                        protocol.writeArray (x.ptr, x.length, protocol.Type.Utf8);
                }
        }


        class Reader
        {
                IBuffer                 buffer;
                IProtocol               protocol;
                IProtocol.Allocator     allocator;


                this (IConduit conduit)
                {
                        this (new Buffer (conduit));
                }

                this (IBuffer buffer)
                {
                        this (new PrintProtocol (buffer));
                }

                this (IAllocator allocator)
                {
                        this (allocator.protocol);
                        this.allocator = &allocator.allocate;
                }

                this (IProtocol protocol)
                {
                        allocator = &allocate;
                        this.protocol = protocol;
                        this.buffer   = protocol.buffer;
                }

                void read (inout int x)
                {
                        protocol.read (&x, x.sizeof, protocol.Type.Int);
                }

                void read (inout char[] x)
                {
                        *cast(void[]*) &x = protocol.readArray (x.ptr, x.length, protocol.Type.Utf8, allocator);
                }

                private void[] allocate (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
                {
                        return reader ((new void[bytes]).ptr, bytes, type);
                }
        }


        class BufferSlice : IAllocator
        {
                private IProtocol protocol_;

                this (IProtocol protocol)
                {
                        protocol_ = protocol;
                }

                void reset ()
                {
                }

                IProtocol protocol ()
                {
                        return protocol_;
                }

                void[] allocate (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
                {
                        return protocol_.buffer.get (bytes);
                }
        }


        void main() {}
        import tango.io.Console;
        
        unittest
        {
                auto protocol = new PrintProtocol (Cout);
                auto input  = new Reader (protocol);
                auto output = new Writer (protocol);

                char[] foo;
                output.write ("testing testing ");
                output.write (123);
                Cout.flush;
        }
}

   
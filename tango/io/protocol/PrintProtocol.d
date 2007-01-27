/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.PrintProtocol;

private import  tango.io.Buffer;

private import  tango.text.convert.Format;

private import  tango.io.protocol.model.IProtocol;

private import  tango.core.Vararg;

/*******************************************************************************

*******************************************************************************/

class PrintProtocol : IProtocol
{
        protected IBuffer buffer_;

        // 
        private static TypeInfo[] revert = 
        [
                typeid(void), // byte.sizeof,
                typeid(char), // char.sizeof,
                typeid(bool), // bool.sizeof,
                typeid(byte), // byte.sizeof,
                typeid(ubyte), // ubyte.sizeof,
                typeid(wchar), // wchar.sizeof,
                typeid(short), // short.sizeof,
                typeid(ushort), // ushort.sizeof,
                typeid(dchar), // dchar.sizeof,
                typeid(int), // int.sizeof,
                typeid(uint), // uint.sizeof,
                typeid(float), // float.sizeof,
                typeid(long), // long.sizeof,
                typeid(ulong), // ulong.sizeof,
                typeid(double), // double.sizeof,
                typeid(real), // real.sizeof,
                typeid(Object), // (Object*).sizeof,
                typeid(void*), // (void*).sizeof,
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
                            auto s = Formatter (result, ti, cast(va_list) src);
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
                                  auto s = Formatter (result, ti, cast(va_list) src);
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
        unittest
        {
        }
}

   

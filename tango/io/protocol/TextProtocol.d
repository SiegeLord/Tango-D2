/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.TextProtocol;

private import  tango.io.Buffer;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.io.protocol.model.IProtocol;

/*******************************************************************************

*******************************************************************************/

class TextProtocol : IProtocol
{
        protected IBuffer buffer_;

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
                this (new Buffer(conduit));
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
                return buffer_.extract (dst, bytes);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void write (void* src, uint bytes, Type type)
        {
                T[]     s;
                T[128]  tmp = void;
                
                switch (type)
                       {
                       case Type.Short:
                       case Type.UShort:
                       case Type.Utf16:
                            write (~1, &ByteSwap.swap16);   
                            break;

                       case Type.Int:
                       case Type.UInt:
                       case Type.Float:
                       case Type.Utf32:
                            write (~3, &ByteSwap.swap32);   
                            break;

                       case Type.Long:
                       case Type.ULong:
                       case Type.Double:
                            write (~7, &ByteSwap.swap64);   
                            break;

                       case Type.Real:
                            write (~15, &ByteSwap.swap80);   
                            break;

                       default:
                            super.write (src, bytes, type);
                            break;
                       }
                
                buffer_.append (src, bytes);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void[] readArray (void* dst, uint bytes, Type type, Allocator alloc)
        {
                return read (dst, bytes, type);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void writeArray (void* src, uint bytes, Type type)
        {
                write (src, bytes, type);
        }
}



/*******************************************************************************

*******************************************************************************/

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
                this (new TextProtocol (buffer));
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


/*******************************************************************************

*******************************************************************************/

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
                this (new TextProtocol (buffer));
        }

        this (Allocator allocator)
        {
                this (allocator.getProtocol);
                this.allocator = &allocator.alloc;
        }

        this (IProtocol protocol)
        {
                allocator = &alloc;
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

        private void[] alloc (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
        {
                return reader ((new void[bytes]).ptr, bytes, type);
        }
}

/*******************************************************************************

*******************************************************************************/

class Allocator
{
        private IProtocol protocol;

        this (IProtocol protocol)
        {
                this.protocol = protocol;
        }

        IProtocol getProtocol ()
        {
                return protocol;
        }

        void[] alloc (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
        {
                return protocol.buffer.get (bytes);
        }
}


/*******************************************************************************

        char:           1ca
        char array:     3cabc

        int array:      3i[2i10 7i1234567 3i-17]
        int array:      3i[2i10 7i1234567 3i-17]

        bool:           1u1
        
        byte:           3i127
        ubyte:          3u127

        short:          3i123
        short:          2i-1
        ushort:         5u12345
        
        int:            3i123
        int:            2i-1
        uint:           5u12345
        
        long:           3i123
        ulong:          2i-1
        uint:           5u12345
        
        float:          12f12345.33e-10
        double:         12f12345.33e-10
        real:           12f12345.33e-10


        types
        -----
        integer
        unsigned
        float
        char
        array
        
*******************************************************************************/

debug (UnitTest)
{
        void main() {}
        
        unittest
        {
                auto protocol = new TextProtocol (new Buffer(32));
                auto input  = new Reader (protocol);
                auto output = new Writer (protocol);

                char[] foo;
                output.write ("testing testing 123");
                input.read (foo);
                assert (foo == "testing testing 123");
        }
}



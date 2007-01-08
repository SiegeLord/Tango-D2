/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.NativeProtocol;

private import  tango.io.Buffer;

private import  tango.io.protocol.model.IProtocol;

/*******************************************************************************

*******************************************************************************/

class NativeProtocol : IProtocol
{
        protected bool          prefix_;
        protected IBuffer       buffer_;

        /***********************************************************************

        ***********************************************************************/

        this (IBuffer buffer, bool prefix=true)
        {
                this.prefix_ = prefix;
                this.buffer_ = buffer;
        }

        /***********************************************************************

        ***********************************************************************/

        this (IConduit conduit, bool prefix=true)
        {
                this (new Buffer(conduit), prefix);
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
                buffer_.append (src, bytes);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void[] readArray (void* dst, uint bytes, Type type, Allocator alloc)
        {
                if (prefix_)
                   {
                   read (&bytes, bytes.sizeof, Type.UInt);
                   return alloc (&read, bytes, type); 
                   }

                return read (dst, bytes, type);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void writeArray (void* src, uint bytes, Type type)
        {
                if (prefix_)
                    write (&bytes, bytes.sizeof, Type.UInt);

                write (src, bytes, type);
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
                        this (new NativeProtocol (buffer));
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
                        this (new NativeProtocol (buffer));
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
        
        unittest
        {
                auto protocol = new NativeProtocol (new Buffer(32));
                auto input  = new Reader (protocol);
                auto output = new Writer (protocol);

                char[] foo;
                output.write ("testing testing 123");
                input.read (foo);
                assert (foo == "testing testing 123");
        }
}

   
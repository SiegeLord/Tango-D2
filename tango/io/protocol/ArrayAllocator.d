/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004

        author:         Kris

*******************************************************************************/

module tango.io.protocol.ArrayAllocator;

private import  tango.io.protocol.Reader;

private import  tango.io.model.IBuffer,
                tango.io.protocol.model.IReader;

/*******************************************************************************

*******************************************************************************/

class SimpleAllocator : IArrayAllocator
{
        private IReader reader;

        /***********************************************************************

        ***********************************************************************/

        override void reset ()
        {
        }

        /***********************************************************************

        ***********************************************************************/

        override void bind (IReader reader)
        {
                this.reader = reader;
        }

        /***********************************************************************

        ***********************************************************************/

        override bool isMutable (void* x)
        {
                return true;
        }

        /***********************************************************************

        ***********************************************************************/

        override void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {
                void[] tmp = new void [bytes];
                *x = tmp [0 .. decoder (tmp, bytes, type) / width];
        }
}


/*******************************************************************************

*******************************************************************************/

class NativeAllocator : SimpleAllocator
{
        private bool aliased;

        /***********************************************************************

        ***********************************************************************/

        this (bool aliased = true)
        {
                this.aliased = aliased;
        }

        /***********************************************************************

        ***********************************************************************/

        override bool isMutable (void* x)
        {
                return cast(bool) !aliased;
        }

        /***********************************************************************

        ***********************************************************************/

        override void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {
                void[] tmp = *x;
                tmp.length = bytes;
                *x = tmp [0 .. decoder (tmp, bytes, type) / width];
        }
}


/*******************************************************************************

*******************************************************************************/

class BufferAllocator : SimpleAllocator
{
        private IBuffer.Converter raw;
        private uint              width;

        /***********************************************************************

        ***********************************************************************/

        this (int width = 0)
        {
                this.width = width;
        }

        /***********************************************************************

        ***********************************************************************/

        override void reset ()
        {
                IBuffer buffer = reader.getBuffer;

                // ensure there's enough room for another record
                if (buffer.writable < width)
                    buffer.compress ();
        }

        /***********************************************************************

        ***********************************************************************/

        override void bind (IReader reader)
        {
                raw = &(cast(Reader) reader).read;
                super.bind (reader);
        }

        /***********************************************************************

        ***********************************************************************/

        override bool isMutable (void* x)
        {
                void[] content = reader.getBuffer.getContent;
                return cast(bool) (x < content || x >= (content.ptr + content.length));
        }

        /***********************************************************************

        ***********************************************************************/

        override void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {
                if (decoder == raw)
                    *x = reader.getBuffer.get (bytes) [0..length / width];
                else
                   super.allocate (x, bytes, width, type, decoder);
        }
}


/*******************************************************************************

*******************************************************************************/

class SliceAllocator : HeapSlice, IArrayAllocator
{
        private IReader reader;

        /***********************************************************************

        ***********************************************************************/

        this (int width)
        {
                super (width);
        }

        /***********************************************************************

        ***********************************************************************/

        override void bind (IReader reader)
        {
                this.reader = reader;
        }

        /***********************************************************************

                Reset content length to zero

        ***********************************************************************/

        override void reset ()
        {
                super.reset();
        }

        /***********************************************************************

        ***********************************************************************/

        override bool isMutable (void* x)
        {
                return false;
        }

        /***********************************************************************

        ***********************************************************************/

        override void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {
                expand (bytes);
                auto tmp = slice (bytes);
                *x = tmp [0 .. decoder (tmp, bytes, type) / width];
        }
}


/*******************************************************************************

*******************************************************************************/

class ReuseAllocator : SliceAllocator
{
        private uint bytes;

        /***********************************************************************

        ***********************************************************************/

        this (int width)
        {
                super (width);
        }

        /***********************************************************************

        ***********************************************************************/

        override void allocate (void[]* x, uint bytes, uint width, uint type, IBuffer.Converter decoder)
        {
                super.reset ();
                super.allocate (x, bytes, width, type, decoder);
        }

}


/*******************************************************************************

*******************************************************************************/

private class HeapSlice
{
        private uint    used;
        private void[]  buffer;

        /***********************************************************************

                Create with the specified starting size

        ***********************************************************************/

        this (uint size)
        {
                buffer = new void[size];
        }

        /***********************************************************************

                Reset content length to zero

        ***********************************************************************/

        void reset ()
        {
                used = 0;
        }

        /***********************************************************************

                Potentially expand the content space, and return a pointer
                to the start of the empty section.

        ***********************************************************************/

        void* expand (uint size)
        {
                if ((used + size) > buffer.length)
                     buffer.length = (used + size) * 2;
                return &buffer [used];
        }

        /***********************************************************************

                Return a slice of the content from the current position
                with the specified size. Adjusts the current position to
                point at an empty zone.

        ***********************************************************************/

        void[] slice (int size)
        {
                uint i = used;
                used += size;
                return buffer [i..used];
        }
}
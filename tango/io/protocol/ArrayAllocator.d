/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004      
                        Outback release: December 2006
        
        author:         Kris

        Allocators to use in conjunction with the Reader class. These are
        intended to manage array allocation for a variety of Reader.get()
        methods. 

*******************************************************************************/

module tango.io.protocol.ArrayAllocator;

private import  tango.io.protocol.model.IReader;


/*******************************************************************************

        Simple allocator, using the heap for each array
        
*******************************************************************************/

class SimpleAllocator : IReader.Allocator
{
        /***********************************************************************
        
        ***********************************************************************/

        void reset ()
        {
        }

        /***********************************************************************
        
        ***********************************************************************/

        void bind (IReader reader)
        {
        }

        /***********************************************************************
        
        ***********************************************************************/

        void[] allocate (uint bytes)
        {
                return new void [bytes];
        }
}


/*******************************************************************************

        Alias directly from the buffer instead of allocating from the heap.
        This avoids heap activity, but requires some care in terms of usage.
        See methods allocate() for details
        
*******************************************************************************/

class BufferAllocator : SimpleAllocator
{
        private IReader reader;

        /***********************************************************************
        
        ***********************************************************************/

        void reset ()
        {
                reader.getBuffer.compress;
        }

        /***********************************************************************
        
        ***********************************************************************/

        void bind (IReader reader)
        {
                this.reader = reader;
        }

        /***********************************************************************

                No allocation: alias directly from the buffer. Note that this
                should be used only in scenarios where content is known to fit
                within a buffer, and there is no conversion of said content
                (e.g. take care when using with EndianReader since it will
                convert within the buffer, potentially confusing additional
                buffer clients)
                
        ***********************************************************************/

        void[] allocate (uint bytes)
        {
                return reader.getBuffer.get (bytes);
        }
}


/*******************************************************************************

        Allocate from within a private heap space. This supports reading
        data as 'records', reusing the same chunk of memory for each record
        loaded. The ctor takes an argument defining the initial allocation
        made, and this will be increased as necessary to accomodate larger
        records. Use the reset() method to indicate end of record (reuse
        memory for subsequent requests), or set the autoReset flag to reuse
        upon each array request.
        
*******************************************************************************/

class SliceAllocator : HeapSlice, IReader.Allocator
{
        private IReader reader;
        private bool    autoReset;

        /***********************************************************************
        
        ***********************************************************************/

        this (int width, bool autoReset = true)
        {
                super (width);
                this.autoReset = autoReset;
        }

        /***********************************************************************
        
        ***********************************************************************/

        void bind (IReader reader)
        {
                this.reader = reader;
        }

        /***********************************************************************
        
                Reset content length to zero

        ***********************************************************************/

        void reset ()
        {
                super.reset;
        }

        /***********************************************************************
        
        ***********************************************************************/

        void[] allocate (uint bytes)
        {
                if (autoReset)
                    super.reset;
                
                expand (bytes);
                return slice (bytes);
        }
}


/*******************************************************************************

        Internal helper to maintain a simple heap

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




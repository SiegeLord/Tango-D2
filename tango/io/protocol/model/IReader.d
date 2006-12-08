/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004     
                        Outback release: December 2006
         
        author:         Kris
                        Ivan Senji (the "alias get" idea)

*******************************************************************************/

module tango.io.protocol.model.IReader;

public import tango.io.model.IBuffer;

/*******************************************************************************

        IReader interface. Each reader operates upon an IBuffer, which is
        provided at construction time. Readers are simple converters of data,
        and have reasonably rigid rules regarding data format. For example,
        each request for data expects the content to be available; an exception
        is thrown where this is not the case. If the data is arranged in a more
        relaxed fashion, consider using IBuffer directly instead.

        All readers support the full set of native data types, plus a full
        selection of array types. The latter can be configured to produce
        either a copy (.dup) of the buffer content, or a slice. See class
        SimpleAllocator, BufferAllocator and SliceAllocator for more on
        this topic. Note that setting a null Allocator disables memory
        management for arrays, and the application is expected to take on
        that role.

        Readers support Java-esque get() notation. However, the Tango
        style is to place IO elements within their own parenthesis, like
        so:
        
        ---
        int count;
        char[] verse;
        
        read (verse) (count);
        ---

        Note that each element read is distict; this style is affectionately
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

        // write data using whisper syntax
        write (c) (i) (j) (d);

        // read them back again
        read (c) (i) (j) (d);


        // same thing again, but using put() syntax instead
        write.put(c).put(i).put(j).put(d);
        read.get(c).get(i).get(j).get(d);
        ---

        Note that certain Readers, such as the basic binary implementation, 
        expect to retrieve the number of array elements from the source. For
        example: when reading an array from a file, the number of elements 
        is read from the file also, and the configurable memory-manager is
        invoked to provide the array space. If content is not arranged in
        such a manner you may read array content directly either by setting
        a Allocator to null (to disable memory management) or by accessing
        buffer content directly via the methods exposed there e.g.

        ---
        void[10] data;
                
        getBuffer.get (data);
        ---

        Readers may also be used with any class implementing the IReadable
        interface. See PickleReader for an example of how this can be used
        
*******************************************************************************/

abstract class IReader   // could be an interface, but that causes poor codegen
{
        alias get opCall;

        /***********************************************************************
        
                These are the basic reader methods

        ***********************************************************************/

        abstract IReader get (inout bool x);
        abstract IReader get (inout byte x);		/// ditto
        abstract IReader get (inout ubyte x);		/// ditto
        abstract IReader get (inout short x);		/// ditto
        abstract IReader get (inout ushort x);		/// ditto
        abstract IReader get (inout int x);		/// ditto
        abstract IReader get (inout uint x);		/// ditto
        abstract IReader get (inout long x);		/// ditto
        abstract IReader get (inout ulong x);		/// ditto
        abstract IReader get (inout float x);		/// ditto
        abstract IReader get (inout double x);		/// ditto
        abstract IReader get (inout real x);		/// ditto
        abstract IReader get (inout char x);		/// ditto
        abstract IReader get (inout wchar x);		/// ditto
        abstract IReader get (inout dchar x);		/// ditto

        abstract IReader get (inout bool[] x);          /// ditto
        abstract IReader get (inout byte[] x);          /// ditto
        abstract IReader get (inout short[] x);         /// ditto
        abstract IReader get (inout int[] x);           /// ditto
        abstract IReader get (inout long[] x);          /// ditto
        abstract IReader get (inout ubyte[] x);         /// ditto
        abstract IReader get (inout ushort[] x);	/// ditto
        abstract IReader get (inout uint[] x);          /// ditto
        abstract IReader get (inout ulong[] x);         /// ditto
        abstract IReader get (inout float[] x);         /// ditto
        abstract IReader get (inout double[] x);	/// ditto
        abstract IReader get (inout real[] x);          /// ditto
        abstract IReader get (inout char[] x);          /// ditto
        abstract IReader get (inout wchar[] x);         /// ditto
        abstract IReader get (inout dchar[] x);         /// ditto

        /***********************************************************************
        
                This is the mechanism used for binding arbitrary classes 
                to the IO system. If a class implements IReadable, it can
                be used as a target for IReader get() operations. That is, 
                implementing IReadable is intended to transform any class 
                into an IReader adaptor for the content held therein.

        ***********************************************************************/

        abstract IReader get (IReadable x);

        /***********************************************************************
        
                Return the buffer associated with this reader

        ***********************************************************************/

        abstract IBuffer getBuffer ();

        /***********************************************************************
        
                Get the allocator to use for array management. Arrays are
                generally allocated by the IReader, via configured managers.
                A number of Allocator classes are available to manage memory
                when reading array content. Alternatively, a null Allocator
                hands responsibility over to the application instead. 

                Gaining access to the allocator can expose some additional
                controls. For example, some allocators benefit from a reset
                operation after each data 'record' has been processed.

        ***********************************************************************/

        abstract Allocator getAllocator (); 

        /***********************************************************************
              
                Set the allocator to use for array management. Arrays are
                generally allocated via the IReader itself, and a variety
                of Allocators are provided to expose different policies.

                By default, an IReader will allocate each array from the 
                heap. You can change that behavior by calling this method
                with an Allocator of choice. For instance, there is a
                BufferAllocator which will slice an array directly from
                the buffer where possible. Also available is the record-
                oriented SliceAllocator, which slices memory from within
                a pre-allocated heap area, and should be reset by the client
                code after each record has been read (to avoid unnecessary
                growth). Setting the Allocator to null disables internal
                memory management entirely, and turns responsiblity over to
                the application instead. In the latter case, array slices
                provided by the application are populated.

                See module ArrayAllocator for more information

        ***********************************************************************/

        abstract void setAllocator (Allocator memory); 

        
        /***********************************************************************

                Helper to allocate arrays for get() methods. A default
                allocator is configured, but can be overridden via the
                setAllocator() method. Assign an Allocator to a Reader
                to optimize for application-specific scenarios.

                A NullAllocator is available to effectively disable array
                allocation where appropriate
                
        ***********************************************************************/

        interface Allocator
        {
                void reset ();

                void bind (IReader input);

                void[] allocate (uint bytes);
        }
}

/*******************************************************************************

        Any class implementing IReadable becomes part of the Reader framework
        
*******************************************************************************/

interface IReadable
{
        void read (IReader input);
}


/*******************************************************************************

        @file IReader.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, March 2004     
         
        @author         Kris
        @author         Ivan Senji (the "alias get" idea)


*******************************************************************************/

module tango.io.protocol.model.IReader;

public import tango.io.model.IBuffer;

/*******************************************************************************

        Any class implementing IReadable becomes part of the Reader framework
        
*******************************************************************************/

interface IReadable
{
        abstract void read (IReader input);
}

/*******************************************************************************

*******************************************************************************/

interface IArrayAllocator
{
        abstract void reset ();

        abstract void bind (IReader input);

        abstract bool isMutable (void* x);

        abstract void allocate  (void[]* x, uint size, uint width, uint type, IBuffer.Converter convert);
}

/*******************************************************************************

        All reader instances should implement this interface.

*******************************************************************************/

abstract class IReader   // could be an interface, but that causes poor codegen
{
        alias get opShr;
        alias get opCall;

        /***********************************************************************
        
                These are the basic reader methods

        ***********************************************************************/

        abstract IReader get (inout bool x);
        abstract IReader get (inout byte x);
        abstract IReader get (inout ubyte x);
        abstract IReader get (inout short x);
        abstract IReader get (inout ushort x);
        abstract IReader get (inout int x);
        abstract IReader get (inout uint x);
        abstract IReader get (inout long x);
        abstract IReader get (inout ulong x);
        abstract IReader get (inout float x);
        abstract IReader get (inout double x);
        abstract IReader get (inout real x);
        abstract IReader get (inout char x);
        abstract IReader get (inout wchar x);
        abstract IReader get (inout dchar x);

        abstract IReader get (inout byte[] x,   uint elements = uint.max);
        abstract IReader get (inout short[] x,  uint elements = uint.max);
        abstract IReader get (inout int[] x,    uint elements = uint.max);
        abstract IReader get (inout long[] x,   uint elements = uint.max);
        abstract IReader get (inout ubyte[] x,  uint elements = uint.max);
        abstract IReader get (inout ushort[] x, uint elements = uint.max);
        abstract IReader get (inout uint[] x,   uint elements = uint.max);
        abstract IReader get (inout ulong[] x,  uint elements = uint.max);
        abstract IReader get (inout float[] x,  uint elements = uint.max);
        abstract IReader get (inout double[] x, uint elements = uint.max);
        abstract IReader get (inout real[] x,   uint elements = uint.max);
        abstract IReader get (inout char[] x,   uint elements = uint.max);
        abstract IReader get (inout wchar[] x,  uint elements = uint.max);
        abstract IReader get (inout dchar[] x,  uint elements = uint.max);

        /***********************************************************************
        
                This is the mechanism used for binding arbitrary classes 
                to the IO system. If a class implements IReadable, it can
                be used as a target for IReader get() operations. That is, 
                implementing IReadable is intended to transform any class 
                into an IReader adaptor for the content held therein.

        ***********************************************************************/

        abstract IReader get (IReadable x);

        /***********************************************************************
                
                Pause the current thread until some content arrives in
                the associated input buffer. This may stall forever.

        ***********************************************************************/

        abstract void wait ();

        /***********************************************************************
        
                Return the buffer associated with this reader

        ***********************************************************************/

        abstract IBuffer getBuffer ();

        /***********************************************************************
        
                Get the allocator to use for array management. Arrays are
                always allocated by the IReader. That is, you cannot read
                data into an array slice (for example). Instead, a number
                of IArrayAllocator classes are available to manage memory
                allocation when reading array content. 

                You might use this to manage the assigned allocator. For
                example, some allocators benefit from a reset() operation
                after each data 'record' has been processed.

        ***********************************************************************/

        abstract IArrayAllocator getAllocator (); 

        /***********************************************************************
        
                Set the allocator to use for array management. Arrays are
                always allocated by the IReader. That is, you cannot read
                data into an array slice (for example). Instead, a number
                of IArrayAllocator classes are available to manage memory
                allocation when reading array content. 

                By default, an IReader will allocate each array from the 
                heap. You can change that behavior by calling this method
                with an IArrayAllocator of choice. For instance, there 
                is a BufferAllocator which will slice an array directly 
                from the buffer where possible. Also available is the 
                record-oriented SliceAllocator, which slices memory from 
                within a pre-allocated heap area, and should be reset by
                the client code after each record has been read (to avoid 
                unnecessary growth).

                See ArrayAllocator for more information.

        ***********************************************************************/

        abstract void setAllocator (IArrayAllocator memory); 

        /***********************************************************************
        
                Bind an IDecoder to the writer. Decoders are intended to
                be used as a conversion mechanism between various character
                representations (encodings).

        ***********************************************************************/

        abstract void setDecoder (AbstractDecoder);

        /***********************************************************************
        
                Return the current decoder type (Type.Raw if not set)

        ***********************************************************************/

        abstract int getDecoderType ();
}

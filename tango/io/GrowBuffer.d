/*******************************************************************************

        @file GrowBuffer.d

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

      
        @version        Initial version; March 2004

        @author         Kris


*******************************************************************************/

module tango.io.GrowBuffer;

private import  tango.io.Buffer;

public  import  tango.io.model.IBuffer;

/*******************************************************************************

        Subclass to provide support for content growth. This is handy when
        you want to keep a buffer around as a scratchpad.

*******************************************************************************/

class GrowBuffer : Buffer
{
        private uint increment;

        /***********************************************************************
        
                Create a GrowBuffer with the specified initial size.

        ***********************************************************************/

        this (uint size = 1024, uint increment = 1024)
        {
                super (size);

                assert (increment >= 32);
                this.increment = increment;
        }

        /***********************************************************************
        
                Create a GrowBuffer with the specified initial size.

        ***********************************************************************/

        this (IConduit conduit, uint size = 1024)
        {
                this (size, size);
                setConduit (conduit);
        }

        /***********************************************************************
        
                Read a chunk of data from the buffer, loading from the
                conduit as necessary. The specified number of bytes is
                loaded into the buffer, and marked as having been read 
                when the 'eat' parameter is set true. When 'eat' is set
                false, the read position is not adjusted.

                Returns the corresponding buffer slice when successful.

        ***********************************************************************/

        override void[] get (uint size, bool eat = true)
        {   
                if (size > readable)
                   {
                   if (conduit is null)
                       error (underflow);

                   if (size + position > capacity)
                       makeRoom (size);

                   // populate tail of buffer with new content
                   do {
                      if (fill(conduit) == IConduit.Eof)
                          error (eofRead);
                      } while (size > readable);
                   }

                uint i = position;
                if (eat)
                    position += size;
                return data [i .. i + size];               
        }

        /***********************************************************************
        
                Append an array of data to this buffer. This is often used 
                in lieu of a Writer.

        ***********************************************************************/

        override IBuffer append (void[] src)        
        {               
                uint size = src.length;

                if (size > writable)
                    makeRoom (size);

                copy (src, size);
                return this;
        }

        /***********************************************************************

                Try to fill the available buffer with content from the 
                specified conduit. In particular, we will never ask to 
                read less than 32 bytes ~ this permits conduit-filters 
                to operate within a known environment. 

                Returns the number of bytes read, or IConduit.Eof
        
        ***********************************************************************/

        override uint fill (IConduit conduit)
        {
                if (writable < 32)
                    makeRoom (increment);

                return write (&conduit.read);
        } 

        /***********************************************************************

                make some room in the buffer
                        
        ***********************************************************************/

        override void makeRoom (uint size)
        {
                if (size < increment)
                    size = increment;

                capacity += size;
                data.length = capacity;               
        }
}

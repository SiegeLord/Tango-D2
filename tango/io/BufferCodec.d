/*******************************************************************************

        @file BufferCodec.d
        
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

       
        @version        Initial version, Feb 2005    
          
        @author         Kris


*******************************************************************************/

module tango.io.BufferCodec;

private import  tango.io.Buffer;

private import  tango.convert.Type,
                tango.convert.Unicode;


/******************************************************************************

******************************************************************************/

private class Importer : AbstractEncoder
{
        protected IBuffer buffer;

        abstract uint type();

        void bind (IBuffer buffer)
        {
                this.buffer = buffer;
        }

        uint encoder (void* src, uint bytes, uint type)
        {
                buffer.append (src [0..bytes]);  
                return bytes;   
        }
}
       

/******************************************************************************

******************************************************************************/

private class Exporter : AbstractDecoder
{
        protected IBuffer buffer;

        abstract uint type();

        void bind (IBuffer buffer)
        {
                this.buffer = buffer;
        }

        /***********************************************************************

                Alternate decoder for simple, non-streaming cases. Note that
                the returned array may reside in shared memory.

        ***********************************************************************/

        void[] decoder (void[] src, uint type)
        {
                return src;
        }

        uint decoder (void* dst, uint bytes, uint type)
        {
                uint length = bytes;

                while (length)
                      {
                      // get as much as there is available in the buffer
                      uint available = buffer.readable();
                      
                      // cap bytes read
                      if (available > length)
                          available = length;

                      // copy them over
                      dst[0..available] = buffer.get (available);

                      // bump counters
                      dst += available;
                      length -= available;

                      // if we need more, prime the input by reading
                      if (length)
                          if (buffer.fill() == uint.max)
                              buffer.error ("end of input");
                      }
                return bytes;
        }
}
       


/*******************************************************************************

*******************************************************************************/

class UnicodeImporter(T) : Importer
{
        Unicode.Into!(T) into;

        this (IBuffer buffer = null)
        {
                bind (buffer);
        }

        override uint type ()
        {
                return into.type;
        }

        override uint encoder (void* src, uint bytes, uint type)
        {
                uint ate;
                uint eaten;

                uint convert (void[] dst)
                {
                        return into.convert (src[eaten..bytes], type, dst, &ate).length;
                }


                if (type == into.type)
                    return super.encoder (src, bytes, type);

                buffer.write (&convert);
                while ((eaten += ate) < bytes)
                      {
                      buffer.makeRoom (bytes - eaten);
                      buffer.write (&convert);
                      }
                return eaten;
        }
}


/*******************************************************************************

*******************************************************************************/

class UnicodeExporter(T) : Exporter
{
        Unicode.From!(T) from;

        this (IBuffer buffer = null)
        {
                bind (buffer);
        }

        override uint type ()
        {
                return from.type;
        }

        /***********************************************************************

                Alternate decoder for simple, non-streaming cases. Note that
                the returned array may reside in shared memory.

        ***********************************************************************/

        void[] decoder (void[] src, uint type)
        {
                return from.convert (src, type);
        }

        override uint decoder (void* dst, uint bytes, uint type)
        {
                int written;

                uint convert (void[] src)
                {
                        uint ate;
                        written += from.convert (src, type, dst[written..bytes], &ate).length;
                        return ate;
                }
        
                if (type == from.type)
                    return super.decoder (dst, bytes, type);

                buffer.read (&convert);
                while (written < bytes)
                      {
                      buffer.fill ();
                      buffer.read (&convert);
                      }
                return written;
        }
}

//alias UnicodeImporter!(wchar) UnicodeImporter16;


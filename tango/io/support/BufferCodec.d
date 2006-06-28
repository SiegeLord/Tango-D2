/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: Feb 2005    
        
        author:         Kris

*******************************************************************************/

module tango.io.support.BufferCodec;

private import  tango.convert.Type,
                tango.convert.Unicode;

private import  tango.io.model.IBuffer;

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


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: Feb 2005    
        
        author:         Kris

*******************************************************************************/

module tango.io.support.BufferCodec;

private import  tango.text.convert.Type,
                tango.text.convert.Utf;

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

        /***********************************************************************

                Convert from an external coding of 'type' to an internally
                normalized representation of T.

                T refers to the destination, whereas 'type' refers to the
                source.

        ***********************************************************************/

        struct Into(T)
        {
                /***************************************************************

                ***************************************************************/

                static uint type ()
                {
                        static if (is (T == char))
                                   return Type.Utf8;
                        static if (is (T == wchar))
                                   return Type.Utf16;
                        static if (is (T == dchar))
                                   return Type.Utf32;
                }

                /***************************************************************

                ***************************************************************/

                static void[] convert (void[] x, uint type, void[] dst=null, uint* ate=null)
                {
                        void[] ret;

                        static if (is (T == char))
                                  {
                                  if (type == Type.Utf8)
                                      return x;

                                  if (type == Type.Utf16)
                                      ret = toUtf8 (cast(wchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf8 (cast(dchar[]) x, cast(char[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (type == Type.Utf16)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf16 (cast(char[]) x, cast(wchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf16 (cast(dchar[]) x, cast(wchar[]) dst, ate);
                                  }

                        static if (is (T == dchar))
                                  {
                                  if (type == Type.Utf32)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf32 (cast(char[]) x, cast(dchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf16)
                                      ret = toUtf32 (cast(wchar[]) x, cast(dchar[]) dst, ate);
                                  }
                        if (ate)
                            *ate *= Type.widths[type];
                        return ret;
                }
        }

        Into!(T) into;
}


/*******************************************************************************

*******************************************************************************/

class UnicodeExporter(T) : Exporter
{
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

        /***********************************************************************

                Convert to an external coding of 'type' from an internally
                normalized representation of T.

                T refers to the source, whereas 'type' is the destination.

        ***********************************************************************/

        struct From(T)
        {
                /***************************************************************

                ***************************************************************/

                static uint type ()
                {
                        static if (is (T == char))
                                   return Type.Utf8;
                        static if (is (T == wchar))
                                   return Type.Utf16;
                        static if (is (T == dchar))
                                   return Type.Utf32;
                }

                /***************************************************************

                ***************************************************************/

                static void[] convert (void[] x, uint type, void[] dst=null, uint* ate=null)
                {
                        void[] ret;

                        static if (is (T == char))
                                  {
                                  if (type == Type.Utf8)
                                      return x;

                                  if (type == Type.Utf16)
                                      ret = toUtf16 (cast(char[]) x, cast(wchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf32 (cast(char[]) x, cast(dchar[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (type == Type.Utf16)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf8 (cast(wchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf32 (cast(wchar[]) x, cast(dchar[]) dst, ate);
                                  }

                        static if (is (T == dchar))
                                  {
                                  if (type == Type.Utf32)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf8 (cast(dchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf16)
                                      ret = toUtf16 (cast(dchar[]) x, cast(wchar[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (ate)
                                      *ate *= 2;
                                  }
                        static if (is (T == dchar))
                                  {
                                  if (ate)
                                      *ate *= 4;
                                  }
                        return ret;
                }
        }

        From!(T) from;
}

// alias UnicodeImporter!(char) imp;
// alias UnicodeExporter!(char) exp;

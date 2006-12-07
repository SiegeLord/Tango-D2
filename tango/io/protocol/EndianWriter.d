/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.protocol.EndianWriter;

private import  tango.core.ByteSwap;

private import  tango.text.convert.Type;

private import  tango.io.protocol.Writer;

/*******************************************************************************

*******************************************************************************/

class EndianWriter : Writer
{       
        /***********************************************************************
        
                Construct EndianWriter upon the given IBuffer

        ***********************************************************************/

        this (IBuffer buffer)
        {
                super (buffer);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected override IWriter write (void* src, uint bytes, uint type)
        {
                void write (int mask, void function (void* dst, uint bytes) mutate)
                {
                        uint writer (void[] dst)
                        {
                                // cap bytes written
                                uint len = dst.length & mask;
                                if (len > bytes)
                                    len = bytes;

                                dst [0..len] = src [0..len];
                                mutate (dst, len);
                                return len;
                        }

                        while (bytes)
                              {
                              //flush if we used all buffer space
                              if (bytes -= buffer.write (&writer))
                                  buffer.makeRoom (bytes);
                              }                          
                }


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

                return this;
        }
}


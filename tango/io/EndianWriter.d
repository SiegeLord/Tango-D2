/*******************************************************************************

        @file EndianWriter.d
        
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


*******************************************************************************/

module tango.io.EndianWriter;

public  import  tango.io.Writer;

private import  tango.convert.Type;

private import  tango.core.ByteSwap;

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

        protected override IWriter write (void* src, uint bytes, int type)
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


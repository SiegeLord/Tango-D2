/*******************************************************************************

        @file ByteSwap.d
        
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


        @version        Initial version; October 2004

        Feb 20th 2005 - Asm version thrown away by Aleksey Bobnev :))
                        non-asm version now makes use of bswap intrinsic

        @author         Kris
                        Aleksey Bobnev

*******************************************************************************/

module tango.sys.ByteSwap;

import tango.core.intrinsic;

/*******************************************************************************

        Reverse byte order for specific datum sizes. Note that the
        byte-swap approach avoids alignment issues, so is probably
        faster overall than a traditional 'shift' implementation.

*******************************************************************************/

struct ByteSwap
{       
        /***********************************************************************
        
        ***********************************************************************/

        final static void swap16 (void *dst, uint count)
        {
                ubyte* p = cast(ubyte*) dst;
                while (count)
                      {
                      ubyte b = p[0];
                      p[0] = p[1];
                      p[1] = b;

                      p += short.sizeof;
                      count -= short.sizeof;
                      }
        }

        /***********************************************************************
        
        ***********************************************************************/

        final static void swap32 (void *dst, uint count)
        {
                uint* p = cast(uint*) dst;
                while (count)
                      {
                      *p = bswap(*p);
                      p ++;
                      count -= int.sizeof;
                      }
        }

        /***********************************************************************
        
        ***********************************************************************/

        final static void swap64 (void *dst, uint count)
        {
                uint* p = cast(uint*) dst;
                while (count)
                      {
                      uint i = p[0];
                      p[0] = bswap(p[1]);
                      p[1] = bswap(i);

                      p += (long.sizeof / int.sizeof);
                      count -= long.sizeof;
                      }
        }

        /***********************************************************************
        
        ***********************************************************************/

        final static void swap80 (void *dst, uint count)
        {
                ubyte* p = cast(ubyte*) dst;
                while (count)
                      {
                      ubyte b = p[0];
                      p[0] = p[9];
                      p[9] = b;

                      b = p[1];
                      p[1] = p[8];
                      p[8] = b;

                      b = p[2];
                      p[2] = p[7];
                      p[7] = b;
        
                      b = p[3];
                      p[3] = p[6];
                      p[6] = b;
        
                      b = p[4];
                      p[4] = p[5];
                      p[5] = b;

                      p += real.sizeof;
                      count -= real.sizeof;
                      }
        }
}

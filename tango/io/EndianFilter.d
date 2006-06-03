/*******************************************************************************

        @file EndianFilter.d
        
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

        
        @version        Initial version; November 2005

        @author         Kris


*******************************************************************************/

module tango.io.EndianFilter;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import  tango.core.ByteSwap;


class EndianFilter : ConduitFilter
{
        private uint mask;

        private this (uint width)
        {
                mask = ~(width - 1);
        }

        abstract void swap (void[] x, uint bytes);

        uint reader (void[] dst)
        {
                //notify ("byte-swapping input ...\n"c);

                dst = dst [0..(length & mask)];

                int ret = next.reader (dst);
                if (ret == Conduit.Eof)
                    return ret;

                int ret1;
                if (ret & ~mask)
                    do {
                       ret1 = next.reader (dst[ret..ret+1]);
                       if (ret1 == Conduit.Eof)
                           error ("odd number of bytes!");
                       } while (ret1 == 0);

                swap (dst, ret + ret1);
                return ret;
        }

        uint writer (void[] src)
        {
                //notify ("byte-swapping output ...\n"c);

                int     written;
                int     ret, 
                        len = src.length & mask;

                src = src [0..len];
                swap (src, len);

                do {
                   ret = next.writer (src[written..len]);
                   if (ret == Conduit.Eof)
                       return ret;
                   } while ((written += ret) < len);

                return len;                        
        }
}

class EndianFilter16 : EndianFilter
{
        this () {super (2);}

        final void swap (void[] x, uint bytes) {ByteSwap.swap16 (x, bytes);}
}

class EndianFilter32 : EndianFilter
{
        this () {super (4);}

        final void swap (void[] x, uint bytes) {ByteSwap.swap32 (x, bytes);}
}


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: November 2005
        
        author:         Kris

*******************************************************************************/

module tango.io.filter.EndianFilter;

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

        final void swap (void[] x, uint bytes) {ByteSwap.swap16 (x.ptr, bytes);}
}

class EndianFilter32 : EndianFilter
{
        this () {super (4);}

        final void swap (void[] x, uint bytes) {ByteSwap.swap32 (x.ptr, bytes);}
}


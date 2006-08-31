/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004

        version:        Feb 20th 2005 - Asm version removed by Aleksey Bobnev
                        non-asm version now makes use of bswap intrinsic
                        Aug 30th 2006 - Added module scope versions by 
                        Benjamin Shropshire. Module Scope version uses element 
                        count rather than byte counts

        author:         Kris, Aleksey Bobnev, Benjamin Shropshire

*******************************************************************************/

module tango.core.ByteSwap;

import tango.core.Intrinsic;


/*******************************************************************************

        Reverse byte order for specific datum sizes. Note that the
        byte-swap approach avoids alignment issues, so is probably
        faster overall than a traditional 'shift' implementation.

        version:        Aug 30th 2006 - Added

        author:         Benjamin Shropshire

        Note: These functions use an element count for the "count" arg.

*******************************************************************************/

void swap16 (void *dst, uint count)
{
        ushort* p = cast(ushort*) dst;
        ubyte* b;
        ubyte i;

        while (count)
        {
                count--;

                b = cast(ubyte*)&(p[count]);
                i = b[0];
                b[0] = b[1];
                b[1] = i;
        }
}

void swap32 (void *dst, uint count) ///ditto
{
        uint* base = cast(uint*) dst;

        while (count)
        {
                count--;
                base[count] = bswap(base[count]);
        }
}


void swap64 (void *dst, uint count)     ///ditto
{
        ulong* base = cast(ulong*) dst;

        uint* p;
        uint i;

        while (count)
        {
                count--;
                p = cast(uint*)&(base[count]);

                p = cast(uint*)&(base[count]);

                i = p[0];
                p[0] = bswap(p[1]);
                p[1] = bswap(i);
        }
}





void swap80 (void *dst, uint count) ///ditto
{
        ubyte* base = cast(ubyte*) dst;
        ubyte* p;
        ubyte b;
        while (count)
        {
                count--;
                p = cast(ubyte*)&(base[count*8]);

                b = p[0];
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
        }
}


/*******************************************************************************

        Reverse byte order for specific datum sizes. Note that the
        byte-swap approach avoids alignment issues, so is probably
        faster overall than a traditional 'shift' implementation.

        Note: These functions use a byte count for the "count" arg.

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





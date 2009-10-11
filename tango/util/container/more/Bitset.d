/*******************************************************************************

        copyright:      Copyright (c) 2009 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Sept 2009: Initial release

        since:          0.99.9

        author:         Kris

*******************************************************************************/

module tango.util.container.more.Bitset;

private import std.intrinsic;

/******************************************************************************

        A fixed or dynamic set of bits. Note that this does no memory 
        allocation of its own when Size != 0, and does heap allocation 
        when Size is zero. Thus you can have a fixed-size low-overhead 
        'instance, or a heap oriented instance. The latter has support
        for resizing, whereas the former does not.

        Note that leveraging intrinsics is slower when using dmd ...

******************************************************************************/

struct Bitset (int Count = 0) 
{
        private const width = size_t.sizeof * 8;
        static if (Count == 0)
        {
                private size_t[] bits;

                /**************************************************************

                        Expand to include the indexed bit (dynamic only)

                **************************************************************/

                Bitset* size (size_t i)
                {
                        i = i / width;
                        if (i >= bits.length)
                             bits.length = i + 1;
                        return this;
                }
        }
        else
           private size_t [(Count+width-1)/width] bits;

        /**********************************************************************

                Turn on an indexed bit

        **********************************************************************/

        void or (size_t i)
        {
                bits[i / width] |= (1 << (i % width));
                //bts (&bits[i / width], i % width);
        }
        
        /**********************************************************************

                Invert an indexed bit

        **********************************************************************/

        void xor (size_t i)
        {
                bits[i / width] ^= (1 << (i % width));
                //btc (&bits[i / width], i % width);
        }
        
        /**********************************************************************

                Test whether the indexed bit is enabled 

        **********************************************************************/

        bool has (size_t i)
        {
                auto idx = i / width;
                return idx < bits.length && (bits[idx] & (1 << (i % width))) != 0;
                //return idx < bits.length && bt(&bits[idx], i % width) != 0;
        }

        /**********************************************************************

                Like has() but a little faster for when you know the range
                is valid

        **********************************************************************/

        bool and (size_t i)
        {
                return (bits[i / width] & (1 << (i % width))) != 0;
                //return bt(&bits[i / width], i % width) != 0;
        }

        /**********************************************************************

                Clear an indexed bit

        **********************************************************************/

        void clr (size_t i)
        {
                bits[i / width] &= ~(1 << (i % width));
                //btr (&bits[i / width], i % width);
        }

        /**********************************************************************

                Clear all bits

        **********************************************************************/

        Bitset* clr ()
        {
                bits[] = 0;
                return this;
        }
        
        /**********************************************************************

                Clone this bistset and return it

        **********************************************************************/

        Bitset* dup ()
        {
                auto x = new Bitset;
                x.bits[] = bits[];
                return x;
        }

        /**********************************************************************

                Is the bit-index within range?

        **********************************************************************/

        bool valid (size_t i)
        {
                return (i / width) < bits.length;
        }
}

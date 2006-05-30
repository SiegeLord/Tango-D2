/*******************************************************************************

        @file Random.d
        
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

        
        @version        Initial version, April 2004      
        @author         various


*******************************************************************************/

module tango.utils.Random;


/******************************************************************************

        KISS (via George Marsaglia & Paul Hsieh)

        the idea is to use simple, fast, individually promising
        generators to get a composite that will be fast, easy to code
        have a very long period and pass all the tests put to it.
        The three components of KISS are

                x(n)=a*x(n-1)+1 mod 2^32
                y(n)=y(n-1)(I+L^13)(I+R^17)(I+L^5),
                z(n)=2*z(n-1)+z(n-2) +carry mod 2^32

        The y's are a shift register sequence on 32bit binary vectors
        period 2^32-1; The z's are a simple multiply-with-carry sequence 
        with period 2^63+2^32-1.  

        The period of KISS is thus 2^32*(2^32-1)*(2^63+2^32-1) > 2^127

******************************************************************************/

version (Win32)
        {
        extern(Windows) int QueryPerformanceCounter (ulong *);
        }

version (Posix)
        {
                version (linux)
                         private import std.c.linux.linux;

                version (darwin)
                         private import std.c.darwin.darwin;
        }

class Random
{
        private static uint kiss_x = 1;
        private static uint kiss_y = 2;
        private static uint kiss_z = 4;
        private static uint kiss_w = 8;
        private static uint kiss_carry = 0;
        private static uint kiss_k;
        private static uint kiss_m;

        /**********************************************************************

        **********************************************************************/

        static this () 
        {
                ulong s;

                version (Posix)
                        {           
                        timeval tv;

                        gettimeofday (&tv, null);
                        s = tv.tv_usec;
                        }
                version (Win32)
                         QueryPerformanceCounter (&s);

                seed (cast(uint) s);
        }

        /**********************************************************************

        **********************************************************************/

        static final void seed (uint seed) 
        {
                kiss_x = seed | 1;
                kiss_y = seed | 2;
                kiss_z = seed | 4;
                kiss_w = seed | 8;
                kiss_carry = 0;
        }

        /**********************************************************************

        **********************************************************************/

        static final uint get (uint limit)
        {
                return get() % limit;
        }

        /**********************************************************************

        **********************************************************************/

        static final uint get ()
        {
                kiss_x = kiss_x * 69069 + 1;
                kiss_y ^= kiss_y << 13;
                kiss_y ^= kiss_y >> 17;
                kiss_y ^= kiss_y << 5;
                kiss_k = (kiss_z >> 2) + (kiss_w >> 3) + (kiss_carry >> 2);
                kiss_m = kiss_w + kiss_w + kiss_z + kiss_carry;
                kiss_z = kiss_w;
                kiss_w = kiss_m;
                kiss_carry = kiss_k >> 30;
                return kiss_x + kiss_y + kiss_w;
        }
}


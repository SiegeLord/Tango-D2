/*******************************************************************************

        Copyright (c) 2006 Regan Heath
        
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


        @version        Initial version, February 2006      
                        Modified for Mango, April 2006

        @author         Regan Heath
                        Kris

*******************************************************************************/

module tango.cipher.md4;

private import tango.cipher.md2;

public  import tango.cipher.base;

/*******************************************************************************

*******************************************************************************/

class Md4Digest : Md2Digest
{       
        /***********************************************************************
        
        ***********************************************************************/

        this(uint[4] raw) { super(cast(ubyte[16])raw); }
}


/*******************************************************************************

*******************************************************************************/

class Md4Cipher : Cipher
{
        protected uint[4]       context;
        private const ubyte     padChar = 0x80;
        
        /***********************************************************************
        
        ***********************************************************************/

        static const uint[4] initial = 
        [
                0x67452301,
                0xefcdab89,
                0x98badcfe,
                0x10325476
        ];
        
        /***********************************************************************
        
        ***********************************************************************/

        static enum 
        {
                S11 =  3,
                S12 =  7,
                S13 = 11,
                S14 = 19,
                S21 =  3,
                S22 =  5,
                S23 =  9,
                S24 = 13,
                S31 =  3,
                S32 =  9,
                S33 = 11,
                S34 = 15,
        };
        
        /***********************************************************************
        
        ***********************************************************************/

        override void start()
        {
                super.start();
                context[] = initial[];
        }

        /***********************************************************************
        
        ***********************************************************************/

        override Md4Digest getDigest()
        {
                return new Md4Digest(context);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected override uint blockSize() { return 64; }

        /***********************************************************************
        
        ***********************************************************************/

        protected override uint addSize()   { return 8;  }

        /***********************************************************************
        
        ***********************************************************************/

        protected override void padMessage(ubyte[] data)
        {
                data[0] = padChar;
                data[1..$] = 0;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        protected override void padLength(ubyte[] data, ulong length)
        {
                length <<= 3;
                data[] = (cast(ubyte*)&length)[0..data.length];
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected override void transform(ubyte[] input)
        {
                uint a,b,c,d;
                uint[16] x;

                littleEndian32(input,x);
                
                a = context[0];
                b = context[1];
                c = context[2];
                d = context[3];
                
                /* Round 1 */
                ff(a, b, c, d, x[ 0], S11, 0); /* 1 */
                ff(d, a, b, c, x[ 1], S12, 0); /* 2 */
                ff(c, d, a, b, x[ 2], S13, 0); /* 3 */
                ff(b, c, d, a, x[ 3], S14, 0); /* 4 */
                ff(a, b, c, d, x[ 4], S11, 0); /* 5 */
                ff(d, a, b, c, x[ 5], S12, 0); /* 6 */
                ff(c, d, a, b, x[ 6], S13, 0); /* 7 */
                ff(b, c, d, a, x[ 7], S14, 0); /* 8 */
                ff(a, b, c, d, x[ 8], S11, 0); /* 9 */
                ff(d, a, b, c, x[ 9], S12, 0); /* 10 */
                ff(c, d, a, b, x[10], S13, 0); /* 11 */
                ff(b, c, d, a, x[11], S14, 0); /* 12 */
                ff(a, b, c, d, x[12], S11, 0); /* 13 */
                ff(d, a, b, c, x[13], S12, 0); /* 14 */
                ff(c, d, a, b, x[14], S13, 0); /* 15 */
                ff(b, c, d, a, x[15], S14, 0); /* 16 */
                
                /* Round 2 */
                gg(a, b, c, d, x[ 0], S21, 0x5a827999); /* 17 */
                gg(d, a, b, c, x[ 4], S22, 0x5a827999); /* 18 */
                gg(c, d, a, b, x[ 8], S23, 0x5a827999); /* 19 */
                gg(b, c, d, a, x[12], S24, 0x5a827999); /* 20 */
                gg(a, b, c, d, x[ 1], S21, 0x5a827999); /* 21 */
                gg(d, a, b, c, x[ 5], S22, 0x5a827999); /* 22 */
                gg(c, d, a, b, x[ 9], S23, 0x5a827999); /* 23 */
                gg(b, c, d, a, x[13], S24, 0x5a827999); /* 24 */
                gg(a, b, c, d, x[ 2], S21, 0x5a827999); /* 25 */
                gg(d, a, b, c, x[ 6], S22, 0x5a827999); /* 26 */
                gg(c, d, a, b, x[10], S23, 0x5a827999); /* 27 */                
                gg(b, c, d, a, x[14], S24, 0x5a827999); /* 28 */
                gg(a, b, c, d, x[ 3], S21, 0x5a827999); /* 29 */
                gg(d, a, b, c, x[ 7], S22, 0x5a827999); /* 30 */
                gg(c, d, a, b, x[11], S23, 0x5a827999); /* 31 */
                gg(b, c, d, a, x[15], S24, 0x5a827999); /* 32 */

                /* Round 3 */
                hh(a, b, c, d, x[ 0], S31, 0x6ed9eba1); /* 33 */
                hh(d, a, b, c, x[ 8], S32, 0x6ed9eba1); /* 34 */
                hh(c, d, a, b, x[ 4], S33, 0x6ed9eba1); /* 35 */
                hh(b, c, d, a, x[12], S34, 0x6ed9eba1); /* 36 */
                hh(a, b, c, d, x[ 2], S31, 0x6ed9eba1); /* 37 */
                hh(d, a, b, c, x[10], S32, 0x6ed9eba1); /* 38 */
                hh(c, d, a, b, x[ 6], S33, 0x6ed9eba1); /* 39 */
                hh(b, c, d, a, x[14], S34, 0x6ed9eba1); /* 40 */
                hh(a, b, c, d, x[ 1], S31, 0x6ed9eba1); /* 41 */
                hh(d, a, b, c, x[ 9], S32, 0x6ed9eba1); /* 42 */
                hh(c, d, a, b, x[ 5], S33, 0x6ed9eba1); /* 43 */
                hh(b, c, d, a, x[13], S34, 0x6ed9eba1); /* 44 */
                hh(a, b, c, d, x[ 3], S31, 0x6ed9eba1); /* 45 */
                hh(d, a, b, c, x[11], S32, 0x6ed9eba1); /* 46 */
                hh(c, d, a, b, x[ 7], S33, 0x6ed9eba1); /* 47 */
                hh(b, c, d, a, x[15], S34, 0x6ed9eba1); /* 48 */

                context[0] += a;
                context[1] += b;
                context[2] += c;
                context[3] += d;

                x[] = 0;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private static uint f(uint x, uint y, uint z)
        {
                return (x&y)|(~x&z);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint g(uint x, uint y, uint z)
        {
                return (x&y)|(x&z)|(y&z);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint h(uint x, uint y, uint z)
        {               
                return x^y^z;
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static void ff(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += f(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static void gg(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += g(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static void hh(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += h(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }
}


/*******************************************************************************

*******************************************************************************/

unittest {
        static char[][] strings = [
                "",
                "a",
                "abc",
                "message digest",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];
        static char[][] results = [
                "31D6CFE0D16AE931B73C59D7E0C089C0",
                "BDE52CB31DE33E46245E05FBDBD6FB24",
                "A448017AAF21D8525FC10AE87AA6729D",
                "D9130A8164549FE818874806E1C7014B",
                "D79E1C308AA5BBCDEEA8ED63DF412DA9",
                "043F8582F241DB351CE627E153E7F0E4",
                "E33B4DDC9C38F2199C3E7B164FCC0536"
        ];
        
        auto h = new Md4Cipher();
        char[] res;

        foreach(int i, char[] s; strings) {
                res = h.sum(s).toString();
                assert(res == results[i]);
        }
}

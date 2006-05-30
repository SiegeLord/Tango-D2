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

module tango.cipher.sha256;

public import tango.cipher.base;

/*******************************************************************************

*******************************************************************************/

class Sha256Digest : Digest
{
        private uint[8] digest;

        /***********************************************************************
        
        ***********************************************************************/

        this(uint[8] context)
        {
                digest[] = context[];
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        char[] toString()
        {
                return toHexString(digest);
        }
}


/*******************************************************************************

*******************************************************************************/

class Sha256Cipher : Cipher
{
        private uint[8]         context;
        private const uint      padChar = 0x80;

        /***********************************************************************
        
        ***********************************************************************/

        override void start()
        {
                super.start();
                context[] = initial[];
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        override Sha256Digest getDigest()
        {
                return new Sha256Digest(context);
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
                for(int j = data.length-1; j >= 0; j--)
                        data[$-j-1] = cast(ubyte) (length >> j*8);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected override void transform(ubyte[] input)
        {
                uint[64] W;
                uint a,b,c,d,e,f,g,h;
                uint j,t1,t2;

                a = context[0];
                b = context[1];
                c = context[2];
                d = context[3];
                e = context[4];
                f = context[5];
                g = context[6];
                h = context[7];

                bigEndian32(input,W[0..16]);
                for(j = 16; j < 64; j++) {
                        W[j] = mix1(W[j-2]) + W[j-7] + mix0(W[j-15]) + W[j-16];
                }

                for(j = 0; j < 64; j++) {
                        t1 = h + sum1(e) + Ch(e,f,g) + K[j] + W[j];
                        t2 = sum0(a) + Maj(a,b,c);
                        h = g;
                        g = f;
                        f = e;
                        e = d + t1;
                        d = c;
                        c = b;
                        b = a;
                        a = t1 + t2;
                }

                context[0] += a;
                context[1] += b;
                context[2] += c;
                context[3] += d;
                context[4] += e;
                context[5] += f;
                context[6] += g;
                context[7] += h;
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint Ch(uint x, uint y, uint z)
        {
                return (x&y)^(~x&z);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint Maj(uint x, uint y, uint z)
        {
                return (x&y)^(x&z)^(y&z);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint sum0(uint x)
        {
                return rotateRight(x,2)^rotateRight(x,13)^rotateRight(x,22);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint sum1(uint x)
        {
                return rotateRight(x,6)^rotateRight(x,11)^rotateRight(x,25);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint mix0(uint x)
        {
                return rotateRight(x,7)^rotateRight(x,18)^shiftRight(x,3);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint mix1(uint x)
        {
                return rotateRight(x,17)^rotateRight(x,19)^shiftRight(x,10);
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private static uint rotateRight(uint x, uint n)
        {
                return (x >> n) | (x << (32-n));
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private static uint shiftRight(uint x, uint n)
        {
                return x >> n;
        }
}


/*******************************************************************************

*******************************************************************************/

private static uint[] K = [
                0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ];

/*******************************************************************************

*******************************************************************************/

private static const uint[8] initial = [
                0x6a09e667,
                0xbb67ae85,
                0x3c6ef372,
                0xa54ff53a,
                0x510e527f,
                0x9b05688c,
                0x1f83d9ab,
                0x5be0cd19
        ];


/*******************************************************************************

*******************************************************************************/

unittest {
        static char[][] strings = [
                "abc",
                "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        ];
        static char[][] results = [
                "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD",
                "248D6A61D20638B8E5C026930C3E6039A33CE45964FF2167F6ECEDD419DB06C1"
        ];
        
        auto h = new Sha256Cipher();
        char[] res;

        foreach(int i, char[] s; strings) {
                res = h.sum(s).toString();
                assert(res == results[i]);
        }
}

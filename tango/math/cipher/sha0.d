/*******************************************************************************

        copyright:      Copyright (c) 2004 Regan Heath. All rights reserved

        license:        BSD style: see doc/license.txt for details
      
        version:        Initial release: Feb 2006
        
        author:         Regan Heath, Kris
        
        This module implements the SHA-0 Algorithm described by Secure Hash 
        Standard, FIPS PUB 180

*******************************************************************************/

module tango.math.cipher.sha0;

public import tango.math.cipher.base;

/*******************************************************************************

*******************************************************************************/

class Sha0Digest : Digest
{
        private ubyte[20] digest;

        /***********************************************************************
        
        ***********************************************************************/

        this() { digest[] = 0; }

        /***********************************************************************
        
        ***********************************************************************/

        this(uint[5] context) {
                foreach(uint i, ubyte b; (cast(ubyte *)context)[0..20])
                        digest[i^3] = b;
        }

        /***********************************************************************
        
        ***********************************************************************/

        this(Sha0Digest rhs) { digest[] = rhs.digest[]; }       

        /***********************************************************************
        
        ***********************************************************************/

        char[] toString() { return toHexString(digest); }

        /***********************************************************************
        
        ***********************************************************************/
        
        void[] toBinary() { return cast(void[]) digest; }
}


/*******************************************************************************

*******************************************************************************/

class Sha0Cipher : Cipher
{
        private uint[5]         context;

        private const ubyte     padChar = 0x80;
        private const uint      mask = 0x0000000F;
        
        /***********************************************************************
        
        ***********************************************************************/

        static const uint[] K = 
        [
                0x5A827999,
                0x6ED9EBA1,
                0x8F1BBCDC,
                0xCA62C1D6
        ];

        /***********************************************************************
        
        ***********************************************************************/

        static const uint[5] initial = 
        [
                0x67452301, 
                0xEFCDAB89, 
                0x98BADCFE, 
                0x10325476, 
                0xC3D2E1F0
        ];

        /***********************************************************************
        
        ***********************************************************************/

        override void start()
        {
                super.start();
                context[] = initial[];
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        override Digest getDigest()
        {
                return new Sha0Digest(context);
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
                        data[$-j-1] = cast(ubyte) (length >> j*data.length);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected override void transform(ubyte[] input)
        {
                uint A,B,C,D,E,TEMP;
                uint[16] W;
                uint s;

                bigEndian32(input,W);

                A = context[0];
                B = context[1];
                C = context[2];
                D = context[3];
                E = context[4];

                /* Method 1
                for(uint t = 16; t < 80; t++) {
                        W[t] = rotateLeft(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16],1);
                }
                for(uint t = 0; t < 80; t++) {
                        TEMP = rotateLeft(A,5) + f(t,B,C,D) + E + W[t] + K[t/20];
                        E = D;
                        D = C;
                        C = rotateLeft(B,30);
                        B = A;
                        A = TEMP;
                }
                */

                /* Method 2 */
                for(uint t = 0; t < 80; t++) {
                        s = t & mask;
                        if (t >= 16) expand(W,s);
                        TEMP = rotateLeft(A,5) + f(t,B,C,D) + E + W[s] + K[t/20];
                        E = D; D = C; C = rotateLeft(B,30); B = A; A = TEMP;                    
                }

                context[0] += A;
                context[1] += B;
                context[2] += C;
                context[3] += D;
                context[4] += E;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        protected void expand(uint W[], uint s)
        {
                W[s] = W[(s+13)&mask] ^ W[(s+8)&mask] ^ W[(s+2)&mask] ^ W[s];
        }

        /***********************************************************************
        
        ***********************************************************************/

        private static uint f(uint t, uint B, uint C, uint D)
        {
                if (t < 20) return (B & C) | ((~B) & D);
                else if (t < 40) return B ^ C ^ D;
                else if (t < 60) return (B & C) | (B & D) | (C & D);
                else return B ^ C ^ D;
        }
}

/*******************************************************************************

*******************************************************************************/

unittest {
        static char[][] strings = [
                "",
                "abc",
                "message digest",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];
        static char[][] results = [
                "F96CEA198AD1DD5617AC084A3D92C6107708C0EF",
                "0164B8A914CD2A5E74C4F7FF082C4D97F1EDF880",
                "C1B0F222D150EBB9AA36A40CAFDC8BCBED830B14",
                "B40CE07A430CFD3C033039B9FE9AFEC95DC1BDCD",
                "79E966F7A3A990DF33E40E3D7F8F18D2CAEBADFA",
                "4AA29D14D171522ECE47BEE8957E35A41F3E9CFF",
        ];
        
        auto h = new Sha0Cipher();
        char[] res;

        foreach(int i, char[] s; strings) {
                res = h.sum(s).toString();
                assert(res == results[i]);
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the SHA-0 Algorithm described by Secure 
        Hash Standard, FIPS PUB 180

*******************************************************************************/

module tango.io.digest.Sha0;

private import tango.io.digest.Sha01;

public  import tango.io.digest.Digest;

/*******************************************************************************

*******************************************************************************/

final class Sha0 : Sha01
{
        /***********************************************************************

                Construct an Sha0

        ***********************************************************************/

        this() { }

        /***********************************************************************

        ***********************************************************************/

        final protected override void transform(ubyte[] input)
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

        final static protected void expand(uint W[], uint s)
        {
                W[s] = W[(s+13)&mask] ^ W[(s+8)&mask] ^ W[(s+2)&mask] ^ W[s];
        }


}


/*******************************************************************************

*******************************************************************************/

version (UnitTest)
{
        unittest 
        {
        static char[][] strings = 
        [
                "",
                "abc",
                "message digest",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];

        static char[][] results = 
        [
                "F96CEA198AD1DD5617AC084A3D92C6107708C0EF",
                "0164B8A914CD2A5E74C4F7FF082C4D97F1EDF880",
                "C1B0F222D150EBB9AA36A40CAFDC8BCBED830B14",
                "B40CE07A430CFD3C033039B9FE9AFEC95DC1BDCD",
                "79E966F7A3A990DF33E40E3D7F8F18D2CAEBADFA",
                "4AA29D14D171522ECE47BEE8957E35A41F3E9CFF",
        ];

        Sha0 h = new Sha0();

        foreach (int i, char[] s; strings) 
                {
                h.update(s);
                char[] d = h.hexDigest();
                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Regan Heath. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: Feb 2006
        
        author:         Regan Heath, Kris

*******************************************************************************/

module tango.cipher.sha1;

public import tango.cipher.sha0;

/*******************************************************************************

*******************************************************************************/

class Sha1Digest : Sha0Digest
{
}


/*******************************************************************************

*******************************************************************************/

class Sha1Cipher : Sha0Cipher
{
        /***********************************************************************
        
        ***********************************************************************/

        protected override void expand (uint W[], uint s)
        {
                W[s] = rotateLeft(W[(s+13)&mask] ^ W[(s+8)&mask] ^ W[(s+2)&mask] ^ W[s],1);
        }
}


/*******************************************************************************

*******************************************************************************/

unittest {
        static char[][] strings = [
                "abc",
                "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
                "a",
                "0123456701234567012345670123456701234567012345670123456701234567"
        ];
        static char[][] results = [
                "A9993E364706816ABA3E25717850C26C9CD0D89D",
                "84983E441C3BD26EBAAE4AA1F95129E5E54670F1",
                "34AA973CD4C4DAA4F61EEB2BDBAD27316534016F",
                "DEA356A2CDDD90C7A7ECEDC5EBB563934F460452"
        ];
        static int[] repeat = [
                1,
                1,
                1000000,
                10
        ];
        
        auto h = new Sha1Cipher();
        char[] res;

        foreach(int i, char[] s; strings) {
                h.start();
                for(int r = 0; r < repeat[i]; r++)
                        h.update(s);
                res = h.finish().toString();
                assert(res == results[i]);
        }
}

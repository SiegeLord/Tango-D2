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

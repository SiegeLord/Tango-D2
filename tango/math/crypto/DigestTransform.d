/******************************************************************************

        copyright:      Copyright (c) 2004 Regan Heath. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Kris, Oskar Linde

        This module defines the DigestTransform interface.  In
        addition CryptoException is defined for exception handling.

******************************************************************************/

module tango.math.crypto.DigestTransform;

/+ Commented out until its proper home is figured out
/******************************************************************************

       This is an exception class to be thrown by algorithms under
       tango.math.crypto where required.

******************************************************************************/

class CryptoException : Exception
{
        /***********************************************************************

                Construct a CryptoException.

                Params:
                msg = the exception text

                Remarks:
                Constructs a CryptoException.

        ***********************************************************************/

        this(char[] msg) { super(msg); }
}
+/

/*******************************************************************************
        The DigestTransform interface defines the interface of message
        digest algorithms, such as MD5 and SHA. Message digests are
        secure hash functions that take a message of arbitrary length
        and produce a fix length digest as output.

        A object implementing the DigestTransform should start out initialized.
        The data is processed though calls to the update method. Once all data
        has been sent to the algorithm, the digest is finalized and computed
        with the digest method.

        The digest method may only be called once. After the digest
        method has been called, the algorithm is reset to its initial
        state.

        Using the update method, data may be processed piece by piece, 
        which is useful for cases involving streams of data.

        For example:
        ---
        // create an MD5 hash algorithm
        Md5 hash = new Md5();

        // process some data
        hash.update("The quick brown fox");

        // process some more data
        hash.update(" jumps over the lazy dog");

        // conclude algorithm and produce digest
        ubyte[] digest = hash.digest();
        ---
 */

interface DigestTransform {
        /********************************************************************
     
               Processes data
               
               Remarks:
                     Updates the hash algorithm state with new data
                 
        *********************************************************************/
    
        void update(void[] data);
    
    
        /********************************************************************

               Computes the digest and resets the state

               Params:
                   buffer = a buffer can be supplied for the digest to be
                            written to

               Remarks:
                   If the buffer is not large enough to hold the
                   digest, a new buffer is allocated and returned.
                   The algorithm state is always reset after a call to
                   digest. Use the digestSize method to find out how
                   large the buffer has to be.
                   
        *********************************************************************/
    
        ubyte[] digest(ubyte[] buffer = null);
    
        /********************************************************************
     
               Returns the size in bytes of the digest
               
               Returns:
                 the size of the digest in bytes

               Remarks:
                 Returns the size of the digest.
                 
        *********************************************************************/
    
        uint digestSize();
}

/* * */
package char[] toHex(ubyte[] src) {
    char[] result;
    static char[] hexdigits = "0123456789ABCDEF";

    if (src.length)
    {
        uint index = -1;
        result = new char [src.length * 2];
        foreach (b; src)
        {
            result [++index] = hexdigits [b >> 4];
            result [++index] = hexdigits [b & 0x0f];
        }
    }

    return result;
} 

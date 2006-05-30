/*******************************************************************************

        @file IBitBucket.d
        
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
           of the source.


        @version        Initial version, June 2004
        @author         Kris


*******************************************************************************/


module tango.io.model.IBitBucket;

/******************************************************************************

        IBitBucket implements a simple mechanism to store and recover a 
        large quantity of data for the duration of the hosting process.
        It is intended to act as a local-cache for a remote data-source, 
        or as a spillover area for large in-memory cache instances. 
        
        Note that any and all stored data is rendered invalid the moment
        an IBucket object is garbage-collected.

        All index keys must be unique. Writing to an IBitBucket with an
        existing key will overwrite any previous content. 

******************************************************************************/

interface IBitBucket
{
        /**********************************************************************

                Return the record-size in use for this IBitBucket

        **********************************************************************/

        int getBufferSize ();

        /**********************************************************************

                Return the currently populated size of this IBitBucket

        **********************************************************************/

        ulong length ();

        /**********************************************************************

                Return the serialized data for the provided key. Returns
                null if the key was not found.

        **********************************************************************/

        void[] get (char[] key);

        /**********************************************************************

                Remove the provided key from this IBitBucket.

        **********************************************************************/

        void remove (char[] key);

        /**********************************************************************

                Write a serialized block of data, and associate it with
                the provided key. All keys must be unique, and it is the
                responsibility of the programmer to ensure this. Reusing 
                an existing key will overwrite previous data. 

        **********************************************************************/

        void put (char[] key, void[] data);
}



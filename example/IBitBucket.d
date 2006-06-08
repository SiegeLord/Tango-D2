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



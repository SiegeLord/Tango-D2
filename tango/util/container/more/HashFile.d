module tango.util.container.more.HashFile;

private import tango.io.device.FileMap : MappedFile;

/******************************************************************************

        HashFile implements a simple mechanism to store and recover a 
        large quantity of data for the duration of the hosting process.
        It is intended to act as a local-cache for a remote data-source, 
        or as a spillover area for large in-memory cache instances. 
        
        Note that any and all stored data is rendered invalid the moment
        a HashFile object is garbage-collected.

        The implementation follows a fixed-capacity record scheme, where
        content can be rewritten in-place until said capacity is reached.
        At such time, the altered content is moved to a larger capacity
        record at end-of-file, and a hole remains at the prior location.
        These holes are not collected, since the lifespan of a HashFile
        is limited to that of the host process.

        All index keys must be unique. Writing to the HashFile with an
        existing key will overwrite any previous content. What follows
        is a contrived example:
        
        ---
        alias HashFile!(char[], char[]) Bucket;

        auto bucket = new Bucket ("bucket.bin", HashFile.HalfK);

        // insert some data, and retrieve it again
        auto text = "this is a test";
        bucket.put ("a key", text);
        auto b = cast(char[]) bucket.get ("a key");

        assert (b == text);
        bucket.close;
        ---

******************************************************************************/

class HashFile(K, V)
{
        /**********************************************************************

                Define the capacity (block-size) of each record

        **********************************************************************/

        struct BlockSize
        {
                int capacity;
        }

        // backing storage
        private MappedFile              file;

        // memory-mapped content
        private ubyte[]                 heap;

        // basic capacity for each record
        private BlockSize               block;

        // pointers to file records
        private Record[K]               map;

        // current file size
        private ulong                   fileSize;

        // current file usage
        private ulong                   waterLine;

        // supported block sizes
        public static const BlockSize   EighthK  = {128-1},
                                        QuarterK = {256-1},
                                        HalfK    = {512-1},
                                        OneK     = {1024*1-1},
                                        TwoK     = {1024*2-1},
                                        FourK    = {1024*4-1},
                                        EightK   = {1024*8-1},
                                        SixteenK = {1024*16-1},
                                        ThirtyTwoK = {1024*32-1},
                                        SixtyFourK = {1024*64-1};


        /**********************************************************************

                Construct a HashFile with the provided path, record-size,
                and inital record count. The latter causes records to be 
                pre-allocated, saving a certain amount of growth activity.
                Selecting a record size that roughly matches the serialized 
                content will limit 'thrashing'. 

        **********************************************************************/

        this (char[] path, BlockSize block, uint initialRecords = 100)
        {
                this.block = block;

                // open a storage file
                file = new MappedFile (path);

                // set initial file size (cannot be zero)
                fileSize = initialRecords * (block.capacity + 1);

                // map the file content
                heap = file.resize (fileSize);
        }

        /**********************************************************************
        
                Return where the HashFile is located

        **********************************************************************/

        final char[] path ()
        {
                return file.path;
        }

        /**********************************************************************

                Return the currently populated size of this HashFile

        **********************************************************************/

        final ulong length ()
        {
                return waterLine;
        }

        /**********************************************************************

                Return the serialized data for the provided key. Returns
                null if the key was not found.

                Be sure to synchronize access by multiple threads

        **********************************************************************/

        final V get (K key, bool clear = false)
        {
                auto p = key in map;

                if (p)
                    return p.read (this, clear);
                return V.init;
        }

        /**********************************************************************

                Remove the provided key from this HashFile. Leaves a 
                hole in the backing file

                Be sure to synchronize access by multiple threads

        **********************************************************************/

        final void remove (K key)
        {
                map.remove (key);
        }

        /**********************************************************************

                Write a serialized block of data, and associate it with
                the provided key. All keys must be unique, and it is the
                responsibility of the programmer to ensure this. Reusing 
                an existing key will overwrite previous data. 

                Note that data is allowed to grow within the occupied 
                bucket until it becomes larger than the allocated space.
                When this happens, the data is moved to a larger bucket
                at the file tail.

                Be sure to synchronize access by multiple threads

        **********************************************************************/

        final void put (K key, V data, K function(K) retain = null)
        {
                auto r = key in map;
                
                if (r)
                    r.write (this, data, block);
                else
                   {
                   Record rr;
                   rr.write (this, data, block);
                   if (retain)
                       key = retain (key);
                   map [key] = rr;
                   }
        }

        /**********************************************************************

                Close this HashFile -- all content is lost.

        **********************************************************************/

        final void close ()
        {
                if (file)
                   {
                   file.close;
                   file = null;
                   map = null;
                   }
        }

        /**********************************************************************

                Each Record takes up a number of 'pages' within the file. 
                The size of these pages is determined by the BlockSize 
                provided during HashFile construction. Additional space
                at the end of each block is potentially wasted, but enables 
                content to grow in size without creating a myriad of holes.

        **********************************************************************/

        private struct Record
        {
                private ulong           offset;
                private int             used,
                                        capacity = -1;

                /**************************************************************

                        This should be protected from thread-contention at
                        a higher level.

                **************************************************************/

                V read (HashFile bucket, bool clear)
                {
                        if (used)
                           {
                           auto ret = cast(V) bucket.heap [offset .. offset + used];
                           if (clear)
                               used = 0;
                           return ret;
                           }
                        return V.init;
                }

                /**************************************************************

                        This should be protected from thread-contention at
                        a higher level.

                **************************************************************/

                void write (HashFile bucket, V data, BlockSize block)
                {
                        this.used = data.length;

                        // create new slot if we exceed capacity
                        if (this.used > this.capacity)
                            createBucket (bucket, this.used, block);

                        bucket.heap [offset .. offset+used] = cast(ubyte[]) data;
                }

                /**************************************************************

                **************************************************************/

                void createBucket (HashFile bucket, int bytes, BlockSize block)
                {
                        this.offset = bucket.waterLine;
                        this.capacity = (bytes + block.capacity) & ~block.capacity;
                        
                        bucket.waterLine += this.capacity;
                        if (bucket.waterLine > bucket.fileSize)
                           {
                           auto target = bucket.waterLine * 2;
                           debug(HashFile) 
                                 printf ("growing file from %lld, %lld, to %lld\n", 
                                          bucket.fileSize, bucket.waterLine, target);

                           // expand the physical file size and remap the heap
                           bucket.heap = bucket.file.resize (bucket.fileSize = target);
                           }
                }
        }
}


/******************************************************************************

******************************************************************************/

debug (HashFile)
{
        extern(C) int printf (char*, ...);

        import tango.io.Path;
        import tango.io.Stdout;
        import tango.text.convert.Integer;

        void main()
        {
                alias HashFile!(char[], char[]) Bucket;

                auto file = new Bucket ("foo.map", Bucket.QuarterK, 1);
        
                char[16] tmp;
                for (int i=1; i < 1024; ++i)
                     file.put (format(tmp, i).dup, "blah");

                auto s = file.get ("1", true);
                if (s.length)
                    Stdout.formatln ("result '{}'", s);
                s = file.get ("1");
                if (s.length)
                    Stdout.formatln ("result '{}'", s);
                file.close;
                remove ("foo.map");
        }
}

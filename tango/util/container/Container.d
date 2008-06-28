/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2008: Initial release

        authors:        Kris

*******************************************************************************/

module tango.util.container.Container;

private import tango.core.Memory;

private import tango.stdc.stdlib;

/*******************************************************************************

        Utility functions and constants

*******************************************************************************/

struct Container
{
        /***********************************************************************
        
               default initial number of buckets of a non-empty hashmap

        ***********************************************************************/
        
        static int defaultInitialBuckets = 31;

        /***********************************************************************

                default load factor for a non-empty hashmap. The hash 
                table is resized when the proportion of elements per 
                buckets exceeds this limit
        
        ***********************************************************************/
        
        static float defaultLoadFactor = 0.75f;

        /***********************************************************************
        
                generic value reaper, which does nothing

        ***********************************************************************/
        
        static void reap(V) (V v) {}

        /***********************************************************************
        
                generic key/value reaper, which does nothing

        ***********************************************************************/
        
        static void reap(K, V) (K k, V v) {}

        /***********************************************************************

                generic hash function, using the default hashing. Thanks
                to 'mwarning' for the optimization suggestion

        ***********************************************************************/

        static uint hash(K) (K k, uint length)
        {
                static if (is(K : int) || is(K : uint) || 
                           is(K : long) || is(K : ulong) || 
                           is(K : short) || is(K : ushort) ||
                           is(K : byte) || is(K : ubyte) ||
                           is(K : char) || is(K : wchar) || is (K : dchar))
                           return cast(uint) (k % length);
                else
                   return (typeid(K).getHash(&k) & 0x7FFFFFFF) % length;
        }

        /***********************************************************************
        
                generic GC allocation manager
                
        ***********************************************************************/
        
        struct Collect(T)
        {
                /***************************************************************
        
                        allocate a T sized memory chunk
                        
                ***************************************************************/
        
                T* allocate ()
                {       
                        return cast(T*) GC.calloc (T.sizeof);
                }
        
                /***************************************************************
        
                        allocate an array of T sized memory chunks
                        
                ***************************************************************/
        
                T*[] allocate (uint count)
                {
                        return new T*[count];
                }
        
                /***************************************************************
        
                        Invoked when a specific T[] is discarded
                        
                ***************************************************************/
        
                void collect (T* p)
                {
                        if (p)
                            delete p;
                }
        
                /***************************************************************
        
                        Invoked when a specific T[] is discarded
                        
                ***************************************************************/
        
                void collect (T*[] t)
                {      
                        if (t)
                            delete t;
                }

                /***************************************************************
        
                        Invoked when clear/reset is called on the host. 
                        This is a shortcut to clear everything allocated.
        
                        Should return true if supported, or false otherwise. 
                        False return will cause a series of discrete collect
                        calls

                ***************************************************************/
        
                bool collect (bool all = true)
                {
                        return false;
                }
        }        
        
                
        /***********************************************************************
        
                Malloc allocation manager.

                Note that, due to GC behaviour, you should not configure
                a custom allocator for containers holding anything managed
                by the GC. For example, you cannot use a MallocAllocator
                to manage a container of classes or strings where those 
                were allocated by the GC. Once something is owned by a GC
                then it's lifetime must be managed by GC-managed entities
                (otherwise the GC may think there are no live references
                and prematurely collect container contents).
        
                You can explicity manage the collection of keys and values
                yourself by providing a reaper delegate. For example, if 
                you use a MallocAllocator to manage key/value pairs which
                are themselves allocated via malloc, then you should also
                provide a reaper delegate to collect those as required.      
                
        ***********************************************************************/
        
        struct Malloc(T)
        {
                /***************************************************************
        
                        allocate an array of T sized memory chunks
                        
                ***************************************************************/
        
                T* allocate ()
                {
                        return cast(T*) calloc (1, T.sizeof);
                }
        
                /***************************************************************
        
                        allocate an array of T sized memory chunks
                        
                ***************************************************************/
        
                T*[] allocate (uint count)
                {
                        return (cast(T**) calloc(count, (T*).sizeof)) [0 .. count];
                }
        
                /***************************************************************
        
                        Invoked when a specific T[] is discarded
                        
                ***************************************************************/
        
                void collect (T*[] t)
                {      
                        if (t.length)
                            free (t.ptr);
                }

                /***************************************************************
        
                        Invoked when a specific T[] is discarded
                        
                ***************************************************************/
        
                void collect (T* p)
                {       
                        if (p)
                            free (p);
                }
        
                /***************************************************************
        
                        Invoked when clear/reset is called on the host. 
                        This is a shortcut to clear everything allocated.
        
                        Should return true if supported, or false otherwise. 
                        False return will cause a series of discrete collect
                        calls
                        
                ***************************************************************/
        
                bool collect (bool all = true)
                {
                        return false;
                }
        }        
        
        
        /***********************************************************************
        
                Chunk allocator

                Can save approximately 30% memory for small elements (tested 
                with integer elements and a chunk size of 1000), and is at 
                least twice as fast at adding elements when compared to the 
                default allocator (approximately 50x faster with LinkedList)
        
                Note that, due to GC behaviour, you should not configure
                a custom allocator for containers holding anything managed
                by the GC. For example, you cannot use a MallocAllocator
                to manage a container of classes or strings where those 
                were allocated by the GC. Once something is owned by a GC
                then it's lifetime must be managed by GC-managed entities
                (otherwise the GC may think there are no live references
                and prematurely collect container contents).
        
                You can explicity manage the collection of keys and values
                yourself by providing a reaper delegate. For example, if 
                you use a MallocAllocator to manage key/value pairs which
                are themselves allocated via malloc, then you should also
                provide a reaper delegate to collect those as required.
        
        ***********************************************************************/
        
        struct Chunk(T)
        {
                private T[]     list;
                private T[][]   lists;
                private int     index;
                private int     freelists;
                private int     presize = 0;
                private int     chunks = 1000;

                private struct Discarded
                {
                        Discarded* next;
                }
                private Discarded* discarded;
                
                /***************************************************************
        
                        set the chunk size and preallocate lists
                        
                ***************************************************************/
        
                void config (int chunks, int presize)
                {
                        this.chunks = chunks;
                        this.presize = presize;
                        lists.length = presize;

                        foreach (ref list; lists)
                                 list = block;
                }
        
                /***************************************************************
        
                        allocate an array of T sized memory chunks
                        
                ***************************************************************/

                T* allocate ()
                {
                        if (index >= list.length)
                            if (discarded)
                               {    
                               auto p = discarded;
                               discarded = p.next;
                               return cast(T*) p;
                               }
                            else
                               newlist;
       
                        return (&list[index++]);
                }
        
                /***************************************************************
        
                        allocate an array of T sized memory chunks
                        
                ***************************************************************/
        
                T*[] allocate (uint count)
                {
                        return (cast(T**) calloc(count, (T*).sizeof)) [0 .. count];
                }
        
                /***************************************************************
        
                        Invoked when a specific T[] is discarded
                        
                ***************************************************************/
        
                void collect (T*[] t)
                {      
                        if (t.length)
                            free (t.ptr);
                }

                /***************************************************************
        
                        Invoked when a specific T is discarded
                        
                ***************************************************************/
        
                void collect (T* p)
                {      
                        if (p)
                           {
                           assert (T.sizeof >= (T*).sizeof);
                           auto d = cast(Discarded*) p;
                           d.next = discarded;
                           discarded = d;
                           }
                }
        
                /***************************************************************
        
                        Invoked when clear/reset is called on the host. 
                        This is a shortcut to clear everything allocated.
        
                        Should return true if supported, or false otherwise. 
                        False return will cause a series of discrete collect
                        calls
                        
                ***************************************************************/
        
                bool collect (bool all = true)
                {
                        freelists = 0;
                        newlist;
                        if (all)
                           {
                           foreach (list; lists)
                                    free (list.ptr);
                           lists.length = 0;
                           }
                        return true;
                }
              
                /***************************************************************
        
                        list manager
                        
                ***************************************************************/
        
                private void newlist ()
                {
                        index = 0;
                        if (freelists >= lists.length)
                           {
                           lists.length = lists.length + 1;
                           lists[$-1] = block;
                           }
                        list = lists[freelists++];
                }
        
                /***************************************************************
        
                        list allocator
                        
                ***************************************************************/
        
                private T[] block ()
                {
                        return (cast(T*) calloc (chunks, T.sizeof)) [0 .. chunks];
                }
        }        
}


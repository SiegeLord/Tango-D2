/*******************************************************************************

        @file PlainCache.d
        
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


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version, April 2004      
        @author         Kris


*******************************************************************************/

module mango.net.servlet.cache.PlainCache;

public  import  mango.net.servlet.cache.HashMap;

public  import  mango.net.servlet.cache.model.ICache,
                mango.net.servlet.cache.model.IPayload;

/******************************************************************************

        A base-class for the cache framework, using a thread-aware hash map
        to contain the cache entries. Cache entries must be instances of the 
        IPayload interface; this allows them to be moved around the network
        or serialized onto some external medium.

******************************************************************************/

class PlainCache : IMutableCache
{
        private HashMap map;

        /**********************************************************************

                Construct a basic cache with the specified number of 
                preallocated entries. The concurrency level indicates
                approximately how many threads will content for write
                access at one time.

        **********************************************************************/

        this (uint capacity = 101, uint concurrency = 16)
        {
                map = new HashMap (capacity, 0.75, concurrency);
        }

        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        IPayload get (char[] key)
        {       
                // cast to void* first to avoid overhead
                return cast (IPayload) cast(void*) map.get (key);
        }

        /**********************************************************************

                Place an entry into the cache and associate it with the
                provided key. Note that there can be only one entry for
                any particular key. If two keys entries are added with
                the same key, the second effectively overwrites the first.

                Returns what it was given

        **********************************************************************/

        IPayload put(char[] key, IPayload entry)
        {
                map.put (key, cast(Object) entry);
                return entry;
        }

        /**********************************************************************

                Remove (and return) the cache entry associated with the 
                provided key. Returns null if there is no such entry.

        **********************************************************************/

        IPayload extract (char[] key)
        {
                // cast to void* first to avoid overhead
                return cast(IPayload) cast(void*) map.remove (key);
        }

        /**********************************************************************

                Remove (and return) the cache entry associated with the 
                provided key. Returns null if there is no such entry.

        **********************************************************************/

        IPayload extract (char[] key, ulong timeLimit)
        {
                // cast to void* first to avoid overhead
                IPayload e = cast(IPayload) cast(void*) map.get (key);

                if (e)
                   {
                   // ignore if existing entry is newer
                   if (e.getTime > timeLimit)
                       return null;

                   // remove the entry from array, and return it
                   map.remove (key);
                   }
                return e;
        }

        /**********************************************************************

        **********************************************************************/

        ICache bind (ICacheLoader loader)
        {
                class PlainLoader : ICache
                {
                        IMutableCache   cache;
                        ICacheLoader    loader;

                        /******************************************************

                        ******************************************************/

                        this (IMutableCache cache, ICacheLoader loader)
                        {
                                this.cache = cache;
                                this.loader = loader;
                        }

                        /******************************************************

                        ******************************************************/

                        IPayload get (char[] key)
                        {
                                ulong t;

                                IPayload p = cache.get (key);
                                
                                if (p)
                                   {
                                   if (loader.test (p))
                                       return p;
                                   t = p.getTime ();
                                   }
                                
                                p = loader.load (key, t);
                                if (p)
                                    cache.put (key, p);
                                return p;
                        }
                }

                return new PlainLoader (this, loader);
        }
}



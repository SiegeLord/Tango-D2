/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.cache.model.ICache;

private import mango.net.servlet.cache.model.IPayload;

/******************************************************************************

        Defines what a cache instance exposes. We try to keep the basic
        operations to a reasonable minimum.

******************************************************************************/

interface ICache
{
        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        IPayload get (char[] key);
}


/******************************************************************************

        Defines what a modifiable cache instance exposes

******************************************************************************/

interface IMutableCache : ICache
{
        /**********************************************************************

                Place an entry into the cache and associate it with the
                provided key. Note that there can be only one entry for
                any particular key. If two keys entries are added with
                the same key, the second effectively overwrites the first.

                Returns what it was given

        **********************************************************************/

        IPayload put (char[] key, IPayload entry);

        /**********************************************************************

                Remove (and return) the cache entry associated with the 
                provided key. The entry will not be removed if it's time
                attribute is newer than the (optional) specified 'timelimit'. 

                Returns null if there is no such entry. 

        **********************************************************************/

        IPayload extract (char[] key, ulong timeLimit = ulong.max);

        /**********************************************************************

                This is a factory for producing an ICache instance upon
                the cache content. The provided loader will populate the
                cache whenever a stale or missing entry is seen

        **********************************************************************/

        ICache bind (ICacheLoader loader);
}


/******************************************************************************

        Manages the lifespan of an ICache entry. These loaders effectively
        isolate the cache from whence the content is derived. It's a good
        idea to employ this abstraction where appropriate, since it allows
        the cache source to change with minimal (if any) impact on client
        code.

******************************************************************************/

interface ICacheLoader
{
        /**********************************************************************

                Test the cache entry to see if it is still valid. A true
                return value indicates the entry is valid, whereas false
                flags the entry as stale. The latter case will cause the
                load() method to be invoked.

        **********************************************************************/

        bool test (IPayload p);

        /**********************************************************************

                Load a cache entry from wherever the content is persisted.
                The 'time' argument represents that belonging to a stale
                entry, which can be used to optimize the loader operation
                (no need to perform a full load where there's already a 
                newer version in an L2 cache). This 'time' value will be
                long.min where was no such stale entry.

        **********************************************************************/

        IPayload load (char[] key, ulong time);
}


/******************************************************************************

        Manages the loading of ICache entries remotely, on the device
        that actually contains the remote cache entry. The benefit of
        this approach lies in the ability to 'gate' access to specific
        resources across the entire network. That is; where particular
        entries are prohibitively costly to construct, it's worthwhile
        ensuring that cost is reduced to a bare minimum. These remote
        loaders allow the cache host to block multiple network clients
        until there's a new entry available. Without this mechanism, 
        it's possible for multiple network clients to request the same
        entry simultaneously; therefore increasing the overall cost. 
        The end result is similar to that of a distributed-transaction.
         
******************************************************************************/

interface IRemoteCacheLoader : IPayload, ICacheLoader
{
        /**********************************************************************
        
                Return the sleep duration between attempts to retrieve 
                a locked cache entry. Consider setting this duration to
                be approximately half the time you'd expect each remote 
                cache-load to typically consume. The 'wait' argument is
                a representation of how many microseconds have added up
                while waiting. When this value exceeds some limit, you
                should return zero to indicate a timeout condition.

                Note that the return value should be in microseconds ~  
                one tenth of a second equals 100_000 microseconds. Note
                also that you might consider returning a sliding value,
                where the pause starts off small, and increases as time
                passes. A simple implementation might look like this:

                @code
                return (wait > 2_000_000) ? 0 : 10_000 + wait / 2;
                @endcode

        **********************************************************************/

        uint pause (uint wait);
}


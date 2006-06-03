/*******************************************************************************

        @file QueuedCache.d
        
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

module tango.net.servlet.cache.QueuedCache;

private import  tango.net.servlet.cache.Payload,
                tango.net.servlet.cache.PlainCache;

private import  tango.net.servlet.cache.model.IPayload;

/******************************************************************************

        QueuedCache extends the basic cache type by adding a limit to 
        the number of items contained at any given time. In addition, 
        QueuedCache sorts the cache entries such that those entries 
        frequently accessed are at the head of the queue, and those
        least frequently accessed are at the tail. When the queue 
        becomes full, old entries are dropped from the tail and are 
        reused to house new cache entries.

        This is great for keeping commonly accessed items around, while
        limiting the amount of memory used. Typically, the queue size 
        would be set in the hundreds (perhaps thousands). 

******************************************************************************/

class QueuedCache : PlainCache
{
        // head and tail of queue
        private QueuedEntry     head,
                                tail;

        // dimension of queue
        private int             entries,
                                capacity;

        /**********************************************************************

                Construct a cache with the specified maximum number of 
                entries. Additions to the cache beyond this number will
                reuse the slot of the least-recently-referenced cache
                entry. The concurrency level indicates approximately how 
                many threads will content for write access at one time.

        **********************************************************************/

        this (uint capacity, uint concurrency = 16)
        {
                super (capacity, concurrency);
                this.capacity = capacity;
        }

        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        override IPayload get (char[] key)
        in {
           assert (key.length);
           }
        body
        {
                // cast to void* first to avoid overhead
                QueuedEntry entry = cast(QueuedEntry) cast(void*) super.get (key);

                // if we find 'key' then move it to the list head
                if (entry)
                    return reReference (entry).entry;
                return null;
        }

        /**********************************************************************

                Place an entry into the cache and associate it with the
                provided key. Note that there can be only one entry for
                any particular key. If two entries are added with the 
                same key, the second effectively overwrites the first.

                Returns what it was given

        **********************************************************************/

        override IPayload put (char[] key, IPayload item)
        in {
           assert (key.length);
           assert (item);
           }
        body
        {
                IPayload e = super.get (key);

                // already in the list? -- replace entry
                if (e)
                   {
                   // cast to void* first to avoid overhead
                   QueuedEntry q = cast(QueuedEntry) cast(void*) e;

                   // set the new item for this key and move to list head
                   q.set (key, item);
                   reReference (q);
                   }
                else
                   // create a new entry at the list head 
                   super.put (key, addEntry (key, item));
                return item;
        }

        /**********************************************************************

                Remove (and return) the cache entry associated with the 
                provided key. Returns null if there is no such entry.

        **********************************************************************/

        override IPayload extract (char[] key, ulong timeLimit = ulong.max)
        in {
           assert (key.length);
           }
        body
        {
                // remove from the lookup table
                // cast to void* first to avoid overhead
                QueuedEntry old = cast(QueuedEntry) cast(void*) super.extract (key, timeLimit);

                // don't actually kill the list entry -- just place
                // it at the list 'tail' ready for subsequent reuse
                if (old)
                   {
                   IPayload e = deReference (old).entry;
                   old.set (null, null);
                   return e;
                   }

                return null;
        }

        /**********************************************************************

                Overridable factory for creating list entries.

        **********************************************************************/

        QueuedEntry createQueuedEntry (char[] key, IPayload entry)
        in {
           assert (key.length);
           assert (entry);
           }
        body
        {
                return new QueuedEntry (key, entry);
        }

        /**********************************************************************

                Place a cache entry at the tail of the queue. This makes
                it the least-recently referenced.

        **********************************************************************/

        private final QueuedEntry deReference (QueuedEntry entry)
        {
                if (! (entry is tail))
                   {
                   // adjust head
                   if (entry is head)
                       head = entry.next;

                   // move to tail
                   entry.extract ();
                   tail = entry.append (tail);
                   }
                return entry;
        }

        /**********************************************************************

                Move a cache entry to the head of the queue. This makes
                it the most-recently referenced.

        **********************************************************************/

        private final QueuedEntry reReference (QueuedEntry entry)
        {
                if (! (entry is head))
                   {
                   // adjust tail
                   if (entry is tail)
                       tail = entry.prev;

                   // move to head
                   entry.extract ();
                   head = entry.prepend (head);
                   }
                return entry;
        }

        /**********************************************************************

                Add an entry into the queue. If the queue is full, the
                least-recently-referenced entry is reused for the new
                addition. 

        **********************************************************************/

        private final QueuedEntry addEntry (char[] key, IPayload item)
        {
                QueuedEntry entry;

                if (entries < capacity)
                   {
                   // create a new item
                   entry = createQueuedEntry (key, item);

                   // set 'head' & 'tail' if first item in list. We need to
                   // do this before reReference() is invoked so it doesn't
                   // have to do "first item" checks itself
                   if (++entries == 1)
                       head = tail = entry;
                   }
                else
                   if (capacity > 0)
                      {
                      // steal from tail ...
                      entry = tail;

                      // we're re-using an old QueuedEntry, so remove
                      // the old name from the hash-table first
                      super.extract (entry.key);

                      // replace old content with new (also destroy old)
                      entry.reuse (key, item);
                      }
                   else
                      return null;

                // place at head of list
                return reReference (entry);
        }
}


/******************************************************************************

        A doubly-linked list entry, used as a wrapper for queued cache 
        entries. Note that this class itself is a valid cache entry.

******************************************************************************/

protected class QueuedEntry : Payload
{
        protected char[]        key;
        protected QueuedEntry   prev,
                                next;
        protected IPayload      entry;

        /**********************************************************************

                Construct a new linked-list entry around the provided 
                IPayload instance, and associate it with the given
                key. Note that the key is held here such that it can
                be referenced by sub-classes which override the reuse()
                method.
        
        **********************************************************************/

        this (char[] key, IPayload entry)
        {
                this.key = key;
                this.entry = entry;
        }

        /**********************************************************************

                Set this linked-list entry with the given arguments. Note
                that the original content is released via a destroy() call.

        **********************************************************************/

        protected void set (char[] key, IPayload entry)
        {
                // destroy any existing object first
                if (! (this.entry is entry))
                       destroy ();

                this.entry = entry;
                this.key = key;
        }

        /**********************************************************************

                Overridable method to reuse this linked-list entry. The
                default behavior is to destroy() the original content.

        **********************************************************************/

        protected void reuse (char[] key, IPayload entry)
        {
                set (key, entry);
        }

        /**********************************************************************

                Insert this entry into the linked-list just in front of
                the given entry.

        **********************************************************************/

        protected QueuedEntry prepend (QueuedEntry before)
        in {
           assert (before);
           }
        body
        {
                if (before)
                   {
                   prev = before.prev;

                   // patch 'prev' to point at me
                   if (prev)
                       prev.next = this;

                   //patch 'before' to point at me
                   next = before;
                   before.prev = this;
                   }
                return this;
        }

        /**********************************************************************
                
                Add this entry into the linked-list just after the given
                entry.

        **********************************************************************/

        protected QueuedEntry append (QueuedEntry after)
        in {
           assert (after);
           }
        body
        {
                if (after)
                   {
                   next = after.next;

                   // patch 'next' to point at me
                   if (next)
                       next.prev = this;

                   //patch 'after' to point at me
                   prev = after;
                   after.next = this;
                   }
                return this;
        }

        /**********************************************************************

                Remove this entry from the linked-list. The previous and
                next entries are patched together appropriately.

        **********************************************************************/

        protected QueuedEntry extract ()
        {
                // make 'prev' and 'next' entries see each other
                if (prev)
                    prev.next = next;

                if (next)
                    next.prev = prev;

                // Murphy's law 
                next = prev = null;
                return this;
        }

        /**********************************************************************

                Return the key belonging to this entry.

        **********************************************************************/

        override char[] toString()
        {
                return key;
        }

        /**********************************************************************

                Destroy this linked list entry by invoking destroy() on the
                wrapped IPayload.

        **********************************************************************/

        protected void destroy()
        {
                if (entry)
                   {
                   entry.destroy ();
                   this.entry = null;
                   }
        }
}


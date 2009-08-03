/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2008: Initial release

        authors:        Kris

        Since:          0.99.7

        Based upon Doug Lea's Java collection package

*******************************************************************************/

module tango.util.container.CircularList;

private import tango.util.container.Clink;

public  import  tango.util.container.Container;

private import tango.util.container.model.IContainer;

/*******************************************************************************

        Circular linked list

        ---
        Iterator iterator ()
        uint opApply (int delegate(ref V value) dg)

        CircularList add (V element)
        CircularList addAt (uint index, V element)
        CircularList append (V element)
        CircularList prepend (V element)
        uint addAt (uint index, IContainer!(V) e)
        uint append (IContainer!(V) e)
        uint prepend (IContainer!(V) e)

        bool take (ref V v)
        bool contains (V element)
        V get (uint index)
        uint first (V element, uint startingIndex = 0)
        uint last (V element, uint startingIndex = 0)

        V head ()
        V tail ()
        V head (V element)
        V tail (V element)
        V removeHead ()
        V removeTail ()

        bool removeAt (uint index)
        uint remove (V element, bool all)
        uint removeRange (uint fromIndex, uint toIndex)

        uint replace (V oldElement, V newElement, bool all)
        bool replaceAt (uint index, V element)

        uint size ()
        bool isEmpty ()
        V[] toArray (V[] dst)
        CircularList dup ()
        CircularList subset (uint from, uint length)
        CircularList clear ()
        CircularList reset ()
        CircularList check ()
        ---

*******************************************************************************/

class CircularList (V, alias Reap = Container.reap, 
                       alias Heap = Container.DefaultCollect) 
                       : IContainer!(V)
{
        // use this type for Allocator configuration
        public alias Clink!(V)  Type;
        
        private alias Type      *Ref;

        private alias Heap!(Type) Alloc;

        // number of elements contained
        private uint            count;

        // configured heap manager
        private Alloc           heap;
        
        // mutation tag updates on each change
        private uint            mutation;

        // head of the list. Null if empty
        private Ref             list;


        /***********************************************************************

                Make an empty list

        ***********************************************************************/

        this ()
        {
                this (null, 0);
        }

        /***********************************************************************

                Make an configured list

        ***********************************************************************/

        protected this (Ref h, uint c)
        {
                list = h;
                count = c;
        }

        /***********************************************************************

                Clean up when deleted

        ***********************************************************************/

        ~this ()
        {
                reset;
        }

        /***********************************************************************

                Return the configured allocator
                
        ***********************************************************************/

        final Alloc allocator ()
        {
                return heap;
        }

        /***********************************************************************

                Return a generic iterator for contained elements
                
        ***********************************************************************/

        final Iterator iterator ()
        {
                // used to be Iterator i = void, but that doesn't initialize
                // fields that are not initialized here.
                Iterator i;
                i.mutation = mutation;
                i.owner = this;
                i.cell = list;
                i.head = list;
                i.bump = &Iterator.fore;
                return i;
        }

        /***********************************************************************


        ***********************************************************************/

        final int opApply (int delegate(ref V value) dg)
        {
                return iterator.opApply (dg);
        }

        /***********************************************************************

                Return the number of elements contained
                
        ***********************************************************************/

        final uint size ()
        {
                return count;
        }
        
        /***********************************************************************

                Make an independent copy of the list. Elements themselves 
                are not cloned

        ***********************************************************************/

        final CircularList dup ()
        {
                return new CircularList!(V, Reap, Heap) (list ? list.copyList(&heap.allocate) : null, count);
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final bool contains (V element)
        {
                if (list)
                    return list.find (element) !is null;
                return false;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V head ()
        {
                return firstCell.value;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V tail ()
        {
                return lastCell.value;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final V get (uint index)
        {
                return cellAt(index).value;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final uint first (V element, uint startingIndex = 0)
        {
                if (startingIndex < 0)
                    startingIndex = 0;

                auto p = list;
                if (p is null)
                    return uint.max;

                for (uint i = 0; true; ++i)
                    {
                    if (i >= startingIndex && element == p.value)
                        return i;

                    p = p.next;
                    if (p is list)
                        break;
                    }
                return uint.max;
        }

        /***********************************************************************
                
                Time complexity: O(n)

        ***********************************************************************/

        final uint last (V element, uint startingIndex = 0)
        {
                if (count is 0)
                    return uint.max;

                if (startingIndex >= count)
                    startingIndex = count - 1;

                if (startingIndex < 0)
                    startingIndex = 0;

                auto p = cellAt (startingIndex);
                uint i = startingIndex;
                for (;;)
                    {
                    if (element == p.value)
                        return i;
                    else
                       if (p is list)
                           break;
                       else
                          {
                          p = p.prev;
                          --i;
                          }
                    }
                return uint.max;
        }

        /***********************************************************************

                Time complexity: O(length)

        ***********************************************************************/

        final CircularList subset (uint from, uint length)
        {
                Ref newlist = null;

                if (length > 0)
                   {
                   checkIndex (from);
                   auto p = cellAt (from);
                   auto current = newlist = heap.allocate.set (p.value);

                   for (uint i = 1; i < length; ++i)
                       {
                       p = p.next;
                       if (p is null)
                           length = i;
                       else
                          {
                          current.addNext (p.value, &heap.allocate);
                          current = current.next;
                          }
                       }
                   }

                return new CircularList (newlist, length);
        }

        /***********************************************************************

                 Time complexity: O(1)

        ***********************************************************************/

        final CircularList clear ()
        {
                return clear (false);
        }

        /***********************************************************************

                Reset the HashMap contents and optionally configure a new
                heap manager. This releases more memory than clear() does

                Time complexity: O(n)
                
        ***********************************************************************/

        final CircularList reset ()
        {
                return clear (true);
        }

        /***********************************************************************

                Time complexity: O(n)

                Takes the last element on the list

        ***********************************************************************/

        final bool take (ref V v)
        {
                if (count)
                   {
                   v = tail;
                   removeTail ();
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final CircularList prepend (V element)
        {
                if (list is null)
                    list = heap.allocate.set (element);
                else
                   list = list.addPrev (element, &heap.allocate);
                increment;
                return this;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V head (V element)
        {
                auto p = firstCell;
                auto v = p.value;
                p.value = element;
                mutate;
                return v;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V removeHead ()
        {
                auto p = firstCell;
                if (p.singleton)
                   list = null;
                else
                   {
                   auto n = p.next;
                   p.unlink;
                   list = n;
                   }

                auto v = p.value;
                decrement (p);
                return v;
        }

       /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final CircularList add (V element)
        {
                return append (element);
        }

       /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final CircularList append (V element)
        {
                if (list is null)
                    prepend (element);
                else
                   {
                   list.prev.addNext (element, &heap.allocate);
                   increment;
                   }
                return this;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V tail (V element)
        {
                auto p = lastCell;
                auto v = p.value;
                p.value = element;
                mutate;
                return v;
        }

        /***********************************************************************

                Time complexity: O(1)

        ***********************************************************************/

        final V removeTail ()
        {
                auto p = lastCell;
                if (p is list)
                    list = null;
                else
                   p.unlink;

                auto v = p.value;
                decrement (p);
                return v;
        }

        /***********************************************************************
                
                Time complexity: O(n)

        ***********************************************************************/

        final CircularList addAt (uint index, V element)
        {
                if (index is 0)
                    prepend (element);
                else
                   {
                   cellAt(index - 1).addNext(element, &heap.allocate);
                   increment;
                   }
                return this;
        }

        /***********************************************************************
                
                Time complexity: O(n)

        ***********************************************************************/

        final CircularList replaceAt (uint index, V element)
        {
                cellAt(index).value = element;
                mutate;
                return this;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final CircularList removeAt (uint index)
        {
                if (index is 0)
                    removeHead;
                else
                   {
                   auto p = cellAt(index);
                   p.unlink;
                   decrement (p);
                   }
                return this;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final uint remove (V element, bool all)
        {
                auto c = count;
                if (list)
                   {
                   auto p = list;
                   for (;;)
                       {
                       auto n = p.next;
                       if (element == p.value)
                          {
                          p.unlink;
                          decrement (p);
                          if (p is list)
                             {
                             if (p is n)
                                {
                                list = null;
                                break;
                                }
                             else
                                list = n;
                             }
   
                          if (! all)
                                break;
                          else
                             p = n;
                          }
                       else
                          if (n is list)
                              break;
                          else
                             p = n;
                       }
                   }
                return c - count;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final uint replace (V oldElement, V newElement, bool all)
        {
                uint c;
                if (list)
                   {
                   auto p = list;
                   do {
                      if (oldElement == p.value)
                         {
                         ++c;
                         mutate;
                         p.value = newElement;
                         if (! all)
                               break;
                         }
                      p = p.next;
                      } while (p !is list);
                   }
                return c;
        }

        /***********************************************************************

                Time complexity: O(number of elements in e)

        ***********************************************************************/

        final uint prepend (IContainer!(V) e)
        {
                Ref hd = null;
                Ref current = null;
                auto c = count;

                foreach (element; e)
                        {
                        increment;

                        if (hd is null)
                           {
                           hd = heap.allocate.set(element);
                           current = hd;
                           }
                        else
                           {
                           current.addNext (element, &heap.allocate);
                           current = current.next;
                           }
                      }

                if (list is null)
                    list = hd;
                else
                   if (hd)
                      {
                      auto tl = list.prev;
                      current.next = list;
                      list.prev = current;
                      tl.next = hd;
                      hd.prev = tl;
                      list = hd;
                      }
                return count - c;
        }

        /***********************************************************************
                
                Time complexity: O(number of elements in e)

        ***********************************************************************/

        final uint append (IContainer!(V) e)
        {
                auto c = count;
                if (list is null)
                    prepend (e);
                else
                   {
                   auto current = list.prev;
                   foreach (element; e)
                           {
                           increment;
                           current.addNext (element, &heap.allocate);
                           current = current.next;
                           }
                   }
                return count - c;
        }

        /***********************************************************************

                Time complexity: O(size() + number of elements in e)

        ***********************************************************************/

        final uint addAt (uint index, IContainer!(V) e)
        {
                auto c = count;
                if (list is null || index is 0)
                    prepend (e);
                else
                   {
                   auto current = cellAt (index - 1);
                   foreach (element; e)
                           {
                           increment;
                           current.addNext (element, &heap.allocate);
                           current = current.next;
                           }
                   }
                return count - c;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        final uint removeRange (uint fromIndex, uint toIndex)
        {
                auto p = cellAt (fromIndex);
                auto last = list.prev;
                auto c = count;
                for (uint i = fromIndex; i <= toIndex; ++i)
                    {
                    auto n = p.next;
                    p.unlink;
                    decrement (p);
                    if (p is list)
                       {
                       if (p is last)
                          {
                          list = null;
                          break;
                          }
                       else
                          list = n;
                       }
                    p = n;
                    }
                return c - count;
        }

        /***********************************************************************

                Copy and return the contained set of values in an array, 
                using the optional dst as a recipient (which is resized 
                as necessary).

                Returns a slice of dst representing the container values.
                
                Time complexity: O(n)
                
        ***********************************************************************/

        final V[] toArray (V[] dst = null)
        {
                if (dst.length < count)
                    dst.length = count;

                int i = 0;
                foreach (v; this)
                         dst[i++] = v;
                return dst [0 .. count];                        
        }

        /***********************************************************************

                Is this container empty?
                
                Time complexity: O(1)
                
        ***********************************************************************/

        final bool isEmpty ()
        {
                return count is 0;
        }

        /***********************************************************************


        ***********************************************************************/

        final CircularList check()
        {
                assert(((count is 0) is (list is null)));
                assert((list is null || list.size is count));

                if (list)
                   {
                   uint c = 0;
                   auto p = list;
                   do {
                      assert(p.prev.next is p);
                      assert(p.next.prev is p);
                      assert(instances(p.value) > 0);
                      assert(contains(p.value));
                      p = p.next;
                      ++c;
                      } while (p !is list);
                   assert(c is size);
                   }
                return this;
        }

        /***********************************************************************

                Time complexity: O(n)

        ***********************************************************************/

        private uint instances (V element)
        {
                if (list)
                    return list.count (element);
                return 0;
        }

        /***********************************************************************


        ***********************************************************************/

        private void checkIndex (uint i)
        {
                if (i >= count)
                    throw new Exception ("out of range");
        }

        /***********************************************************************

                return the first cell, or throw exception if empty

        ***********************************************************************/

        private Ref firstCell ()
        {
                checkIndex (0);
                return list;
        }

        /***********************************************************************

                return the last cell, or throw exception if empty

        ***********************************************************************/

        private Ref lastCell ()
        {
                checkIndex (0);
                return list.prev;
        }

        /***********************************************************************

                 return the index'th cell, or throw exception if bad index

        ***********************************************************************/

        private Ref cellAt (uint index)
        {
                checkIndex (index);
                return list.nth (index);
        }

        /***********************************************************************

                 Time complexity: O(1)

        ***********************************************************************/

        private CircularList clear (bool all)
        {
                mutate;

                // collect each node if we can't collect all at once
                if (heap.collect(all) is false && count)
                   {
                   auto p = list;
                   do {
                      auto n = p.next;
                      decrement (p);
                      p = n;
                      } while (p != list);
                   }
        
                list = null;
                count = 0;
                return this;
        }

        /***********************************************************************

                new element was added
                
        ***********************************************************************/

        private void increment ()
        {
                ++mutation;
                ++count;
        }
        
        /***********************************************************************

                element was removed
                
        ***********************************************************************/

        private void decrement (Ref p)
        {
                Reap (p.value);
                heap.collect (p);
                ++mutation;
                --count;
        }
        
        /***********************************************************************

                set was changed
                
        ***********************************************************************/

        private void mutate ()
        {
                ++mutation;
        }

        /***********************************************************************

                Iterator with no filtering

        ***********************************************************************/

        private struct Iterator
        {
                Ref function(Ref) bump;
                Ref               cell,
                                  head,
                                  prior;
                CircularList      owner;
                uint              mutation;

                /***************************************************************

                        Did the container change underneath us?

                ***************************************************************/

                bool valid ()
                {
                        return owner.mutation is mutation;
                }               

                /***************************************************************

                        Accesses the next value, and returns false when
                        there are no further values to traverse

                ***************************************************************/

                bool next (ref V v)
                {
                        auto n = next;
                        return (n) ? v = *n, true : false;
                }
                
                /***************************************************************

                        Return a pointer to the next value, or null when
                        there are no further values to traverse

                ***************************************************************/

                V* next ()
                {
                        V* r;

                        if (cell)
                           {
                           prior = cell;
                           r = &cell.value;
                           cell = bump (cell);
                           if (cell is head)
                               cell = null;
                           }
                        return r;
                }

                /***************************************************************

                        Foreach support

                ***************************************************************/

                int opApply (int delegate(ref V value) dg)
                {
                        int result;

                        auto c = cell;
                        while (c)
                              {
                              prior = c;
                              if ((c = bump(c)) is head)
                                   c = null;
                              if ((result = dg(prior.value)) != 0)
                                   break;
                              }
                        cell = c;
                        return result;
                }                               

                /***************************************************************

                        Remove value that was just iterated.

                ***************************************************************/

                bool remove ()
                {
                        if (prior)
                           {
                           auto next = bump (prior);
                           if (prior is head)
                           {
                               if (prior is next)
                                   owner.list = null;
                               else
                                   head = owner.list = next;
                           }

                           prior.unlink;
                           owner.decrement (prior);
                           prior = null;

                           // ignore this change
                           ++mutation;
                           return true;
                           }
                        return false;
                }

                /***************************************************************

                        Insert a new value before the node about to be
                        iterated (or after the node that was just iterated).

                        Returns: a copy of this iterator for chaining.

                ***************************************************************/

                Iterator insert(V value)
                {
                    // Note: this needs some attention, not sure how
                    // to handle when iterator is in reverse.
                    if(cell is null)
                        prior.addNext(value, &owner.heap.allocate);
                    else
                        cell.addPrev(value, &owner.heap.allocate);
                    owner.increment;

                    //
                    // ignore this change
                    //
                    mutation++;
                    return *this;
                }

                /***************************************************************

                ***************************************************************/

                Iterator reverse ()
                {
                        if (bump is &fore)
                            bump = &back;
                        else
                           bump = &fore;
                        return *this;
                }

                /***************************************************************

                ***************************************************************/

                private static Ref fore (Ref p)
                {
                        return p.next;
                }

                /***************************************************************

                ***************************************************************/

                private static Ref back (Ref p)
                {
                        return p.prev;
                }
        }
}

debug (UnitTest)
{
    unittest
    {
        auto list = new CircularList!(int);
        list.add(1);
        list.add(2);
        list.add(3);

        int i = 1;
        foreach(v; list)
        {
            assert(v == i);
            i++;
        }

        auto iter = list.iterator;
        iter.next();
        iter.remove();                          // delete the first item

        i = 2;
        foreach(v; list)
        {
            assert(v == i);
            i++;
        }

        // test insert functionality
        iter = list.iterator;
        iter.next;
        iter.insert(4);

        int[] compareto = [2, 4, 3];
        i = 0;
        foreach(v; list)
        {
            assert(v == compareto[i++]);
        }
    }
}

/*******************************************************************************

*******************************************************************************/

debug (CircularList)
{
        import tango.io.Stdout;
        import tango.core.Thread;
        import tango.time.StopWatch;

        void main()
        {
                // usage examples ...
                auto list = new CircularList!(char[]);
                foreach (value; list)
                         Stdout (value).newline;

                list.add ("foo");
                list.add ("bar");
                list.add ("wumpus");

                // implicit generic iteration
                foreach (value; list)
                         Stdout (value).newline;

                // explicit generic iteration   
                foreach (value; list.iterator.reverse)
                         Stdout.formatln ("> {}", value);

                // generic iteration with optional remove
                auto s = list.iterator;
                foreach (value; s)
                         {} //s.remove;

                // incremental iteration, with optional remove
                char[] v;
                auto iterator = list.iterator;
                while (iterator.next(v))
                       {}//iterator.remove;
                
                // incremental iteration, with optional failfast
                auto it = list.iterator;
                while (it.valid && it.next(v))
                      {}

                // remove specific element
                list.remove ("wumpus", false);

                // remove first element ...
                while (list.take(v))
                       Stdout.formatln ("taking {}, {} left", v, list.size);
                
                
                // setup for benchmark, with a set of integers. We
                // use a chunk allocator, and presize the bucket[]
                auto test = new CircularList!(uint, Container.reap, Container.Chunk);
                test.allocator.config (1000, 1000);
                const count = 1_000_000;
                StopWatch w;

                // benchmark adding
                w.start;
                for (uint i=count; i--;)
                     test.add(i);
                Stdout.formatln ("{} adds: {}/s", test.size, test.size/w.stop);

                // benchmark adding without allocation overhead
                test.clear;
                w.start;
                for (uint i=count; i--;)
                     test.add(i);
                Stdout.formatln ("{} adds (after clear): {}/s", test.size, test.size/w.stop);

                // benchmark duplication
                w.start;
                auto dup = test.dup;
                Stdout.formatln ("{} element dup: {}/s", dup.size, dup.size/w.stop);

                // benchmark iteration
                w.start;
                foreach (value; test) {}
                Stdout.formatln ("{} element iteration: {}/s", test.size, test.size/w.stop);

                test.check;
        }
}

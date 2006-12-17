/*
 File: HashSet.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.HashSet;

private import  tango.util.collection.Exception;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.HashParams,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.LLCell,
                tango.util.collection.impl.SetCollection,
                tango.util.collection.impl.AbstractIterator;


/**
 *
 * Hash table implementation of set
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class HashSet(T) : SetCollection!(T), HashParams
{
        private alias LLCell!(T) LLCellT;


        // instance variables

        /**
         * The table. Each entry is a list. Null if no table allocated
        **/
        private LLCellT table[];
        /**
         * The threshold load factor
        **/
        private float loadFactor;


        // constructors

        /**
         * Make an empty HashedSet.
        **/

        public this ()
        {
                this(null, defaultLoadFactor);
        }

        /**
         * Make an empty HashedSet using given element screener
        **/

        public this (Predicate screener)
        {
                this(screener, defaultLoadFactor);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, float f)
        {
                super(s);
                table = null;
                loadFactor = f;
        }

        /**
         * Make an independent copy of the table. Does not clone elements.
        **/

        public final HashSet duplicate()
        {
                auto c = new HashSet (screener, loadFactor);

                if (count !is 0)
                   {
                   int cap = 2 * cast(int)(count / loadFactor) + 1;
                   if (cap < defaultInitialBuckets)
                       cap = defaultInitialBuckets;

                   c.buckets(cap);
                   for (int i = 0; i < table.length; ++i)
                        for (LLCellT p = table[i]; p !is null; p = p.next())
                             c.add(p.element());
                   }
                return c;
        }


        // HashTableParams methods

        /**
         * Implements store.HashTableParams.buckets.
         * Time complexity: O(1).
         * @see store.HashTableParams#buckets.
        **/

        public final int buckets()
        {
                return (table is null) ? 0 : table.length;
        }

        /**
         * Implements store.HashTableParams.buckets.
         * Time complexity: O(n).
         * @see store.HashTableParams#buckets.
        **/

        public final void buckets(int newCap)
        {
                if (newCap is buckets())
                    return ;
                else
                   if (newCap >= 1)
                       resize(newCap);
                   else
                      {
                      char[16] tmp;
                      throw new IllegalArgumentException("Impossible Hash table size:" ~ itoa(tmp, newCap));
                      }
        }

        /**
         * Implements store.HashTableParams.thresholdLoadfactor
         * Time complexity: O(1).
         * @see store.HashTableParams#thresholdLoadfactor
        **/

        public final float thresholdLoadFactor()
        {
                return loadFactor;
        }

        /**
         * Implements store.HashTableParams.thresholdLoadfactor
         * Time complexity: O(n).
         * @see store.HashTableParams#thresholdLoadfactor
        **/

        public final void thresholdLoadFactor(float desired)
        {
                if (desired > 0.0)
                   {
                   loadFactor = desired;
                   checkLoadFactor();
                   }
                else
                   throw new IllegalArgumentException("Invalid Hash table load factor");
        }





        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return false;

                LLCellT p = table[hashOf(element)];
                if (p !is null)
                    return p.find(element) !is null;
                else
                   return false;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (contains(element))
                    return 1;
                else
                   return 0;
        }

        /**
         * Implements store.Collection.elements.
         * Time complexity: O(1).
         * @see store.Collection#elements
        **/
        public final GuardIterator!(T) elements()
        {
                return new CellIterator!(T)(this);
        }

        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                setCount(0);
                table = null;
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableCollection#exclude
        **/
        public final void removeAll(T element)
        {
                remove(element);
        }

        public final void remove(T element)
        {
                if (!isValidArg(element) || count is 0)
                    return ;

                int h = hashOf(element);
                LLCellT hd = table[h];
                LLCellT p = hd;
                LLCellT trail = p;

                while (p !is null)
                      {
                      LLCellT n = p.next();
                      if (p.element() == (element))
                         {
                         decCount();
                         if (p is table[h])
                            {
                            table[h] = n;
                            trail = n;
                            }
                         else
                            trail.next(n);
                         return ;
                         } 
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        public final void replace(T oldElement, T newElement)
        {

                if (count is 0 || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                if (contains(oldElement))
                   {
                   checkElement(newElement);
                   remove(oldElement);
                   add(newElement);
                   }
        }

        public final void replaceAll(T oldElement, T newElement)
        {
                replace(oldElement, newElement);
        }

        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(number of buckets).
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (count !is 0)
                   {
                   for (int i = 0; i < table.length; ++i)
                       {
                       if (table[i] !is null)
                          {
                          decCount();
                          auto v = table[i].element();
                          table[i] = table[i].next();
                          return v;
                          }
                       }
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableSet methods

        /**
         * Implements store.MutableSet.add.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableSet#add
        **/
        public final void add(T element)
        {
                checkElement(element);

                if (table is null)
                    resize(defaultInitialBuckets);

                int h = hashOf(element);
                LLCellT hd = table[h];
                if (hd !is null && hd.find(element) !is null)
                    return ;

                LLCellT n = new LLCellT(element, hd);
                table[h] = n;
                incCount();

                if (hd !is null)
                    checkLoadFactor(); // only check if bin was nonempty
        }



        // Helper methods

        /**
         * Check to see if we are past load factor threshold. If so, resize
         * so that we are at half of the desired threshold.
         * Also while at it, check to see if we are empty so can just
         * unlink table.
        **/
        protected final void checkLoadFactor()
        {
                if (table is null)
                   {
                   if (count !is 0)
                       resize(defaultInitialBuckets);
                   }
                else
                   {
                   float fc = cast(float) (count);
                   float ft = table.length;
                   if (fc / ft > loadFactor)
                      {
                      int newCap = 2 * cast(int)(fc / loadFactor) + 1;
                      resize(newCap);
                      }
                   }
        }

        /**
         * Mask off and remainder the hashCode for element
         * so it can be used as table index
        **/

        protected final int hashOf(T element)
        {
                return (typeid(T).getHash(&element) & 0x7FFFFFFF) % table.length;
        }


        /**
         * resize table to new capacity, rehashing all elements
        **/
        protected final void resize(int newCap)
        {
                LLCellT newtab[] = new LLCellT[newCap];

                if (table !is null)
                   {
                   for (int i = 0; i < table.length; ++i)
                       {
                       LLCellT p = table[i];
                       while (p !is null)
                             {
                             LLCellT n = p.next();
                             int h = (p.elementHash() & 0x7FFFFFFF) % newCap;
                             p.next(newtab[h]);
                             newtab[h] = p;
                             p = n;
                             }
                       }
                   }

                table = newtab;
                incVersion();
        }

        /+
        private final void readObject(java.io.ObjectInputStream stream)

        {
                int len = stream.readInt();

                if (len > 0)
                    table = new LLCellT[len];
                else
                   table = null;

                loadFactor = stream.readFloat();
                int count = stream.readInt();

                while (count-- > 0)
                      {
                      T element = stream.readObject();
                      int h = hashOf(element);
                      LLCellT hd = table[h];
                      LLCellT n = new LLCellT(element, hd);
                      table[h] = n;
                      }
        }

        private final void writeObject(java.io.ObjectOutputStream stream)
        {
                int len;

                if (table !is null)
                    len = table.length;
                else
                   len = 0;

                stream.writeInt(len);
                stream.writeFloat(loadFactor);
                stream.writeInt(count);

                if (len > 0)
                   {
                   Iterator e = elements();
                   while (e.more())
                          stream.writeObject(e.value());
                   }
        }

        +/

        // ImplementationCheckable methods

        /**
         * Implements store.ImplementationCheckable.checkImplementation.
         * @see store.ImplementationCheckable#checkImplementation
        **/
        public override void checkImplementation()
        {
                super.checkImplementation();

                assert(!(table is null && count !is 0));
                assert((table is null || table.length > 0));
                assert(loadFactor > 0.0f);

                if (table !is null)
                   {
                   int c = 0;
                   for (int i = 0; i < table.length; ++i)
                       {
                       for (LLCellT p = table[i]; p !is null; p = p.next())
                           {
                           ++c;
                           assert(allows(p.element()));
                           assert(contains(p.element()));
                           assert(instances(p.element()) is 1);
                           assert(hashOf(p.element()) is i);
                           }
                       }
                   assert(c is count);
                   }
        }



        private static class CellIterator(T) : AbstractIterator!(T)
        {
                private int             row;
                private LLCellT         cell;
                private LLCellT[]       table;

                public this (HashSet set)
                {
                        super (set);
                        table = set.table;
                }

                public final T get()
                {
                        decRemaining();

                        while (cell is null)
                               cell = table [row++];

                        auto v = cell.element();
                        cell = cell.next();
                        return v;
                }
        }
}



debug (Test)
{
void main()
{
        auto set = new HashSet!(char[]);
        set.add ("foo");
        set.add ("bar");
        set.add ("wumpus");
        
        foreach (value; set.elements) {}

        auto elements = set.elements();
        while (elements.more)
               auto v = elements.get();

        set.checkImplementation();
}
}

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

private import tango.convert.Integer;

private import tango.store.Exception;

private import tango.store.impl.LLCell;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableSetImpl;

private import tango.store.model.Set;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Iterator;
private import tango.store.model.MutableSet;
private import tango.store.model.HashTableParams;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;


/**
 *
 * Hash table implementation of set
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class HashSetT(T) : MutableSetImplT!(T), HashTableParams
{
        alias LLCellT!(T)               LLCell;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias CollectionIteratorT!(T)   CollectionIterator;


        // instance variables

        /**
         * The table. Each entry is a list. Null if no table allocated
        **/
        package LLCell table_[];
        /**
         * The threshold load factor
        **/
        protected float loadFactor_;


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
                table_ = null;
                loadFactor_ = f;
        }

        /**
         * Make an independent copy of the table. Does not clone elements.
        **/

        public final Collection duplicate()
        {
                auto c = new HashSetT (screener_, loadFactor_);

                if (count_ !is 0)
                   {
                   int cap = 2 * cast(int)(count_ / loadFactor_) + 1;
                   if (cap < defaultInitialBuckets)
                       cap = defaultInitialBuckets;

                   c.buckets(cap);
                   for (int i = 0; i < table_.length; ++i)
                        for (LLCell p = table_[i]; p !is null; p = p.next())
                             c.include(p.element());
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
                return (table_ is null) ? 0 : table_.length;
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
                      throw new IllegalArgumentException("Impossible Hash table size:" ~ Integer.format(tmp, newCap));
                      }
        }

        /**
         * Implements store.HashTableParams.thresholdLoadfactor
         * Time complexity: O(1).
         * @see store.HashTableParams#thresholdLoadfactor
        **/

        public final float thresholdLoadFactor()
        {
                return loadFactor_;
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
                   loadFactor_ = desired;
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
                if (!isValidArg(element) || count_ is 0)
                     return false;

                LLCell p = table_[hashOf(element)];
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
        public final CollectionIterator elements()
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
                table_ = null;
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableCollection#exclude
        **/
        public final void exclude(T element)
        {
                removeOneOf(element);
        }

        public final void removeOneOf(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                    return ;

                int h = hashOf(element);
                LLCell hd = table_[h];
                LLCell p = hd;
                LLCell trail = p;

                while (p !is null)
                      {
                      LLCell n = p.next();
                      if (p.element() == (element))
                         {
                         decCount();
                         if (p is table_[h])
                            {
                            table_[h] = n;
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

        public final void replaceOneOf(T oldElement, T newElement)
        {

                if (count_ is 0 || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                if (contains(oldElement))
                   {
                   checkElement(newElement);
                   exclude(oldElement);
                   include(newElement);
                   }
        }

        public final void replaceAllOf(T oldElement, T newElement)
        {
                replaceOneOf(oldElement, newElement);
        }

        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(number of buckets).
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (count_ !is 0)
                   {
                   for (int i = 0; i < table_.length; ++i)
                       {
                       if (table_[i] !is null)
                          {
                          decCount();
                          auto v = table_[i].element();
                          table_[i] = table_[i].next();
                          return v;
                          }
                       }
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableSet methods

        /**
         * Implements store.MutableSet.include.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableSet#include
        **/
        public final void include(T element)
        {
                checkElement(element);

                if (table_ is null)
                    resize(defaultInitialBuckets);

                int h = hashOf(element);
                LLCell hd = table_[h];
                if (hd !is null && hd.find(element) !is null)
                    return ;

                LLCell n = new LLCell(element, hd);
                table_[h] = n;
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
                if (table_ is null)
                   {
                   if (count_ !is 0)
                       resize(defaultInitialBuckets);
                   }
                else
                   {
                   float fc = cast(float) (count_);
                   float ft = table_.length;
                   if (fc / ft > loadFactor_)
                      {
                      int newCap = 2 * cast(int)(fc / loadFactor_) + 1;
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
                return (typeid(T).getHash(&element) & 0x7FFFFFFF) % table_.length;
        }


        /**
         * resize table to new capacity, rehashing all elements
        **/
        protected final void resize(int newCap)
        {
                LLCell newtab[] = new LLCell[newCap];

                if (table_ !is null)
                   {
                   for (int i = 0; i < table_.length; ++i)
                       {
                       LLCell p = table_[i];
                       while (p !is null)
                             {
                             LLCell n = p.next();
                             int h = (p.elementHash() & 0x7FFFFFFF) % newCap;
                             p.next(newtab[h]);
                             newtab[h] = p;
                             p = n;
                             }
                       }
                   }

                table_ = newtab;
                incVersion();
        }

        /+
        private final void readObject(java.io.ObjectInputStream stream)

        {
                int len = stream.readInt();

                if (len > 0)
                    table_ = new LLCell[len];
                else
                   table_ = null;

                loadFactor_ = stream.readFloat();
                int count = stream.readInt();

                while (count-- > 0)
                      {
                      T element = stream.readObject();
                      int h = hashOf(element);
                      LLCell hd = table_[h];
                      LLCell n = new LLCell(element, hd);
                      table_[h] = n;
                      }
        }

        private final void writeObject(java.io.ObjectOutputStream stream)
        {
                int len;

                if (table_ !is null)
                    len = table_.length;
                else
                   len = 0;

                stream.writeInt(len);
                stream.writeFloat(loadFactor_);
                stream.writeInt(count_);

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

                assert(!(table_ is null && count_ !is 0));
                assert((table_ is null || table_.length > 0));
                assert(loadFactor_ > 0.0f);

                if (table_ !is null)
                   {
                   int c = 0;
                   for (int i = 0; i < table_.length; ++i)
                       {
                       for (LLCell p = table_[i]; p !is null; p = p.next())
                           {
                           ++c;
                           assert(canInclude(p.element()));
                           assert(contains(p.element()));
                           assert(instances(p.element()) is 1);
                           assert(hashOf(p.element()) is i);
                           }
                       }
                   assert(c is count_);
                   }
        }



        private static class CellIterator(T) : AbstractIteratorT!(T)
        {
                private int             row;
                private LLCell          cell;
                private LLCell[]        table;

                public this (HashSetT set)
                {
                        super (set);
                        table = set.table_;
                }

                public final bool more()
                {
                        if (remaining_)
                           {
                           if (cell)
                               cell = cell.next();

                           while (cell is null)
                                  cell = table [row++];

                           decRemaining();
                           return true;
                           }

                        return false;
                }

                public final T value()
                {
                        return cell.element();
                }
        }
}


alias HashSetT!(Object) HashSet;
/*
 File: HashMap.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses
 21Oct95  dl                 fixed error in removeAt
 9Apr97   dl                 made Serializable

*/


module tango.store.HashMap;

private import tango.store.Exception;

private import tango.store.impl.LLCell;
private import tango.store.impl.LLPair;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableMapImpl;

private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.MutableMap;
private import tango.store.model.HashTableParams;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;

/**
 *
 * Hash table implementation of Map
 * @author Doug Lea
 * @version 0.94
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class HashMapT(K, T) : MutableMapImplT!(K, T), HashTableParams
{
        alias LLCellT!(T)               LLCell;
        alias LLPairT!(K, T)            LLPair;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias CollectionIteratorT!(T)   CollectionIterator;

        // instance variables

        /**
         * The table. Each entry is a list. Null if no table allocated
        **/
        package LLPair table_[];

        /**
         * The threshold load factor
        **/

        protected float loadFactor_;


        // constructors

        /**
         * Make a new empty map.
        **/

        public this ()
        {
                this(null, defaultLoadFactor);
        }

        /**
         * Make a new empty map to use given element screener.
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
         * Make an independent copy of the table. Elements themselves are not cloned.
        **/

        public final Collection duplicate()
        {
                auto c = new HashMapT (screener_, loadFactor_);

                if (count_ !is 0)
                   {
                   int cap = 2 * cast(int)((count_ / loadFactor_)) + 1;
                   if (cap < defaultInitialBuckets)
                       cap = defaultInitialBuckets;

                   c.buckets(cap);

                   for (int i = 0; i < table_.length; ++i)
                        for (LLPair p = table_[i]; p !is null; p = cast(LLPair)(p.next()))
                             c.putAt(p.key(), p.element());
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
                      throw new IllegalArgumentException("Invalid Hash table size");
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

                for (int i = 0; i < table_.length; ++i)
                    {
                    LLPair hd = table_[i];
                    if (hd !is null && hd.find(element) !is null)
                        return true;
                    }
                return false;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                    return 0;
    
                int c = 0;
                for (int i = 0; i < table_.length; ++i)
                    {
                    LLPair hd = table_[i];
                    if (hd !is null)
                        c += hd.count(element);
                    }
                return c;
        }

        /**
         * Implements store.Collection.elements.
         * Time complexity: O(1).
         * @see store.Collection#elements
        **/
        public final CollectionIterator elements()
        {
                return new PairIterator!(K, T)(this);
        }


        // Map methods


        /**
         * Implements store.Map.containsKey.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.Map#containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || count_ is 0)
                    return false;

                LLPair p = table_[hashOf(key)];
                if (p !is null)
                    return p.findKey(key) !is null;
                else
                   return false;
        }

        /**
         * Implements store.Map.containsPair
         * Time complexity: O(1) average; O(n) worst.
         * @see store.Map#containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (!isValidKey(key) || !isValidArg(element) || count_ is 0)
                    return false;

                LLPair p = table_[hashOf(key)];
                if (p !is null)
                    return p.find(key, element) !is null;
                else
                   return false;
        }

        /**
         * Implements store.Map.keys.
         * Time complexity: O(1).
         * @see store.Map#keys
        **/
        public final CollectionMapIteratorT!(K, T) keys()
        {
                return new PairIterator!(K, T)(this);
        }

        /**
         * Implements store.Map.get.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.Map#at
        **/
        public final T get(K key)
        {
                checkKey(key);
                if (count_ !is 0)
                   {
                   LLPair p = table_[hashOf(key)];
                   if (p !is null)
                      {
                      LLPair c = p.findKey(key);
                      if (c !is null)
                          return c.element();
                      }
                   }
                throw new NoSuchElementException("no matching key");
        }


        /**
         * Return the element associated with Key key. 
         * @param key a key
         * @return whether the key is contained or not
        **/

        public bool get(K key, inout T element)
        {
                checkKey(key);
                if (count_ !is 0)
                   {
                   LLPair p = table_[hashOf(key)];
                   if (p !is null)
                      {
                      LLPair c = p.findKey(key);
                      if (c !is null)
                         {
                         element = c.element();
                         return true;
                         }
                      }
                   }
                return false;
        }



        /**
         * Implements store.Map.keyOf.
         * Time complexity: O(n).
         * @see store.Map#akyOf
        **/
        public final K keyOf(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                    return K.init;

                // for (int i = 0; i < table_._length; ++i) {
                for (int i = 0; i < table_.length; ++i)
                    { 
                    LLPair hd = table_[i];
                    if (hd !is null)
                       {
                       LLPair p = (cast(LLPair)(hd.find(element)));
                       if (p !is null)
                           return p.key();
                       }
                    }
                return K.init;
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
         * Time complexity: O(n).
         * @see store.MutableCollection#exclude
        **/
        public final void exclude(T element)
        {
                remove_(element, true);
        }


        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void removeOneOf(T element)
        {
                remove_(element, false);
        }


        /**
         * Implements store.MutableCollection.replaceOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replaceOneOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAllOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
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
                          table_[i] = cast(LLPair)(table_[i].next());
                          return v;
                          }
                       }
                   }
                checkIndex(0);
                return T.init; // not reached
        }

        // MutableMap methods


        /**
         * Implements store.MutableMap.putAt.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableMap#putAt
        **/
        public final void putAt(K key, T element)
        {
                checkKey(key);
                checkElement(element);

                if (table_ is null)
                    resize (defaultInitialBuckets);

                int h = hashOf(key);
                LLPair hd = table_[h];
                if (hd is null)
                   {
                   table_[h] = new LLPair(key, element, hd);
                   incCount();
                   return;
                   }
                else
                   {
                   LLPair p = hd.findKey(key);
                   if (p !is null)
                      {
                      if (p.element() != (element))
                         {
                         p.element(element);
                         incVersion();
                         }
                      }
                   else
                      {
                      table_[h] = new LLPair(key, element, hd);
                      incCount();
                      checkLoadFactor(); // we only check load factor on add to nonempty bin
                      }
                   }
        }


        /**
         * Implements store.MutableMap.remove.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableMap#remove
        **/
        public final void remove(K key)
        {
                if (!isValidKey(key) || count_ is 0)
                    return;

                int h = hashOf(key);
                LLPair hd = table_[h];
                LLPair p = hd;
                LLPair trail = p;

                while (p !is null)
                      {
                      LLPair n = cast(LLPair)(p.next());
                      if (p.key() == (key))
                         {
                         decCount();
                         if (p is hd)
                             table_[h] = n;
                         else
                            trail.unlinkNext();
                         return;
                         }
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        /**
         * Implements store.MutableMap.replaceElement.
         * Time complexity: O(1) average; O(n) worst.
         * @see store.MutableMap#replaceElement
        **/
        public final void replaceElement(K key, T oldElement, T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || count_ is 0)
                    return;

                LLPair p = table_[hashOf(key)];
                if (p !is null)
                   {
                   LLPair c = p.find(key, oldElement);
                   if (c !is null)
                      {
                      checkElement(newElement);
                      c.element(newElement);
                      incVersion();
                      }
                   }
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

        protected final int hashOf(K key)
        {
                return (typeid(K).getHash(&key) & 0x7FFFFFFF) % table_.length;
        }


        protected final void resize(int newCap)
        {
                LLPair newtab[] = new LLPair[newCap];

                if (table_ !is null)
                   {
                   for (int i = 0; i < table_.length; ++i)
                       {
                       LLPair p = table_[i];
                       while (p !is null)
                             {
                             LLPair n = cast(LLPair)(p.next());
                             int h = (p.keyHash() & 0x7FFFFFFF) % newCap;
                             p.next(newtab[h]);
                             newtab[h] = p;
                             p = n;
                             }
                       }
                   }
                table_ = newtab;
                incVersion();
        }

        // helpers

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count_ is 0)
                    return;

                for (int h = 0; h < table_.length; ++h)
                    {
                    LLCell hd = table_[h];
                    LLCell p = hd;
                    LLCell trail = p;
                    while (p !is null)
                          {
                          LLPair n = cast(LLPair)(p.next());
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
                             if (! allOccurrences)
                                   return;
                             else
                                p = n;
                             }
                          else
                             {
                             trail = p;
                             p = n;
                             }
                          }
                    }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (count_ is 0 || !isValidArg(oldElement) || oldElement == (newElement))
                    return;

                for (int h = 0; h < table_.length; ++h)
                    {
                    LLCell hd = table_[h];
                    LLCell p = hd;
                    LLCell trail = p;
                    while (p !is null)
                          {
                          LLPair n = cast(LLPair)(p.next());
                          if (p.element() == (oldElement))
                             {
                             checkElement(newElement);
                             incVersion();
                             p.element(newElement);
                             if (! allOccurrences)
                                   return ;
                             }
                          trail = p;
                          p = n;
                          }
                    }
        }


        /+
        private final void readObject(java.io.ObjectInputStream stream)
        {
                int len = stream.readInt();

                if (len > 0)
                    table_ = new LLPair[len];
                else
                   table_ = null;

                loadFactor_ = stream.readFloat();
                int count = stream.readInt();

                while (count-- > 0)
                      {
                      Object key = stream.readObject();
                      T element = stream.readObject();
                      int h = hashOf(key);
                      LLPair hd = table_[h];
                      LLPair n = new LLPair(key, element, hd);
                      table_[h] = n;
                      }
        }

        private final void writeObject(java.io.ObjectOutputStream stream)
        {
                int len;

                if (table_ !is null)
                    // len = table_._length;
                    len = table_.length;
                else
                   len = 0;

                stream.writeInt(len);
                stream.writeFloat(loadFactor_);
                stream.writeInt(count_);

                if (len > 0)
                   {
                   Iterator i = keys();
                   while (i.more())
                         {
                         stream.writeObject(i.key());
                         stream.writeObject(i.value());
                         }
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

                if (table_ is null)
                    return;

                int c = 0;
                for (int i = 0; i < table_.length; ++i)
                    {
                    for (LLPair p = table_[i]; p !is null; p = cast(LLPair)(p.next()))
                        {
                        ++c;
                        assert(canInclude(p.element()));
                        assert(canIncludeKey(p.key()));
                        assert(containsKey(p.key()));
                        assert(contains(p.element()));
                        assert(instances(p.element()) >= 1);
                        assert(containsPair(p.key(), p.element()));
                        assert(hashOf(p.key()) is i);
                        }
                    }
                assert(c is count_);


        }



        private static class PairIterator(K, T) : MapIteratorImplT!(K, T)
        {
                private int             row;
                private LLPair          pair;
                private LLPair[]        table;

                public this (HashMapT map)
                {
                        super (map);
                        table = map.table_;
                }

                public final bool more()
                {
                        if (remaining_)
                           {
                           if (pair)
                               pair = cast(LLPair) pair.next();

                           while (pair is null)
                                  pair = table [row++];

                           decRemaining();
                           return true;
                           }

                        return false;
                }

                public final T value()
                {
                        return pair.element();
                }

                public final K key()
                {
                        return pair.key();
                }
        }
}


alias HashMapT!(Object, Object) HashMap;
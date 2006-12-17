/*
 File: LinkMap.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses
 21Oct95  dl                 Fixed error in remove

*/


module tango.util.collection.LinkMap;

private import tango.util.collection.Exception;

private import  tango.io.protocol.model.IReader,
                tango.io.protocol.model.IWriter;

private import  tango.util.collection.model.View,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.LLCell,
                tango.util.collection.impl.LLPair,
                tango.util.collection.impl.MapCollection,
                tango.util.collection.impl.AbstractIterator;

/**
 *
 *
 * Linked lists of (key, element) pairs
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class LinkMap(K, T) : MapCollection!(K, T) // , IReadable, IWritable
{
        alias LLCell!(T)               LLCellT;
        alias LLPair!(K, T)            LLPairT;

        // instance variables

        /**
         * The head of the list. Null if empty
        **/

        package LLPairT list;

        // constructors

        /**
         * Make an empty list
        **/

        public this ()
        {
                this(null, null, 0);
        }

        /**
         * Make an empty list with the supplied element screener
        **/

        public this (Predicate screener)
        {
                this(screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        protected this (Predicate s, LLPairT l, int c)
        {
                super(s);
                list = l;
                count = c;
        }

        /**
         * Make an independent copy of the list. Does not clone elements
        **/

        public LinkMap duplicate()
        {
                if (list is null)
                    return new LinkMap (screener, null, 0);
                else
                   return new LinkMap (screener, cast(LLPairT)(list.copyList()), count);
        }


        // Collection methods

        /**
         * Implements util.collection.Collection.contains.
         * Time complexity: O(n).
         * @see util.collection.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || list is null)
                     return false;

                return list.find(element) !is null;
        }

        /**
         * Implements util.collection.Collection.instances.
         * Time complexity: O(n).
         * @see util.collection.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || list is null)
                     return 0;

                return list.count(element);
        }

        /**
         * Implements util.collection.Collection.elements.
         * Time complexity: O(1).
         * @see util.collection.Collection#elements
        **/
        public final GuardIterator!(T) elements()
        {
                return keys();
        }

        // Map methods


        /**
         * Implements util.collection.Map.containsKey.
         * Time complexity: O(n).
         * @see util.collection.Map#containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || list is null)
                     return false;

                return list.findKey(key) !is null;
        }

        /**
         * Implements util.collection.Map.containsPair
         * Time complexity: O(n).
         * @see util.collection.Map#containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (!isValidKey(key) || !isValidArg(element) || list is null)
                    return false;
                return list.find(key, element) !is null;
        }

        /**
         * Implements util.collection.Map.keys.
         * Time complexity: O(1).
         * @see util.collection.Map#keys
        **/
        public final PairIterator!(K, T) keys()
        {
                return new MapIterator!(K, T)(this);
        }

        /**
         * Implements util.collection.Map.get.
         * Time complexity: O(n).
         * @see util.collection.Map#get
        **/
        public final T get(K key)
        {
                checkKey(key);
                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                       return p.element();
                   }
                throw new NoSuchElementException("no matching Key");
        }

        /**
         * Return the element associated with Key key. 
         * @param key a key
         * @return whether the key is contained or not
        **/

        public final bool get(K key, inout T element)
        {
                checkKey(key);
                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                      {
                      element = p.element();
                      return true;
                      }
                   }
                return false;
        }



        /**
         * Implements util.collection.Map.keyOf.
         * Time complexity: O(n).
         * @see util.collection.Map#keyOf
        **/
        public final K keyOf(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return null;

                auto p = (cast(LLPairT)(list.find(element)));
                if (p !is null)
                    return p.key();
                else
                   return null;
        }


        // MutableCollection methods

        /**
         * Implements util.collection.MutableCollection.clear.
         * Time complexity: O(1).
         * @see util.collection.MutableCollection#clear
        **/
        public final void clear()
        {
                list = null;
                setCount(0);
        }

        /**
         * Implements util.collection.MutableCollection.replaceOneOf
         * Time complexity: O(n).
         * @see util.collection.MutableCollection#replaceOneOf
        **/
        public final void replace (T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements util.collection.MutableCollection.replaceAllOf.
         * Time complexity: O(n).
         * @see util.collection.MutableCollection#replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements util.collection.MutableCollection.removeAll.
         * Time complexity: O(n).
         * @see util.collection.MutableCollection#removeAll
        **/
        public final void removeAll(T element)
        {
                remove_(element, true);
        }

        /**
         * Implements util.collection.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see util.collection.MutableCollection#removeOneOf
        **/
        public final void remove(T element)
        {
                remove_(element, false);
        }

        /**
         * Implements util.collection.MutableCollection.take.
         * Time complexity: O(1).
         * takes the first element on the list
         * @see util.collection.MutableCollection#take
        **/
        public final T take()
        {
                if (list !is null)
                   {
                   auto v = list.element();
                   list = cast(LLPairT)(list.next());
                   decCount();
                   return v;
                   }
                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements util.collection.MutableMap.add.
         * Time complexity: O(n).
         * @see util.collection.MutableMap#add
        **/
        public final void add (K key, T element)
        {
                checkKey(key);
                checkElement(element);

                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                      {
                      if (p.element() != (element))
                         {
                         p.element(element);
                         incVersion();
                         }
                      return ;
                      }
                   }
                list = new LLPairT(key, element, list);
                incCount();
        }


        /**
         * Implements util.collection.MutableMap.remove.
         * Time complexity: O(n).
         * @see util.collection.MutableMap#remove
        **/
        public final void removeKey (K key)
        {
                if (!isValidKey(key) || list is null)
                    return ;

                auto p = list;
                auto trail = p;

                while (p !is null)
                      {
                      auto n = cast(LLPairT)(p.next());
                      if (p.key() == (key))
                         {
                         decCount();
                         if (p is list)
                             list = n;
                         else
                            trail.unlinkNext();
                         return ;
                         }
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        /**
         * Implements util.collection.MutableMap.replaceElement.
         * Time complexity: O(n).
         * @see util.collection.MutableMap#replaceElement
        **/
        public final void replacePair (K key, T oldElement, T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || list is null)
                     return ;

                auto p = list.find(key, oldElement);
                if (p !is null)
                   {
                   checkElement(newElement);
                   p.element(newElement);
                   incVersion();
                   }
        }

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count is 0)
                     return ;

                auto p = list;
                auto trail = p;

                while (p !is null)
                      {
                      auto n = cast(LLPairT)(p.next());
                      if (p.element() == (element))
                         {
                         decCount();
                         if (p is list)
                            {
                            list = n;
                            trail = n;
                            }
                         else
                            trail.next(n);

                         if (!allOccurrences || count is 0)
                              return ;
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

        /**
         * Helper for replace
        **/

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (list is null || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                auto p = list.find(oldElement);
                while (p !is null)
                      {
                      checkElement(newElement);
                      p.element(newElement);
                      incVersion();
                      if (!allOccurrences)
                           return ;
                      p = p.find(oldElement);
                      }
        }

        // ImplementationCheckable methods

        /**
         * Implements util.collection.ImplementationCheckable.checkImplementation.
         * @see util.collection.ImplementationCheckable#checkImplementation
        **/
        public override void checkImplementation()
        {
                super.checkImplementation();

                assert(((count is 0) is (list is null)));
                assert((list is null || list._length() is count));

                for (auto p = list; p !is null; p = cast(LLPairT)(p.next()))
                    {
                    assert(allows(p.element()));
                    assert(allowsKey(p.key()));
                    assert(containsKey(p.key()));
                    assert(contains(p.element()));
                    assert(instances(p.element()) >= 1);
                    assert(containsPair(p.key(), p.element()));
                    }
        }


        private static class MapIterator(K, V) : AbstractMapIterator!(K, V)
        {
                private LLPairT pair;
                
                public this (LinkMap map)
                {
                        super (map);
                        pair = map.list;
                } 

                public final V get(inout K key)
                {
                        key = pair.key;
                        return get();
                }

                public final V get()
                {
                        decRemaining();
                        auto v = pair.element();
                        pair = cast(LLPairT) pair.next();
                        return v;
                }
        }
}


         
debug(Test)
{
void main()
{
        auto map = new LinkMap!(Object, double);

        foreach (key, value; map.keys) {typeof(key) x; x = key;}

        foreach (value; map.keys) {}

        foreach (value; map.elements) {}

        auto keys = map.keys();
        while (keys.more)
               auto v = keys.get();

        keys.keyType e;
        while (keys.get(e)) {}
}
}

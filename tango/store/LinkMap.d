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


module tango.store.LinkMap;

private import tango.store.Exception;

private import tango.store.impl.LLCell;
private import tango.store.impl.LLPair;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableMapImpl;

private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Iterator;
private import tango.store.model.MutableMap;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;


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


public class LinkMapT(K, T) : MutableMapImplT!(K, T)
{
        alias LLCellT!(T)               LLCell;
        alias LLPairT!(K, T)            LLPair;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias CollectionIteratorT!(T)   CollectionIterator;

        // instance variables

        /**
         * The head of the list. Null if empty
        **/

        package LLPair list_;

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
        protected this (Predicate s, LLPair l, int c)
        {
                super(s);
                list_ = l;
                count_ = c;
        }

        /**
         * Make an independent copy of the list. Does not clone elements
        **/

        //  protected Object clone()  {
        public Collection duplicate()
        {
                if (list_ is null)
                        return new LinkMapT(screener_, null, 0);
                else
                        return new LinkMapT(screener_, cast(LLPair)(list_.copyList()), count_);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || list_ is null)
                     return false;

                return list_.find(element) !is null;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || list_ is null)
                     return 0;

                return list_.count(element);
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
         * Time complexity: O(n).
         * @see store.Map#containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || list_ is null)
                     return false;

                return list_.findKey(key) !is null;
        }

        /**
         * Implements store.Map.containsPair
         * Time complexity: O(n).
         * @see store.Map#containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (!isValidKey(key) || !isValidArg(element) || list_ is null)
                    return false;
                return list_.find(key, element) !is null;
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
         * Time complexity: O(n).
         * @see store.Map#get
        **/
        public final T get(K key)
        {
                checkKey(key);
                if (list_ !is null)
                   {
                   LLPair p = list_.findKey(key);
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
                if (list_ !is null)
                   {
                   LLPair p = list_.findKey(key);
                   if (p !is null)
                      {
                      element = p.element();
                      return true;
                      }
                   }
                return false;
        }



        /**
         * Implements store.Map.keyOf.
         * Time complexity: O(n).
         * @see store.Map#keyOf
        **/
        public final K keyOf(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                     return null;

                LLPair p = (cast(LLPair)(list_.find(element)));
                if (p !is null)
                    return p.key();
                else
                   return null;
        }


        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                list_ = null;
                setCount(0);
        }

        /**
         * Implements store.MutableCollection.replaceOneOf
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replaceOneOf (T oldElement, T newElement)
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
         * Implements store.MutableCollection.take.
         * Time complexity: O(1).
         * takes the first element on the list
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (list_ !is null)
                   {
                   T v = list_.element();
                   list_ = cast(LLPair)(list_.next());
                   decCount();
                   return v;
                   }
                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements store.MutableMap.putAt.
         * Time complexity: O(n).
         * @see store.MutableMap#putAt
        **/
        public final void putAt(K key, T element)
        {
                checkKey(key);
                checkElement(element);

                if (list_ !is null)
                   {
                   LLPair p = list_.findKey(key);
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
                list_ = new LLPair(key, element, list_);
                incCount();
        }


        /**
         * Implements store.MutableMap.remove.
         * Time complexity: O(n).
         * @see store.MutableMap#remove
        **/
        public final void remove(K key)
        {
                if (!isValidKey(key) || list_ is null)
                    return ;

                LLPair p = list_;
                LLPair trail = p;

                while (p !is null)
                      {
                      LLPair n = cast(LLPair)(p.next());
                      if (p.key() == (key))
                         {
                         decCount();
                         if (p is list_)
                             list_ = n;
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
         * Implements store.MutableMap.replaceElement.
         * Time complexity: O(n).
         * @see store.MutableMap#replaceElement
        **/
        public final void replaceElement(K key, T oldElement, T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || list_ is null)
                     return ;

                LLPair p = list_.find(key, oldElement);
                if (p !is null)
                   {
                   checkElement(newElement);
                   p.element(newElement);
                   incVersion();
                   }
        }

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count_ is 0)
                     return ;

                LLPair p = list_;
                LLPair trail = p;

                while (p !is null)
                      {
                      LLPair n = cast(LLPair)(p.next());
                      if (p.element() == (element))
                         {
                         decCount();
                         if (p is list_)
                            {
                            list_ = n;
                            trail = n;
                            }
                         else
                            trail.next(n);

                         if (!allOccurrences || count_ is 0)
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
                if (list_ is null || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                LLCell p = list_.find(oldElement);
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
         * Implements store.ImplementationCheckable.checkImplementation.
         * @see store.ImplementationCheckable#checkImplementation
        **/
        public override void checkImplementation()
        {
                super.checkImplementation();

                assert(((count_ is 0) is (list_ is null)));
                assert((list_ is null || list_._length() is count_));

                for (LLPair p = list_; p !is null; p = cast(LLPair)(p.next()))
                    {
                    assert(canInclude(p.element()));
                    assert(canIncludeKey(p.key()));
                    assert(containsKey(p.key()));
                    assert(contains(p.element()));
                    assert(instances(p.element()) >= 1);
                    assert(containsPair(p.key(), p.element()));
                    }
        }


        private static class PairIterator(K, T) : MapIteratorImplT!(K, T)
        {
                private LLPair  pair, 
                                start;
                
                public this (LinkMapT map)
                {
                        super (map);
                        start = map.list_;
                } 

                public final bool more()
                {
                        if (pair)
                            pair = cast(LLPair)(pair.next);
                        else
                           if (start)
                               pair = start, start = null;
                           else
                              return false;
                                                              
                        decRemaining();
                        return true;
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


alias LinkMapT!(Object, Object) LinkMap;
/*
 File: TreeMap.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.TreeMap;

private import tango.store.Exception;

private import tango.store.impl.RBPair;
private import tango.store.impl.RBCell;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableMapImpl;
private import tango.store.impl.DefaultComparator;

private import tango.store.model.Map;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Comparator;
private import tango.store.model.MutableMap;
private import tango.store.model.KeySortedCollection;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;



/**
 *
 *
 * RedBlack Trees of (key, element) pairs
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class TreeMapT(K, T) : MutableMapImplT!(K, T), KeySortedCollectionT!(K, T)
{
        alias RBCellT!(T)               RBCell;
        alias RBPairT!(K, T)            RBPair;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias ComparatorT!(K)           Comparator;
        alias CollectionIteratorT!(T)   CollectionIterator;


        // instance variables

        /**
         * The root of the tree. Null if empty.
        **/

        package RBPair tree_;

        /**
         * The comparator to use for ordering
        **/

        protected Comparator cmp_;
        protected ComparatorT!(T) cmpElem_;

        /**
         * Make an empty tree, using DefaultComparator for ordering
        **/

        public this ()
        {
                this(null, null, null, 0);
        }


        /**
         * Make an empty tree, using given screener for screening elements (not keys)
        **/
        public this (Predicate screener)
        {
                this(screener, null, null, 0);
        }

        /**
         * Make an empty tree, using given Comparator for ordering
        **/
        public this (Comparator c)
        {
                this(null, c, null, 0);
        }

        /**
         * Make an empty tree, using given screener and Comparator.
        **/
        public this (Predicate s, Comparator c)
        {
                this(s, c, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, Comparator cmp, RBPair t, int n)
        {
                super(s);
                count_ = n;
                tree_ = t;
                if (cmp !is null)
                    cmp_ = cmp;
                else
                   cmp_ = new DefaultComparatorT!(K);

                cmpElem_ = new DefaultComparatorT!(T);
        }

        /**
         * Create an independent copy. Does not clone elements.
        **/

        //  protected Object clone() {
        public Collection duplicate()
        {
                if (count_ is 0)
                    return new TreeMapT!(K, T)(screener_, cmp_);
                else
                   return new TreeMapT!(K, T)(screener_, cmp_, cast(RBPair)(tree_.copyTree()), count_);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(log n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                     return false;
                return tree_.find(element, cmpElem_) !is null;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(log n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                     return 0;
                return tree_.count(element, cmpElem_);
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

        // KeySortedCollection methods

        /**
         * Implements store.KeySortedCollection.keyComparator
         * Time complexity: O(1).
         * @see store.KeySortedCollection#keyComparator
        **/
        public final Comparator keyComparator()
        {
                return cmp_;
        }

        /**
         * Use a new comparator. Causes a reorganization
        **/

        public final void comparator(Comparator cmp)
        {
                if (cmp !is cmp_)
                   {
                   if (cmp !is null)
                       cmp_ = cmp;
                   else
                      cmp_ = new DefaultComparatorT!(K);

                   if (count_ !is 0)
                      {       
                      // must rebuild tree!
                      incVersion();
                      RBPair t = cast(RBPair) (tree_.leftmost());
                      tree_ = null;
                      count_ = 0;
                      while (t !is null)
                            {
                            add_(t.key(), t.element(), false);
                            t = cast(RBPair)(t.successor());
                            }
                      }
                   }
        }

        // Map methods

        /**
         * Implements store.Map.containsKey.
         * Time complexity: O(log n).
         * @see store.Map#containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || count_ is 0)
                    return false;
                return tree_.findKey(key, cmp_) !is null;
        }

        /**
         * Implements store.Map.containsPair.
         * Time complexity: O(n).
         * @see store.Map#containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (count_ is 0 || !isValidKey(key) || !isValidArg(element))
                    return false;
                return tree_.find(key, element, cmp_) !is null;
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
         * Time complexity: O(log n).
         * @see store.Map#get
        **/
        public final T get(K key)
        {
                if (count_ !is 0)
                   {
                   RBPair p = tree_.findKey(key, cmp_);
                   if (p !is null)
                       return p.element();
                   }
                throw new NoSuchElementException("no matching Key ");
        }

        /**
         * Return the element associated with Key key. 
         * @param key a key
         * @return whether the key is contained or not
        **/

        public final bool get(K key, inout T value)
        {
                if (count_ !is 0)
                   {
                   RBPair p = tree_.findKey(key, cmp_);
                   if (p !is null)
                      {
                      value = p.element();
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

                RBPair p = (cast(RBPair)( tree_.find(element, cmpElem_)));
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
                setCount(0);
                tree_ = null;
        }


        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(n).
         * @see store.MutableCollection#exclude
        **/
        public final void exclude(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                      return ;

                RBPair p = cast(RBPair)(tree_.find(element, cmpElem_));
                while (p !is null)
                      {
                      tree_ = cast(RBPair)(p.remove(tree_));
                      decCount();
                      if (count_ is 0)
                          return ;
                      p = cast(RBPair)(tree_.find(element, cmpElem_));
                      }
        }

        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void removeOneOf(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                      return ;

                RBPair p = cast(RBPair)(tree_.find(element, cmpElem_));
                if (p !is null)
                   {
                   tree_ = cast(RBPair)(p.remove(tree_));
                   decCount();
                   }
        }


        /**
         * Implements store.MutableCollection.replaceOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replaceOneOf(T oldElement, T newElement)
        {
                if (count_ is 0 || !isValidArg(oldElement) || !isValidArg(oldElement))
                    return ;

                RBPair p = cast(RBPair)(tree_.find(oldElement, cmpElem_));
                if (p !is null)
                   {
                   checkElement(newElement);
                   incVersion();
                   p.element(newElement);
                   }
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAllOf(T oldElement, T newElement)
        {
                RBPair p = cast(RBPair)(tree_.find(oldElement, cmpElem_));
                while (p !is null)
                      {
                      checkElement(newElement);
                      incVersion();
                      p.element(newElement);
                      p = cast(RBPair)(tree_.find(oldElement, cmpElem_));
                      }
        }

        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(log n).
         * Takes the element associated with the least key.
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (count_ !is 0)
                   {
                   RBPair p = cast(RBPair)(tree_.leftmost());
                   T v = p.element();
                   tree_ = cast(RBPair)(p.remove(tree_));
                   decCount();
                   return v;
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements store.MutableMap.putAt.
         * Time complexity: O(log n).
         * @see store.MutableMap#putAt
        **/
        public final void putAt(K key, T element)
        {
                add_(key, element, true);
        }


        /**
         * Implements store.MutableMap.remove.
         * Time complexity: O(log n).
         * @see store.MutableMap#remove
        **/
        public final void remove(K key)
        {
                if (!isValidKey(key) || count_ is 0)
                      return ;

                RBCell p = tree_.findKey(key, cmp_);
                if (p !is null)
                   {
                   tree_ = cast(RBPair)(p.remove(tree_));
                   decCount();
                   }
        }


        /**
         * Implements store.MutableMap.replaceElement.
         * Time complexity: O(log n).
         * @see store.MutableMap#replaceElement
        **/
        public final void replaceElement(K key, T oldElement,
                                                T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || count_ is 0)
                    return ;

                RBPair p = tree_.find(key, oldElement, cmp_);
                if (p !is null)
                   {
                   checkElement(newElement);
                   p.element(newElement);
                   incVersion();
                   }
        }


        // helper methods


        private final void add_(K key, T element, bool checkOccurrence)
        {
                checkKey(key);
                checkElement(element);

                if (tree_ is null)
                   {
                   tree_ = new RBPair(key, element);
                   incCount();
                   }
                else
                   {
                   RBPair t = tree_;
                   for (;;)
                       {
                       int diff = cmp_.compare(key, t.key());
                       if (diff is 0 && checkOccurrence)
                          {
                          if (t.element() != element)
                             {
                             t.element(element);
                             incVersion();
                             }
                          return ;
                          }
                       else
                          if (diff <= 0)
                             {
                             if (t.left() !is null)
                                 t = cast(RBPair)(t.left());
                             else
                                {
                                tree_ = cast(RBPair)(t.insertLeft(new RBPair(key, element), tree_));
                                incCount();
                                return ;
                                }
                             }
                          else
                             {
                             if (t.right() !is null)
                                 t = cast(RBPair)(t.right());
                             else
                                {
                                tree_ = cast(RBPair)(t.insertRight(new RBPair(key, element), tree_));
                                incCount();
                                return ;
                                }
                             }
                       }
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
                assert(cmp_ !is null);
                assert(((count_ is 0) is (tree_ is null)));
                assert((tree_ is null || tree_.size() is count_));

                if (tree_ !is null)
                   {
                   tree_.checkImplementation();
                   K last = K.init;
                   RBPair t = cast(RBPair)(tree_.leftmost());

                   while (t !is null)
                         {
                         K v = t.key();
                         assert((last is K.init || cmp_.compare(last, v) <= 0));
                         last = v;
                         t = cast(RBPair)(t.successor());
                         }
                   }
        }


        private static class PairIterator(K, T) : MapIteratorImplT!(K, T)
        {
                private RBPair  pair,
                                start;

                public this (TreeMapT tree)
                {
                        super (tree);
                        start = tree.tree_;
                }

                public final bool more()
                {
                        if (pair)
                            pair = cast(RBPair) pair.successor();
                        else
                           if (start)
                               pair = cast(RBPair) start.leftmost(), start = null;
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


alias TreeMapT!(Object, Object) TreeMap;

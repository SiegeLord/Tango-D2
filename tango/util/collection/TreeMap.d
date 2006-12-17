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


module tango.util.collection.TreeMap;

private import  tango.util.collection.Exception;

private import  tango.util.collection.model.Comparator,
                tango.util.collection.model.SortedKeys,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.RBPair,
                tango.util.collection.impl.RBCell,
                tango.util.collection.impl.MapCollection,
                tango.util.collection.impl.AbstractIterator,
                tango.util.collection.impl.DefaultComparator;


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


public class TreeMap(K, T) : MapCollection!(K, T), SortedKeys!(K, T)
{
        alias RBCell!(T)                RBCellT;
        alias RBPair!(K, T)             RBPairT;
        alias Comparator!(K)            ComparatorT;
        alias GuardIterator!(T)         GuardIteratorT;


        // instance variables

        /**
         * The root of the tree. Null if empty.
        **/

        package RBPairT tree;

        /**
         * The Comparator to use for ordering
        **/

        protected ComparatorT           cmp;
        protected Comparator!(T)        cmpElem;

        /**
         * Make an empty tree, using DefaultComparator for ordering
        **/

        public this ()
        {
                this (null, null, null, 0);
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
        public this (ComparatorT c)
        {
                this(null, c, null, 0);
        }

        /**
         * Make an empty tree, using given screener and Comparator.
        **/
        public this (Predicate s, ComparatorT c)
        {
                this(s, c, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, ComparatorT c, RBPairT t, int n)
        {
                super(s);
                count = n;
                tree = t;
                cmp = (c is null) ? new DefaultComparator!(K) : c;
                cmpElem = new DefaultComparator!(T);
        }

        /**
         * Create an independent copy. Does not clone elements.
        **/

        public TreeMap duplicate()
        {
                if (count is 0)
                    return new TreeMap!(K, T)(screener, cmp);
                else
                   return new TreeMap!(K, T)(screener, cmp, cast(RBPairT)(tree.copyTree()), count);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(log n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return false;
                return tree.find(element, cmpElem) !is null;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(log n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return 0;
                return tree.count(element, cmpElem);
        }

        /**
         * Implements store.Collection.elements.
         * Time complexity: O(1).
         * @see store.Collection#elements
        **/
        public final GuardIterator!(T) elements()
        {
                return keys();
        }

        // KeySortedCollection methods

        /**
         * Implements store.KeySortedCollection.comparator
         * Time complexity: O(1).
         * @see store.KeySortedCollection#comparator
        **/
        public final ComparatorT comparator()
        {
                return cmp;
        }

        /**
         * Use a new Comparator. Causes a reorganization
        **/

        public final void comparator (ComparatorT c)
        {
                if (cmp !is c)
                   {
                   cmp = (c is null) ? new DefaultComparator!(K) : c;

                   if (count !is 0)
                      {       
                      // must rebuild tree!
                      incVersion();
                      auto t = cast(RBPairT) (tree.leftmost());
                      tree = null;
                      count = 0;
                      
                      while (t !is null)
                            {
                            add_(t.key(), t.element(), false);
                            t = cast(RBPairT)(t.successor());
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
                if (!isValidKey(key) || count is 0)
                    return false;
                return tree.findKey(key, cmp) !is null;
        }

        /**
         * Implements store.Map.containsPair.
         * Time complexity: O(n).
         * @see store.Map#containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (count is 0 || !isValidKey(key) || !isValidArg(element))
                    return false;
                return tree.find(key, element, cmp) !is null;
        }

        /**
         * Implements store.Map.keys.
         * Time complexity: O(1).
         * @see store.Map#keys
        **/
        public final PairIterator!(K, T) keys()
        {
                return new MapIterator!(K, T)(this);
        }

        /**
         * Implements store.Map.get.
         * Time complexity: O(log n).
         * @see store.Map#get
        **/
        public final T get(K key)
        {
                if (count !is 0)
                   {
                   RBPairT p = tree.findKey(key, cmp);
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
                if (count !is 0)
                   {
                   RBPairT p = tree.findKey(key, cmp);
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
                if (!isValidArg(element) || count is 0)
                      return null;

                RBPairT p = (cast(RBPairT)( tree.find(element, cmpElem)));
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
                tree = null;
        }


        /**
         * Implements store.MutableCollection.removeAll.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeAll
        **/
        public final void removeAll(T element)
        {
                if (!isValidArg(element) || count is 0)
                      return ;

                RBPairT p = cast(RBPairT)(tree.find(element, cmpElem));
                while (p !is null)
                      {
                      tree = cast(RBPairT)(p.remove(tree));
                      decCount();
                      if (count is 0)
                          return ;
                      p = cast(RBPairT)(tree.find(element, cmpElem));
                      }
        }

        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void remove (T element)
        {
                if (!isValidArg(element) || count is 0)
                      return ;

                RBPairT p = cast(RBPairT)(tree.find(element, cmpElem));
                if (p !is null)
                   {
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   }
        }


        /**
         * Implements store.MutableCollection.replaceOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replace(T oldElement, T newElement)
        {
                if (count is 0 || !isValidArg(oldElement) || !isValidArg(oldElement))
                    return ;

                RBPairT p = cast(RBPairT)(tree.find(oldElement, cmpElem));
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
        public final void replaceAll(T oldElement, T newElement)
        {
                RBPairT p = cast(RBPairT)(tree.find(oldElement, cmpElem));
                while (p !is null)
                      {
                      checkElement(newElement);
                      incVersion();
                      p.element(newElement);
                      p = cast(RBPairT)(tree.find(oldElement, cmpElem));
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
                if (count !is 0)
                   {
                   RBPairT p = cast(RBPairT)(tree.leftmost());
                   T v = p.element();
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   return v;
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements store.MutableMap.add.
         * Time complexity: O(log n).
         * @see store.MutableMap#add
        **/
        public final void add(K key, T element)
        {
                add_(key, element, true);
        }


        /**
         * Implements store.MutableMap.remove.
         * Time complexity: O(log n).
         * @see store.MutableMap#remove
        **/
        public final void removeKey (K key)
        {
                if (!isValidKey(key) || count is 0)
                      return ;

                RBCellT p = tree.findKey(key, cmp);
                if (p !is null)
                   {
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   }
        }


        /**
         * Implements store.MutableMap.replaceElement.
         * Time complexity: O(log n).
         * @see store.MutableMap#replaceElement
        **/
        public final void replacePair (K key, T oldElement,
                                              T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || count is 0)
                    return ;

                RBPairT p = tree.find(key, oldElement, cmp);
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

                if (tree is null)
                   {
                   tree = new RBPairT(key, element);
                   incCount();
                   }
                else
                   {
                   RBPairT t = tree;
                   for (;;)
                       {
                       int diff = cmp.compare(key, t.key());
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
                                 t = cast(RBPairT)(t.left());
                             else
                                {
                                tree = cast(RBPairT)(t.insertLeft(new RBPairT(key, element), tree));
                                incCount();
                                return ;
                                }
                             }
                          else
                             {
                             if (t.right() !is null)
                                 t = cast(RBPairT)(t.right());
                             else
                                {
                                tree = cast(RBPairT)(t.insertRight(new RBPairT(key, element), tree));
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
                assert(cmp !is null);
                assert(((count is 0) is (tree is null)));
                assert((tree is null || tree.size() is count));

                if (tree !is null)
                   {
                   tree.checkImplementation();
                   K last = K.init;
                   RBPairT t = cast(RBPairT)(tree.leftmost());

                   while (t !is null)
                         {
                         K v = t.key();
                         assert((last is K.init || cmp.compare(last, v) <= 0));
                         last = v;
                         t = cast(RBPairT)(t.successor());
                         }
                   }
        }


        private static class MapIterator(K, V) : AbstractMapIterator!(K, V)
        {
                private RBPairT pair;

                public this (TreeMap map)
                {
                        super (map);

                        if (map.tree)
                            pair = cast(RBPairT) map.tree.leftmost;
                }

                public final V get(inout K key)
                {
                        if (pair)
                            key = pair.key;
                        return get();
                }

                public final V get()
                {
                        decRemaining();
                        auto v = pair.element();
                        pair = cast(RBPairT) pair.successor();
                        return v;
                }
        }
}



debug (Test)
{
void main()
{
        auto map = new TreeMap!(char[], double);
        map.add ("foo", 1);
        map.add ("bar", 2);
        map.add ("wumpus", 3);
        
        foreach (key, value; map.keys) {typeof(key) x; x = key;}

        foreach (value; map.keys) {}

        foreach (value; map.elements) {}

        auto keys = map.keys();
        while (keys.more)
               auto v = keys.get();

        map.checkImplementation();
}
}

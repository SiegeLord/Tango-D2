/*
 File: TreeBag.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.TreeBag;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.Comparator,
                tango.util.collection.model.SortedValues,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.RBCell,
                tango.util.collection.impl.BagCollection,
                tango.util.collection.impl.AbstractIterator,
                tango.util.collection.impl.DefaultComparator;

/**
 *
 * RedBlack trees.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class TreeBag(T) : BagCollection!(T), SortedValues!(T)
{
        alias RBCell!(T)        RBCellT;
        alias Comparator!(T)    ComparatorT;


        // instance variables

        /**
         * The root of the tree. Null if empty.
        **/

        package RBCellT tree;

        /**
         * The comparator to use for ordering.
        **/
        protected ComparatorT cmp_;

        // constructors

        /**
         * Make an empty tree.
         * Initialize to use DefaultComparator for ordering
        **/
        public this ()
        {
                this(null, null, null, 0);
        }

        /**
         * Make an empty tree, using the supplied element screener.
         * Initialize to use DefaultComparator for ordering
        **/

        public this (Predicate s)
        {
                this(s, null, null, 0);
        }

        /**
         * Make an empty tree, using the supplied element comparator for ordering.
        **/
        public this (ComparatorT c)
        {
                this(null, c, null, 0);
        }

        /**
         * Make an empty tree, using the supplied element screener and comparator
        **/
        public this (Predicate s, ComparatorT c)
        {
                this(s, c, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, ComparatorT cmp, RBCellT t, int n)
        {
                super(s);
                count = n;
                tree = t;
                if (cmp !is null)
                    cmp_ = cmp;
                else
                   cmp_ = new DefaultComparator!(T);
        }

        /**
         * Make an independent copy of the tree. Does not clone elements.
        **/ 

        public TreeBag duplicate()
        {
                if (count is 0)
                    return new TreeBag!(T)(screener, cmp_);
                else
                   return new TreeBag!(T)(screener, cmp_, tree.copyTree(), count);
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

                return tree.find(element, cmp_) !is null;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(log n).
         * @see store.Collection#instances
        **/
        public final uint instances(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return 0;

                return tree.count(element, cmp_);
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

        /**
         * Implements store.Collection.View.opApply
         * Time complexity: O(n).
         * @see store.Collection.View#opApply
        **/
        int opApply (int delegate (inout T value) dg)
        {
                auto scope iterator = new CellIterator!(T)(this);
                return iterator.opApply (dg);
        }


        // ElementSortedCollection methods


        /**
         * Implements store.ElementSortedCollection.comparator
         * Time complexity: O(1).
         * @see store.ElementSortedCollection#comparator
        **/
        public final ComparatorT comparator()
        {
                return cmp_;
        }

        /**
         * Reset the comparator. Will cause a reorganization of the tree.
         * Time complexity: O(n log n).
        **/
        public final void comparator(ComparatorT cmp)
        {
                if (cmp !is cmp_)
                   {
                   if (cmp !is null)
                       cmp_ = cmp;
                   else
                      cmp_ = new DefaultComparator!(T);

                   if (count !is 0)
                      {       // must rebuild tree!
                      incVersion();
                      RBCellT t = tree.leftmost();
                      tree = null;
                      count = 0;
                      while (t !is null)
                            {
                            add_(t.element(), false);
                            t = t.successor();
                            }
                      }
                   }
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
         * Time complexity: O(log n * instances(element)).
         * @see store.MutableCollection#removeAll
        **/
        public final void removeAll(T element)
        {
                remove_(element, true);
        }


        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(log n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void remove(T element)
        {
                remove_(element, false);
        }

        /**
         * Implements store.MutableCollection.replaceOneOf
         * Time complexity: O(log n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replace(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(log n * instances(oldElement)).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(log n).
         * Takes the least element.
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (count !is 0)
                   {
                   RBCellT p = tree.leftmost();
                   T v = p.element();
                   tree = p.remove(tree);
                   decCount();
                   return v;
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableBag methods

        /**
         * Implements store.MutableBag.addIfAbsent
         * Time complexity: O(log n).
         * @see store.MutableBag#addIfAbsent
        **/
        public final void addIf (T element)
        {
                add_(element, true);
        }


        /**
         * Implements store.MutableBag.add.
         * Time complexity: O(log n).
         * @see store.MutableBag#add
        **/
        public final void add (T element)
        {
                add_(element, false);
        }


        // helper methods

        private final void add_(T element, bool checkOccurrence)
        {
                checkElement(element);

                if (tree is null)
                   {
                   tree = new RBCellT(element);
                   incCount();
                   }
                else
                   {
                   RBCellT t = tree;

                   for (;;)
                       {
                       int diff = cmp_.compare(element, t.element());
                       if (diff is 0 && checkOccurrence)
                           return ;
                       else
                          if (diff <= 0)
                             {
                             if (t.left() !is null)
                                 t = t.left();
                             else
                                {
                                tree = t.insertLeft(new RBCellT(element), tree);
                                incCount();
                                return ;
                                }
                             }
                          else
                             {
                             if (t.right() !is null)
                                 t = t.right();
                              else
                                 {
                                 tree = t.insertRight(new RBCellT(element), tree);
                                 incCount();
                                 return ;
                                 }
                              }
                          }
                   }
        }


        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element))
                    return ;

                while (count > 0)
                      {
                      RBCellT p = tree.find(element, cmp_);

                      if (p !is null)
                         {
                         tree = p.remove(tree);
                         decCount();
                         if (!allOccurrences)
                             return ;
                         }
                      else
                         break;
                      }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || count is 0 || oldElement == newElement)
                    return ;

                while (contains(oldElement))
                      {
                      remove(oldElement);
                      add (newElement);
                      if (!allOccurrences)
                          return ;
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
                assert(((count is 0) is (tree is null)));
                assert((tree is null || tree.size() is count));

                if (tree !is null)
                   {
                   tree.checkImplementation();
                   T last = T.init;
                   RBCellT t = tree.leftmost();
                   while (t !is null)
                         {
                         T v = t.element();
                         if (last !is T.init)
                             assert(cmp_.compare(last, v) <= 0);
                         last = v;
                         t = t.successor();
                         }
                   }
        }


        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        private static class CellIterator(T) : AbstractIterator!(T)
        {
                private RBCellT cell;

                public this (TreeBag bag)
                {
                        super(bag);

                        if (bag.tree)
                            cell = bag.tree.leftmost;
                }

                public final T get()
                {
                        decRemaining();
                        auto v = cell.element();
                        cell = cell.successor();
                        return v;
                }

                int opApply (int delegate (inout T value) dg)
                {
                        int result;

                        for (auto i=remaining(); i--;)
                            {
                            auto value = get();
                            if ((result = dg(value)) != 0)
                                 break;
                            }
                        return result;
                }
        }
}



debug (Test)
{
        import tango.io.Console;
        
        void main()
        {
                auto bag = new TreeBag!(char[]);
                bag.add ("bar");
                bag.add ("barrel");
                bag.add ("foo");

                foreach (value; bag.elements) {}

                auto elements = bag.elements();
                while (elements.more)
                       auto v = elements.get();

                foreach (value; bag.elements)
                         Cout (value).newline;
                     
                bag.checkImplementation();
        }
}

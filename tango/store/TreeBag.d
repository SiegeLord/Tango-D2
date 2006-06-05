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


module tango.store.TreeBag;

private import tango.store.impl.RBCell;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableBagImpl;
private import tango.store.impl.DefaultComparator;

private import tango.store.model.Bag;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Comparator;
private import tango.store.model.Iterator;
private import tango.store.model.MutableBag;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;
private import tango.store.model.ElementSortedCollection;


/**
 *
 * RedBlack trees.
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class TreeBagT(T) : MutableBagImplT!(T), ElementSortedCollectionT!(T)
{
        alias RBCellT!(T)               RBCell;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias ComparatorT!(T)           Comparator;
        alias CollectionIteratorT!(T)   CollectionIterator;


        // instance variables

        /**
         * The root of the tree. Null if empty.
        **/

        package RBCell tree_;

        /**
         * The comparator to use for ordering.
        **/
        protected Comparator cmp_;

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
        public this (Comparator c)
        {
                this(null, c, null, 0);
        }

        /**
         * Make an empty tree, using the supplied element screener and comparator
        **/
        public this (Predicate s, Comparator c)
        {
                this(s, c, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, Comparator cmp, RBCell t, int n)
        {
                super(s);
                count_ = n;
                tree_ = t;
                if (cmp !is null)
                    cmp_ = cmp;
                else
                   cmp_ = new DefaultComparatorT!(T);
        }

        /**
         * Make an independent copy of the tree. Does not clone elements.
        **/ 
        //  protected Object clone() {
        public Collection duplicate()
        {
                if (count_ is 0)
                    return new TreeBagT!(T)(screener_, cmp_);
                else
                   return new TreeBagT!(T)(screener_, cmp_, tree_.copyTree(), count_);
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

                return tree_.find(element, cmp_) !is null;
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

                return tree_.count(element, cmp_);
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


        // ElementSortedCollection methods


        /**
         * Implements store.ElementSortedCollection.elementComparator
         * Time complexity: O(1).
         * @see store.ElementSortedCollection#elementComparator
        **/
        public final Comparator elementComparator()
        {
                return cmp_;
        }

        /**
         * Reset the comparator. Will cause a reorganization of the tree.
         * Time complexity: O(n log n).
        **/
        public final void elementComparator(Comparator cmp)
        {
                if (cmp !is cmp_)
                   {
                   if (cmp !is null)
                       cmp_ = cmp;
                   else
                      cmp_ = new DefaultComparatorT!(T);

                   if (count_ !is 0)
                      {       // must rebuild tree!
                      incVersion();
                      RBCell t = tree_.leftmost();
                      tree_ = null;
                      count_ = 0;
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
                tree_ = null;
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(log n * instances(element)).
         * @see store.MutableCollection#exclude
        **/
        public final void exclude(T element)
        {
                remove_(element, true);
        }


        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(log n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void removeOneOf(T element)
        {
                remove_(element, false);
        }

        /**
         * Implements store.MutableCollection.replaceOneOf
         * Time complexity: O(log n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replaceOneOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(log n * instances(oldElement)).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAllOf(T oldElement, T newElement)
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
                if (count_ !is 0)
                   {
                   RBCell p = tree_.leftmost();
                   T v = p.element();
                   tree_ = p.remove(tree_);
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
        public final void addIfAbsent(T element)
        {
                add_(element, true);
        }


        /**
         * Implements store.MutableBag.add.
         * Time complexity: O(log n).
         * @see store.MutableBag#add
        **/
        public final void add
                (T element)
        {
                add_(element, false);
        }


        // helper methods

        private final void add_(T element, bool checkOccurrence)
        {
                checkElement(element);

                if (tree_ is null)
                   {
                   tree_ = new RBCell(element);
                   incCount();
                   }
                else
                   {
                   RBCell t = tree_;

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
                                tree_ = t.insertLeft(new RBCell(element), tree_);
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
                                 tree_ = t.insertRight(new RBCell(element), tree_);
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

                while (count_ > 0)
                      {
                      RBCell p = tree_.find(element, cmp_);

                      if (p !is null)
                         {
                         tree_ = p.remove(tree_);
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
                if (!isValidArg(oldElement) || count_ is 0 || oldElement == newElement)
                    return ;

                while (contains(oldElement))
                      {
                      removeOneOf(oldElement);
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
                assert(((count_ is 0) is (tree_ is null)));
                assert((tree_ is null || tree_.size() is count_));

                if (tree_ !is null)
                   {
                   tree_.checkImplementation();
                   T last = T.init;
                   RBCell t = tree_.leftmost();
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


        /**
         *
         *
         * Enumerator for collections based on RBCells
         * @author Doug Lea
         * @version 0.93
         *
         * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
        **/
        private static class CellIterator(T) : AbstractIteratorT!(T)
        {
                private RBCell  cell,
                                start;

                public this (TreeBagT bag)
                {
                        super(bag);
                        start = bag.tree_;
                }

                public final bool more()
                {
                        if (cell)
                            cell = cell.successor();
                        else
                           if (start)
                               cell = start.leftmost(), start = null;
                           else
                              return false;
                                                              
                        decRemaining();
                        return true;
                }

                public final T value()
                {
                        return cell.element();
                }
        }
}


alias TreeBagT!(Object) TreeBag;
/*
 File: LinkSeq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 2Oct95  dl@cs.oswego.edu   repack from LLSeq.d
 9apr97  dl                 insert bounds check in first
*/


module tango.store.LinkSeq;

private import tango.store.impl.LLCell;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableSeqImpl;

private import tango.store.model.Seq;
private import tango.store.model.Predicate;
private import tango.store.model.Comparator;
private import tango.store.model.Collection;
private import tango.store.model.Iterator;
private import tango.store.model.SortableCollection;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;

/**
 *
 * LinkedList implementation.
 * Publically implements only those methods defined in its interfaces.
 *
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class LinkSeqT(T) : MutableSeqImplT!(T), SortableCollectionT!(T)
{
        alias LLCellT!(T)               LLCell;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias ComparatorT!(T)           Comparator;
        alias CollectionIteratorT!(T)   CollectionIterator;

        // instance variables

        /**
         * The head of the list. Null iff count_ == 0
        **/

        package LLCell list_;

        // constructors

        /**
         * Create a new empty list
        **/

        public this ()
        {
                this(null, null, 0);
        }

        /**
         * Create a list with a given element screener
        **/

        public this (Predicate screener)
        {
                this(screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, LLCell l, int c)
        {
                super(s);
                list_ = l;
                count_ = c;
        }

        /**
         * Build an independent copy of the list.
         * The elements themselves are not cloned
        **/

        //  protected Object clone() {
        public Collection duplicate()
        {
                if (list_ is null)
                    return new LinkSeqT(screener_, null, 0);
                else
                   return new LinkSeqT(screener_, list_.copyList(), count_);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count_ is 0)
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
                if (!isValidArg(element) || count_ is 0)
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
                return new CellIterator!(T)(this);
        }



        // Seq Methods

        /**
         * Implements store.Seq.head.
         * Time complexity: O(1).
         * @see store.Seq#head
        **/
        public final T head()
        {
                return firstCell().element();
        }

        /**
         * Implements store.Seq.tail.
         * Time complexity: O(n).
         * @see store.Seq#tail
        **/
        public final T tail()
        {
                return lastCell().element();
        }

        /**
         * Implements store.Seq.get.
         * Time complexity: O(n).
         * @see store.Seq#get
        **/
        public final T get(int index)
        {
                return cellAt(index).element();
        }

        /**
         * Implements store.Seq.first.
         * Time complexity: O(n).
         * @see store.Seq#first
        **/
        public final int first(T element, int startingIndex = 0)
        {
                if (!isValidArg(element) || list_ is null || startingIndex >= count_)
                      return -1;

                if (startingIndex < 0)
                    startingIndex = 0;

                LLCell p = list_.nth(startingIndex);
                if (p !is null)
                   {
                   int i = p.index(element);
                   if (i >= 0)
                       return i + startingIndex;
                   }
                return -1;
        }

        /**
         * Implements store.Seq.last.
         * Time complexity: O(n).
         * @see store.Seq#last
        **/
        public final int last(T element, int startingIndex = 0)
        {
                if (!isValidArg(element) || list_ is null)
                     return -1;

                int i = 0;
                if (startingIndex >= size())
                    startingIndex = size() - 1;

                int index = -1;
                LLCell p = list_;
                while (i <= startingIndex && p !is null)
                      {
                      if (p.element() == (element))
                          index = i;
                      ++i;
                      p = p.next();
                      }
                return index;
        }



        /**
         * Implements store.Seq.subseq.
         * Time complexity: O(length).
         * @see store.Seq#subseq
        **/
        public final  /* LinkedList */ SeqT!(T) subseq(int from, int _length)
        {
                if (_length > 0)
                   {
                   LLCell p = cellAt(from);
                   LLCell newlist = new LLCell(p.element(), null);
                   LLCell current = newlist;
         
                   for (int i = 1; i < _length; ++i)
                       {
                       p = p.next();
                       if (p is null)
                           checkIndex(from + i); // force exception

                       current.linkNext(new LLCell(p.element(), null));
                       current = current.next();
                       }
                   return new LinkSeqT!(T)(screener_, newlist, _length);
                   }
                else
                   return new LinkSeqT!(T)(screener_, null, 0);
        }


        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                if (list_ !is null)
                   {
                   list_ = null;
                   setCount(0);
                   }
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
         * Implements store.MutableCollection.replaceOneOf
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
         * Time complexity: O(1).
         * takes the first element on the list
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                T v = head();
                removeHead();
                return v;
        }

        // SortableCollection methods

        /**
         * Implements store.SortableCollection.sort.
         * Time complexity: O(n log n).
         * Uses a merge-sort-based algorithm.
         * @see store.SortableCollection#sort
        **/
        public final void sort(Comparator cmp)
        {
                if (list_ !is null)
                   {
                   list_ = LLCell.mergeSort(list_, cmp);
                   incVersion();
                   }
        }


        // MutableSeq methods

        /**
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(1).
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(T element)
        {
                checkElement(element);
                list_ = new LLCell(element, list_);
                incCount();
        }

        /**
         * Implements store.MutableSeq.replaceHead.
         * Time complexity: O(1).
         * @see store.MutableSeq#replaceHead
        **/
        public final void replaceHead(T element)
        {
                checkElement(element);
                firstCell().element(element);
                incVersion();
        }

        /**
         * Implements store.MutableSeq.removeHead.
         * Time complexity: O(1).
         * @see store.MutableSeq#removeHead
        **/
        public final void removeHead()
        {
                list_ = firstCell().next();
                decCount();
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(n).
         * @see store.MutableSeq#append
        **/
        public final void append(T element)
        {
                checkElement(element);
                if (list_ is null)
                    prepend(element);
                else
                   {
                   list_.tail().next(new LLCell(element));
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.replaceTail.
         * Time complexity: O(n).
         * @see store.MutableSeq#replaceTail
        **/
        public final void replaceTail(T element)
        {
                checkElement(element);
                lastCell().element(element);
                incVersion();
        }

        /**
         * Implements store.MutableSeq.removeTail.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeTail
        **/
        public final void removeTail()
        {
                if (firstCell().next() is null)
                    removeHead();
                else
                   {
                   LLCell trail = list_;
                   LLCell p = trail.next();

                   while (p.next() !is null)
                         {
                         trail = p;
                         p = p.next();
                         }
                   trail.next(null);
                   decCount();
                   }
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(n).
         * @see store.MutableSeq#insert
        **/
        public final void insert(int index, T element)
        {
                if (index is 0)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   cellAt(index - 1).linkNext(new LLCell(element));
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.remove.
         * Time complexity: O(n).
         * @see store.MutableSeq#remove
        **/
        public final void remove(int index)
        {
                if (index is 0)
                    removeHead();
                else
                   {
                   cellAt(index - 1).unlinkNext();
                   decCount();
                   }
        }

        /**
         * Implements store.MutableSeq.replace.
         * Time complexity: O(n).
         * @see store.MutableSeq#replace
        **/
        public final void replace(int index, T element)
        {
                cellAt(index).element(element);
                incVersion();
        }

        /**
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(number of elements in e).
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(Iterator e)
        {
                splice_(e, null, list_);
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(n + number of elements in e).
         * @see store.MutableSeq#append
        **/
        public final void append(Iterator e)
        {
                if (list_ is null)
                    splice_(e, null, null);
                else
                   splice_(e, list_.tail(), null);
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(n + number of elements in e).
         * @see store.MutableSeq#insert
        **/
        public final void insert(int index, Iterator e)
        {
                if (index is 0)
                    splice_(e, null, list_);
                else
                   {
                   LLCell p = cellAt(index - 1);
                   splice_(e, p, p.next());
                   }
        }

        /**
         * Implements store.MutableSeq.removeFromTo.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeFromTo
        **/
        public final void removeFromTo(int fromIndex, int toIndex)
        {
                checkIndex(toIndex);

                if (fromIndex <= toIndex)
                   {
                   if (fromIndex is 0)
                      {
                      LLCell p = firstCell();
                      for (int i = fromIndex; i <= toIndex; ++i)
                           p = p.next();
                      list_ = p;
                      }
                   else
                      {
                      LLCell f = cellAt(fromIndex - 1);
                      LLCell p = f;
                      for (int i = fromIndex; i <= toIndex; ++i)
                           p = p.next();
                      f.next(p.next());
                      }
                  addToCount( -(toIndex - fromIndex + 1));
                  }
        }



        // helper methods

        private final LLCell firstCell()
        {
                if (list_ !is null)
                    return list_;

                checkIndex(0);
                return null; // not reached!
        }

        private final LLCell lastCell()
        {
                if (list_ !is null)
                    return list_.tail();

                checkIndex(0);
                return null; // not reached!
        }

        private final LLCell cellAt(int index)
        {
                checkIndex(index);
                return list_.nth(index);
        }

        /**
         * Helper method for removeOneOf()
        **/

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count_ is 0)
                     return ;

                LLCell p = list_;
                LLCell trail = p;

                while (p !is null)
                      {
                      LLCell n = p.next();
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
                if (count_ is 0 || !isValidArg(oldElement) || oldElement == (newElement))
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

        /**
         * Splice elements of e between hd and tl. if hd is null return new hd
        **/

        private final void splice_(Iterator e, LLCell hd, LLCell tl)
        {
                if (e.more())
                   {
                   LLCell newlist = null;
                   LLCell current = null;

                   while (e.more())
                        {
                        T v = e.value();
                        checkElement(v);
                        incCount();

                        LLCell p = new LLCell(v, null);
                        if (newlist is null)
                            newlist = p;
                        else
                           current.next(p);
                        current = p;
                        }

                   if (current !is null)
                       current.next(tl);

                   if (hd is null)
                       list_ = newlist;
                   else
                      hd.next(newlist);
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

                int c = 0;
                for (LLCell p = list_; p !is null; p = p.next())
                    {
                    assert(canInclude(p.element()));
                    assert(instances(p.element()) > 0);
                    assert(contains(p.element()));
                    ++c;
                    }
                assert(c is count_);

        }


        private static class CellIterator(T) : AbstractIteratorT!(T)
        {
                private LLCell  cell,
                                start;

                public this (LinkSeqT seq)
                {
                        super (seq);
                        start = seq.list_;
                }

                public final bool more()
                {
                        if (cell)
                            cell = cell.next();
                        else
                           if (start)
                               cell = start, start = null;
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


alias LinkSeqT!(Object) LinkSeq;
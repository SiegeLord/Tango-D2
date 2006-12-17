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


module tango.util.collection.LinkSeq;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.Sortable,
                tango.util.collection.model.Comparator,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.LLCell,
                tango.util.collection.impl.SeqCollection,
                tango.util.collection.impl.AbstractIterator;

/**
 *
 * LinkedList implementation.
 * Publically implements only those methods defined in its interfaces.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class LinkSeq(T) : SeqCollection!(T), Sortable!(T)
{
        alias LLCell!(T) LLCellT;

        // instance variables

        /**
         * The head of the list. Null iff count == 0
        **/

        package LLCellT list;

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

        protected this (Predicate s, LLCellT l, int c)
        {
                super(s);
                list = l;
                count = c;
        }

        /**
         * Build an independent copy of the list.
         * The elements themselves are not cloned
        **/

        //  protected Object clone() {
        public LinkSeq duplicate()
        {
                if (list is null)
                    return new LinkSeq(screener, null, 0);
                else
                   return new LinkSeq(screener, list.copyList(), count);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count is 0)
                      return false;

                return list.find(element) !is null;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (!isValidArg(element) || count is 0)
                    return 0;

                return list.count(element);
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
                if (!isValidArg(element) || list is null || startingIndex >= count)
                      return -1;

                if (startingIndex < 0)
                    startingIndex = 0;

                LLCellT p = list.nth(startingIndex);
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
                if (!isValidArg(element) || list is null)
                     return -1;

                int i = 0;
                if (startingIndex >= size())
                    startingIndex = size() - 1;

                int index = -1;
                LLCellT p = list;
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
        public final LinkSeq subset(int from, int _length)
        {
                if (_length > 0)
                   {
                   LLCellT p = cellAt(from);
                   LLCellT newlist = new LLCellT(p.element(), null);
                   LLCellT current = newlist;
         
                   for (int i = 1; i < _length; ++i)
                       {
                       p = p.next();
                       if (p is null)
                           checkIndex(from + i); // force exception

                       current.linkNext(new LLCellT(p.element(), null));
                       current = current.next();
                       }
                   return new LinkSeq!(T)(screener, newlist, _length);
                   }
                else
                   return new LinkSeq!(T)(screener, null, 0);
        }


        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                if (list !is null)
                   {
                   list = null;
                   setCount(0);
                   }
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(n).
         * @see store.MutableCollection#exclude
        **/
        public final void removeAll (T element)
        {
                remove_(element, true);
        }

        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeOneOf
        **/
        public final void remove (T element)
        {
                remove_(element, false);
        }

        /**
         * Implements store.MutableCollection.replaceOneOf
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public final void replace (T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
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

        // Sortable methods

        /**
         * Implements store.Sortable.sort.
         * Time complexity: O(n log n).
         * Uses a merge-sort-based algorithm.
         * @see store.SortableCollection#sort
        **/
        public final void sort(Comparator!(T) cmp)
        {
                if (list !is null)
                   {
                   list = LLCellT.mergeSort(list, cmp);
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
                list = new LLCellT(element, list);
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
                list = firstCell().next();
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
                if (list is null)
                    prepend(element);
                else
                   {
                   list.tail().next(new LLCellT(element));
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
                   LLCellT trail = list;
                   LLCellT p = trail.next();

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
         * Implements store.MutableSeq.addAt.
         * Time complexity: O(n).
         * @see store.MutableSeq#addAt
        **/
        public final void addAt(int index, T element)
        {
                if (index is 0)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   cellAt(index - 1).linkNext(new LLCellT(element));
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.removeAt.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeAt
        **/
        public final void removeAt(int index)
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
         * Implements store.MutableSeq.replaceAt.
         * Time complexity: O(n).
         * @see store.MutableSeq#replaceAt
        **/
        public final void replaceAt(int index, T element)
        {
                cellAt(index).element(element);
                incVersion();
        }

        /**
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(number of elements in e).
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(Iterator!(T) e)
        {
                splice_(e, null, list);
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(n + number of elements in e).
         * @see store.MutableSeq#append
        **/
        public final void append(Iterator!(T) e)
        {
                if (list is null)
                    splice_(e, null, null);
                else
                   splice_(e, list.tail(), null);
        }

        /**
         * Implements store.MutableSeq.addAt.
         * Time complexity: O(n + number of elements in e).
         * @see store.MutableSeq#addAt
        **/
        public final void addAt(int index, Iterator!(T) e)
        {
                if (index is 0)
                    splice_(e, null, list);
                else
                   {
                   LLCellT p = cellAt(index - 1);
                   splice_(e, p, p.next());
                   }
        }

        /**
         * Implements store.MutableSeq.removeFromTo.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeFromTo
        **/
        public final void removeRange (int fromIndex, int toIndex)
        {
                checkIndex(toIndex);

                if (fromIndex <= toIndex)
                   {
                   if (fromIndex is 0)
                      {
                      LLCellT p = firstCell();
                      for (int i = fromIndex; i <= toIndex; ++i)
                           p = p.next();
                      list = p;
                      }
                   else
                      {
                      LLCellT f = cellAt(fromIndex - 1);
                      LLCellT p = f;
                      for (int i = fromIndex; i <= toIndex; ++i)
                           p = p.next();
                      f.next(p.next());
                      }
                  addToCount( -(toIndex - fromIndex + 1));
                  }
        }



        // helper methods

        private final LLCellT firstCell()
        {
                if (list !is null)
                    return list;

                checkIndex(0);
                return null; // not reached!
        }

        private final LLCellT lastCell()
        {
                if (list !is null)
                    return list.tail();

                checkIndex(0);
                return null; // not reached!
        }

        private final LLCellT cellAt(int index)
        {
                checkIndex(index);
                return list.nth(index);
        }

        /**
         * Helper method for removeOneOf()
        **/

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count is 0)
                     return ;

                LLCellT p = list;
                LLCellT trail = p;

                while (p !is null)
                      {
                      LLCellT n = p.next();
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
                if (count is 0 || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                LLCellT p = list.find(oldElement);
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

        private final void splice_(Iterator!(T) e, LLCellT hd, LLCellT tl)
        {
                if (e.more())
                   {
                   LLCellT newlist = null;
                   LLCellT current = null;

                   while (e.more())
                        {
                        T v = e.get();
                        checkElement(v);
                        incCount();

                        LLCellT p = new LLCellT(v, null);
                        if (newlist is null)
                            newlist = p;
                        else
                           current.next(p);
                        current = p;
                        }

                   if (current !is null)
                       current.next(tl);

                   if (hd is null)
                       list = newlist;
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

                assert(((count is 0) is (list is null)));
                assert((list is null || list._length() is count));

                int c = 0;
                for (LLCellT p = list; p !is null; p = p.next())
                    {
                    assert(allows(p.element()));
                    assert(instances(p.element()) > 0);
                    assert(contains(p.element()));
                    ++c;
                    }
                assert(c is count);

        }


        private static class CellIterator(T) : AbstractIterator!(T)
        {
                private LLCellT cell;

                public this (LinkSeq seq)
                {
                        super (seq);
                        cell = seq.list;
                }

                public final T get()
                {
                        decRemaining();
                        auto v = cell.element();
                        cell = cell.next();
                        return v;
                }
        }
}


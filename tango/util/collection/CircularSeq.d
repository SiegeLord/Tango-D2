/*
 File: CircularSeq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses
*/


module tango.util.collection.CircularSeq;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.CLCell,
                tango.util.collection.impl.SeqCollection,
                tango.util.collection.impl.AbstractIterator;


/**
 *
 * Circular linked lists. Publically Implement only those
 * methods defined in interfaces.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class CircularSeq(T) : SeqCollection!(T)
{
        alias CLCell!(T) CLCellT;


        // instance variables

        /**
         * The head of the list. Null if empty
        **/
        package CLCellT list;

        // constructors

        /**
         * Make an empty list with no element screener
        **/

        public this ()
        {
                this(null, null, 0);
        }

        /**
         * Make an empty list with supplied element screener
        **/
        public this (Predicate screener)
        {
                this(screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, CLCellT h, int c)
        {
                super(s);
                list = h;
                count = c;
        }

        /**
         * Make an independent copy of the list. Elements themselves are not cloned
        **/

        public final CircularSeq duplicate()
        {
                if (list is null)
                    return new CircularSeq (screener, null, 0);
                else
                   return new CircularSeq (screener, list.copyList(), count);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || list is null)
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
                if (!isValidArg(element) || list is null)
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


        // Seq methods

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
         * Time complexity: O(1).
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
                if (startingIndex < 0)
                    startingIndex = 0;

                CLCellT p = list;
                if (p is null || !isValidArg(element))
                    return -1;

                for (int i = 0; true; ++i)
                    {
                    if (i >= startingIndex && p.element() == (element))
                        return i;

                    p = p.next();
                    if (p is list)
                        break;
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
                if (!isValidArg(element) || count is 0)
                    return -1;

                if (startingIndex >= size())
                    startingIndex = size() - 1;

                if (startingIndex < 0)
                    startingIndex = 0;

                CLCellT p = cellAt(startingIndex);
                int i = startingIndex;
                for (;;)
                    {
                    if (p.element() == (element))
                        return i;
                    else
                       if (p is list)
                           break;
                       else
                          {
                          p = p.prev();
                          --i;
                          }
                    }
                return -1;
        }

        /**
         * Implements store.Seq.subseq.
         * Time complexity: O(length).
         * @see store.Seq#subseq
        **/
        public final CircularSeq subset (int from, int _length)
        {
                if (_length > 0)
                   {
                   checkIndex(from);
                   CLCellT p = cellAt(from);
                   CLCellT newlist = new CLCellT(p.element());
                   CLCellT current = newlist;

                   for (int i = 1; i < _length; ++i)
                       {
                       p = p.next();
                       if (p is null)
                           checkIndex(from + i); // force exception

                       current.addNext(p.element());
                       current = current.next();
                       }
                   return new CircularSeq (screener, newlist, _length);
                   }
                else
                   return new CircularSeq ();
        }

        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                list = null;
                setCount(0);
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
        public final void replaceAll (T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }


        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(1).
         * takes the last element on the list.
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                auto v = tail();
                removeTail();
                return v;
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
                if (list is null)
                    list = new CLCellT(element);
                else
                   list = list.addPrev(element);
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
                if (firstCell().isSingleton())
                   list = null;
                else
                   {
                   auto n = list.next();
                   list.unlink();
                   list = n;
                   }
                decCount();
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(1).
         * @see store.MutableSeq#append
        **/
        public final void append(T element)
        {
                if (list is null)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   list.prev().addNext(element);
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.replaceTail.
         * Time complexity: O(1).
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
         * Time complexity: O(1).
         * @see store.MutableSeq#removeTail
        **/
        public final void removeTail()
        {
                auto l = lastCell();
                if (l is list)
                    list = null;
                else
                   l.unlink();
                decCount();
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
                   cellAt(index - 1).addNext(element);
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.replaceAt.
         * Time complexity: O(n).
         * @see store.MutableSeq#replaceAt
        **/
        public final void replaceAt(int index, T element)
        {
                checkElement(element);
                cellAt(index).element(element);
                incVersion();
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
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(number of elements in e).
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(Iterator!(T) e)
        {
                CLCellT hd = null;
                CLCellT current = null;
      
                while (e.more())
                      {
                      auto element = e.get();
                      checkElement(element);
                      incCount();

                      if (hd is null)
                         {
                         hd = new CLCellT(element);
                         current = hd;
                         }
                      else
                         {
                         current.addNext(element);
                         current = current.next();
                         }
                      }

                if (list is null)
                    list = hd;
                else
                   if (hd !is null)
                      {
                      auto tl = list.prev();
                      current.next(list);
                      list.prev(current);
                      tl.next(hd);
                      hd.prev(tl);
                      list = hd;
                      }
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(number of elements in e).
         * @see store.MutableSeq#append
        **/
        public final void append(Iterator!(T) e)
        {
                if (list is null)
                    prepend(e);
                else
                   {
                   CLCellT current = list.prev();
                   while (e.more())
                         {
                         T element = e.get();
                         checkElement(element);
                         incCount();
                         current.addNext(element);
                         current = current.next();
                         }
                   }
        }

        /**
         * Implements store.MutableSeq.addAt.
         * Time complexity: O(size() + number of elements in e).
         * @see store.MutableSeq#addAt
        **/
        public final void addAt(int index, Iterator!(T) e)
        {
                if (list is null || index is 0)
                    prepend(e);
                else
                   {
                   CLCellT current = cellAt(index - 1);
                   while (e.more())
                         {
                         T element = e.get();
                         checkElement(element);
                         incCount();
                         current.addNext(element);
                         current = current.next();
                         }
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
                CLCellT p = cellAt(fromIndex);
                CLCellT last = list.prev();
                for (int i = fromIndex; i <= toIndex; ++i)
                    {
                    decCount();
                    CLCellT n = p.next();
                    p.unlink();
                    if (p is list)
                       {
                       if (p is last)
                          {
                          list = null;
                          return ;
                          }
                       else
                          list = n;
                       }
                    p = n;
                    }
        }


        // helper methods

        /**
         * return the first cell, or throw exception if empty
        **/
        private final CLCellT firstCell()
        {
                if (list !is null)
                    return list;

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the last cell, or throw exception if empty
        **/
        private final CLCellT lastCell()
        {
                if (list !is null)
                    return list.prev();

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the index'th cell, or throw exception if bad index
        **/
        private final CLCellT cellAt(int index)
        {
                checkIndex(index);
                return list.nth(index);
        }

        /**
         * helper for remove/exclude
        **/
        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || list is null)
                    return;

                CLCellT p = list;
                for (;;)
                    {
                    CLCellT n = p.next();
                    if (p.element() == (element))
                       {
                       decCount();
                       p.unlink();
                       if (p is list)
                          {
                          if (p is n)
                             {
                             list = null;
                             break;
                             }
                          else
                             list = n;
                          }

                       if (! allOccurrences)
                             break;
                       else
                          p = n;
                       }
                    else
                       if (n is list)
                           break;
                       else
                          p = n;
                    }
        }


        /**
         * helper for replace *
        **/
        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || list is null)
                    return;

                CLCellT p = list;
                do {
                   if (p.element() == (oldElement))
                      {
                      checkElement(newElement);
                      incVersion();
                      p.element(newElement);
                      if (! allOccurrences)
                            return;
                      }
                   p = p.next();
                } while (p !is list);
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

                if (list is null)
                    return;

                int c = 0;
                CLCellT p = list;
                do {
                   assert(p.prev().next() is p);
                   assert(p.next().prev() is p);
                   assert(allows(p.element()));
                   assert(instances(p.element()) > 0);
                   assert(contains(p.element()));
                   p = p.next();
                   ++c;
                   } while (p !is list);

                assert(c is count);
        }


        static class CellIterator(T) : AbstractIterator!(T)
        {
                private CLCellT cell,
                                start;

                public this (CircularSeq seq)
                {
                        super (seq);
                        start = seq.list;
                }

                public final T get()
                {
                        decRemaining();

                        if (cell)
                            cell = cell.next();
                        else
                           if (start)
                               cell = start, start = null;
                           else
                              throw new Exception ("Invalid iterator");
                                                              
                        return cell.element;
                }
        }
}



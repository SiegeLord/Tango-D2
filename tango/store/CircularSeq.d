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


module tango.store.CircularSeq;

private import tango.store.impl.CLCell;
private import tango.store.impl.IteratorImpl;
private import tango.store.impl.MutableSeqImpl;

private import tango.store.model.Seq;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Iterator;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;


/**
 *
 * Circular linked lists. Publically Implement only those
 * methods defined in interfaces.
 *
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class CircularSeqT(T) : MutableSeqImplT!(T)
{
        alias CLCellT!(T)               CLCell;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias CollectionIteratorT!(T)   CollectionIterator;


        // instance variables

        /**
         * The head of the list. Null if empty
        **/
        package CLCell list_;

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

        protected this (Predicate s, CLCell h, int c)
        {
                super(s);
                list_ = h;
                count_ = c;
        }

        /**
         * Make an independent copy of the list. Elements themselves are not cloned
        **/

        public Collection duplicate()
        {
                if (list_ is null)
                    return new CircularSeqT (screener_, null, 0);
                else
                   return new CircularSeqT (screener_, list_.copyList(), count_);
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public synchronized bool contains(T element)
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
        public synchronized int instances(T element)
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
        public synchronized CollectionIterator elements()
        {
                return new CellIterator!(T)(this);
        }


        // Seq methods

        /**
         * Implements store.Seq.head.
         * Time complexity: O(1).
         * @see store.Seq#head
        **/
        public synchronized T head()
        {
                return firstCell().element();
        }

        /**
         * Implements store.Seq.tail.
         * Time complexity: O(1).
         * @see store.Seq#tail
        **/
        public synchronized T tail()
        {
                return lastCell().element();
        }

        /**
         * Implements store.Seq.get.
         * Time complexity: O(n).
         * @see store.Seq#get
        **/
        public synchronized T get(int index)
        {
                return cellAt(index).element();
        }

        /**
         * Implements store.Seq.first.
         * Time complexity: O(n).
         * @see store.Seq#first
        **/
        public synchronized int first(T element, int startingIndex = 0)
        {
                if (startingIndex < 0)
                    startingIndex = 0;

                CLCell p = list_;
                if (p is null || !isValidArg(element))
                    return -1;

                for (int i = 0; true; ++i)
                    {
                    if (i >= startingIndex && p.element() == (element))
                        return i;

                    p = p.next();
                    if (p is list_)
                        break;
                    }
                return -1;
        }


        /**
         * Implements store.Seq.last.
         * Time complexity: O(n).
         * @see store.Seq#last
        **/
        public synchronized int last(T element, int startingIndex = 0)
        {
                if (!isValidArg(element) || count_ is 0)
                    return -1;

                if (startingIndex >= size())
                    startingIndex = size() - 1;

                if (startingIndex < 0)
                    startingIndex = 0;

                CLCell p = cellAt(startingIndex);
                int i = startingIndex;
                for (;;)
                    {
                    if (p.element() == (element))
                        return i;
                    else
                       if (p is list_)
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
        public synchronized  /* CircularSeq */ SeqT!(T) subseq(int from, int _length)
        {
                if (_length > 0)
                   {
                   checkIndex(from);
                   CLCell p = cellAt(from);
                   CLCell newlist = new CLCell(p.element());
                   CLCell current = newlist;

                   for (int i = 1; i < _length; ++i)
                       {
                       p = p.next();
                       if (p is null)
                           checkIndex(from + i); // force exception

                       current.addNext(p.element());
                       current = current.next();
                       }
                   return new CircularSeqT (screener_, newlist, _length);
                   }
                else
                   return new CircularSeqT ();
        }

        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public synchronized void clear()
        {
                list_ = null;
                setCount(0);
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(n).
         * @see store.MutableCollection#exclude
        **/
        public synchronized void exclude(T element)
        {
                remove_(element, true);
        }

        /**
         * Implements store.MutableCollection.removeOneOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#removeOneOf
        **/
        public synchronized void removeOneOf(T element)
        {
                remove_(element, false);
        }

        /**
         * Implements store.MutableCollection.replaceOneOf
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceOneOf
        **/
        public synchronized void replaceOneOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements store.MutableCollection.replaceAllOf.
         * Time complexity: O(n).
         * @see store.MutableCollection#replaceAllOf
        **/
        public synchronized void replaceAllOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }


        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(1).
         * takes the last element on the list.
         * @see store.MutableCollection#take
        **/
        public synchronized T take()
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
        public synchronized void prepend(T element)
        {
                checkElement(element);
                if (list_ is null)
                    list_ = new CLCell(element);
                else
                   list_ = list_.addPrev(element);
                incCount();
        }

        /**
         * Implements store.MutableSeq.replaceHead.
         * Time complexity: O(1).
         * @see store.MutableSeq#replaceHead
        **/
        public synchronized void replaceHead(T element)
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
        public synchronized void removeHead()
        {
                if (firstCell().isSingleton())
                   list_ = null;
                else
                   {
                   auto n = list_.next();
                   list_.unlink();
                   list_ = n;
                   }
                decCount();
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(1).
         * @see store.MutableSeq#append
        **/
        public synchronized void append(T element)
        {
                if (list_ is null)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   list_.prev().addNext(element);
                   incCount();
                   }
        }

        /**
         * Implements store.MutableSeq.replaceTail.
         * Time complexity: O(1).
         * @see store.MutableSeq#replaceTail
        **/
        public synchronized void replaceTail(T element)
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
        public synchronized void removeTail()
        {
                auto l = lastCell();
                if (l is list_)
                    list_ = null;
                else
                   l.unlink();
                decCount();
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(n).
         * @see store.MutableSeq#insert
        **/
        public synchronized void insert(int index, T element)
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
         * Implements store.MutableSeq.replace.
         * Time complexity: O(n).
         * @see store.MutableSeq#replace
        **/
        public synchronized void replace(int index, T element)
        {
                checkElement(element);
                cellAt(index).element(element);
                incVersion();
        }

        /**
         * Implements store.MutableSeq.remove.
         * Time complexity: O(n).
         * @see store.MutableSeq#remove
        **/
        public synchronized void remove(int index)
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
        public synchronized void prepend(Iterator e)
        {
                CLCell hd = null;
                CLCell current = null;
      
                while (e.more())
                      {
                      auto element = e.value();
                      checkElement(element);
                      incCount();

                      if (hd is null)
                         {
                         hd = new CLCell(element);
                         current = hd;
                         }
                      else
                         {
                         current.addNext(element);
                         current = current.next();
                         }
                      }

                if (list_ is null)
                    list_ = hd;
                else
                   if (hd !is null)
                      {
                      auto tl = list_.prev();
                      current.next(list_);
                      list_.prev(current);
                      tl.next(hd);
                      hd.prev(tl);
                      list_ = hd;
                      }
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(number of elements in e).
         * @see store.MutableSeq#append
        **/
        public synchronized void append(Iterator e)
        {
                if (list_ is null)
                    prepend(e);
                else
                   {
                   CLCell current = list_.prev();
                   while (e.more())
                         {
                         T element = e.value();
                         checkElement(element);
                         incCount();
                         current.addNext(element);
                         current = current.next();
                         }
                   }
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(size() + number of elements in e).
         * @see store.MutableSeq#insert
        **/
        public synchronized void insert(int index, Iterator e)
        {
                if (list_ is null || index is 0)
                    prepend(e);
                else
                   {
                   CLCell current = cellAt(index - 1);
                   while (e.more())
                         {
                         T element = e.value();
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
        public synchronized void removeFromTo(int fromIndex, int toIndex)
        {
                checkIndex(toIndex);
                CLCell p = cellAt(fromIndex);
                CLCell last = list_.prev();
                for (int i = fromIndex; i <= toIndex; ++i)
                    {
                    decCount();
                    CLCell n = p.next();
                    p.unlink();
                    if (p is list_)
                       {
                       if (p is last)
                          {
                          list_ = null;
                          return ;
                          }
                       else
                          list_ = n;
                       }
                    p = n;
                    }
        }


        // helper methods

        /**
         * return the first cell, or throw exception if empty
        **/
        private CLCell firstCell()
        {
                if (list_ !is null)
                    return list_;

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the last cell, or throw exception if empty
        **/
        private CLCell lastCell()
        {
                if (list_ !is null)
                    return list_.prev();

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the index'th cell, or throw exception if bad index
        **/
        private CLCell cellAt(int index)
        {
                checkIndex(index);
                return list_.nth(index);
        }

        /**
         * helper for remove/exclude
        **/
        private void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || list_ is null)
                    return;

                CLCell p = list_;
                for (;;)
                    {
                    CLCell n = p.next();
                    if (p.element() == (element))
                       {
                       decCount();
                       p.unlink();
                       if (p is list_)
                          {
                          if (p is n)
                             {
                             list_ = null;
                             break;
                             }
                          else
                             list_ = n;
                          }

                       if (! allOccurrences)
                             break;
                       else
                          p = n;
                       }
                    else
                       if (n is list_)
                           break;
                       else
                          p = n;
                    }
        }


        /**
         * helper for replace*
        **/
        private void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || list_ is null)
                    return;

                CLCell p = list_;
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
                } while (p !is list_);
        }

        // ImplementationCheckable methods

        /**
         * Implements store.ImplementationCheckable.checkImplementation.
         * @see store.ImplementationCheckable#checkImplementation
        **/

        public synchronized void checkImplementation()
        {
                super.checkImplementation();

                assert(((count_ is 0) is (list_ is null)));
                assert((list_ is null || list_._length() is count_));

                if (list_ is null)
                    return;

                int c = 0;
                CLCell p = list_;
                do {
                   assert(p.prev().next() is p);
                   assert(p.next().prev() is p);
                   assert(canInclude(p.element()));
                   assert(instances(p.element()) > 0);
                   assert(contains(p.element()));
                   p = p.next();
                   ++c;
                   } while (p !is list_);

                assert(c is count_);
        }


        static class CellIterator(T) : IteratorImplT!(T)
        {
                private CLCell  cell,
                                start;

                public this (CircularSeqT seq)
                {
                        super (seq);
                        start = seq.list_;
                }

                public bool more()
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

                public T value()
                {
                        return cell.element();
                }
        }
}


alias CircularSeqT!(Object) CircularSeq;
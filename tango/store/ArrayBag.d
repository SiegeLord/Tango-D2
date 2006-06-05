/*
 File: ArrayBag.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.ArrayBag;

private import tango.store.Exception;

private import tango.store.impl.CLCell;
private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableBagImpl;

private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;


/**
 *
 * Linked Buffer implementation of Bags. The Bag consists of
 * any number of buffers holding elements, arranged in a list.
 * Each buffer holds an array of elements. The size of each
 * buffer is the value of chunkSize that was current during the
 * operation that caused the Bag to grow. The chunkSize() may
 * be adjusted at any time. (It is not considered a version change.)
 * 
 * <P>
 * All but the final buffer is always kept full.
 * When a buffer has no elements, it is released (so is
 * available for garbage collection).
 * <P>
 * ArrayBags are good choices for collections in which
 * you merely put a lot of things in, and then look at
 * them via enumerations, but don't often look for
 * particular elements.
 * 
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class ArrayBagT(T) : MutableBagImplT!(T)
{
        alias CLCellT!(T[])              CLCell;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias CollectionIteratorT!(T)   CollectionIterator;


        /**
         * The default chunk size to use for buffers
        **/

        public static int defaultChunkSize = 32;

        // instance variables

        /**
         * The last node of the circular list of chunks. Null if empty.
        **/

        package CLCell tail_;

        /**
         * The number of elements of the tail node actually used. (all others
         * are kept full).
        **/
        protected int lastCount_;

        /**
         * The chunk size to use for making next buffer
        **/

        protected int chunkSize_;

        // constructors

        /**
         * Make an empty buffer.
        **/
        public this ()
        {
                this (null, 0, null, 0, defaultChunkSize);
        }

        /**
         * Make an empty buffer, using the supplied element screener.
        **/

        public this (Predicate s)
        {
                this (s, 0, null, 0, defaultChunkSize);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        protected this (Predicate s, int n, CLCell t, int lc, int cs)
        {
                super (s);
                count_ = n;
                tail_ = t;
                lastCount_ = lc;
                chunkSize_ = cs;
        }

        /**
         * Make an independent copy. Does not clone elements.
        **/ 

        public final Collection duplicate ()
        {
                if (count_ is 0)
                    return new ArrayBagT (screener_);
                else
                   {
                   CLCell h = tail_.copyList();
                   CLCell p = h;

                   do {
                      T[] obuff = p.element();
                      T[] nbuff = new T[obuff.length];

                      for (int i = 0; i < obuff.length; ++i)
                           nbuff[i] = obuff[i];

                      p.element(nbuff);
                      p = p.next();
                      } while (p !is h);

                   return new ArrayBagT (screener_, count_, h, lastCount_, chunkSize_);
                   }
        }


        /**
         * Report the chunk size used when adding new buffers to the list
        **/

        public final int chunkSize()
        {
                return chunkSize_;
        }

        /**
         * Set the chunk size to be used when adding new buffers to the 
         * list during future add() operations.
         * Any value greater than 0 is OK. (A value of 1 makes this a
         * into very slow simulation of a linked list!)
        **/

        public final void chunkSize (int newChunkSize)
        {
                if (newChunkSize > 0)
                    chunkSize_ = newChunkSize;
                else
                   throw new IllegalArgumentException("Attempt to set negative chunk size value");
        }

        // Collection methods

        /*
          This code is pretty repetitive, but I don't know a nice way to
          separate traversal logic from actions
        */

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count_ is 0)
                     return false;

                CLCell p = tail_.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail_;

                    int n;
                    if (isLast)
                        n = lastCount_;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                        {
                        if (buff[i] == (element))
                        return true;
                        }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
                return false;
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

                int c = 0;
                CLCell p = tail_.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail_;

                    int n;
                    if (isLast)
                        n = lastCount_;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                       {
                       if (buff[i] == (element))
                           ++c;
                       }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
                return c;
        }

        /**
         * Implements store.Collection.elements.
         * Time complexity: O(1).
         * @see store.Collection#elements
        **/
        public final CollectionIterator elements()
        {
                return new ArrayIterator!(T)(this);
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
                tail_ = null;
                lastCount_ = 0;
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
         * Takes the least element.
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                if (count_ !is 0)
                   {
                   T[] buff = tail_.element();
                   T v = buff[lastCount_ -1];
                   buff[lastCount_ -1] = T.init;
                   shrink_();
                   return v;
                   }
                checkIndex(0);
                return T.init; // not reached
        }



        // MutableBag methods

        /**
         * Implements store.MutableBag.addIfAbsent.
         * Time complexity: O(n).
         * @see store.MutableBag#addIfAbsent
        **/
        public final void addIfAbsent(T element)
        {
                if (!contains(element))
                     add (element);
        }


        /**
         * Implements store.MutableBag.add.
         * Time complexity: O(1).
         * @see store.MutableBag#add
        **/
        public final void add (T element)
        {
                checkElement(element);

                incCount();
                if (tail_ is null)
                   {
                   tail_ = new CLCell(new T[chunkSize_]);
                   lastCount_ = 0;
                   }

                T[] buff = tail_.element();
                if (lastCount_ is buff.length)
                   {
                   buff = new T[chunkSize_];
                   tail_.addNext(buff);
                   tail_ = tail_.next();
                   lastCount_ = 0;
                   }

                buff[lastCount_++] = element;
        }

        /**
         * helper for remove/exclude
        **/

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count_ is 0)
                     return ;

                CLCell p = tail_;

                for (;;)
                    {
                    T[] buff = p.element();
                    int i = (p is tail_) ? lastCount_ - 1 : buff.length - 1;
                    
                    while (i >= 0)
                          {
                          if (buff[i] == (element))
                             {
                             T[] lastBuff = tail_.element();
                             buff[i] = lastBuff[lastCount_ -1];
                             lastBuff[lastCount_ -1] = T.init;
                             shrink_();
        
                             if (!allOccurrences || count_ is 0)
                                  return ;
        
                             if (p is tail_ && i >= lastCount_)
                                 i = lastCount_ -1;
                             }
                          else
                             --i;
                          }

                    if (p is tail_.next())
                        break;
                    else
                       p = p.prev();
                }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || count_ is 0 || oldElement == (newElement))
                     return ;

                CLCell p = tail_.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail_;

                    int n;
                    if (isLast)
                        n = lastCount_;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                        {
                        if (buff[i] == (oldElement))
                           {
                           checkElement(newElement);
                           incVersion();
                           buff[i] = newElement;
                           if (!allOccurrences)
                           return ;
                           }
                        }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
        }

        private final void shrink_()
        {
                decCount();
                lastCount_--;
                if (lastCount_ is 0)
                   {
                   if (count_ is 0)
                       clear();
                   else
                      {
                      CLCell tmp = tail_;
                      tail_ = tail_.prev();
                      tmp.unlink();
                      T[] buff = tail_.element();
                      lastCount_ = buff.length;
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
                assert(chunkSize_ >= 0);
                assert(lastCount_ >= 0);
                assert(((count_ is 0) is (tail_ is null)));

                if (tail_ is null)
                    return ;

                int c = 0;
                CLCell p = tail_.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail_;

                    int n;
                    if (isLast)
                        n = lastCount_;
                    else
                       n = buff.length;
   
                    c += n;
                    for (int i = 0; i < n; ++i)
                        {
                        auto v = buff[i];
                        assert(canInclude(v) && contains(v));
                        }
   
                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }

                assert(c is count_);

        }



        static class ArrayIterator(T) : AbstractIteratorT!(T)
        {
                private CLCell  cell;
                private T[]     buff;
                private int     index = -1;

                public this (ArrayBagT bag)
                {
                        super(bag);
                        cell = bag.tail_;  
                        if (cell)
                            buff = cell.element();  
                }

                public final bool more()
                {
                        if (remaining_)
                           {
                           if (++index >= buff.length)
                              {
                              cell = cell.next();
                              buff = cell.element();
                              index = 0;
                              }
        
                           decRemaining();
                           return true;
                           }
                        return false;
                }

                public final T value()
                {
                        return buff[index];
                }
        }
}


alias ArrayBagT!(Object) ArrayBag;
/*
 File: ArraySeq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 2Oct95  dl@cs.oswego.edu   refactored from DASeq.d
 13Oct95  dl                 Changed protection statuses

*/

        
module tango.store.ArraySeq;

private import tango.store.iterator.AbstractIterator;
private import tango.store.impl.MutableSeqImpl;

private import tango.store.model.Seq;
private import tango.store.model.Iterator;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Comparator;
private import tango.store.model.SortableCollection;
private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;


/**
 *
 * Dynamically allocated and resized Arrays.
 * 
 * Beyond implementing its interfaces, adds methods
 * to adjust capacities. The default heuristics for resizing
 * usually work fine, but you can adjust them manually when
 * you need to.
 *
 * ArraySeqs are generally like java.util.Vectors. But unlike them,
 * ArraySeqs do not actually allocate arrays when they are constructed.
 * Among other consequences, you can adjust the capacity `for free'
 * after construction but before adding elements. You can adjust
 * it at other times as well, but this may lead to more expensive
 * resizing. Also, unlike Vectors, they release their internal arrays
 * whenever they are empty.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public class ArraySeqT(T) : MutableSeqImplT!(T), SortableCollectionT!(T)
{
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias ComparatorT!(T)           Comparator;
        alias CollectionIteratorT!(T)   CollectionIterator;


        /**
         * The minimum capacity of any non-empty buffer
        **/

        public static int minCapacity = 16;


        // instance variables

        /**
         * The elements, or null if no buffer yet allocated.
        **/

        package T array_[];


        // constructors

        /**
         * Make a new empty ArraySeq. 
        **/

        public this ()
        {
                this (null, null, 0);
        }

        /**
         * Make an empty ArraySeq with given element screener
        **/

        public this (Predicate screener)
        {
                this (screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        package this (Predicate s, T[] b, int c)
        {
                super(s);
                array_ = b;
                count_ = c;
        }

        /**
         * Make an independent copy. The elements themselves are not cloned
        **/

        public final Collection duplicate()
        {
                int cap = count_;
                if (cap is 0)
                    return new ArraySeqT (screener_, null, 0);
                else
                   {
                   if (cap < minCapacity)
                       cap = minCapacity;

                   T newArray[] = new T[cap];
                   //System.copy (array_[0].sizeof, array_, 0, newArray, 0, count_);

                   newArray[0..count_] = array_[0..count_];
                   return new ArraySeqT!(T)(screener_, newArray, count_);
                   }
        }

        // methods introduced _in ArraySeq

        /**
         * return the current internal buffer capacity (zero if no buffer allocated).
         * @return capacity (always greater than or equal to size())
        **/

        public final int capacity()
        {
                return (array_ is null) ? 0 : array_.length;
        }

        /**
         * Set the internal buffer capacity to max(size(), newCap).
         * That is, if given an argument less than the current
         * number of elements, the capacity is just set to the
         * current number of elements. Thus, elements are never lost
         * by setting the capacity. 
         * 
         * @param newCap the desired capacity.
         * @return condition: 
         * <PRE>
         * capacity() >= size() &&
         * version() != PREV(this).version() == (capacity() != PREV(this).capacity())
         * </PRE>
        **/

        public final void capacity(int newCap)
        {
                if (newCap < count_)
                    newCap = count_;

                if (newCap is 0)
                   {
                   clear();
                   }
                else
                   if (array_ is null)
                      {
                      array_ = new T[newCap];
                      incVersion();
                      }
                   else
                      if (newCap !is array_.length)
                         {
                         T newArray[] = new T[newCap];
                         //  System.copy (array_[0].sizeof, array_, 0, newArray, 0, count_);
                         newArray[0..count_] = array_[0..count_];
                         array_ = newArray;
                         incVersion();
                         }
        }


        // Collection methods

        /**
         * Implements store.Collection.contains.
         * Time complexity: O(n).
         * @see store.Collection#contains
        **/
        public final bool contains(T element)
        {
                if (! isValidArg (element))
                      return false;

                for (int i = 0; i < count_; ++i)
                     if (array_[i] == (element))
                         return true;
                return false;
        }

        /**
         * Implements store.Collection.instances.
         * Time complexity: O(n).
         * @see store.Collection#instances
        **/
        public final int instances(T element)
        {
                if (! isValidArg(element))
                      return 0;

                int c = 0;
                for (int i = 0; i < count_; ++i)
                     if (array_[i] == (element))
                         ++c;
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



        // Seq methods:

        /**
         * Implements store.Seq.head.
         * Time complexity: O(1).
         * @see store.Seq#head
        **/
        public final T head()
        {
                checkIndex(0);
                return array_[0];
        }

        /**
         * Implements store.Seq.tail.
         * Time complexity: O(1).
         * @see store.Seq#tail
        **/
        public final T tail()
        {
                checkIndex(count_ -1);
                return array_[count_ -1];
        }

        /**
         * Implements store.Seq.get.
         * Time complexity: O(1).
         * @see store.Seq#get
        **/
        public final T get(int index)
        in {
           checkIndex(index);
           }
        body
        {
                return array_[index];
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

                for (int i = startingIndex; i < count_; ++i)
                     if (array_[i] == (element))
                         return i;
                return -1;
        }

        /**
         * Implements store.Seq.last.
         * Time complexity: O(n).
         * @see store.Seq#last
        **/
        public final int last(T element, int startingIndex = 0)
        {
                if (startingIndex >= count_)
                    startingIndex = count_ -1;
 
                for (int i = startingIndex; i >= 0; --i)
                     if (array_[i] == (element))
                         return i;
                return -1;
        }


        /**
         * Implements store.Seq.subseq.
         * Time complexity: O(length).
         * @see store.Seq#subseq
        **/
        public final  /* ArraySeq */ SeqT!(T) subseq(int from, int _length)
        {
                if (_length > 0)
                   {
                   checkIndex(from);
                   checkIndex(from + _length - 1);

                   T newArray[] = new T[_length];
                   //System.copy (array_[0].sizeof, array_, from, newArray, 0, _length);

                   newArray[0.._length] = array_[from..from+_length];
                   return new ArraySeqT!(T)(screener_, newArray, _length);
                   }
                else
                   return new ArraySeqT!(T)(screener_);
        }


        // MutableCollection methods

        /**
         * Implements store.MutableCollection.clear.
         * Time complexity: O(1).
         * @see store.MutableCollection#clear
        **/
        public final void clear()
        {
                array_ = null;
                setCount(0);
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
         * Time complexity: O(n * number of replacements).
         * @see store.MutableCollection#replaceAllOf
        **/
        public final void replaceAllOf(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements store.MutableCollection.exclude.
         * Time complexity: O(n * instances(element)).
         * @see store.MutableCollection#exclude
        **/
        public final void exclude(T element)
        {
                remove_(element, true);
        }

        /**
         * Implements store.MutableCollection.take.
         * Time complexity: O(1).
         * Takes the rightmost element of the array.
         * @see store.MutableCollection#take
        **/
        public final T take()
        {
                T v = tail();
                removeTail();
                return v;
        }


        // SortableCollection methods:


        /**
         * Implements store.SortableCollection.sort.
         * Time complexity: O(n log n).
         * Uses a quicksort-based algorithm.
         * @see store.SortableCollection#sort
        **/
        public void sort(Comparator cmp)
        {
                if (count_ > 0)
                   {
                   quickSort(array_, 0, count_ - 1, cmp);
                   incVersion();
                   }
        }


        // MutableSeq methods

        /**
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(n)
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(T element)
        {
                checkElement(element);
                growBy_(1);
                for (int i = count_ -1; i > 0; --i)
                     array_[i] = array_[i - 1];
                array_[0] = element;
        }

        /**
         * Implements store.MutableSeq.replaceHead.
         * Time complexity: O(1).
         * @see store.MutableSeq#replaceHead
        **/
        public final void replaceHead(T element)
        {
                checkElement(element);
                array_[0] = element;
                incVersion();
        }

        /**
         * Implements store.MutableSeq.removeHead.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeHead
        **/
        public final void removeHead()
        {
                remove(0);
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: normally O(1), but O(n) if size() == capacity().
         * @see store.MutableSeq#append
        **/
        public final void append(T element)
        in {
           checkElement (element);
           }
        body
        {
                int last = count_;
                growBy_(1);
                array_[last] = element;
        }

        /**
         * Implements store.MutableSeq.replaceTail.
         * Time complexity: O(1).
         * @see store.MutableSeq#replaceTail
        **/
        public final void replaceTail(T element)
        {
                checkElement(element);
                array_[count_ -1] = element;
                incVersion();
        }

        /**
         * Implements store.MutableSeq.removeTail.
         * Time complexity: O(1).
         * @see store.MutableSeq#removeTail
        **/
        public final void removeTail()
        {
                checkIndex(0);
                array_[count_ -1] = T.init;
                growBy_( -1);
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(n).
         * @see store.MutableSeq#insert
        **/
        public final void insert(int index, T element)
        {
                if (index !is count_)
                    checkIndex(index);

                checkElement(element);
                growBy_(1);
                for (int i = count_ -1; i > index; --i)
                     array_[i] = array_[i - 1];
                array_[index] = element;
        }

        /**
         * Implements store.MutableSeq.remove.
         * Time complexity: O(n).
         * @see store.MutableSeq#remove
        **/
        public final void remove(int index)
        {
                checkIndex(index);
                for (int i = index + 1; i < count_; ++i)
                     array_[i - 1] = array_[i];
                array_[count_ -1] = T.init;
                growBy_( -1);
        }


        /**
         * Implements store.MutableSeq.replace.
         * Time complexity: O(1).
         * @see store.MutableSeq#replace
        **/
        public final void replace(int index, T element)
        {
                checkIndex(index);
                checkElement(element);
                array_[index] = element;
                incVersion();
        }

        /**
         * Implements store.MutableSeq.prepend.
         * Time complexity: O(n + number of elements in e) if (e 
         * instanceof CollectionIterator) else O(n * number of elements in e)
         * @see store.MutableSeq#prepend
        **/
        public final void prepend(Iterator e)
        {
                insert_(0, e);
        }

        /**
         * Implements store.MutableSeq.append.
         * Time complexity: O(number of elements in e) 
         * @see store.MutableSeq#append
        **/
        public final void append(Iterator e)
        {
                insert_(count_, e);
        }

        /**
         * Implements store.MutableSeq.insert.
         * Time complexity: O(n + number of elements in e) if (e 
         * instanceof CollectionIterator) else O(n * number of elements in e)
         * @see store.MutableSeq#insert
        **/
        public final void insert(int index, Iterator e)
        {
                if (index !is count_)
                    checkIndex(index);
                insert_(index, e);
        }


        /**
         * Implements store.MutableSeq.removeFromTo.
         * Time complexity: O(n).
         * @see store.MutableSeq#removeFromTo
        **/
        public final void removeFromTo(int fromIndex, int toIndex)
        {
                checkIndex(fromIndex);
                checkIndex(toIndex);
                if (fromIndex <= toIndex)
                   {
                   int gap = toIndex - fromIndex + 1;
                   int j = fromIndex;
                   for (int i = toIndex + 1; i < count_; ++i)
                        array_[j++] = array_[i];
 
                   for (int i = 1; i <= gap; ++i)
                        array_[count_ -i] = T.init;
                   addToCount( -gap);
                   }
        }

        /**
         * An implementation of Quicksort using medians of 3 for partitions.
         * Used internally by sort.
         * It is public and static so it can be used  to sort plain
         * arrays as well.
         * @param s, the array to sort
         * @param lo, the least index to sort from
         * @param hi, the greatest index
         * @param cmp, the comparator to use for comparing elements
        **/

        public final static void quickSort(T s[], int lo, int hi, Comparator cmp)
        {
                if (lo >= hi)
                    return;

                /*
                   Use median-of-three(lo, mid, hi) to pick a partition. 
                   Also swap them into relative order while we are at it.
                */

                int mid = (lo + hi) / 2;

                if (cmp.compare(s[lo], s[mid]) > 0)
                   {
                   T tmp = s[lo];
                   s[lo] = s[mid];
                   s[mid] = tmp; // swap
                   }

                if (cmp.compare(s[mid], s[hi]) > 0)
                   {
                   T tmp = s[mid];
                   s[mid] = s[hi];
                   s[hi] = tmp; // swap

                   if (cmp.compare(s[lo], s[mid]) > 0)
                      {
                      T tmp2 = s[lo];
                      s[lo] = s[mid];
                      s[mid] = tmp2; // swap
                      }
                   }

                int left = lo + 1;           // start one past lo since already handled lo
                int right = hi - 1;          // similarly
                if (left >= right)
                    return;                  // if three or fewer we are done

                T partition = s[mid];

                for (;;)
                    {
                    while (cmp.compare(s[right], partition) > 0)
                           --right;

                    while (left < right && cmp.compare(s[left], partition) <= 0)
                           ++left;

                    if (left < right)
                       {
                       T tmp = s[left];
                       s[left] = s[right];
                       s[right] = tmp; // swap
                       --right;
                       }
                    else
                       break;
                    }

                quickSort(s, lo, left, cmp);
                quickSort(s, left + 1, hi, cmp);
        }

        // helper methods

        /**
         * Main method to control buffer sizing.
         * The heuristic used for growth is:
         * <PRE>
         * if out of space:
         *   if need less than minCapacity, grow to minCapacity
         *   else grow by average of requested size and minCapacity.
         * </PRE>
         * <P>
         * For small buffers, this causes them to be about 1/2 full.
         * while for large buffers, it causes them to be about 2/3 full.
         * <P>
         * For shrinkage, the only thing we do is unlink the buffer if it is empty.
         * @param inc, the amount of space to grow by. Negative values mean shrink.
         * @return condition: adjust record of count, and if any of
         * the above conditions apply, allocate and copy into a new
         * buffer of the appropriate size.
        **/

        private final void growBy_(int inc)
        {
                int needed = count_ + inc;
                if (inc > 0)
                   {
                   /* heuristic: */
                   int current = capacity();
                   if (needed > current)
                      {
                      incVersion();
                      int newCap = needed + (needed + minCapacity) / 2;

                      if (newCap < minCapacity)
                          newCap = minCapacity;

                      if (array_ is null)
                         {
                         array_ = new T[newCap];
                         }
                      else
                         {
                         T newArray[] = new T[newCap];
                         //System.copy (array_[0].sizeof, array_, 0, newArray, 0, count_);

                         newArray[0..count_] = array_[0..count_];
                         array_ = newArray;
                         }
                      }
                   }
                else
                   if (needed is 0)
                       array_ = null;

                setCount(needed);
        }


        /**
         * Utility to splice in enumerations
        **/

        private final void insert_(int index, Iterator e)
        {
                if (cast(CollectionIterator) e)
                   { 
                   // we know size!
                   int inc = (cast(CollectionIterator) (e)).remaining();
                   int oldcount = count_;
                   int oldversion = version_;
                   growBy_(inc);

                   for (int i = oldcount - 1; i >= index; --i)
                        array_[i + inc] = array_[i];

                   int j = index;
                   while (e.more())
                         {
                         T element = e.value();
                         if (!canInclude(element))
                            { // Ugh. Can only do full rollback
                            for (int i = index; i < oldcount; ++i)
                                 array_[i] = array_[i + inc];

                            version_ = oldversion;
                            count_ = oldcount;
                            checkElement(element); // force throw
                            }
                         array_[j++] = element;
                         }
                   }
                else
                   if (index is count_)
                      { // next best; we can append
                      while (e.more())
                            {
                            T element = e.value();
                            checkElement(element);
                            growBy_(1);
                            array_[count_ -1] = element;
                            }
                      }
                   else
                      { // do it the slow way
                      int j = index;
                      while (e.more())
                            {
                            T element = e.value();
                            checkElement(element);
                            growBy_(1);

                            for (int i = count_ -1; i > j; --i)
                                 array_[i] = array_[i - 1];
                            array_[j++] = element;
                            }
                      }
        }

        private final void remove_(T element, bool allOccurrences)
        {
                if (! isValidArg(element))
                      return;

                for (int i = 0; i < count_; ++i)
                    {
                    while (i < count_ && array_[i] == (element))
                          {
                          for (int j = i + 1; j < count_; ++j)
                               array_[j - 1] = array_[j];

                          array_[count_ -1] = T.init;
                          growBy_( -1);

                          if (!allOccurrences || count_ is 0)
                               return ;
                          }
                    }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (isValidArg(oldElement) is false || count_ is 0)
                    return;

                for (int i = 0; i < count_; ++i)
                    {
                    if (array_[i] == (oldElement))
                       {
                       checkElement(newElement);
                       array_[i] = newElement;
                       incVersion();

                       if (! allOccurrences)
                             return;
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
                assert(!(array_ is null && count_ !is 0));
                assert((array_ is null || count_ <= array_.length));

                for (int i = 0; i < count_; ++i)
                    {
                    assert(canInclude(array_[i]));
                    assert(instances(array_[i]) > 0);
                    assert(contains(array_[i]));
                    }
        }

        /**
         *
         * Enumerator for collections based on dynamic arrays.
         * 
        author: Doug Lea
         * @version 0.93
         *
         * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
        **/
        static class ArrayIterator(T) : AbstractIteratorT!(T)
        {
                private T[]             array;
                private int             row = -1;

                public this (ArraySeqT seq)
                {
                        super (seq);
                        array = seq.array_;
                }

                public final bool more()
                {
                        if (remaining_)
                           {
                           ++row;
                           decRemaining();
                           return true;
                           }

                        return false;
                }

                public final T value()
                {
                        return array[row];
                }
        }
}


alias ArraySeqT!(Object) ArraySeq;

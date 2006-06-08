/*
 File: ArrayIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.iterator.ArrayIterator;

private import tango.store.Exception;

private import tango.store.model.CollectionIterator;


/**
 *
 * ArrayIterator allows you to use arrays as Iterators
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class ArrayIteratorT(T) : CollectionIteratorT!(T)
{
        private T [] arr_;
        private int cur_;
        private int size_;

        /**
         * Build an enumeration that returns successive elements of the array
        **/
        public this (T arr[])
        {
                // arr_ = arr; cur_ = 0; size_ = arr._length;
                arr_ = arr;
                cur_ = -1;
                size_ = arr.length;
        }

        /**
         * Implements store.CollectionIterator.remaining
         * @see store.CollectionIterator#remaining
        **/
        public int remaining()
        {
                return size_;
        }

        /**
         * Implements java.util.Iterator.more.
         * @see java.util.Iterator#more
        **/
        public bool more()
        {
                if (size_ > 0)
                   {
                   --size_;
                   ++cur_;
                   return true;
                   }
                return false;
        }

        /**
         * Implements store.CollectionIterator.corrupted.
         * Always false. Inconsistency cannot be reliably detected for arrays
         * @return false
         * @see store.CollectionIterator#corrupted
        **/

        public bool corrupted()
        {
                return false;
        }

        /**
         * Implements java.util.Iterator.get().
         * @see java.util.Iterator#get()
        **/
        public Object value()
        {
                return arr_[cur_];
        }
}


alias ArrayIteratorT!(Object) ArrayIterator;
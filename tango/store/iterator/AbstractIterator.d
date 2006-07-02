/*
 File: AbstractIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses
  9Apr97  dl                 made class public
*/


module tango.store.iterator.AbstractIterator;

private import tango.store.Exception;

private import tango.store.model.MutableCollection;
private import tango.store.model.CollectionIterator;

private import tango.text.convert.Integer;

/**
 *
 * A convenient base class for implementations of CollectionIterator
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public abstract class AbstractIteratorT(T) : CollectionIteratorT!(T)
{
        /**
         * The collection being enumerated
        **/

        protected MutableCollectionT!(T) coll_;

        /**
         * The version number of the collection we got upon construction
        **/

        protected int version_;

        /**
         * The number of elements we think we have left.
         * Initialized to coll_.size() upon construction
        **/

        protected int remaining_;

        protected this (MutableCollectionT!(T) c)
        {
                coll_ = c;
                version_ = c._version();
                remaining_ = c.size();
        }

        /**
         * Implements store.CollectionIterator.corrupted.
         * Claim corruption if version numbers differ
         * @see store.CollectionIterator#corrupted
        **/

        public final bool corrupted()
        {
                return version_ !is coll_._version();
        }

        /**
         * Implements store.CollectionIterator.numberOfRemaingingElements.
         * @see store.CollectionIterator#remaining
        **/
        public final int remaining()
        {
                return remaining_;
        }

        /**
         * Implements java.util.Iterator.more.
         * Return true if remaining > 0 and not corrupted
         * @see java.util.Iterator#more
        **/
        public bool more()
        {
                return !corrupted() && remaining_ > 0;
        }

        /**
         * Subclass utility. 
         * Tries to decrement remaining_, raising exceptions
         * if it is already zero or if corrupted()
         * Always call as the first line of get.
        **/
        protected final void decRemaining()
        {
                if (corrupted())
                   {
                   char[16] v1, v2;
                   Integer.format (v1, version_);
                   Integer.format (v2, coll_._version());

//                   throw new CorruptedIteratorException(version_, coll_._version(), coll_, "Using _version " ~ v1 ~ "but now at _version " ~ v2);
                   throw new CorruptedIteratorException(version_, coll_._version(), null, "Using _version " ~ v1 ~ "but now at _version " ~ v2);
                   }
                else
                   if (remaining() <= 0)
                       throw new NoSuchElementException("exhausted enumeration");
                   else
                      --remaining_;
        }
}


public abstract class MapIteratorImplT(K, T) : AbstractIteratorT!(T), CollectionMapIteratorT!(K, T) 
{
        protected this (MutableCollectionT!(T) c)
        {
                super (c);
        }
}

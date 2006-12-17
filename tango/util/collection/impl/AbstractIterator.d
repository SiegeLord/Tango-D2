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


module tango.util.collection.impl.AbstractIterator;

private import  tango.util.collection.Exception;

private import  tango.util.collection.model.View,
                tango.util.collection.model.GuardIterator;
                


/**
 *
 * A convenient base class for implementations of CollectionIterator
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public abstract class AbstractIterator(T) : GuardIterator!(T)
{
        /**
         * The collection being enumerated
        **/

        private View!(T) view;

        /**
         * The version number of the collection we got upon construction
        **/

        private int mutation;

        /**
         * The number of elements we think we have left.
         * Initialized to view.size() upon construction
        **/

        private int togo;
        

        protected this (View!(T) v)
        {
                view = v;
                togo = v.size();
                mutation = v.mutation();
        }

        /**
         * Implements store.CollectionIterator.corrupted.
         * Claim corruption if version numbers differ
         * @see store.CollectionIterator#corrupted
        **/

        public final bool corrupted()
        {
                return mutation !is view.mutation();
        }

        /**
         * Implements store.CollectionIterator.numberOfRemaingingElements.
         * @see store.CollectionIterator#remaining
        **/
        public final int remaining()
        {
                return togo;
        }

        /**
         * Implements java.util.Iterator.more.
         * Return true if remaining > 0 and not corrupted
         * @see java.util.Iterator#more
        **/
        public final bool more()
        {
                return !corrupted() && togo > 0;
        }

        /**
         * Subclass utility. 
         * Tries to decrement togo, raising exceptions
         * if it is already zero or if corrupted()
         * Always call as the first line of get.
        **/
        protected final void decRemaining()
        {
                if (corrupted())
                   throw new CorruptedIteratorException("Collection modified during iteration");
                else
                   if (togo <= 0)
                       throw new NoSuchElementException("exhausted enumeration");
                   else
                      --togo;
        }


        int opApply (int delegate (inout T value) dg)
        {
                int result;

                for (int i=togo; i--;)
                    {
                    auto value = get();
                    if ((result = dg(value)) != 0)
                         break;
                    }
                return result;
        }
}


public abstract class AbstractMapIterator(K, V) : AbstractIterator!(V), PairIterator!(K, V) 
{
        abstract V get (inout K key);

        protected this (View!(V) c)
        {
                super (c);
        }

        int opApply (int delegate (inout K key, inout V value) dg)
        {
                K   key;
                int result;

                for (int i=togo; i--;)
                    {
                    auto value = get(key);
                    if ((result = dg(key, value)) != 0)
                         break;
                    }
                return result;
        }
}

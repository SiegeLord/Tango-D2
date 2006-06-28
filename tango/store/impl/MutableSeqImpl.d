/*
 File: MutableSeqImpl.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 28jab97  dl                 make class public
*/


module tango.store.impl.MutableSeqImpl;

private import tango.store.model.Predicate;
private import tango.store.model.Seq;
private import tango.store.impl.MutableImpl;
private import tango.store.model.MutableSeq;



/**
 *
 * MutableSeqImpl extends MutableImpl to provide
 * default implementations of some Seq operations. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class MutableSeqImplT(T) : MutableImplT!(T) , MutableSeqT!(T)
{
        /**
         * Initialize at version 0, an empty count, and null screener
        **/

        protected this ()
        {
                super();
        }

        /**
         * Initialize at version 0, an empty count, and supplied screener
        **/
        protected this (PredicateT!(T) screener)
        {
                super(screener);
        }


        // Default implementations of Seq methods

version (VERBOSE)
{
        /**
         * Implements store.Seq.insertingAt.
         * @see store.Seq#insertingAt
        **/
        public final Seq insertingAt(int index, T element)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.insert(index, element);
                return c;
        }

        /**
         * Implements store.Seq.removingAt.
         * @see store.Seq#removingAt
        **/
        public final Seq removingAt(int index)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.remove(index);
                return c;
        }


        /**
         * Implements store.Seq.replacingAt
         * @see store.Seq#replacingAt
        **/
        public final Seq replacingAt(int index, T element)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.replace(index, element);
                return c;
        }
} // version
}

alias MutableSeqImplT!(Object) MutableSeqImpl;
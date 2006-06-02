/*
 File: MutableBagImpl.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 22Oct95  dl                 add addElements
 28jan97  dl                 make class public
*/


module tango.store.impl.MutableBagImpl;

private import tango.store.model.Bag;
private import tango.store.model.Predicate;
private import tango.store.model.MutableBag;
private import tango.store.impl.MutableImpl;

private import tango.store.model.Iterator;

/**
 *
 * MutableBagImpl extends MutableImpl to provide
 * default implementations of some Bag operations. 
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class MutableBagImplT(T) : MutableImplT!(T) , MutableBagT!(T)
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
        protected this (Predicate screener)
        {
                super(screener);
        }

        /**
         * Implements store.MutableBag.addElements
         * @see store.MutableBag#addElements
        **/

        public final void addElements(Iterator e)
        {
                while (e.more)
                        add (e.value);
        }


        // Default implementations of Bag methods

version (VERBOSE)
{
        /**
         * Implements store.Bag.addingIfAbsent
         * @see store.Bag#addingIfAbsent
        **/
        public final Bag addingIfAbsent(T element)
        {
                MutableBag c = null;
                //      c = (cast(MutableBag)clone());
                c = (cast(MutableBag)duplicate());
                c.addIfAbsent(element);
                return c;
        }


        /**
         * Implements store.Bag.adding
         * @see store.Bag#adding
        **/

        public final Bag adding(T element)
        {
                MutableBag c = null;
                //      c = (cast(MutableBag)clone());
                c = (cast(MutableBag)duplicate());
                c.add(element);
                return c;
        }
} // version
}


alias MutableBagImplT!(Object) MutableBagImpl;
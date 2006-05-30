/*
 File: MutableSetImpl.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 22Oct95  dl                 add includeElements
 28jan97  dl                 make class public
*/


module tango.store.impl.MutableSetImpl;

private import tango.store.impl.MutableImpl;

private import tango.store.model.Set;
private import tango.store.model.Predicate;
private import tango.store.model.Iterator;
private import tango.store.model.MutableSet;

/**
 *
 * MutableSetImpl extends MutableImpl to provide
 * default implementations of some Set operations. 
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class MutableSetImplT(T) : MutableImplT!(T) , MutableSetT!(T)
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


version (VERBOSE)
{
        // Default implementations of Set methods

        /**
         * Implements store.Set.including
         * @see store.Set#including
        **/
        public synchronized Set including(T element)
        {
                MutableSet c = null;
                //      c = (cast(MutableSet)clone());
                c = (cast(MutableSet)duplicate());
                c.include(element);
                return c;
        }
} // version


        /**
         * Implements store.MutableSet.includeElements
         * @see store.MutableSet#includeElements
        **/

        public synchronized void includeElements(Iterator e)
        {
                while (e.more())
                        include(e.value());
        }

}


alias MutableSetImplT!(Object) MutableSetImpl;
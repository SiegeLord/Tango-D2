/*
 File: ElementSortedCollection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.model.ElementSortedCollection;

private import tango.store.model.Collection;
private import tango.store.model.Comparator;


/**
 *
 *
 * ElementSorted is a mixin interface for Collections that
 * are always in sorted order with respect to a Comparator
 * held by the Collection.
 * <P>
 * ElementSorted Collections guarantee that enumerations
 * appear in sorted order;  that is if a and b are two Elements
 * obtained in succession from elements().nextElement(), that 
 * <PRE>
 * elementComparator().compare(a, b) <= 0.
 * </PRE>
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public interface ElementSortedCollectionT(T) : CollectionT!(T)
{

        /**
         * Report the Comparator used for ordering
        **/

        public ComparatorT!(T) elementComparator();
}


alias ElementSortedCollectionT!(Object) ElementSortedCollection;
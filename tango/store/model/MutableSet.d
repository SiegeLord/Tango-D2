/*
 File: MutableSet.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file
 22Oct95  dl                 add addElements

*/


module tango.store.model.MutableSet;

private import tango.store.model.Set;
private import tango.store.model.Iterator;
private import tango.store.model.MutableCollection;


/**
 *
 * MutableSets support an include operations to add
 * an element only if it not present. 
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public interface MutableSetT(T) : MutableCollectionT!(T), SetT!(T)
{
        /**
         * Include the indicated element in the collection.
         * No effect if the element is already present.
         * @param element the element to add
         * @return condition: 
         * <PRE>
         * has(element) &&
         * no spurious effects &&
         * Version change iff !PREV(this).has(element)
         * </PRE>
         * @exception IllegalElementException if !canInclude(element)
        **/

        public void include(T element);


        /**
         * Include all elements of the enumeration in the collection.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) include(e.get());
         * </PRE>
         * @param e the elements to include
         * @exception IllegalElementException if !canInclude(element)
         * @exception CorruptedIteratorException propagated if thrown
        **/

        public void includeElements(IteratorT!(T) e);
}

alias MutableSetT!(Object) MutableSet;
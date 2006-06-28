/*
 File: MutableBag.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file
 22Oct95  dl                 add addElements

*/


module tango.store.model.MutableBag;

private import tango.store.model.Bag;
private import tango.store.model.MutableCollection;

private import tango.store.model.Iterator;

/**
 *
 *
 * MutableBags support operations to add multiple occurrences of elements
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public interface MutableBagT(T) : MutableCollectionT!(T), BagT!(T)
{
        /**
         * Add an occurrence of the indicated element to the collection.
         * @param element the element to add
         * @return condition: 
         * <PRE>
         * occurrences(element) == PREV(this).instances(element)+1 &&
         * Version change: always
         * </PRE>
         * @exception IllegalElementException if !canInclude(element)
        **/

        public void add (T element);

        /**
         * Add an occurrence of the indicated element if it
         * is not already present in the collection.
         * No effect if the element is already present.
         * @param element the element to add
         * @return condition: 
         * <PRE>
         * instances(element) == min(1, PREV(this).instances(element) &&
         * no spurious effects &&
         * Version change iff !PREV(this).has(element)
         * </PRE>
         * @exception IllegalElementException if !canInclude(element)
        **/


        public void addIfAbsent(T element);

        /**
         * Add all elements of the enumeration to the collection.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) add(e.value());
         * </PRE>
         * @param e the elements to include
         * @exception IllegalElementException if !canInclude(element)
         * @exception CorruptedIteratorException propagated if thrown
        **/


        public void addElements(IteratorT!(T) e);
}


alias MutableBagT!(Object) MutableBag;

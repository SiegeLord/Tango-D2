/*
 File: MutableCollection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.store.model.MutableCollection;

private import tango.store.model.Collection;

private import tango.store.model.Iterator;

/**
 *
 * MutableCollection is the root interface of all mutable collections; i.e.,
 * collections that may have elements dynamically added, removed,
 * and/or replaced in accord with their collection semantics.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public interface MutableCollectionT(T) : CollectionT!(T)
{
        /**
         * All updatable collections maintain a `version number'. The numbering
         * scheme is arbitrary, but is guaranteed to change upon every
         * modification that could possibly affect an elements() enumeration traversal.
         * (This is true at least within the precision of the `int' representation;
         * performing more than 2^32 operations will lead to reuse of version numbers).
         * Versioning
         * <EM>may</EM> be conservative with respect to `replacement' operations.
         * For the sake of versioning replacements may be considered as
         * removals followed by additions. Thus version numbers may change 
         * even if the old and new  elements are identical.
         * <P>
         * All element() enumerations for Mutable Collections track version
         * numbers, and raise inconsistency exceptions if the enumeration is
         * used (via get()) on a version other than the one generated
         * by the elements() method.
         * <P>
         * You can use versions to check if update operations actually have any effect
         * on observable state.
         * For example, clear() will cause cause a version change only
         * if the collection was previously non-empty.
         * @return the version number
        **/

        public int _version();

        /**
         * Cause the collection to become empty. 
         * @return condition:
         * <PRE>
         * isEmpty() &&
         * Version change iff !PREV(this).isEmpty();
         * </PRE>
        **/

        public void clear();

        /**
         * Exclude all occurrences of the indicated element from the collection. 
         * No effect if element not present.
         * @param element the element to exclude.
         * @return condition: 
         * <PRE>
         * !has(element) &&
         * size() == PREV(this).size() - PREV(this).instances(element) &&
         * no other element changes &&
         * Version change iff PREV(this).has(element)
         * </PRE>
        **/

        public void exclude(T element);


        /**
         * Remove an instance of the indicated element from the collection. 
         * No effect if !has(element)
         * @param element the element to remove
         * @return condition: 
         * <PRE>
         * let occ = max(1, instances(element)) in
         *  size() == PREV(this).size() - occ &&
         *  instances(element) == PREV(this).instances(element) - occ &&
         *  no other element changes &&
         *  version change iff occ == 1
         * </PRE>
        **/

        public void removeOneOf(T element);

        /**
         * Replace an occurrence of oldElement with newElement.
         * No effect if does not hold oldElement or if oldElement.equals(newElement).
         * The operation has a consistent, but slightly special interpretation
         * when applied to Sets. For Sets, because elements occur at
         * most once, if newElement is already included, replacing oldElement with
         * with newElement has the same effect as just removing oldElement.
         * @return condition:
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
         *               max(1, PREV(this).instances(oldElement) in
         *  instances(oldElement) == PREV(this).instances(oldElement) - delta &&
         *  instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, PREV(this).instances(oldElement) + delta):
         *                PREV(this).instances(oldElement) + delta) &&
         *  no other element changes &&
         *  Version change iff delta != 0
         * </PRE>
         * @exception IllegalElementException if has(oldElement) and !canInclude(newElement)
        **/

        public void replaceOneOf(T oldElement, T newElement);


        /**
         * Replace all occurrences of oldElement with newElement.
         * No effect if does not hold oldElement or if oldElement.equals(newElement).
         * The operation has a consistent, but slightly special interpretation
         * when applied to Sets. For Sets, because elements occur at
         * most once, if newElement is already included, replacing oldElement with
         * with newElement has the same effect as just removing oldElement.
         * @return condition:
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
                           PREV(this).instances(oldElement) in
         *  instances(oldElement) == PREV(this).instances(oldElement) - delta &&
         *  instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, PREV(this).instances(oldElement) + delta):
         *                PREV(this).instances(oldElement) + delta) &&
         *  no other element changes &&
         *  Version change iff delta != 0
         * </PRE>
         * @exception IllegalElementException if has(oldElement) and !canInclude(newElement)
        **/

        public void replaceAllOf(T oldElement, T newElement);


        /**
         * Remove and return an element.  Implementations
         * may strengthen the guarantee about the nature of this element.
         * but in general it is the most convenient or efficient element to remove.
         * <P>
         * Example usage. One way to transfer all elements from 
         * MutableCollection a to MutableBag b is:
         * <PRE>
         * while (!a.empty()) b.add(a.take());
         * </PRE>
         * @return an element v such that PREV(this).has(v) 
         * and the postconditions of removeOneOf(v) hold.
         * @exception NoSuchElementException iff isEmpty.
        **/

        public T take();


        /**
         * Exclude all occurrences of each element of the Iterator.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) exclude(e.value());
         * @param e the enumeration of elements to exclude.
         * @exception CorruptedIteratorException is propagated if thrown
        **/

        public void excludeElements(IteratorT!(T) e);



        /**
         * Remove an occurrence of each element of the Iterator.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) removeOneOf(e.value());
         * @param e the enumeration of elements to remove.
         * @exception CorruptedIteratorException is propagated if thrown
        **/

        public void removeElements(IteratorT!(T) e);
}


alias MutableCollectionT!(Object) MutableCollection;
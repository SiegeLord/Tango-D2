/*
 File: Collection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file
 14dec95  dl                 Declare as a subinterface of Cloneable
 9Apr97   dl                 made Serializable

*/


module tango.store.model.Collection;

private import tango.store.model.CollectionIterator;
private import tango.store.model.ImplementationCheckable;


/**
 * Collection is the base interface for most classes in this package.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/
public interface CollectionT(T) : ImplementationCheckable
{

        public char[] toString();

        /**
         * public version of java.lang.T.clone
         * All Collections implement clone. But this is a protected method.
         * Duplicate allows public access.
         * @see clone
        **/

        public CollectionT duplicate();

        /**
         * Report the number of elements in the CollectionT.
         * No other spurious effects.
         * @return number of elements
        **/
        public int size();

        /**
         * Report whether this Collection has no elements.
         * Behaviorally equivalent to <CODE>size() == 0</CODE>.
         * @return true iff size() == 0
        **/

        public bool isEmpty();


        /**
         * Report whether the Collection COULD contain element,
         * i.e., that it is valid with respect to the Collection's
         * element screener if it has one.
         * Always returns false if element == null.
         * A constant function: if canInclude(v) is ever true it is always true.
         * (This property is not in any way enforced however.)
         * No other spurious effects.
         * @return true if non-null and passes element screener check
        **/
        public bool canInclude(T element);


        /**
         * Report the number of occurrences of element in Collection.
         * Always returns 0 if element == null.
         * Otherwise T.equals is used to test for equality.
         * @param element the element to look for
         * @return the number of occurrences (always nonnegative)
        **/
        public int instances(T element);

        /**
         * Report whether the Collection contains element.
         * Behaviorally equivalent to <CODE>instances(element) &gt;= 0</CODE>.
         * @param element the element to look for
         * @return true iff contains at least one member that is equal to element.
        **/
        public bool contains(T element);

        /**
         * Return an enumeration that may be used to traverse through
         * the elements in the Collection. Standard usage, for some
         * CollectionT c, and some operation `use(T obj)':
         * <PRE>
         * for (Iterator e = c.elements(); e.more(); )
         *   use(e.value());
         * </PRE>
         * (The values of get very often need to
         * be coerced to types that you know they are.)
         * <P>
         * All Collections return instances
         * of CollectionIterator, that can report the number of remaining
         * elements, and also perform consistency checks so that
         * for MutableCollections, element enumerations may become 
         * invalidated if the Collection is modified during such a traversal
         * (which could in turn cause random effects on the CollectionT.
         * TO prevent this,  CollectionIterators 
         * raise CorruptedIteratorException on attempts to access
         * gets of altered Collections.)
         * Note: Since all Collection implementations are synchronizable,
         * you may be able to guarantee that element traversals will not be
         * corrupted by using the java <CODE>synchronized</CODE> construct
         * around code blocks that do traversals. (Use with care though,
         * since such constructs can cause deadlock.)
         * <P>
         * Guarantees about the nature of the elements returned by  get of the
         * returned Iterator may vary accross sub-interfaces.
         * In all cases, the enumerations provided by elements() are guaranteed to
         * step through (via get) ALL elements in the Collection.
         * Unless guaranteed otherwise (for example in Seq), elements() enumerations
         * need not have any particular get() ordering so long as they
         * allow traversal of all of the elements. So, for example, two successive
         * calls to element() may produce enumerations with the same
         * elements but different get() orderings.
         * Again, sub-interfaces may provide stronger guarantees. In
         * particular, Seqs produce enumerations with gets in
         * index order, ElementSortedCollections enumerations are in ascending 
         * sorted order, and KeySortedCollections are in ascending order of keys.
         * @return an enumeration e such that
         * <PRE>
         *   e.remaining() == size() &&
         *   foreach (v in e) has(e) 
         * </PRE>
        **/

        public CollectionIteratorT!(T) elements();

        /**
         * Report whether other has the same element structure as this.
         * That is, whether other is of the same size, and has the same 
         * elements() properties.
         * This is a useful version of equality testing. But is not named
         * `equals' in part because it may not be the version you need.
         * <P>
         * The easiest way to decribe this operation is just to
         * explain how it is interpreted in standard sub-interfaces:
         * <UL>
         *  <LI> Seq and ElementSortedCollection: other.elements() has the 
         *        same order as this.elements().
         *  <LI> Bag: other.elements has the same instances each element as this.
         *  <LI> Set: other.elements has all elements of this
         *  <LI> Map: other has all (key, element) pairs of this.
         *  <LI> KeySortedCollection: other has all (key, element)
         *       pairs as this, and with keys enumerated in the same order as
         *       this.keys().
         *</UL>
         * @param other, a Collection
         * @return true if considered to have the same size and elements.
        **/

        public bool matches(CollectionT other);


version (VERBOSE)
{
        /**
         * Construct a new Collection that is a clone of self except
         * that it does not include any occurrences of the indicated element.
         * It is NOT an error to exclude a non-existent element.
         *
         * @param element the element to exclude from the new CollectionT
         * @return a new Collection, c, with the matches as this
         * except that !c.has(element).
        **/
        public CollectionT excluding(T element);


        /**
         * Construct a new Collection that is a clone of self except
         * that it does not include an occurrence of the indicated element.
         * It is NOT an error to remove a non-existent element.
         *
         * @param element the element to exclude from the new Collection
         * @return a new Collection, c, with the matches as this
         * except that c.instances(element) == max(0,instances(element)-1)
        **/
        public CollectionT removingOneOf(T element);

        /**
         * Construct a new Collection that is a clone of self except
         * that one occurrence of oldElement is replaced with
         * newElement. 
         * It is NOT an error to replace a non-existent element.
         *
         * @param oldElement the element to replace
         * @param newElement the replacement
         * @return a new Collection, c, with the matches as this, except:
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
         *               max(1, this.instances(oldElement) in
         *  c.instances(oldElement) == this.instances(oldElement) - delta &&
         *  c.instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, this.instances(oldElement) + delta):
         *                this.instances(oldElement) + delta) &&
         * </PRE>
         * @exception IllegalElementException if has(oldElement) and !canInclude(newElement)
        **/
        public CollectionT replacingOneOf(T oldElement, T newElement);


        /**
         * Construct a new Collection that is a clone of self except
         * that all occurrences of oldElement are replaced with
         * newElement. 
         * It is NOT an error to convert a non-existent element.
         *
         * @param oldElement the element to replace
         * @param newElement the replacement
         * @return a new Collection, c, with the matches as this except
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
                           instances(oldElement) in
         *  c.instances(oldElement) == this.instances(oldElement) - delta &&
         *  c.instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, this.instances(oldElement) + delta):
         *                this.instances(oldElement) + delta)
         * </PRE>
         * @exception IllegalElementException if has(oldElement) and !canInclude(newElement)
        **/

        public CollectionT replacingAllOf(T oldElement, T newElement);
} // version
}


alias CollectionT!(Object) Collection;
/*
 File: Map.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.store.model.Map;

private import tango.store.model.Collection;
private import tango.store.model.CollectionIterator;


/**
 *
 * Maps maintain keyed elements. Any kind of Object 
 * may serve as a key for an element.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public interface MapT(K, T) : CollectionT!(T)
{

        /**
         * Report whether the MapT COULD include k as a key
         * Always returns false if k is null
        **/

        public bool canIncludeKey(K k);

        /**
         * Report whether there exists any element with Key key.
         * @return true if there is such an element
        **/

        public bool containsKey(K key);

        /**
         * Report whether there exists a (key, value) pair
         * @return true if there is such an element
        **/

        public bool containsPair(K key, T value);


        /**
         * Return an enumeration that may be used to traverse through
         * the keys (not elements) of the collection. The corresponding
         * elements can be looked at by using at(k) for each key k. For example:
         * <PRE>
         * Iterator keys = amap.keys();
         * while (keys.more()) {
         *   K key = keys.value();
         *   T value = amap.get(key)
         * // ...
         * }
         * </PRE>
         * @return the enumeration
        **/

        public CollectionMapIteratorT!(K, T) keys();


        /**
         * Return the element associated with Key key. 
         * @param key a key
         * @return element such that contains(key, element)
         * @exception NoSuchElementException if !containsKey(key)
        **/

        public T get(K key);

        /**
         * Return the element associated with Key key. 
         * @param key a key
         * @return whether the key is contained or not
        **/

        public bool get(K key, inout T element);


        /**
         * Return a key associated with element. There may be any
         * number of keys associated with any element, but this returns only
         * one of them (any arbitrary one), or null if no such key exists.
         * @param element, a value to try to find a key for.
         * @return k, such that 
         * <PRE>
         * (k == null && !has(element)) ||  contains(k, element)
         * </PRE>
        **/

        public K keyOf(T element);

version (VERBOSE)
{
        /**
         * Construct a new MapT that is a clone of self except
         * that it has the new pair. If there already exists
         * another pair with the same key, the new collection will
         * instead have one with the new elment.
         * @param the key for element to add
         * @param the element to add
         * @return the new MapT c, for which:
         * <PRE>
         * c.get(key).equals(element) &&
         * foreach (k in keys()) c.get(v).equals(at(k))
         * foreach (k in c.keys()) (!k.equals(key)) --> c.at(v).equals(get(k))
         * </PRE>
        **/


        public MapT puttingAt(K key, T element);


        /**
         * Construct a new MapT that is a clone of self except
         * that it does not include the given key.
         * It is NOT an error to exclude a non-existenK key.
         * @param key the key for the par to remove
         * @param element the element for the par to remove
         * @return the new MapT c, for which:
         * <PRE>
         * foreach (v in c.keys()) contains(v, get(v)) &&
         * !c.containsKey(key) 
         * </PRE>
        **/
        public MapT removingAt(K key);
} // version
}


alias MapT!(Object, Object) Map;

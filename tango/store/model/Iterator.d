/*
 File: Iterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.store.model.Iterator;


/**
 *
 **/

public interface IteratorT(V)
{
        public bool more();

        public V value();
}

public interface MapIteratorT(K, V) : IteratorT!(V)
{
        public K key();
}

alias IteratorT!(Object) Iterator;
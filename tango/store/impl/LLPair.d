/*
 File: LLPair.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file

*/


module tango.store.impl.LLPair;

private import tango.store.impl.LLCell;

private import tango.store.model.Iterator;


/**
 *
 *
 * LLPairs are LLCells with keys, and operations that deal with them.
 * As with LLCells, the are pure implementation tools.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class LLPairT(K, T) : LLCellT!(T) 
{
        alias LLCellT!(T).find find;
        alias LLCellT!(T).count count;
        alias LLCellT!(T).element element;


        // instance variables

        private K key_;

        /**
         * Make a cell with given key, elment, and next link
        **/

        public this (K k, T v, LLPairT n)
        {
                super(v, n);
                key_ = k;
        }

        /**
         * Make a pair with given key and element, and null next link
        **/

        public this (K k, T v)
        {
                super(v, null);
                key_ = k;
        }

        /**
         * Make a pair with null key, elment, and next link
        **/

        public this ()
        {
                super(T.init, null);
                key_ = K.init;
        }

        /**
         * return the key
        **/

        public final K key()
        {
                return key_;
        }

        /**
         * set the key
        **/

        public final void key(K k)
        {
                key_ = k;
        }


        /**
         * set the key
        **/

        public final int keyHash()
        {
                return typeid(K).getHash(&key_);
        }


        /**
         * return a cell with key() key or null if no such
        **/

        public final LLPairT findKey(K key)
        {
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                     if (p.key() == (key))
                         return p;
                return null;
        }

        /**
         * return a cell holding the indicated pair or null if no such
        **/

        public final LLPairT find(K key, T element)
        {
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                     if (p.key() == (key) && p.element() == (element))
                         return p;
                return null;
        }

        /**
         * Return the number of cells traversed to find a cell with key() key,
         * or -1 if not present
        **/

        public final int indexKey(K key)
        {
                int i = 0;
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                    {
                    if (p.key() == (key))
                        return i;
                    else
                       ++i;
                    }
                return -1;
        }

        /**
         * Return the number of cells traversed to find a cell with indicated pair
         * or -1 if not present
        **/
        public final int index(K key, T element)
        {
                int i = 0;
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                    {
                    if (p.key() == (key) && p.element() == (element))
                        return i;
                    else
                       ++i;
                    }
                return -1;
        }

        /**
         * Return the number of cells with key() key.
        **/
        public final int countKey(K key)
        {
                int c = 0;
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                     if (p.key() == (key))
                         ++c;
                return c;
        }

        /**
         * Return the number of cells with indicated pair
        **/
        public final int count(K key, T element)
        {
                int c = 0;
                for (LLPairT p = this; p !is null; p = cast(LLPairT)(p.next()))
                     if (p.key() == (key) && p.element() == (element))
                         ++c;
                return c;
        }

        //  protected T clone()  {
        protected final LLPairT duplicate()
        {
                return new LLPairT(key(), element(), cast(LLPairT)(next()));
        }
}


alias LLPairT!(Object, Object) LLPair;
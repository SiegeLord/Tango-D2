/*
 File: MutableMapImpl.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 28jan97  dl                 make class public
*/


module tango.store.impl.MutableMapImpl;

private import tango.store.Exception;
private import tango.store.impl.MutableImpl;

private import tango.store.model.Map;
private import tango.store.model.Predicate;
private import tango.store.model.MutableMap;
private import tango.store.model.Collection;
private import tango.store.model.KeySortedCollection;

private import tango.text.String;

/**
 *
 * MutableMapImpl extends MutableImpl to provide
 * default implementations of some Map operations. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class MutableMapImplT(K, T) : MutableImplT!(T), MutableMapT!(K, T)
{
        alias MapT!(K, T)               Map;
        alias PredicateT!(T)            Predicate;
        alias CollectionT!(T)           Collection;
        alias KeySortedCollectionT!(K, T)  KeySortedCollection;


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
         * Implements store.Map.canIncludeKey.
         * Default key-screen. Just checks for null.
         * @see store.Map#canIncludeKey
        **/
        public final bool canIncludeKey(K key)
        {
                return (key !is K.init);
        }

        protected final bool isValidKey(K key)
        {
                static if (is (T : Object))
                          {
                          if (key is null)
                              return false;
                          }
                return true;
        }

        /**
         * Principal method to throw a IllegalElementException for keys
        **/
        protected final void checkKey(K key)
        {
                if (!canIncludeKey(key))
                {
                        throw new IllegalElementException(null, "Attempt to include invalid key _in Collection");
                }
        }


        /**
         * Implements store.Collection.matches
         * Time complexity: O(n).
         * Default implementation. Fairly sleazy approach.
         * (Defensible only when you remember that it is just a default impl.)
         * It tries to cast to one of the known collection interface types
         * and then applies the corresponding comparison rules.
         * This suffices for all currently supported collection types,
         * but must be overridden if you define new Collection subinterfaces
         * and/or implementations.
         * 
         * @see store.Collection#matches
        **/

        public override bool matches(Collection other)
        {
                if (other is null)
                   {}
                else
                   if (other is this)
                       return true;
                   else
                      {
                      auto tmp = cast (Map) other;
                      if (tmp)
                          if (cast(KeySortedCollection) this)
                              return sameOrderedPairs(this, tmp);
                          else
                             return samePairs(this, tmp);
                      }
                return false;
        }


        public final static bool samePairs(Map s, Map t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.keys();

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          auto k = ts.key();
                          auto v = t.get(k);
                          if (!s.containsPair(k, v))
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }

        public final static bool sameOrderedPairs(Map s, Map t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.keys();
                auto ss = s.keys();

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          auto sk = ss.key();
                          auto k = ts.key();
                          if (sk != k)
                              return false;

                          auto v = t.get(k);
                          if (! s.containsPair(k, v))
                                return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }


        // Object methods

        /**
         * Default implementation of toUtf8 for Collections. Not
         * very pretty, but parenthesizing each element means that
         * for most kinds of elements, it's conceivable that the
         * strings could be parsed and used to build other store.
         * <P>
         * Not a very pretty implementation either. Casts are used
         * to get at elements/keys
        **/

        public final char[] toUtf8()
        {
                auto buf = new MutableString;
                buf.append("( (class: "c).append(this.classinfo.name).append(")"c);
                buf.append(" (size:"c).append(size()).append(")"c);
                buf.append(" (elements:"c);

                   {
                   Map m = this;
                   auto k = m.keys();

                   try {
                       while (k.more())
                             {
                             buf.append(" ("c);

                             buf.append(" ("c);
                             buf.append ("key"c); //buf.append(k.key().toUtf8());
                             k.key();
                             buf.append(")"c);
                             
                             buf.append(" ("c);
                             buf.append ("value"c);//buf.append(k.value().toUtf8());
                             k.value();
                             buf.append(")"c);
                             
                             buf.append(" )"c);
                             }
                       } catch (NoSuchElementException ex)
                               {
                               buf.append("? Cannot access elements?"c);
                               }
                   }

                buf.append(" ) )"c);
                return buf.aliasOf();
        }



version (VERBOSE)
{
        // Default implementations of Map methods

        /**
         * Implements store.Map.puttingAt.
         * @see store.Map#puttingAt
        **/
        public final final Map puttingAt(K key, V element)
        {
                MutableMap c = null;
                //      c = (cast(MutableMap)clone());
                c = (cast(MutableMap)duplicate());
                c.putAt(key, element);
                return c;
        }

        /**
         * Implements store.Map.removingAt
         * @see store.Map#removingAt
        **/
        public final final Map removingAt(K key)
        {
                MutableMap c = null;
                //      c = (cast(MutableMap)clone());
                c = (cast(MutableMap)duplicate());
                c.remove(key);
                return c;
        }
} // version
}

alias MutableMapImplT!(Object, Object) MutableMapImpl;
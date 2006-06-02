/*
 File: MutableImpl.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Add assert
 22Oct95  dl                 Add excludeElements, removeElements
 28jan97  dl                 make class public; isolate version_ changes
*/


module tango.store.impl.MutableImpl;

private import tango.store.Exception;

private import tango.store.model.Bag;
private import tango.store.model.Map;
private import tango.store.model.Seq;
private import tango.store.model.Set;
private import tango.store.model.Predicate;
private import tango.store.model.Collection;
private import tango.store.model.Iterator;
private import tango.store.model.KeySortedCollection;
private import tango.store.model.MutableCollection;
private import tango.store.model.ElementSortedCollection;

private import tango.convert.Integer;

private import tango.text.String;


/**
 *
 * MutableImpl serves as a convenient base class for most 
 * implementations of updatable store. It maintains
 * a version number and element count.
 * It also provides default implementations of many
 * collection operations. 
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class MutableImplT(T) : MutableCollectionT!(T)
{
        alias IteratorT!(T)     Iterator;
        alias PredicateT!(T)    Predicate;
        alias CollectionT!(T)   Collection;


        // instance variables

        /**
         * version_ represents the current version number
        **/
        protected int version_;

        /**
         * screener_ hold the supplied element screener
        **/

        protected Predicate screener_;

        /**
         * count_ holds the number of elements.
        **/
        protected int count_;

        // constructors

        /**
         * Initialize at version 0, an empty count, and null screener
        **/

        protected this ()
        {
                version_ = 0;
                count_ = 0;
                screener_ = null;
        }

        /**
         * Initialize at version 0, an empty count, and supplied screener
        **/
        protected this (Predicate screener)
        {
                version_ = 0;
                count_ = 0;
                screener_ = screener;
        }


        package final static bool isValidArg (T element)
        {
                static if (is (T : Object))
                          {
                          if (element is null)
                              return false;
                          }
                return true;
        }

        // Default implementations of Collection methods
        /+
        /**
         * Wrapper for clone()
         * @see clone
        **/

        public final Collection duplicate()
        {
                Collection c = null;
                c = cast(Collection)(clone());
                return c;
        }
        +/
        /**
         * Implements store.Collection.isEmpty.
         * Time complexity: O(1).
         * @see store.Collection#isEmpty
        **/

        public final bool isEmpty()
        {
                return count_ is 0;
        }

        /**
         * Implements store.Collection.size.
         * Time complexity: O(1).
         * @see store.Collection#size
        **/
        public final int size()
        {
                return count_;
        }

        /**
         * Implements store.Collection.canInclude.
         * Time complexity: O(1) + time of screener, if present
         * @see store.Collection#canInclude
        **/
        public final bool canInclude(T element)
        {
                return isValidArg(element) && (screener_ is null || screener_.predicate(element));
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

        public bool matches(Collection other)
        {
/+
                if (other is null)
                    return false;
                else
                   if (other is this)
                       return true;
                   else
                      if (cast(KeySortedCollection) this)
                         {
                         if (!(cast(Map) other))
                               return false;
                         else
                            return sameOrderedPairs(cast(Map)this, cast(Map)other);
                         }
                      else
                         if (cast(Map) this)
                            {
                            if (!(cast(Map) other))
                                  return false;
                            else
                               return samePairs(cast(Map)(this), cast(Map)(other));
                            }
                         else
                            if ((cast(Seq) this) || (cast(ElementSortedCollection) this))
                                 return sameOrderedElements(this, other);
                            else
                               if (cast(Bag) this)
                                   return sameOccurrences(this, other);
                               else
                                  if (cast(Set) this)
                                      return sameInclusions(this, cast(Collection)(other));
                                  else
                                     return false;
+/
        return false;
        }



version (VERBOSE)
{
        /**
         * Implements store.Collection.removingOneOf
         * @see store.Collection#removingOneOf
        **/
        public final Collection removingOneOf(T element)
        {
                MutableCollection c = null;
                //      c = (cast(MutableCollection)clone());
                c = (cast(MutableCollection)duplicate());
                c.removeOneOf(element);
                return c;
        }

        /**
         * Implements store.Collection.excluding.
         * @see store.Collection#excluding
        **/
        public final Collection excluding(T element)
        {
                MutableCollection c = null;
                //      c = (cast(MutableCollection)clone());
                c = (cast(MutableCollection)duplicate());
                c.exclude(element);
                return c;
        }


        /**
         * Implements store.Collection.replacingOneOf
         * @see store.Collection#replacingOneOf
        **/
        public final Collection replacingOneOf(T oldElement, T newElement)
        {
                MutableCollection c = null;
                //      c = (cast(MutableCollection)clone());
                c = (cast(MutableCollection)duplicate());
                c.replaceOneOf(oldElement, newElement);
                return c;
        }

        /**
         * Implements store.Collection.replacingAllOf
         * @see store.Collection#replacingAllOf
        **/
        public final Collection replacingAllOf(T oldElement, T newElement)
        {
                MutableCollection c = null;
                //      c = (cast(MutableCollection)clone());
                c = (cast(MutableCollection)duplicate());
                c.replaceAllOf(oldElement, newElement);
                return c;
        }
} // version


        // Default implementations of MutableCollection methods

        /**
         * Implements store.MutableCollection.version.
         * Time complexity: O(1).
         * @see store.MutableCollection#version
        **/
        public final int _version()
        {
                return version_;
        }


        /**
         * Implements store.MutableCollection.excludeElements
         * @see store.MutableCollection#excludeElements
        **/
        public final void excludeElements(Iterator e)
        {
                while (e.more)
                       exclude(e.value);
        }


        /**
         * Implements store.MutableCollection.removeElements
         * @see store.MutableCollection#removeElements
        **/
        public final void removeElements(Iterator e)
        {
                while (e.more)
                       removeOneOf(e.value);
        }

        // Object methods

        /**
         * Default implementation of toString for Collections. Not
         * very pretty, but parenthesizing each element means that
         * for most kinds of elements, it's conceivable that the
         * strings could be parsed and used to build other store.
         * <P>
         * Not a very pretty implementation either. Casts are used
         * to get at elements/keys
        **/

        public char[] toString()
        {
                auto buf = new MutableString;
                buf.append("<class "c).append(this.classinfo.name).append(':').append(typeid(T).toString);
                buf.append(" size:"c).append(size());
                buf.append(" elements:"c);

                   {
                   auto e = elements();
                   try {
                       while (e.more)
                             {
                             buf.append(" ("c);
                             buf.append ("value"c);//buf.append(e.value().toString());
                             e.value();
                             buf.append(")"c);
                             }
                       } catch (NoSuchElementException ex)
                               {
                               buf.append("? Cannot access elements?"c);
                               }
                   }
                buf.append(">"c);
                return buf.aliasOf();
        }

        // protected operations on version_ and count_

        /**
         * change the version number
        **/

        protected final void incVersion()
        {
                ++version_;
        }


        /**
         * Increment the element count and update version_
        **/
        protected final void incCount()
        {
                count_++;
                incVersion();
        }

        /**
         * Decrement the element count and update version_
        **/
        protected final void decCount()
        {
                count_--;
                incVersion();
        }


        /**
         * add to the element count and update version_ if changed
        **/
        protected final void addToCount(int c)
        {
                if (c !is 0)
                   {
                   count_ += c;
                   incVersion();
                   }
        }

        /**
         * set the element count and update version_ if changed
        **/
        protected final void setCount(int c)
        {
                if (c !is count_)
                   {
                   count_ = c;
                   incVersion();
                   }
        }


        // Helper methods left public since they might be useful

        public final static bool sameInclusions(Collection s, Collection t)
        {
                if (s.size !is t.size)
                    return false;

                try { // set up to return false on collection exceptions
                    auto ts = t.elements();
                    while (ts.more)
                          {
                          if (!s.contains(ts.value))
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }

        public final static bool sameOccurrences(Collection s, Collection t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                T last = T.init; // minor optimization -- skip two successive if same

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.value;
                          if (m !is last)
                             {
                             if (s.instances(m) !is t.instances(m))
                                 return false;
                             }
                          last = m;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }

        public final static bool sameOrderedElements(Collection s, Collection t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                auto ss = s.elements();

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.value;
                          T o = ss.value;
                          if (m != o)
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {       
                            return false;
                            }
        }

        // misc common helper methods

        /**
         * Principal method to throw a NoSuchElementException.
         * Besides index checks in Seqs, you can use it to check for
         * operations on empty collections via checkIndex(0)
        **/
        protected final void checkIndex(int index)
        {
                if (index < 0 || index >= count_)
                   {
                   char[] msg;

                   if (count_ is 0)
                       msg = "Element access on empty collection";
                   else
                      {
                      char[16] idx, cnt;
                      msg = "Index " ~ Integer.format (idx, index) ~ " out of range for collection of size " ~ Integer.format (cnt, count_);
                      }
                   throw new NoSuchElementException(msg);
                   }
        }

        /**
         * Principal method to throw a IllegalElementException
        **/

        protected final void checkElement(T element)
        {
                if (! canInclude(element))
                   {
                   //throw new IllegalElementException(element, "Attempt to include invalid element _in Collection");
                   throw new IllegalElementException(null, "Attempt to include invalid element _in Collection");
                   }
        }


        /+
        /**
         * Implements store.ImplementationCheckable.assert.
         * @see store.ImplementationCheckable#assert
        **/
        public final void assert(bool pred)
        {
                ImplementationError.assert(this, pred);
        }
        +/


        /**
         * Implements store.ImplementationCheckable.checkImplementation.
         * @see store.ImplementationCheckable#checkImplementation
        **/
        public override void checkImplementation()
        {
                assert(count_ >= 0);
        }
}


alias MutableImplT!(Object)  MutableImpl;
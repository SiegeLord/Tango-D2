/*******************************************************************************

        File: Collection.d

        Originally written by Doug Lea and released into the public domain. 
        Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
        Inc, Loral, and everyone contributing, testing, and using this code.

        History:
        Date     Who                What
        24Sep95  dl@cs.oswego.edu   Create from store.d  working file
        13Oct95  dl                 Add assert
        22Oct95  dl                 Add excludeElements, removeElements
        28jan97  dl                 make class public; isolate version changes
        14Dec06  kb                 Adapted for Tango usage
        
********************************************************************************/

module tango.util.collection.impl.Collection;

private import  tango.util.collection.Exception;

private import  tango.io.protocol.model.IReader,
                tango.io.protocol.model.IWriter;

private import  tango.util.collection.model.View,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.Dispenser;

/*******************************************************************************

        Collection serves as a convenient base class for most implementations
        of mutable containers. It maintains a version number and element count.
        It also provides default implementations of many collection operations. 
 
        author: Doug Lea
                @version 0.93
        <P> For an introduction to this package see <A HREF="index.html"
        > Overview </A>.
        
********************************************************************************/

public abstract class Collection(T) : Dispenser!(T), IReadable, IWritable
{
        alias View!(T)          ViewT;

        alias bool delegate(T)  Predicate;


        // instance variables

        /***********************************************************************

                version represents the current version number

        ************************************************************************/

        protected int vershion;

        /***********************************************************************

                screener hold the supplied element screener

        ************************************************************************/

        protected Predicate screener;

        /***********************************************************************

		count holds the number of elements.

        ************************************************************************/

        protected int count;

        // constructors

        /***********************************************************************

		Initialize at version 0, an empty count, and supplied screener

        ************************************************************************/

        protected this (Predicate screener = null)
        {
                this.screener = screener;
        }


        /***********************************************************************

        ************************************************************************/

        protected final static bool isValidArg (T element)
        {
                static if (is (T : Object))
                          {
                          if (element is null)
                              return false;
                          }
                return true;
        }

        // Default implementations of Collection methods

        /***********************************************************************

		Implements store.Collection.drained.
		Time complexity: O(1).
		@see store.Collection#drained

        ************************************************************************/

        public final bool drained()
        {
                return count is 0;
        }

        /***********************************************************************

		Implements store.Collection.size.
		Time complexity: O(1).
		@see store.Collection#size

        ************************************************************************/

        public final int size()
        {
                return count;
        }

        /***********************************************************************

		Implements store.Collection.allows.
		Time complexity: O(1) + time of screener, if present
		@see store.Collection#allows

        ************************************************************************/

        public final bool allows (T element)
        {
                return isValidArg(element) &&
                                 (screener is null || screener(element));
        }

        
        /***********************************************************************

		Implements store.Collection.matches
		Time complexity: O(n).
		Default implementation. Fairly sleazy approach.
		(Defensible only when you remember that it is just a default impl.)
		It tries to cast to one of the known collection interface types
		and then applies the corresponding comparison rules.
		This suffices for all currently supported collection types,
		but must be overridden if you define new Collection subinterfaces
		and/or implementations.
		
		@see store.Collection#matches

        ************************************************************************/

        public bool matches(ViewT other)
        {
/+
                if (other is null)
                    return false;
                else
                   if (other is this)
                       return true;
                   else
                      if (cast(SortedKeys) this)
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
                            if ((cast(Seq) this) || (cast(SortedValues) this))
                                 return sameOrderedElements(this, other);
                            else
                               if (cast(Bag) this)
                                   return sameOccurrences(this, other);
                               else
                                  if (cast(Set) this)
                                      return sameInclusions(this, cast(View)(other));
                                  else
                                     return false;
+/
                   return false;
        }

        // Default implementations of MutableCollection methods

        /***********************************************************************

		Implements store.MutableCollection.version.
		Time complexity: O(1).
		@see store.MutableCollection#version

        ************************************************************************/

        public final int mutation()
        {
                return vershion;
        }

        // Object methods

        /***********************************************************************

		Default implementation of toUtf8 for Collections. Not
		very pretty, but parenthesizing each element means that
		for most kinds of elements, it's conceivable that the
		strings could be parsed and used to build other store.
		<P>
		Not a very pretty implementation either. Casts are used
		to get at elements/keys

        ************************************************************************/

        public char[] toUtf8()
        {
                char[]   buf;
                char[16] tmp;
                
                buf ~= "<class " ~ this.classinfo.name ~ ':' ~ typeid(T).toUtf8 ~ " size:" ~ itoa(tmp, size()) ~ " elements:";

                foreach (value; elements)
                        {
                        buf ~= " (";
                        //buf.append(e.value().toUtf8());
                        buf ~= ')';
                        }
                buf ~= '>';
                return buf;
        }


        /***********************************************************************

        ************************************************************************/

        protected final char[] itoa(char[] buf, int i)
        {
                int j = buf.length;
                
                do {
                   buf[--j] = i % 10;
                   } while (i /= 10);
                return buf [j..$];
        }
        
        // protected operations on version and count

        /***********************************************************************

		change the version number

        ************************************************************************/

        protected final void incVersion()
        {
                ++vershion;
        }


        /***********************************************************************

		Increment the element count and update version

        ************************************************************************/

        protected final void incCount()
        {
                count++;
                incVersion();
        }

        /***********************************************************************

		Decrement the element count and update version

        ************************************************************************/

        protected final void decCount()
        {
                count--;
                incVersion();
        }


        /***********************************************************************

		add to the element count and update version if changed

        ************************************************************************/

        protected final void addToCount(int c)
        {
                if (c !is 0)
                   {
                   count += c;
                   incVersion();
                   }
        }
        

        /***********************************************************************

		set the element count and update version if changed

        ************************************************************************/

        protected final void setCount(int c)
        {
                if (c !is count)
                   {
                   count = c;
                   incVersion();
                   }
        }


        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameInclusions(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                try { // set up to return false on collection exceptions
                    auto ts = t.elements();
                    while (ts.more)
                          {
                          if (!s.contains(ts.get))
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }

        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameOccurrences(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                T last = T.init; // minor optimization -- skip two successive if same

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.get;
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
        

        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameOrderedElements(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                auto ss = s.elements();

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.get;
                          T o = ss.get;
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

        /***********************************************************************

		Principal method to throw a NoSuchElementException.
		Besides index checks in Seqs, you can use it to check for
		operations on empty collections via checkIndex(0)

        ************************************************************************/

        protected final void checkIndex(int index)
        {
                if (index < 0 || index >= count)
                   {
                   char[] msg;

                   if (count is 0)
                       msg = "Element access on empty collection";
                   else
                      {
                      char[16] idx, cnt;
                      msg = "Index " ~ itoa (idx, index) ~ " out of range for collection of size " ~ itoa (cnt, count);
                      }
                   throw new NoSuchElementException(msg);
                   }
        }

        
        /***********************************************************************

		Principal method to throw a IllegalElementException

        ************************************************************************/

        protected final void checkElement(T element)
        {
                if (! allows(element))
                   {
                   //throw new IllegalElementException(element, "Attempt to include invalid element _in Collection");
                   throw new IllegalElementException(null, "Attempt to include invalid element _in Collection");
                   }
        }


        /+
        /***********************************************************************

		Implements store.ImplementationCheckable.assert.
		@see store.ImplementationCheckable#assert

        ************************************************************************/

        public final void assert(bool pred)
        {
                ImplementationError.assert(this, pred);
        }
        +/

        /***********************************************************************

                Default implementation of IReadable interface
                
        ************************************************************************/

        public void read (IReader input)
        {
        }
                        
        /***********************************************************************

                Default implementation of IWritable interface

        ************************************************************************/

        public void write (IWriter output)
        {
        }
                        
        /***********************************************************************

		Implements store.ImplementationCheckable.checkImplementation.
		@see store.ImplementationCheckable#checkImplementation

        ************************************************************************/

        public override void checkImplementation()
        {
                assert(count >= 0);
        }

        /***********************************************************************

		Cause the collection to become empty. 
		@return condition:
		<PRE>
		drained() &&
		Version change iff !PREV(this).drained();
		</PRE>

        ************************************************************************/

        abstract void clear();

        
        /***********************************************************************

		Exclude all occurrences of the indicated element from the collection. 
		No effect if element not present.
		@param element the element to exclude.
		@return condition: 
		<PRE>
		!has(element) &&
		size() == PREV(this).size() - PREV(this).instances(element) &&
		no other element changes &&
		Version change iff PREV(this).has(element)
		</PRE>

        ************************************************************************/

        abstract void removeAll(T element);


        /***********************************************************************

		Remove an instance of the indicated element from the collection. 
		No effect if !has(element)
		@param element the element to remove
		@return condition: 
		<PRE>
		let occ = max(1, instances(element)) in
		 size() == PREV(this).size() - occ &&
		 instances(element) == PREV(this).instances(element) - occ &&
		 no other element changes &&
		 version change iff occ == 1
		</PRE>

        ************************************************************************/

        abstract void remove (T element);

        
        /***********************************************************************

		Replace an occurrence of oldElement with newElement.
		No effect if does not hold oldElement or if oldElement.equals(newElement).
		The operation has a consistent, but slightly special interpretation
		when applied to Sets. For Sets, because elements occur at
		most once, if newElement is already included, replacing oldElement with
		with newElement has the same effect as just removing oldElement.
		@return condition:
		<PRE>
		let int delta = oldElement.equals(newElement)? 0 : 
		              max(1, PREV(this).instances(oldElement) in
		 instances(oldElement) == PREV(this).instances(oldElement) - delta &&
		 instances(newElement) ==  (this instanceof Set) ? 
		        max(1, PREV(this).instances(oldElement) + delta):
		               PREV(this).instances(oldElement) + delta) &&
		 no other element changes &&
		 Version change iff delta != 0
		</PRE>
		@exception IllegalElementException if has(oldElement) and !allows(newElement)

        ************************************************************************/

        abstract void replace (T oldElement, T newElement);


        /***********************************************************************

		Replace all occurrences of oldElement with newElement.
		No effect if does not hold oldElement or if oldElement.equals(newElement).
		The operation has a consistent, but slightly special interpretation
		when applied to Sets. For Sets, because elements occur at
		most once, if newElement is already included, replacing oldElement with
		with newElement has the same effect as just removing oldElement.
		@return condition:
		<PRE>
		let int delta = oldElement.equals(newElement)? 0 : 
                           PREV(this).instances(oldElement) in
		 instances(oldElement) == PREV(this).instances(oldElement) - delta &&
		 instances(newElement) ==  (this instanceof Set) ? 
		        max(1, PREV(this).instances(oldElement) + delta):
		               PREV(this).instances(oldElement) + delta) &&
		 no other element changes &&
		 Version change iff delta != 0
		</PRE>
		@exception IllegalElementException if has(oldElement) and !allows(newElement)

        ************************************************************************/

        abstract void replaceAll(T oldElement, T newElement);


        /***********************************************************************

                Exclude all occurrences of each element of the Iterator.
                Behaviorally equivalent to
                <PRE>
                while (e.more()) removeAll(e.get());
                @param e the enumeration of elements to exclude.
                @exception CorruptedIteratorException is propagated if thrown
		Implements store.MutableCollection.removeAll
		@see store.MutableCollection#removeAll

        ************************************************************************/

        abstract void removeAll (Iterator!(T) e);


        /***********************************************************************

                 Remove an occurrence of each element of the Iterator.
                 Behaviorally equivalent to
                 <PRE>
                 while (e.more()) remove (e.get());
                 @param e the enumeration of elements to remove.
                 @exception CorruptedIteratorException is propagated if thrown

        ************************************************************************/

        abstract void remove (Iterator!(T) e);

   
        /***********************************************************************

		Remove and return an element.  Implementations
		may strengthen the guarantee about the nature of this element.
		but in general it is the most convenient or efficient element to remove.
		<P>
		Example usage. One way to transfer all elements from 
		MutableCollection a to MutableBag b is:
		<PRE>
		while (!a.empty()) b.add(a.take());
		</PRE>
		@return an element v such that PREV(this).has(v) 
		and the postconditions of removeOneOf(v) hold.
		@exception NoSuchElementException iff drained.

        ************************************************************************/

        abstract T take();
}



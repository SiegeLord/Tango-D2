/*
 File: Exception.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.store.Exception;

private import tango.store.model.Collection;

/**
 *
 *
 * CorruptedIteratorException is thrown by CollectionIterator
 * nextElement if a versioning inconsistency is detected in the process
 * of returning the next element
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class CorruptedIteratorException : NoSuchElementException
{

        /**
         * The collection that this is an enumeration of
        **/

        public Collection collection;

        /**
         * The version expected of the collection
        **/
        public int oldVersion;

        /**
         * The current version of the collection
        **/

        public int newVersion;

        public this (int oldv, int newv, Collection coll, char[] msg)
        {
                super(msg);
                oldVersion = oldv;
                newVersion = newv;
                collection = coll;
        }
}


/**
 *
 *
 * IllegalArgumentException 
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class IllegalArgumentException : Exception
{
        public this (char[] msg)
        {
                super(msg);
        }
}


/**
 *
 *
 * IllegalElementException is thrown by Collection methods
 * that add (or replace) elements (and/or keys) when their
 * arguments are null or do not pass screeners.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class IllegalElementException : IllegalArgumentException
{
        public Object argument;

        public this (Object v, char[] msg)
        {
                super(msg);
                argument = v;
        }
}


/**
 * ImplementationError is thrown by 
 * ImplementationCheckable.checkImplementation upon failure
 * to verify internal representation constraints.
 * 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public class ImplementationError : Exception
{

        /**
         * The object failing the ImplementationCheck
        **/

        public Object failedObject;

        public this (char[] msg, Object v)
        {
                super(msg);
                failedObject = v;
        }
}


/**
 *
 *
 * IllegalElementException is thrown by Collection methods
 * that add (or replace) elements (and/or keys) when their
 * arguments are null or do not pass screeners.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class NoSuchElementException : Exception
{
        public Object argument;

        public this (Object v, char[] msg)
        {
                super(msg);
                argument = v;
        }

        public this (char[] msg)
        {
                super(msg);
        }
}

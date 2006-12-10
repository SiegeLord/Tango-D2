/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006      
        
        author:         Kris

*******************************************************************************/

module tango.text.LineIterator;

private import  tango.text.Iterator;

/*******************************************************************************

        Iterate across a set of text patterns.

        These iterators are based upon the IBuffer construct, and can
        thus be used in conjunction with other Iterators and/or Reader
        instances upon a common buffer ~ each will stay in lockstep via
        state maintained within the IBuffer.

        The content exposed via an iterator is supposed to be entirely
        read-only. All current iterators abide by this rule, but it is
        possible a user could mutate the content through a get() slice.
        To enforce the desired read-only aspect, the code would have to 
        introduce redundant copying or the compiler would have to support 
        read-only arrays.

        See LineIterator, SimpleIterator, RegexIterator, QuotedIterator.


*******************************************************************************/

class LineIteratorT(T) : IteratorT!(T)
{
        /***********************************************************************
        
                Construct an uninitialized iterator. Use as follows:

                auto line = new LineIterator;

                void somefunc (IBuffer buffer)
                {
                        // there are several set() methods
                        line.set (buffer);
                        
                        while (line.next)
                               Println (line.get);
                }
        
        ***********************************************************************/

        this () {}

        /***********************************************************************

                Construct a streaming iterator upon the provided buffer. 
                Use as follows:

                void somefunc (IBuffer buffer)
                {
                        auto line = new LineIterator (buffer);
                        
                        while (line.next)
                               Println (line.get);
                }
        
        ***********************************************************************/

        this (IBuffer buffer)
        {
                super (buffer);
        }

        /***********************************************************************
        
                Construct a streaming iterator upon the provided conduit. 
                Use as follows:

                auto line = new LineIterator (new FileConduit ("myfile"));

                while (line.next)
                       Println (line.get);

        ***********************************************************************/

        this (IConduit conduit)
        {
                super (conduit);
        }

        /***********************************************************************
        
                Construct an iterator upon the provided string. Use as follows:

                void somefunc (char[] string)
                {
                        auto line = new LineIterator (string);
                        
                        while (line.next)
                               Println (line.get);
                }
        
        ***********************************************************************/

        this (T[] string)
        {
               super (string);
        }

        /***********************************************************************
        
                Scanner implementation for this iterator. Find a '\n',
                and eat any immediately preceeding '\r'
                
        ***********************************************************************/

        protected uint scan (void[] data)
        {
                T[] content = convert (data);

                foreach (int i, T c; content)
                         if (c is '\n')
                            {
                            int slice = i;
                            if (i && content[i-1] is '\r')
                                --slice;
                            set (content.ptr, 0, slice);
                            return found (i);
                            }

                return notFound (content);
        }
}


// convenience alias
alias LineIteratorT!(char) LineIterator;


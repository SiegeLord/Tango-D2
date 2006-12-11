/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006      
        
        author:         Kris

*******************************************************************************/

module tango.text.RegexIterator;

private import  tango.text.Regex;
    
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

class RegexIteratorT(T) : IteratorT!(T)
{
        private Regex regex;

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

        this (T[] pattern) 
        {
                init (pattern);
        }

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

        this (IBuffer buffer, T[] pattern)
        {
                super (buffer);
                init (pattern);
        }

        /***********************************************************************
        
                Construct a streaming iterator upon the provided conduit. 
                Use as follows:

                auto line = new LineIterator (new FileConduit ("myfile"));

                while (line.next)
                       Println (line.get);

        ***********************************************************************/

        this (IConduit conduit, T[] pattern)
        {
                super (conduit);
                init (pattern);
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

        this (T[] string, T[] pattern)
        {
                super (string);
                init (pattern);
        }

        /***********************************************************************
                
        ***********************************************************************/

        protected uint scan (void[] data)
        {
                T[] content = convert (data);

                if (regex.test (content))
                   {
                   int start = regex.pmatch[0].rm_so;
                   int finish = regex.pmatch[0].rm_eo;
                   set (content.ptr, 0, start);
                   return found (finish);        
                   }

                return notFound (content);
        }

        /***********************************************************************
                
        ***********************************************************************/

        private void init (T[] pattern)
        {
                regex = new Regex (pattern, "");
        }
}


// convenience alias
alias RegexIteratorT!(char) RegexIterator;


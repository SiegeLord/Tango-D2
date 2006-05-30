/*******************************************************************************

        @file RegexIterator.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, January 2006      

        @author         Kris


*******************************************************************************/

module tango.text.RegexIterator;

private import  std.regexp;
    
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
        private RegExp regex;

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
                   set (content, 0, start);
                   return found (finish);        
                   }

                return notFound (content);
        }

        /***********************************************************************
                
        ***********************************************************************/

        private void init (T[] pattern)
        {
                regex = new RegExp (pattern, "");
        }
}


// convenience alias
alias RegexIteratorT!(char) RegexIterator;


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006      
        
        author:         Kris

*******************************************************************************/

module tango.text.stream.LineIterator;

private import  tango.text.stream.StreamIterator;

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

class LineIterator(T) : StreamIterator!(T)
{
        /***********************************************************************
        
                Construct an uninitialized iterator. For example:
                ---
                auto lines = new LineIterator!(char);

                void somefunc (IBuffer buffer)
                {
                        foreach (line; lines.set(buffer))
                                 Cout (line).newline;
                }
                ---

                Construct a streaming iterator upon a buffer:
                ---
                void somefunc (IBuffer buffer)
                {
                        foreach (line; new LineIterator!(char) (buffer))
                                 Cout (line).newline;
                }
                ---
                
                Construct a streaming iterator upon a conduit:
                ---
                foreach (line; new LineIterator!(char) (new FileConduit ("myfile")))
                         Cout (line).newline;
                ---

        ***********************************************************************/

        this (InputStream stream = null)
        {
                super (stream);
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


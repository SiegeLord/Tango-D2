/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006

        author:         Kris

*******************************************************************************/

module tango.io.stream.Delimiters;

private import tango.io.stream.Iterator;

/*******************************************************************************

        Iterate across a set of text patterns.

        Each pattern is exposed to the client as a slice of the original
        content, where the slice is transient. If you need to retain the
        exposed content, then you should .dup it appropriately.

        The content exposed via an iterator is supposed to be entirely
        read-only. All current iterators abide by this rule, but it is
        possible a user could mutate the content through a get() slice.
        To enforce the desired read-only aspect, the code would have to
        introduce redundant copying or the compiler would have to support
        read-only arrays.

        See Lines, Patterns, Quotes.

*******************************************************************************/

class Delimiters(T) : Iterator!(T)
{
        private const(T)[] delim;

        /***********************************************************************

                Construct an uninitialized iterator. For example:
                ---
                auto lines = new Lines!(char);

                void somefunc (InputStream stream)
                {
                        foreach (line; lines.set(stream))
                                 Cout (line).newline;
                }
                ---

                Construct a streaming iterator upon a stream:
                ---
                void somefunc (InputStream stream)
                {
                        foreach (line; new Lines!(char) (stream))
                                 Cout (line).newline;
                }
                ---

                Construct a streaming iterator upon a conduit:
                ---
                foreach (line; new Lines!(char) (new File ("myfile")))
                         Cout (line).newline;
                ---

        ***********************************************************************/

        this (const(T)[] delim, InputStream stream = null)
        {
                this.delim = delim;
                super (stream);
        }

        /***********************************************************************

        ***********************************************************************/

        protected override size_t scan (const(void)[] data)
        {
                auto content = (cast(const(T)*) data.ptr) [0 .. data.length / T.sizeof];

                if (delim.length is 1)
                   {
                   foreach (int i, T c; content)
                            if (c is delim[0])
                                return found (set (content.ptr, 0, i, i));
                   }
                else
                   foreach (int i, T c; content)
                            if (has (delim, c))
                                return found (set (content.ptr, 0, i, i));

                return notFound();
        }
}



/*******************************************************************************

*******************************************************************************/

debug(UnitTest)
{
        private import tango.io.device.Array;

        unittest
        {
                auto p = new Delimiters!(char) (", ", new Array("blah".dup));
        }
}

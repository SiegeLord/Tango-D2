/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006

        author:         Kris

*******************************************************************************/

module tango.io.stream.Patterns;

private import tango.text.Regex;

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

        See Delimiters, Lines, Quotes.

*******************************************************************************/

class Patterns : Iterator!(char)
{
        private Regex regex;
        private alias char T;

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

        this (const(T)[] pattern, InputStream stream = null)
        {
                regex = new Regex (pattern, "");
                super (stream);
        }

        /***********************************************************************

        ***********************************************************************/

        protected override size_t scan (const(void)[] data)
        {
                auto content = (cast(const(T)*) data.ptr) [0 .. data.length / T.sizeof];

                if (regex.test (content))
                   {
                   int start = regex.registers_[0];
                   int finish = regex.registers_[1];
                   set (content.ptr, 0, start);
                   return found (finish-1);
                   }

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
                auto p = new Patterns ("b.*", new Array("blah".dup));
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.LineStream;

private import tango.io.Conduit;

private import tango.io.model.IConduit;

private import tango.text.stream.LineIterator;

/*******************************************************************************

        Simple way to hook up a line-tokenizer to an arbitrary InputStream,
        such as a file conduit:
        ---
        auto input = new LineInput (new FileConduit("path"));
        foreach (line; input)
                 ...
        input.close;
        ---

*******************************************************************************/

class LineInput : InputFilter, Buffered
{
        private LineIterator!(char) line;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                line = new LineIterator!(char)(stream);
                super (line.buffer);
        }

        /***********************************************************************

                Buffered interface

        ***********************************************************************/

        IBuffer buffer ()
        {
                return line.buffer;
        }

        /***********************************************************************

        ***********************************************************************/

        LineIterator!(char) iterator ()
        {
                return line;
        }

        /**********************************************************************

                Iterate over the set of tokens. This should really
                provide read-only access to the tokens, but D does
                not support that at this time

        **********************************************************************/

        int opApply (int delegate(inout char[]) dg)
        {       
                return line.opApply (dg);
        }
}



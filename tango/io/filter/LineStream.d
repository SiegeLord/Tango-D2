/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.LineStream;

private import tango.io.Conduit;

private import tango.io.model.IConduit;

/*******************************************************************************

*******************************************************************************/

class LineInput(T) : InputFilter, Buffered
{
        private LineIterator!(T) line;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
                line = new LineInterator!(T)(stream);
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

        T[] readln ()
        {
                return line.next;
        }
}



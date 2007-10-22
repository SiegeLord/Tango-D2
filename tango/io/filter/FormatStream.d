/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.FormatStream;

private import tango.io.Print;

private import tango.io.Conduit;

private import tango.io.model.IConduit;

private import tango.text.convert.Layout;

/*******************************************************************************

*******************************************************************************/

class FormatStream(T) : OutputFilter
{
        private Print!(T) output;

        /***********************************************************************

                Create a Print instance and attach it to the given stream

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (stream);
                output = new Print!(T) (new Layout!(T), stream);
        }

        /***********************************************************************

                Return the Print instance

        ***********************************************************************/

        Print!(T) print ()
        {
                return output;
        }
}



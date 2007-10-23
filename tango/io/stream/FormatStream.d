/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.FormatStream;

private import  tango.io.Print,
                tango.io.Conduit;

private import  tango.text.convert.Layout;

/*******************************************************************************

        Simple way to hook up a utf8 formatter to an arbitrary OutputStream,
        such as a file conduit:
        ---
        auto output = new FormatOutput (new FileOutput("path"));
        output.print.formatln ("{} green bottles", 10);
        output.close;
        ---

*******************************************************************************/

class FormatOutput : OutputFilter
{
        private Print!(char) output;

        /***********************************************************************

                Create a Print instance and attach it to the given stream

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (stream);
                output = new Print!(char) (new Layout!(char), stream);
        }

        /***********************************************************************

                Return the Print instance

        ***********************************************************************/

        final Print!(char) print ()
        {
                return output;
        }
}



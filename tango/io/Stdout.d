/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

*******************************************************************************/

module tango.io.Stdout;

private import  tango.io.Console;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.text.convert.Format;

/*******************************************************************************

        A bridge between a Format instance and a Buffer. This is used for
        the Stdout & Stderr globals, but can be used for general purpose
        buffer-formatting as desired. The Template type 'T' dictates the 
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32)

*******************************************************************************/

private class BufferedFormat(T)
{
        public alias print      opCall;

        private T[]             eol;
        private IBuffer         output;

        /**********************************************************************

                Construct a BufferedFormat instance, tying the provided
                buffer to a formatter

        **********************************************************************/

        this (IBuffer output, T[] eol = "\n")
        {
                this.output = output;
                this.eol = eol;
        }
                
        /**********************************************************************

                Format output using the provided formatting specification

        **********************************************************************/

        final BufferedFormat format (T[] fmt, ...)
        {
                Formatter.format (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Format output using the provided formatting specification
                and append a newline

        **********************************************************************/

        final BufferedFormat formatln (T[] fmt, ...)
        {
                Formatter.format (&sink, _arguments, _argptr, fmt);
                return newline();
        }

        /**********************************************************************

                Format output using a default layout

        **********************************************************************/

        final BufferedFormat print (...)        
        {
                static  T[][] fmt = 
                        [
                        "{0}",
                        "{0}, {1}",
                        "{0}, {1}, {2}",
                        "{0}, {1}, {2}, {3}",
                        "{0}, {1}, {2}, {3}, {4}",
                        "{0}, {1}, {2}, {3}, {4}, {5}",
                        "{0}, {1}, {2}, {3}, {4}, {5}, {6}",
                        "{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}",
                        "{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}",
                        "{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}",
                        ];

                int count = _arguments.length;
                assert (count < 10);

                // zero args is just a flush
                if (count is 0)
                    output.flush;
                else
                   Formatter.format (&sink, _arguments, _argptr, fmt[count-1]);

                return this;
        }

        /***********************************************************************
        
                output a newline

        ***********************************************************************/

        final BufferedFormat newline ()
        {
                output(eol).flush;
                return this;
        }

        /**********************************************************************

               Flush the output buffer

        **********************************************************************/

        final BufferedFormat flush ()
        {
                output.flush;
                return this;
        }      
        
        /**********************************************************************

                Return the associated buffer

        **********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }      

        /**********************************************************************

                Return the associated conduit

        **********************************************************************/

        final IConduit conduit ()
        {
                return output.getConduit;
        }      

        /**********************************************************************

                Sink for passing to the formatter

        **********************************************************************/

        private final uint sink (T[] s)
        {
                output (s);
                return s.length;
        }
}

/*******************************************************************************

        Standard, global formatters for console output. If you don't need
        formatted output or unicode translation, consider using the module
        tango.io.Console directly

        Note that both the buffer and conduit in use are exposed by these
        global instances ~ this can be leveraged, for instance, to copy a 
        file to the standard output:

        ---
        Stdout.conduit.copy (new FileConduit ("myfile"));
        ---

*******************************************************************************/

public static BufferedFormat!(char)     Stdout, 
                                        Stderr;

static this()
{
        Stdout = new BufferedFormat!(char) (Cout);
        Stderr = new BufferedFormat!(char) (Cerr);
}


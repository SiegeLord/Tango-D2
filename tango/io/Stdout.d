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

private import tango.text.convert.Format;

/*******************************************************************************

        A bridge between a Format instance and a Buffer. This is used for
        the Stdout & Stderr globals, but can be used for general-purpose
        buffer-formatting as desired. The Template type 'T' dictates the 
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32)

*******************************************************************************/

private class BufferedFormat
{
        public alias print      opCall;

        private IBuffer         target;
        private bool            autoFlush;

        /**********************************************************************

                Construct a BufferedFormat instance, tying the provided
                buffer to a formatter. Set option 'flush' to true if the
                result should be flushed after each output operation.

        **********************************************************************/

        this (IBuffer target, bool autoFlush = true)
        {
                this.target = target;
                this.autoFlush = autoFlush;
        }
                
        /**********************************************************************

        **********************************************************************/

        final BufferedFormat format (char[] fmt, ...)
        {
                Formatter.format (&sink, _arguments, _argptr, fmt);

                if (autoFlush)
                    target.flush;
                return this;
        }

        /**********************************************************************

        **********************************************************************/

        final BufferedFormat print (...)        
        {
                static  char[][] fmt = 
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
                    target.flush;
                else
                   {
                   Formatter.format (&sink, _arguments, _argptr, fmt[count-1]);
                   if (autoFlush)
                       target.flush;
                   }
                return this;
        }

        /***********************************************************************
        
                Emit a newline

        ***********************************************************************/

        final BufferedFormat newline ()
        {
                target.append ("\n");

                if (autoFlush)
                    target.flush;
                return this;
        }

        /**********************************************************************

                Render content -- flush the output buffer

        **********************************************************************/

        final BufferedFormat flush ()
        {
                target.flush;
                return this;
        }      
        
        /**********************************************************************

                return the associated buffer

        **********************************************************************/

        final IBuffer buffer ()
        {
                return target;
        }      

        /**********************************************************************

                return the associated conduit

        **********************************************************************/

        final IConduit conduit ()
        {
                return target.getConduit;
        }      

        /**********************************************************************

                Sink for passing to the formatter

        **********************************************************************/

        private final uint sink (char[] s)
        {
                target.append (s);
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

public static BufferedFormat Stdout, 
                             Stderr;

static this()
{
        Stdout = new BufferedFormat (Cout);
        Stderr = new BufferedFormat (Cerr);
}


/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial release

        author:         Kris

        Synchronized, formatted console output. This can be used in lieu
        of true logging where appropriate.

        Trace exposes this style of usage:
        ---
        Trace.format ("abc {}", 1);             => abc 1
        Trace.format ("abc {}:{}", 1, 2);       => abc 1:2
        Trace.format ("abc {1}:{0}", 1, 2);     => abc 2:1
        ---

        Special character sequences, such as "\n", are written directly to
        the output without any translation (though an output-filter could
        be inserted to perform translation as required). Platform-specific
        newlines are generated instead via the formatln() method, which also
        flushes the output when configured to do so:
        ---
        Trace.formatln ("hello {}", "world");
        ---

        Explicitly flushing the output is achieved via a flush() method
        ---
        Trace.format ("hello {}", "world").flush;
        ---

*******************************************************************************/

module tango.util.log.Trace;

private import tango.io.Console;

private import tango.io.model.IConduit;

private import tango.text.convert.Layout;

/*******************************************************************************

        Construct Trace when this module is loaded

*******************************************************************************/

/// global trace instance
public static SyncPrint Trace;

static this()
{
        Trace = new SyncPrint (Cerr.stream, !Cerr.redirected);
}

/*******************************************************************************

        Intended for internal use only

*******************************************************************************/

private class SyncPrint
{
        private Object          mutex;
        private OutputStream    output;
        private Layout!(char)   convert;
        private bool            flushLines;

        version (Win32)
                 private const char[] Eol = "\r\n";
             else
                private const char[] Eol = "\n";

        /**********************************************************************

                Construct a Print instance, tying the provided stream
                to a layout formatter

        **********************************************************************/

        this (OutputStream output, bool flush=false)
        {
                this.mutex = cast(Object) output;
                this.output = output;
                this.flushLines = flush;
                this.convert = Layout!(char).instance;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final SyncPrint format (char[] fmt, ...)
        {
                synchronized (mutex)
                              convert (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final SyncPrint formatln (char[] fmt, ...)
        {
                synchronized (mutex)
                             {
                             convert (&sink, _arguments, _argptr, fmt);
                             output.write (Eol);
                             if (flushLines)
                                 output.flush;
                             }
                return this;
        }

        /**********************************************************************

               Flush the output stream

        **********************************************************************/

        final void flush ()
        {
                synchronized (mutex)
                              output.flush;
        }

        /**********************************************************************

                Sink for passing to the formatter

        **********************************************************************/

        private final uint sink (char[] s)
        {
                return output.write (s);
        }

        /**********************************************************************

                Print a range of raw memory as a hex dump.
                Characters in range 0x20..0x7E are printed, all others are
                shown as dots.

                ----
000000:  47 49 46 38  39 61 10 00  10 00 80 00  00 48 5D 8C  GIF89a.......H].
000010:  FF FF FF 21  F9 04 01 00  00 01 00 2C  00 00 00 00  ...!.......,....
000020:  10 00 10 00  00 02 11 8C  8F A9 CB ED  0F A3 84 C0  ................
000030:  D4 70 A7 DE  BC FB 8F 14  00 3B                     .p.......;
                ----

        **********************************************************************/

        final SyncPrint memory (void[] mem)
        {
            auto data = cast(ubyte[]) mem;
            synchronized (mutex)
            {
                for( int row = 0; row < data.length; row += 16 )
                {
                    // print relative offset
                    convert.convert (&sink, "{:X6}:  ", row );

                    // print data bytes
                    for( int idx = 0; idx < 16 ; idx++ )
                    {
                        // print byte or stuffing spaces
                        if ( idx + row < data.length )
                            convert (&sink, "{:X2} ", data[ row + idx ] );
                        else
                            output.write ("   ");

                        // after each 4 bytes group an extra space
                        if (( idx & 0x03 ) == 3 )
                            output.write (" ");
                    }

                    // ascii view
                    // all char 0x20..0x7e are OK for printing,
                    // other values are printed as a dot
                    ubyte[16] ascii = void;
                    int asciiIdx;
                    for ( asciiIdx = 0;
                        (asciiIdx<16) && (asciiIdx+row < data.length);
                        asciiIdx++ )
                    {
                        ubyte c = data[ row + asciiIdx ];
                        if ( c < 0x20 || c > 0x7E )
                            c = '.';
                        ascii[asciiIdx] = c;
                    }
                    output.write (ascii[ 0 .. asciiIdx ]);
                    output.write (Eol);
                }
                if (flushLines)
                    output.flush;
            }
            return this;
        }
}

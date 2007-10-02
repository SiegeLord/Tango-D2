/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial release

        author:         Kris

        Synchronized, formatted console output. This can be used in lieu 
        of true logging where appropriate.

        Trace exposes this style of usage:
        ---
        Trace ("hello");                        => hello
        Trace (1);                              => 1
        Trace (3.14);                           => 3.14
        Trace ('b');                            => b
        Trace (1, 2, 3);                        => 1, 2, 3         
        Trace ("abc", 1, 2, 3);                 => abc, 1, 2, 3        
        Trace ("abc", 1, 2) ("foo");            => abc, 1, 2foo        
        Trace ("abc") ("def") (3.14);           => abcdef3.14

        Trace.format ("abc {}", 1);             => abc 1
        Trace.format ("abc {}:{}", 1, 2);       => abc 1:2
        Trace.format ("abc {1}:{0}", 1, 2);     => abc 2:1
        ---

        Flushing the output is achieved through the flush() method, or
        via an empty pair of parens: 
        ---
        Trace ("hello world") ();
        Trace ("hello world").flush;

        Trace.format ("hello {}", "world") ();
        Trace.format ("hello {}", "world").flush;
        ---
        
        Special character sequences, such as "\n", are written directly to
        the output without any translation (though an output-filter could
        be inserted to perform translation as required). Platform-specific 
        newlines are generated instead via the newline() method, which also 
        flushes the output when configured to do so:
        ---
        Trace ("hello world").newline;
        Trace.format ("hello {}", "world").newline;
        Trace.formatln ("hello {}", "world");
        ---

        The format() method of Trace supports the range
        of formatting options provided by tango.text.convert.Layout and
        extensions thereof; including the full I18N extensions where it
        has been configured in that manner. To enable a French Trace, 
        do the following:
        ---
        import tango.text.locale.Locale;

        Trace.layout = new Locale (Culture.getCulture ("fr-FR"));
        ---
        
        Note that Trace is a shared entity, so every usage of it will
        be affected by the above example. For applications supporting 
        multiple regions, create multiple Locale instances instead and 
        cache them in an appropriate manner

        Note also that the output stream in use is exposed by this global 
        instance ~ this can be leveraged, for instance, to copy a file to 
        the traced output:
        ---
        Trace.stream.copy (new FileConduit ("myfile"));
        ---

*******************************************************************************/

module tango.util.log.Trace;

private import  tango.io.Print,
                tango.io.Console;

private import  tango.text.convert.Layout;

private import  tango.io.filter.MutexFilter;

/*******************************************************************************

        Construct Trace when this module is loaded

*******************************************************************************/

static this()
{
        Trace = new Print!(char) (new Layout!(char), new MutexOutput(Cerr.stream));
        Trace.flush = !Cerr.redirected;
}

/// global trace instance
public static Print!(char) Trace;

/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2005: Initial release

        author:         Kris

        Standard, global formatters for console output. If you don't need
        formatted output or unicode translation, consider using the module
        tango.io.Console directly. If you need to format, but not output
        to console, consider tango.text.convert.Format instead.

        Stdout &amp; Stderr expose this style of usage:
        ---
        Stdout ("hello");                    // => hello
        Stdout (1);                          // => 1
        Stdout (3.14);                       // => 3.14
        Stdout ('b');                        // => b
        Stdout (1, 2, 3);                    // => 1, 2, 3
        Stdout ("abc", 1, 2, 3);             // => abc, 1, 2, 3
        Stdout ("abc", 1, 2) ("foo");        // => abc, 1, 2foo
        Stdout ("abc") ("def") (3.14);       // => abcdef3.14

        Stdout.format ("abc {}", 1);         // => abc 1
        Stdout.format ("abc {}:{}", 1, 2);   // => abc 1:2
        Stdout.format ("abc {1}:{0}", 1, 2); // => abc 2:1
        Stdout.format ("abc ", 1);           // => abc
        ---

        Note that the last example does not throw an exception. There
        are several use-cases where dropping an argument is legitimate,
        so we're currently not enforcing any particular trap mechanism.

        Flushing the output is achieved through the flush() method, or
        via an empty pair of parens:
        ---
        Stdout ("hello world") ();
        Stdout ("hello world").flush;

        Stdout.format ("hello {}", "world") ();
        Stdout.format ("hello {}", "world").flush;
        ---

        Special character sequences, such as "\n", are written directly to
        the output without any translation (though an output-filter could
        be inserted to perform translation as required). Platform-specific
        newlines are generated instead via the newline() method, which also
        flushes the output when configured to do so:
        ---
        Stdout ("hello ") ("world").newline;
        Stdout.format ("hello {}", "world").newline;
        Stdout.formatln ("hello {}", "world");
        ---

        The format() method of both Stderr and Stdout support the range
        of formatting options provided by tango.text.convert.Layout and
        extensions thereof; including the full I18N extensions where it
        has been configured in that manner. To enable a French Stdout,
        do the following:
        ---
        import tango.text.locale.Locale;

        Stdout.layout = new Locale (Culture.getCulture ("fr-FR"));
        ---

        Note that Stdout is a shared entity, so every usage of it will
        be affected by the above example. For applications supporting
        multiple regions, create multiple Locale instances instead and
        cache them in an appropriate manner.

        Stdout.layout can also be used for formatting without outputting
        to the console such as in the following example:
        ---
        char[] str = Stdout.layout.convert("{} and {}", 42, "abc");
        //str is "42 and abc"
        ---
        This can be useful if you already have Stdout imported.

        Note also that the output-stream in use is exposed by these
        global instances ~ this can be leveraged, for instance, to copy a
        file to the standard output:
        ---
        Stdout.copy (new File ("myfile"));
        ---

        Note that Stdout is *not* intended to be thread-safe. Use either
        tango.util.log.Trace or the standard logging facilities in order
        to enable atomic console I/O.

*******************************************************************************/

module tango.io.Stdout;

private import tango.io.Console;

private import tango.io.stream.Format;

private import tango.text.convert.Layout;

/*******************************************************************************

        Construct Stdout &amp; Stderr when this module is loaded

*******************************************************************************/

private alias FormatOutput!(char) Output;

public static __gshared Output Stdout; /// global standard output
public static __gshared Output Stderr; /// global error output
public alias Stdout            stdout; /// alternative
public alias Stderr            stderr; /// alternative

shared static this ()
{
        // note that a static-ctor inside Layout fails
        // to be invoked before this is executed (bug)
        auto layout = Layout!(char).instance;

        Stdout = new Output (layout, Cout.stream);
        Stderr = new Output (layout, Cerr.stream);

        Stdout.flush = !Cout.redirected;
        Stderr.flush = !Cerr.redirected;
}


/******************************************************************************

******************************************************************************/

debug (Stdout)
{
        void main()
        {
        Stdout ("hello").newline;
        Stdout (1).newline;
        Stdout (3.14).newline;
        Stdout ('b').newline;
        Stdout ("abc") ("def") (3.14).newline;
        Stdout ("abc", 1, 2, 3).newline;
        Stdout (1, 2, 3).newline;
        Stdout (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1).newline;

        Stdout ("abc {}{}{}", 1, 2, 3).newline;
        Stdout.format ("abc {}{}{}", 1, 2, 3).newline;
        }
}

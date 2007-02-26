/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2005: Initial release

        author:         Kris

*******************************************************************************/

module tango.io.Stdout;

public  import  tango.io.TextFormat;

private import  tango.io.Console;

private import  tango.text.convert.Layout;

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

        Stdout exposes this style of usage:
        ---
        Stdout ("hello");               => hello
        Stdout (1);                     => 1
        Stdout (3.14);                  => 3.14
        Stdout ('b');                   => b
        Stdout (1, 2, 3);               => 1, 2, 3         
        Stdout ("abc", 1, 2, 3);        => abc, 1, 2, 3        
        Stdout ("abc", 1, 2) ("foo");   => abc, 1, 2foo        
        Stdout ("abc") ("def") (3.14);  => abcdef3.14

        Stdout.format ("abc {}", 1);    => abc 1
        Stdout.format ("abc ", 1);      => abc
        ---

        Note that the last example does not throw an exception. There
        are several use-cases where dropping an argument is legitimate,
        so we're currently not enforcing any particular trap mechanism.

        Flushing the output is achieved through the flush() method, or
        via an empty pair of parens: 
        ---
        Stdout ("hello world") ();
        Stdout ("hello world").flush;

        Stdout ("hello ") ("world") ();
        Stdout ("hello ") ("world").flush;

        Stdout.format ("hello {}", "world") ();
        Stdout.format ("hello {}", "world").flush;
        ---
        
        Newline is handled by either placing '\n' in the output, or via
        the newline() method. The latter also flushes the output:
        ---
        Stdout ("hello ") ("world").newline;

        Stdout.format ("hello {}", "world").newline;
        ---

*******************************************************************************/

public static TextFormat!(char) Stdout,
                                Stderr;

static this()
{
        auto layout = new Layout!(char);

        Stdout = new TextFormat!(char) (layout, Cout.buffer);
        Stderr = new TextFormat!(char) (layout, Cerr.buffer);
}


/******************************************************************************

******************************************************************************/

debug (Test)
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

        Stdout ("abc {}{}{}", 1, 2, 3).newline; 
        Stdout.format ("abc {}{}{}", 1, 2, 3).newline; 
        }
}

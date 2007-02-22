/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2005: Initial release
        version:        Feb 2007: Moved sprint() here due to technical issues
                
        author:         Kris

*******************************************************************************/

module tango.io.Stdout;

private import  tango.io.Console;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.text.convert.Format;

/*******************************************************************************

        Platform issues ...
        
*******************************************************************************/

version (DigitalMars)
         alias void* Args;
   else 
      alias char* Args;

/*******************************************************************************

        A bridge between a Format instance and a Buffer. This is used for
        the Stdout & Stderr globals, but can be used for general purpose
        buffer-formatting as desired. The Template type 'T' dictates the
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32). 
        
        When wrapped by Stdout, TextFormat exposes this style of usage:
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

class TextFormat(T)
{
        private T[]             eol;
        private IBuffer         output;
        private Format!(T)      convert;

        public alias print      opCall;

        version (Win32)
                 private const char[] Eol = "\r\n";
             else
                private const char[] Eol = "\n";

        /**********************************************************************

                Construct a TextFormat instance, tying the provided
                buffer to a formatter

        **********************************************************************/

        this (Format!(T) convert, IBuffer output, T[] eol = Eol)
        {
                this.convert = convert;
                this.output = output;
                this.eol = eol;
        }

        /**********************************************************************

                Format output using the provided formatting specification

        **********************************************************************/

        final TextFormat format (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Format output using the provided formatting specification

        **********************************************************************/

        final TextFormat formatln (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return newline;
        }

        /**********************************************************************

                Format output using the provided formatting specification

        **********************************************************************/

        final TextFormat print (...)
        {
                static  T[][] fmt =
                        [
                        "{}",
                        "{}, {}",
                        "{}, {}, {}",
                        "{}, {}, {}, {}",
                        "{}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}",
                        "{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}",
                        ];
               
                if (_arguments.length is 0)
                    output.flush;
                else
                   convert (&sink, _arguments, _argptr, fmt[_arguments.length - 1]);
                         
                return this;
        }

        /**********************************************************************

                Format a set of arguments into the provided output buffer
                and return a valid slice
                
        **********************************************************************/

        final T[] sprint (T[] buffer, T[] fmt, ...)
        {
                return convert.sprint (buffer, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                output a newline and flush

        ***********************************************************************/

        final TextFormat newline ()
        {
                output(eol).flush;
                return this;
        }

        /**********************************************************************

               Flush the output buffer

        **********************************************************************/

        final TextFormat flush ()
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
                return output.conduit;
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

public static TextFormat!(char) Stdout,
                                Stderr;

static this()
{
        auto Formatter = new Format!(char);
        Stdout = new TextFormat!(char) (Formatter, Cout.buffer);
        Stderr = new TextFormat!(char) (Formatter, Cerr.buffer);
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

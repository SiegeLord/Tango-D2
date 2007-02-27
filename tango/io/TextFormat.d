/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: layout() provides a gateway to sprint() 
                
        author:         Kris

*******************************************************************************/

module tango.io.TextFormat;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.text.convert.Layout;

/*******************************************************************************

        Platform issues ...
        
*******************************************************************************/

version (DigitalMars)
         alias void* Args;
   else 
      alias char* Args;

/*******************************************************************************

        A bridge between a Layout instance and a Buffer. This is used for
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

        The format() method supports the range of formatting options 
        exposed by tango.text.convert.Layout and extensions thereof; 
        including the full I18N extensions where configured in that 
        manner. To create a French TextFormat:
        ---
        import tango.text.locale.Locale;

        auto locale = new Locale (Culture.getCulture ("fr-FR"));
        auto format = new TextFormat (locale, ...);
        ---
        
*******************************************************************************/

class TextFormat(T)
{
        private T[]             eol;
        private IBuffer         output;
        private Layout!(T)      convert;

        public alias print      opCall;

        version (Win32)
                 private const T[] Eol = "\r\n";
             else
                private const T[] Eol = "\n";

        /**********************************************************************

                Construct a TextFormat instance, tying the provided
                buffer to a formatter

        **********************************************************************/

        this (Layout!(T) convert, IBuffer output, T[] eol = Eol)
        {
                this.convert = convert;
                this.output = output;
                this.eol = eol;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final TextFormat format (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final TextFormat formatln (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return newline;
        }

        /**********************************************************************

                Unformatted layout, with commas inserted between args

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
               
                assert (_arguments.length <= fmt.length);

                if (_arguments.length is 0)
                    output.flush;
                else
                   convert (&sink, _arguments, _argptr, fmt[_arguments.length - 1]);
                         
                return this;
        }

        /***********************************************************************

                Output a newline and flush

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

                Return the associated Layout

        **********************************************************************/

        final Layout!(T) layout ()
        {
                return convert;
        }

        /**********************************************************************

                Set the associated Layout

        **********************************************************************/

        final TextFormat layout (Layout!(T) layout)
        {
                convert = layout;
                return this;
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

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

*******************************************************************************/

module tango.io.Stdout;

private import  tango.io.Console;

private import  tango.convert.Format,
                tango.convert.Double;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.io.support.BufferCodec;

/*******************************************************************************

        A bridge between a Format instance and a Buffer. This is used for
        the Stdout & Stderr globals, but can be used for general-purpose
        buffer-formatting as desired. The Template type 'T' dictates the 
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32)

*******************************************************************************/

private class BufferFormatT(T)
{
        private alias FormatStructT!(T) Format;
        public  alias print             opCall;

        private T[128]                  tmp;
        private bool                    flush;
        private IBuffer                 target;
        private Importer                importer;
        private Format                  formatter;

        /**********************************************************************

                Construct a BufferFormat instance, tying the provided
                buffer to a formatter. Set option 'flush' to true if
                the result should be flushed when complete.

        **********************************************************************/

        this (IBuffer target, bool flush = true)
        {
                // configure the formatter
                formatter.ctor (&write, tmp, &Double.format);

                // hook up a unicode converter
                importer = new UnicodeImporter!(T)(target);

                // save buffer and tail references
                this.target = target;
                this.flush = flush;
        }
                
        /**********************************************************************

        **********************************************************************/

        BufferFormatT print (T[] fmt, ...)
        {
                formatter.print (fmt, _arguments, _argptr);
                return render();
        }

        /**********************************************************************

        **********************************************************************/

        BufferFormatT print (bool v)
        {
                return print ("%s", v);
        }

        /**********************************************************************

        **********************************************************************/

        BufferFormatT print (long v)
        {
                return print ("%s", v);
        }

        /**********************************************************************

        **********************************************************************/

        BufferFormatT print (Object v)
        {
                return print ("%s", v);
        }

        /***********************************************************************
        
                Emit a newline

        ***********************************************************************/

        BufferFormatT newline ()
        {
                formatter.newline;
                return render();
        }

        /**********************************************************************

                return the associated buffer

        **********************************************************************/

        IBuffer buffer ()
        {
                return target;
        }      

        /**********************************************************************

                return the associated conduit

        **********************************************************************/

        IConduit conduit ()
        {
                return target.getConduit;
        }      

        /**********************************************************************

                Callback from the Format instance to write an array

        **********************************************************************/

        private uint write (void[] x, uint type)
        {
                return importer (x, x.length, type);
        }      

        /**********************************************************************

                Render content -- flush the output buffer

        **********************************************************************/

        private BufferFormatT render ()
        {
                if (flush)
                    target.flush;
                return this;
        }      
}

// convenience alias
alias BufferFormatT!(char) BufferFormat;


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

public static BufferFormat Stdout, 
                           Stderr;

static this()
{
        Stdout = new BufferFormat (Cerr);
        Stderr = new BufferFormat (Cout);
}


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        version:        Rewritten to support format tags; March 2005
       
        author:         Kris

*******************************************************************************/

module tango.io.protocol.DisplayWriter;

private import  tango.core.Vararg;

private import  tango.convert.Type,
                tango.convert.Format,
                tango.convert.Double;

public  import  tango.io.protocol.Writer;

/*******************************************************************************

        Format output suitable for presentation. DisplayWriter provide 
        the means to append formatted  data to an IBuffer, and exposes 
        a convenient method of handling a variety of data types. 
        
        DisplayWriter supports the usual printf() format specifiers & flags, 
        and extends the notion to operate with one dimensional arrays. For
        instance, this code

        ---
        static int x = [1, 2, 3, 4, 5, 6, 7, 8];

        Stdout.print ("%@04b, ", x);
        ---

        results in the following output: 

        ---
        0001, 0010, 0011, 0100, 0101, 0110, 0111, 1000,
        ---

        Note that DisplayWriter itself is a wrapper around the tango.convert 
        package, which can be used directly as desired (Integer, Double, 
        DGDouble, etc). The latter classes are home to a set of static 
        formatting-methods, making them convenient for ad-hoc application.

        tango.convert also has Format and Sprint classes for working directly
        with text arrays.
         
*******************************************************************************/

class DisplayWriter : Writer
{
        alias FormatStructT!(char) Format;

        private Format          format;
        private char[128]       workspace;

        /***********************************************************************
        
                Construct a DisplayWriter upon the specified IBuffer. 
                One can override the default floating-point formatting
                by providing an appropriate handler to this constructor.
                For example, one might configure the DGDouble.format()
                function instead.

        ***********************************************************************/

        this (IBuffer buffer, char[] workspace = null, Format.DblFormat df = &Double.format)
        {
                super (buffer);
                
                if (workspace is null)
                    workspace = this.workspace;

                // configure output-handler, workspace, and the
                // floating-point converter
                format.ctor (&emit, workspace, df);
        }
     
        /***********************************************************************
        
                Construct a DisplayWriter upon the specified IConduit

        ***********************************************************************/

        this (IConduit conduit)
        {
                super (conduit);

                // configure formatter
                format.ctor (&emit, workspace, &Double.format);
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.convert.Format for details

        ***********************************************************************/

        int print (char[] s, TypeInfo[] ti, va_list args)
        {       
                return format (s, ti, args);
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.convert.Format for details

        ***********************************************************************/

        DisplayWriter print (char[] s, ...)
        {       
                print (s, _arguments, _argptr);
                return this;
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.convert.Format for details

        ***********************************************************************/

        DisplayWriter println (char[] s, ...)
        {       
                print (s, _arguments, _argptr);
                put (CR);
                return this;
        }

        /***********************************************************************
        
                Is this Writer text oriented?

        ***********************************************************************/

        bool isTextBased()
        {
                return true;
        }

        /***********************************************************************
        
                Intercept discrete output and convert it to printable form

        ***********************************************************************/

        protected override IWriter write (void* src, uint bytes, int type)
        {
                format.emit (src, bytes, type);
                return this;
        }

        /***********************************************************************
        
                formatting handler

        ***********************************************************************/

        private uint emit (void[] x, uint type)
        {
                encode (x, x.length, type);
                return x.length;
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        version:        Rewritten to support format tags; March 2005
       
        author:         Kris

*******************************************************************************/

module tango.io.protocol.DisplayWriter;

private import  tango.core.Vararg;

private import  tango.text.convert.Type,
                tango.text.convert.Format;

public  import  tango.io.protocol.Writer;

/*******************************************************************************

        Format output suitable for presentation. DisplayWriter provide 
        the means to append formatted  data to an IBuffer, and exposes 
        a convenient method of handling a variety of data types. 
        
        The DisplayWriter itself is a wrapper around the tango.text.convert 
        package, which should be used directly as desired (Integer, Double, 
        DGDouble, etc). The latter modules are home to a set of static 
        formatting-methods, making them convenient for ad-hoc application.

        Tango.text.convert also has Format and Sprint modules for working 
        directly with text arrays.
         
*******************************************************************************/

class DisplayWriter : Writer
{
        /***********************************************************************
        
                Construct a DisplayWriter upon the specified IBuffer. 
                One can override the default floating-point formatting
                by providing an appropriate handler to this constructor.
                For example, one might configure the DGDouble.format()
                function instead.

        ***********************************************************************/

        this (IBuffer buffer)
        {
                super (buffer);
        }
     
        /***********************************************************************
        
                Construct a DisplayWriter upon the specified IConduit

        ***********************************************************************/

        this (IConduit conduit)
        {
                super (conduit);
        }

        /***********************************************************************
        
                Is this Writer text oriented?

        ***********************************************************************/

        bool isTextBased()
        {
                return true;
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.text.convert.Format for details

        ***********************************************************************/

        DisplayWriter format (char[] s, ...)
        {       
                format (s, _arguments, cast(va_list) _argptr);
                return this;
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.text.convert.Format for details.

        ***********************************************************************/
        DisplayWriter formatln (char[] s, ...)
        {
                format (s, _arguments, cast(va_list) _argptr);
                newline;
                return this;
        }

        /***********************************************************************
        
                Format a set of arguments a la printf(). Please see module
                tango.text.convert.Format for details

        ***********************************************************************/

        protected int format (char[] s, TypeInfo[] ti, va_list args)
        {       
                uint sink (char[] s)
                {
                        encode (s.ptr, s.length, Type.Utf8);
                        return s.length;
                }

                return Formatter (&sink, ti, args, s);
        }

        /***********************************************************************
        
                Intercept discrete output and convert it to printable form

        ***********************************************************************/

        protected override IWriter write (void* src, uint bytes, int type)
        {
                switch (type)
                       {
                       case Type.Utf8:
                       case Type.Utf16:
                       case Type.Utf32:
                            encode (src, bytes, type);
                            break;

                       default:
                            char[256] output = void;
                            char[256] convert = void;
                            auto ti = Type.revert [type];
                            auto result = Formatter.Result (output, convert);

                            auto width = ti.tsize();
                            assert ((bytes % width) is 0, "invalid arg[] length");

                            bool array = width < bytes;

                            if (array)
                                encode ("[".ptr, 1, Type.Utf8);

                            while (bytes)
                                  {
                                  auto s = Formatter (result, ti, src);
                                  encode (s.ptr, s.length, Type.Utf8);

                                  bytes -= width;
                                  src += width;

                                  if (bytes > 0)
                                      encode (", ".ptr, 2, Type.Utf8);
                                  }

                            if (array)
                                encode ("]".ptr, 1, Type.Utf8);
                            break;
                       }
                return this;
        }
}

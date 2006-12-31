/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        version:        Rewritten to support alternate formatter; July 2006
                        Outback release: December 2006
       
        author:         Kris

*******************************************************************************/

module tango.io.protocol.DisplayWriter;

private import  tango.core.Vararg;

private import  tango.text.convert.Type,
                tango.text.convert.Format;

private import  tango.io.protocol.Writer;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

public  import  tango.io.protocol.model.IWriter;

/*******************************************************************************

        Format output suitable for presentation. DisplayWriter provides 
        a means to append formatted data to an IBuffer, and exposes 
        a convenient method of handling a variety of data types. 
        
        The DisplayWriter itself is a wrapper around the tango.text.convert 
        package, which should be used directly as desired (Integer, Float, 
        etc). The latter modules are home to a set of formatting-methods,
        making them convenient for ad-hoc application.

        Tango.text.convert also has a Sprint module for working more directly
        with text arrays.
         
*******************************************************************************/

class DisplayWriter : Writer
{
        /***********************************************************************
        
                Construct a DisplayWriter upon the specified IBuffer. 

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
        
                Format a set of arguments. Please see module
                tango.text.convert.Format for details

        ***********************************************************************/

        DisplayWriter format (char[] s, ...)
        {       
                format (s, _arguments, cast(va_list) _argptr);
                return this;
        }

        /***********************************************************************
        
                Format a set of arguments. Please see module
                tango.text.convert.Format for details.

        ***********************************************************************/

        DisplayWriter formatln (char[] s, ...)
        {
                format (s, _arguments, cast(va_list) _argptr);
                newline;
                return this;
        }

        /***********************************************************************
        
                Format a set of arguments. Please see module
                tango.text.convert.Format for details

        ***********************************************************************/

        protected int format (char[] s, TypeInfo[] ti, va_list args)
        {       
                uint sink (char[] s)
                {
                        write (s.ptr, s.length, Type.Utf8);
                        return s.length;
                }

                return Formatter (&sink, ti, args, s);
        }

        /***********************************************************************
        
                Intercept array writing, to supress the output of array
                lengths

        ***********************************************************************/

        protected override IWriter writeArray (void* src, uint elements, uint bytes, uint type)
        {
                return write (src, bytes, type);
        }
        
        /***********************************************************************
        
                Intercept discrete output and convert it to printable form

        ***********************************************************************/

        protected override IWriter write (void* src, uint bytes, uint type)
        {
                switch (type)
                       {
                       case Type.Utf8:
                       case Type.Utf16:
                       case Type.Utf32:
                            super.write (src, bytes, type);
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
                                write ("[".ptr, 1, Type.Utf8);

                            while (bytes)
                                  {
                                  auto s = Formatter (result, ti, src);
                                  write (s.ptr, s.length, Type.Utf8);

                                  bytes -= width;
                                  src += width;

                                  if (bytes > 0)
                                      write (", ".ptr, 2, Type.Utf8);
                                  }

                            if (array)
                                write ("]".ptr, 1, Type.Utf8);
                            break;
                       }
                return this;
        }
}

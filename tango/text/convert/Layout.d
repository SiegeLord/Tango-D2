/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         Kris

        This module provides a general-purpose formatting system to
        convert values to text suitable for display. There is support
        for alignment, justification, and common format specifiers for
        numbers.

        Layout can be customized via configuring various handlers and
        associated meta-date. This is utilized to plug in text.locale
        for handling custom formats, date/time and culture-specific
        conversions.

        The format notation is influenced by that used by the .NET
        and ICU frameworks, rather than C-style printf or D-style
        writef notation.

******************************************************************************/

module tango.text.convert.Layout;

private import  tango.core.Exception;

private import  Unicode = tango.text.convert.Utf;

private import  Float   = tango.text.convert.Float,
                Integer = tango.text.convert.Integer;

/*******************************************************************************

        Platform issues ...

*******************************************************************************/

version (DigitalMars)
         alias void* Arg;
   else
      alias char* Arg;

/*******************************************************************************

        Contains methods for replacing format items in a string with string
        equivalents of each argument.

*******************************************************************************/

class Layout(T)
{
        public alias convert opCall;
        public alias uint delegate (T[]) Sink;

        /**********************************************************************

        **********************************************************************/

        public final T[] sprint (T[] result, T[] formatStr, ...)
        {
                return sprint (result, formatStr, _arguments, _argptr);
        }

        /**********************************************************************

        **********************************************************************/

        public final T[] sprint (T[] result, T[] formatStr, TypeInfo[] arguments, Arg args)
        {
                T* p = result.ptr;

                uint sink (T[] s)
                {
                        int len = s.length;
                        if (len < (result.ptr + result.length) - p)
                           {
                           p [0..len] = s;
                           p += len;
                           }
                        else
                           error ("Layout.sprint :: output buffer is full");
                        return len;
                }

                convert (&sink, arguments, args, formatStr);
                return result [0 .. p-result.ptr];
        }

        /**********************************************************************

                Replaces the _format item in a string with the string
                equivalent of each argument.

                Params:
                  formatStr  = A string containing _format items.
                  args       = A list of arguments.

                Returns: A copy of formatStr in which the items have been
                replaced by the string equivalent of the arguments.

                Remarks: The formatStr parameter is embedded with _format
                items of the form: $(BR)$(BR)
                  {index[,alignment][:_format-string]}$(BR)$(BR)
                  $(UL $(LI index $(BR)
                    An integer indicating the element in a list to _format.)
                  $(LI alignment $(BR)
                    An optional integer indicating the minimum width. The
                    result is padded with spaces if the length of the value
                    is less than alignment.)
                  $(LI _format-string $(BR)
                    An optional string of formatting codes.)
                )$(BR)

                The leading and trailing braces are required. To include a
                literal brace character, use two leading or trailing brace
                characters.$(BR)$(BR)
                If formatStr is "{0} bottles of beer on the wall" and the
                argument is an int with the value of 99, the return value
                will be:$(BR) "99 bottles of beer on the wall".

        **********************************************************************/

        public final T[] convert (T[] formatStr, ...)
        {
                return convert (_arguments, _argptr, formatStr);
        }

        /**********************************************************************

        **********************************************************************/

        public final uint convert (Sink sink, T[] formatStr, ...)
        {
                return convert (sink, _arguments, _argptr, formatStr);
        }

        /**********************************************************************

        **********************************************************************/

        public final T[] convert (TypeInfo[] arguments, Arg args, T[] formatStr)
        {
                T[] output;

                uint sink (T[] s)
                {
                        output ~= s;
                        return s.length;
                }

                convert (&sink, arguments, args, formatStr);
                return output;
        }

        /**********************************************************************

        **********************************************************************/

        public final T[] convertOne (T[] result, TypeInfo ti, Arg arg)
        {
                return munge (result, null, ti, arg);
        }

        /**********************************************************************

        **********************************************************************/

        public final uint convert (Sink sink, TypeInfo[] arguments, Arg args, T[] formatStr)
        {
                assert (formatStr, "null format specifier");
                assert (arguments.length < 64, "too many args in Layout.convert");

                Arg[64] arglist = void;
                foreach (i, arg; arguments)
                        {
                        arglist[i] = args;
                        args += (arg.tsize + int.sizeof - 1) & ~ (int.sizeof - 1);
                        }

                return parse (formatStr, arguments, arglist, sink);
        }

        /**********************************************************************

                Parse the format-string, emitting formatted args and text
                fragments as we go.

        **********************************************************************/

        private uint parse (T[] layout, TypeInfo[] ti, Arg[] args, Sink sink)
        {
                T[384] result = void;
                int length, nextIndex;


                T* s = layout.ptr;
                T* fragment = s;
                T* end = s + layout.length;

                while (true)
                      {
                      while (s < end && *s != '{')
                             ++s;

                      // emit fragment
                      length += sink (fragment [0 .. s - fragment]);

                      // all done?
                      if (s is end)
                          break;

                      // check for "{{" and skip if so
                      if (*++s is '{')
                         {
                         fragment = s++;
                         continue;
                         }

                      int index = 0;
                      bool indexed = false;

                      // extract index
                      while (*s >= '0' && *s <= '9')
                            {
                            index = index * 10 + *s++ -'0';
                            indexed = true;
                            }

                      // skip spaces
                      while (s < end && *s is ' ')
                             ++s;

                      int  width;
                      bool leftAlign;

                      // has width?
                      if (*s is ',')
                         {
                         while (++s < end && *s is ' ') {}

                         if (*s is '-')
                            {
                            leftAlign = true;
                            ++s;
                            }

                         // get width
                         while (*s >= '0' && *s <= '9')
                                width = width * 10 + *s++ -'0';

                         // skip spaces
                         while (s < end && *s is ' ')
                                ++s;
                         }

                      T[] format;

                      // has a format string?
                      if (*s is ':' && s < end)
                         {
                         T* fs = ++s;

                         // eat everything up to closing brace
                         while (s < end && *s != '}')
                                ++s;
                         format = fs [0 .. s - fs];
                         }

                      // insist on a closing brace
                      if (*s != '}')
                         {
                         length += sink ("{missing or misplaced '}'}");
                         continue;
                         }

                      // check for default index & set next default counter
                      if (! indexed)
                            index = nextIndex;
                      nextIndex = index + 1;

                      // next char is start of following fragment
                      fragment = ++s;

                      // convert argument to a string
                      T[] str = (index < ti.length
                                 ? munge (result, format, ti[index], args[index])
                                 : "{invalid index}");
                      int padding = width - str.length;

                      // if not left aligned, pad out with spaces
                      if (! leftAlign && padding > 0)
                            length += spaces (sink, padding);

                      // emit formatted argument
                      length += sink (str);

                      // finally, pad out on right
                      if (leftAlign && padding > 0)
                          length += spaces (sink, padding);
                      }

                return length;
        }

        /**********************************************************************

        **********************************************************************/

        private void error (char[] msg)
        {
                throw new IllegalArgumentException (msg);
        }

        /**********************************************************************

        **********************************************************************/

        private uint spaces (Sink sink, int count)
        {
                uint ret;

                static const T[32] Spaces = ' ';
                while (count > Spaces.length)
                      {
                      ret += sink (Spaces);
                      count -= Spaces.length;
                      }
                return ret + sink (Spaces[0..count]);
        }

        /***********************************************************************

        ***********************************************************************/

        private T[] munge (T[] result, T[] format, TypeInfo type, Arg p)
        {
                switch (type.classinfo.name[9])
                       {
                       case TypeCode.ARRAY:
                            if (type is typeid(char[]))
                                return fromUtf8 (*cast(char[]*) p, result);

                            if (type is typeid(wchar[]))
                                return fromUtf16 (*cast(wchar[]*) p, result);

                            if (type is typeid(dchar[]))
                                return fromUtf32 (*cast(dchar[]*) p, result);

                            // Currently we only format d/w/char[] arrays.
                            return fromUtf8 (type.toUtf8, result);

                       case TypeCode.BOOL:
                            static T[] t = "true";
                            static T[] f = "false";
                            return (*cast(bool*) p) ? t : f;

                       case TypeCode.BYTE:
                            return integer (result, *cast(byte*) p, format);

                       case TypeCode.UBYTE:
                            return integer (result, *cast(ubyte*) p, format, 'u');

                       case TypeCode.SHORT:
                            return integer (result, *cast(short*) p, format);

                       case TypeCode.USHORT:
                            return integer (result, *cast(ushort*) p, format, 'u');

                       case TypeCode.INT:
                            return integer (result, *cast(int*) p, format);

                       case TypeCode.UINT:
                       case TypeCode.POINTER:
                            return integer (result, *cast(uint*) p, format, 'u');

                       case TypeCode.LONG:
                       case TypeCode.ULONG:
                            return integer (result, *cast(long*) p, format);

                       case TypeCode.FLOAT:
                            return floater (result, *cast(float*) p, format);

                       case TypeCode.DOUBLE:
                            return floater (result, *cast(double*) p, format);

                       case TypeCode.REAL:
                            return floater (result, *cast(real*) p, format);

                       case TypeCode.CHAR:
                            return fromUtf8 ((cast(char*) p)[0..1], result);

                       case TypeCode.WCHAR:
                            return fromUtf16 ((cast(wchar*) p)[0..1], result);

                       case TypeCode.DCHAR:
                            return fromUtf32 ((cast(dchar*) p)[0..1], result);

                       case TypeCode.INTERFACE:
                            Interface* pi = **cast(Interface ***)*cast(void**) p;
                            Object o = cast(Object)(*cast(void**)p - pi.offset);
                            return fromUtf8 (o.toUtf8, result);
                            
                       case TypeCode.CLASS:
                            return fromUtf8 ((*cast(Object*) p).toUtf8, result);

                       case TypeCode.ENUM:
                            return munge (result, format, (cast(TypeInfo_Enum) type).base, p);

                       case TypeCode.TYPEDEF:
                            return munge (result, format, (cast(TypeInfo_Typedef) type).base, p);

                       default:
                            return unknown (result, format, type, p);
                       }

                return null;
        }

        /**********************************************************************

        **********************************************************************/

        protected T[] unknown (T[] result, T[] format, TypeInfo type, Arg p)
        {
                return "{unhandled argument type: " ~ fromUtf8 (type.toUtf8, result) ~ "}";
        }

        /**********************************************************************

        **********************************************************************/

        protected T[] integer (T[] output, long v, T[] alt, T format = 'd')
        {
                uint width;
                auto style = cast(Integer.Style) parse2 (alt, width, format);

                Integer.Flags flags;
                if (width)
                   {
                   output = output [0 .. width];
                   flags = flags.Zero;
                   }

                return Integer.format (output, v, style, flags);
        }

        /**********************************************************************

        **********************************************************************/

        protected T[] floater (T[] output, real v, T[] format)
        {
                uint places;
                bool scientific;

                if (parse2(format, places) is 'e')
                    scientific = true;

                if (places is 0)
                    places = 2;

                return Float.format (output, v, places, scientific);
        }

        /**********************************************************************

        **********************************************************************/

        private T parse2 (T[] format, inout uint width, T def=T.init)
        {
                uint number;
                foreach (c; format)
                         if (c >= '0' && c <= '9')
                             number = number * 10 + c - '0';

                width = number;
                return format.length > 0 ? format[0] : def;
        }

        /***********************************************************************

        ***********************************************************************/

        private static T[] fromUtf8 (char[] s, T[] scratch)
        {
                static if (is (T == char))
                           return s;

                static if (is (T == wchar))
                           return Unicode.toUtf16 (s, scratch);

                static if (is (T == dchar))
                           return Unicode.toUtf32 (s, scratch);
        }

        /***********************************************************************

        ***********************************************************************/

        private static T[] fromUtf16 (wchar[] s, T[] scratch)
        {
                static if (is (T == wchar))
                           return s;

                static if (is (T == char))
                           return Unicode.toUtf8 (s, scratch);

                static if (is (T == dchar))
                           return Unicode.toUtf32 (s, scratch);
        }

        /***********************************************************************

        ***********************************************************************/

        private static T[] fromUtf32 (dchar[] s, T[] scratch)
        {
                static if (is (T == dchar))
                           return s;

                static if (is (T == char))
                           return Unicode.toUtf8 (s, scratch);

                static if (is (T == wchar))
                           return Unicode.toUtf16 (s, scratch);
        }
}


/*******************************************************************************

*******************************************************************************/

private enum TypeCode
{
        EMPTY = 0,
        BOOL = 'b',
        UBYTE = 'h',
        BYTE = 'g',
        USHORT = 't',
        SHORT = 's',
        UINT = 'k',
        INT = 'i',
        ULONG = 'm',
        LONG = 'l',
        REAL = 'e',
        FLOAT = 'f',
        DOUBLE = 'd',
        CHAR = 'a',
        WCHAR = 'u',
        DCHAR = 'w',
        ARRAY = 'A',
        CLASS = 'C',
        STRUCT = 'S',
        ENUM = 'E',
        POINTER = 'P',
        TYPEDEF = 'T',
        INTERFACE = 'I',
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        //void main() {}

        unittest
        {
        auto Formatter = new Layout!(char);

        assert( Formatter( "abc" ) == "abc" );
        assert( Formatter( "{0}", 1 ) == "1" );
        assert( Formatter( "{0}", -1 ) == "-1" );

        assert( Formatter( "{}", 1 ) == "1" );
        assert( Formatter( "{} {}", 1, 2) == "1 2" );
        assert( Formatter( "{} {0} {}", 1, 3) == "1 1 3" );
        assert( Formatter( "{} {0} {} {}", 1, 3) == "1 1 3 {invalid index}" );
        assert( Formatter( "{} {0} {} {:x}", 1, 3) == "1 1 3 {invalid index}" );

        assert( Formatter( "{0}", true ) == "true" , Formatter( "{0}", true ));
        assert( Formatter( "{0}", false ) == "false" );

        assert( Formatter( "{0}", cast(byte)-128 ) == "-128" );
        assert( Formatter( "{0}", cast(byte)127 ) == "127" );
        assert( Formatter( "{0}", cast(ubyte)255 ) == "255" );

        assert( Formatter( "{0}", cast(short)-32768  ) == "-32768" );
        assert( Formatter( "{0}", cast(short)32767 ) == "32767" );
        assert( Formatter( "{0}", cast(ushort)65535 ) == "65535" );
        // assert( Formatter( "{0:x4}", cast(ushort)0xafe ) == "0afe" );
        // assert( Formatter( "{0:X4}", cast(ushort)0xafe ) == "0AFE" );

        assert( Formatter( "{0}", -2147483648 ) == "-2147483648" );
        assert( Formatter( "{0}", 2147483647 ) == "2147483647" );
        assert( Formatter( "{0}", 4294967295 ) == "4294967295" );
        // compiler error
        //assert( Formatter( "{0}", -9223372036854775808L) == "-9223372036854775808" );
        assert( Formatter( "{0}", 0x8000_0000_0000_0000L) == "-9223372036854775808" );
        assert( Formatter( "{0}", 9223372036854775807L ) == "9223372036854775807" );
        // Error: prints -1
        // assert( Formatter( "{0}", 18446744073709551615UL ) == "18446744073709551615" );

        assert( Formatter( "{0}", "s" ) == "s" );
        // fragments before and after
        assert( Formatter( "d{0}d", "s" ) == "dsd" );
        assert( Formatter( "d{0}d", "1234567890" ) == "d1234567890d" );

        // brace escaping
        assert( Formatter( "d{0}d", "<string>" ) == "d<string>d");
        assert( Formatter( "d{{0}d", "<string>" ) == "d{0}d");
        assert( Formatter( "d{{{0}d", "<string>" ) == "d{<string>d");
        assert( Formatter( "d{0}}d", "<string>" ) == "d<string>}d");

        assert( Formatter( "{0:x}", 0xafe0000 ) == "afe0000" );
        // todo: is it correct to print 7 instead of 6 chars???
        assert( Formatter( "{0:x7}", 0xafe0000 ) == "afe0000" );
        assert( Formatter( "{0:x8}", 0xafe0000 ) == "0afe0000" );
        assert( Formatter( "{0:X8}", 0xafe0000 ) == "0AFE0000" );
        assert( Formatter( "{0:X9}", 0xafe0000 ) == "00AFE0000" );
        assert( Formatter( "{0:X13}", 0xafe0000 ) == "000000AFE0000" );
        assert( Formatter( "{0:x13}", 0xafe0000 ) == "000000afe0000" );
        // decimal width
        assert( Formatter( "{0:d6}", 123 ) == "000123" );
        assert( Formatter( "{0,7:d6}", 123 ) == " 000123" );
        assert( Formatter( "{0,-7:d6}", 123 ) == "000123 " );

        assert( Formatter( "{0:d7}", -123 ) == "-000123" );
        assert( Formatter( "{0,7:d6}", 123 ) == " 000123" );
        assert( Formatter( "{0,7:d7}", -123 ) == "-000123" );
        assert( Formatter( "{0,8:d7}", -123 ) == " -000123" );
        assert( Formatter( "{0,5:d7}", -123 ) == "-000123" );

        // compiler error
        //assert( Formatter( "{0}", -9223372036854775808L) == "-9223372036854775808" );
        assert( Formatter( "{0}", 0x8000_0000_0000_0000L) == "-9223372036854775808" );
        assert( Formatter( "{0}", 9223372036854775807L ) == "9223372036854775807" );
        assert( Formatter( "{0:X}", 0xFFFF_FFFF_FFFF_FFFF) == "FFFFFFFFFFFFFFFF" );
        assert( Formatter( "{0:x}", 0xFFFF_FFFF_FFFF_FFFF) == "ffffffffffffffff" );
        assert( Formatter( "{0:x}", 0xFFFF_1234_FFFF_FFFF) == "ffff1234ffffffff" );
        assert( Formatter( "{0:x19}", 0x1234_FFFF_FFFF) == "00000001234ffffffff" );
        // Error: prints -1
        // assert( Formatter( "{0}", 18446744073709551615UL ) == "18446744073709551615" );
        assert( Formatter( "{0}", "s" ) == "s" );
        // fragments before and after
        assert( Formatter( "d{0}d", "s" ) == "dsd" );

        // argument index
        assert( Formatter( "a{0}b{1}c{2}", "x", "y", "z" ) == "axbycz" );
        assert( Formatter( "a{2}b{1}c{0}", "x", "y", "z" ) == "azbycx" );
        assert( Formatter( "a{1}b{1}c{1}", "x", "y", "z" ) == "aybycy" );

        // alignment
        // align does not restrict the length
        assert( Formatter( "{0,5}", "hellohello" ) == "hellohello" );
        // align fills with spaces
        assert( Formatter( "->{0,-10}<-", "hello" ) == "->hello     <-" );
        assert( Formatter( "->{0,10}<-", "hello" ) == "->     hello<-" );
        assert( Formatter( "->{0,-10}<-", 12345 ) == "->12345     <-" );
        assert( Formatter( "->{0,10}<-", 12345 ) == "->     12345<-" );

        /+ Not yet implemented +/ //assert( Formatter(Culture.getCulture("de-DE"), "{0:#,#}", 12345678)
        /+ Not yet implemented +/ //        == "12.345.678" );
        /+ Not yet implemented +/ //assert( Formatter(Culture.getCulture("es-ES"), "{0:C}", 59.99)
        /+ Not yet implemented +/ //        == "59,99 €" );
        /+ Not yet implemented +/ //assert( Formatter(Culture.getCulture("fr-FR"), "{0:D}", DateTime.today)
        /+ Not yet implemented +/ //        == "vendredi 3 mars 2006" );

        assert( Formatter( "{0:f}", 1.23f ) == "1.23" ,  Formatter( "{0:f}", 1.23f ));
        assert( Formatter( "{0:f4}", 1.23456789L ) == "1.2346" );
        }
}



debug (Layout)
{
        import tango.io.Console;
        
        interface foo {}

        class X : foo {char[] toUtf8() {return "hello";}}

        void main ()
        {
                int i = int.max;
                auto Formatter = new Layout!(char);
        
                auto x = new X;
                foo f = x;
                Cout (Formatter ("{:x8} {} {} bottles", -1, f, x));
        }
}

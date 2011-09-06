/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         Kris, Keinfarbton

        This module provides a general-purpose formatting system to
        convert values to text suitable for display. There is support
        for alignment, justification, and common format specifiers for
        numbers.

        Layout can be customized via configuring various handlers and
        associated meta-data. This is utilized to plug in text.locale
        for handling custom formats, date/time and culture-specific
        conversions.

        The format notation is influenced by that used by the .NET
        and ICU frameworks, rather than C-style printf or D-style
        writef notation.

******************************************************************************/

module tango.text.convert.Layout;

private import core.vararg;
private import tango.core.Exception;
private import tango.core.Traits;
private import Utf = tango.text.convert.Utf;
private import Float = tango.text.convert.Float;
private import Integer = tango.text.convert.Integer;



version(DigitalMars)
    private import  tango.io.model.IConduit;
else
    private import  tango.io.model.IConduit : OutputStream;

version(WithVariant)
        private import tango.core.Variant;

version(WithExtensions)
        private import tango.text.convert.Extensions;
else
version (WithDateTime)
        {
        private import tango.time.Time;
        private import tango.text.convert.DateTime;
        }

/*******************************************************************************

        Contains methods for replacing format items in a string with string
        equivalents of each argument.

*******************************************************************************/

class Layout(T)
{
        public alias convert opCall;
        public alias scope size_t delegate (const(T)[]) Sink;
        public alias const(void)* Arg;
        public enum Type {
            UNKNOWN,
            CHAR,
            BYTE,
            UBYTE,
            BOOL,
            VOID,
            SHORT,
            USHORT,
            INT,
            UINT,
            LONG,
            ULONG,
            FLOAT,
            IFLOAT,
            CFLOAT,
            REAL,
            IREAL,
            CREAL,
            DOUBLE,
            IDOUBLE,
            CDOUBLE,
            STRING,
            WSTRING,
            DSTRING,
            CSTRING,
            OBJECT
        };
        
        static if (is (DateTimeLocale))
                   private DateTimeLocale* dateTime = &DateTimeDefault;

        /**********************************************************************

                Return shared instance
                
                Note that this is not threadsafe, and that static-ctor
                usage doesn't get invoked appropriately (compiler bug)

        **********************************************************************/

        static Layout instance ()
        {
                static __gshared Layout common;

                if (common is null)
                    common = new Layout!(T);
                return common;
        }

        /**********************************************************************

        **********************************************************************/

        public final T[] sprint (T[] result, const(T)[] formatStr, ...)
        {
                return vprint (result, formatStr, _arguments, _argptr);
        }

        /**********************************************************************

        **********************************************************************/

        public final T[] vprint (T[] result, const(T[]) formatStr, TypeInfo[] arguments, va_list args)
        {
                T*  p = result.ptr;
                size_t available = result.length;

                size_t sink (const(T)[] s)
                {
                        size_t len = s.length;
                        if (len > available)
                            len = available;

                        available -= len;
                        p [0..len] = s[0..len];
                        p += len;
                        return len;
                }

                core.stdc.stdio.printf("Layout vsprintf needs to get fixed!!!");
                //convert (&sink, arguments, args, formatStr);
                return result [0 .. cast(size_t) (p-result.ptr)];
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

        public final T[] convert (Char, S...)(in Char[] fmt, S args)
        {
            T[] output;

            size_t sink (const(T)[] s)
            {
                    output ~= s;
                    return s.length;
            }

            convert(&sink, fmt, args);
            return output;
        }

        /**********************************************************************

            Tentative convert using an OutputStream as sink

            Since: 0.99.7

        **********************************************************************/

        public final size_t convert(Output, Char, S...)(in Char[] fmt, S args)
        {
                size_t sink (const(T)[] s)
                {
                        return output.write(s);
                }

                return convert (&sink, fmt, args);
        }

        /**********************************************************************

        **********************************************************************/

        public final const(T)[] convertOne (T[] result, Type type, Arg args)
        {
                return dispatch(result, null, type, args);
        }

        /**********************************************************************

        **********************************************************************/

        public final size_t convert (Callback:Sink, Char, S...)(Callback sink, in Char[] format, S arguments)
        {
            // declaration
            Arg[] storedArguments;
            Type[] storedTypes;
            
            // detect type of all arguments
            foreach(argument; arguments) {
                // T = Type, S = BaseType Example: [T=const(float) | S = float]
                alias typeof(argument) T;
                alias BaseTypeOf!(T) S;
                
                static if( !isStringType!(T) && isArrayType!(T) ) {
                    // it's an array like int[] or long[], we need to loop through every element
                    size_t length = 0;
                    length += sink("[");
                    foreach(i, element; argument) {
                        if(i) length += sink(", ");
                        length += convert(sink, format, element);
                    }
                    length += sink("]");
                    return length;
                } else static if( !isStringType!(T) && isAssocArrayType!(T) ) {
                    // it's an assoc array like ushort[long].
                    size_t length = 0;
                    size_t i = 0;
                    length += sink("{");
                    foreach(key, value; argument) {
                        if(i++) length += sink(", ");
                        length += convert(sink, format, key);
                        length += sink(" => ");
                        length += convert(sink, format, value);
                    }
                    length += sink("}");
                    return length;
                } else {
                    // set the argument and it's type to default values
                    Arg storedArgument = &argument;
                    Type storedType = Type.UNKNOWN;
                    
                    static if(is(S == byte)) {
                        storedType = Type.BYTE;
                    } else static if(is(S == short)) {
                        storedType = Type.SHORT;
                    } else static if(is(S == int)) {
                        storedType = Type.INT;
                    } else static if(is(S == long)) {
                        storedType = Type.LONG;
                    } else static if(is(S == ubyte)) {
                        storedType = Type.UBYTE;
                    } else static if(is(S == ushort)) {
                        storedType = Type.USHORT;
                    } else static if(is(S == uint)) {
                        storedType = Type.UINT;
                    } else static if(is(S == ulong)) {
                        storedType = Type.ULONG;
                    } else static if(is(T : const(bool))) {
                        storedType = Type.BOOL;
                    } else static if(is(S == float)) {
                        storedType = Type.FLOAT;
                    } else static if(is(S == ifloat)) {
                        storedType = Type.IFLOAT;
                    } else static if(is(S == cfloat)) {
                        storedType = Type.CFLOAT;
                    } else static if(is(S == real)) {
                        storedType = Type.REAL;
                    } else static if(is(S == ireal)) {
                        storedType = Type.IREAL;
                    } else static if(is(S == creal)) {
                        storedType = Type.CREAL;
                    } else static if(is(S == double)) {
                        storedType = Type.DOUBLE;
                    } else static if(is(S == idouble)) {
                        storedType = Type.IDOUBLE;
                    } else static if(is(S == cdouble)) {
                        storedType = Type.CDOUBLE;
                    } else static if(is(T : const(char)[])) {
                        storedType = Type.STRING;
                    } else static if(is(T : const(wchar)[])) {
                        storedType = Type.WSTRING;
                    } else static if(is(T : const(dchar)[])) {
                        storedType = Type.DSTRING;
                    } else static if(is(T : const(char)*)) {
                        storedType = Type.CSTRING;
                    } else static if(is(T : const(void*))) {
                        storedType = Type.VOID;
                    } else static if(is(T : Object)) {
                        storedType = Type.OBJECT;
                    } else static if(is(S == char)) {
                        storedType = Type.CHAR;
                    }
                    
                    // append the stored type and argument to the list
                    storedTypes ~= storedType;
                    storedArguments ~= storedArgument;
                }
            }
            
            // parse the arguments and return the string size
            return parse(format, storedTypes, storedArguments, sink);
        }

        /**********************************************************************

                Parse the format-string, emitting formatted args and text
                fragments as we go

        **********************************************************************/

        private size_t parse(const(T)[] fmt, Type[] types, Arg[] arguments, Sink sink)
        {
            // assertions
            assert(fmt, "null fmt specifier");
            assert(types.length == arguments.length, "arguments and types must equal in length");
            
            // declaration and initalisation
            size_t length = 0;
            int nextIndex = 0;
            T[512] result = void;
            const(T)* cursor = cast(const(T)*)fmt.ptr;
            const(T)* fragment = cast(const(T)*)fmt.ptr;
            const(T)* end = cursor + fmt.length;
            
            // parse the format string
            for(;;) {
                // find the first {
                while (cursor < end && *cursor != '{')
                     ++cursor;
                
                // emit fragment
                length += sink(fragment[0 .. (cursor - fragment)]);
                
                // all done?
                if (cursor is end)
                    break;
                
                // check for "{{" and skip if so
                if (*++cursor is '{') {
                    fragment = cursor++;
                    continue;
                }
                
                // extract index (if it's indexed)
                int index = 0;
                bool indexed = false;
                while (*cursor >= '0' && *cursor <= '9') {
                    index = index * 10 + *cursor++ -'0';
                    indexed = true;
                }

                // skip spaces
                while (cursor < end && *cursor is ' ')
                    ++cursor;
                
                // has minimum or maximum width?
                bool crop;
                bool left;
                bool right;
                int width;
                if (*cursor is ',' || *cursor is '.') {
                    // check if crop
                    if (*cursor is '.')
                        crop = true;

                    // eat all spaces
                    while(++cursor < end && *cursor is ' ') { }
                    
                    if (*cursor is '-') {
                        left = true;
                        ++cursor;
                    } else {
                        right = true;
                    }

                    // get width
                    while (*cursor >= '0' && *cursor <= '9')
                        width = width * 10 + *cursor++ -'0';

                    // skip spaces
                    while (cursor < end && *cursor is ' ')
                        ++cursor;
                }
                
                // has a format string?
                const(T)[] format;
                if (*cursor is ':' && cursor < end) {
                    const(T)* fs = ++cursor;
                    
                    // eat everything up to closing brace
                    while (cursor < end && *cursor != '}')
                        ++cursor;
                        
                    format = fs[0 .. cast(size_t) (cursor - fs)];
                }
                
                // insist on a closing brace
                if (*cursor != '}') {
                    length += sink("{malformed format}");
                    continue;
                }

                // check for default index & set next default counter
                if (!indexed) {
                    index = nextIndex;
                }
                nextIndex = index + 1;
                
                // next char is start of following fragment
                fragment = ++cursor;
                
                // index not valid
                if(index >= arguments.length) {
                    sink("{invalid index}");
                    continue;
                }
                
                // fetch type, argument and build a string from it
                Arg argument = arguments[index];
                Type type = types[index];
                const(T[]) str = dispatch(result, format, type, argument);
                
                // handle alignment
                int padding = cast(int)(width - str.length);
                if(crop) {
                    if(padding < 0) {
                        if (left) {
                            length += sink ("...");
                            length += sink (Utf.cropLeft (str[-padding..$]));
                        } else {
                            length += sink (Utf.cropRight (str[0..width]));
                            length += sink ("...");
                        }
                    } else {
                        length += sink (str);
                    }
                } else {
                    // if right aligned, pad out with spaces
                    if (right && padding > 0)
                        length += spaces (sink, padding);

                    // emit formatted argument
                    length += sink(str);

                    // finally, pad out on right
                    if (left && padding > 0)
                        length += spaces (sink, padding);
                }
            }
            
            // return the length
            return length;
        }

        /***********************************************************************

        ***********************************************************************/

        private const(T)[] dispatch (T[] result, const(T)[] format, Type type, Arg p)
        {
            switch(type)
            {
                case Type.BOOL:
                    immutable(T)[] t = cast(immutable(T)[])"true";
                    immutable(T)[] f = cast(immutable(T)[])"false";
                    return (*cast(bool*)p) ? t : f;
                
                case Type.BYTE:
                    return integer(result, *cast(byte*) p, format, ubyte.max);
                
                case Type.CHAR:
                    return [*cast(T*) p];
                    
                case Type.VOID:
                case Type.UBYTE:
                    return integer(result, *cast(ubyte*) p, format, ubyte.max, "u");
                
                case Type.SHORT:
                    return integer(result, *cast(short*) p, format, ushort.max);

                case Type.USHORT:
                    return integer(result, *cast(ushort*) p, format, ushort.max, "u");

                case Type.INT:
                    return integer(result, *cast(int*) p, format, uint.max);
                
                case Type.UINT:
                    return integer (result, *cast(uint*) p, format, uint.max, "u");

                case Type.ULONG:
                    return integer (result, *cast(long*) p, format, ulong.max, "u");
                
                case Type.LONG:
                    return integer (result, *cast(long*) p, format, ulong.max);
                
                case Type.OBJECT:
                    return (*cast(Object*)p).toString();
                    
                case Type.FLOAT:
                    return floater(result, *cast(float*) p, format);
                    
                case Type.DOUBLE:
                    return floater(result, *cast(double*) p, format);
                
                case Type.REAL:
                    return floater(result, *cast(real*) p, format);
                
                case Type.IFLOAT:
                    return imaginary(result, *cast(ifloat*) p, format);

                case Type.IDOUBLE:
                    return imaginary(result, *cast(idouble*) p, format);

                case Type.IREAL:
                    return imaginary(result, *cast(ireal*) p, format);
                
                case Type.CFLOAT:
                    return complex(result, *cast(cfloat*) p, format);

                case Type.CDOUBLE:
                    return complex(result, *cast(cdouble*) p, format);

                case Type.CREAL:
                    return complex(result, *cast(creal*) p, format);
                
                case Type.STRING:
                    return Utf.fromString8(*cast(char[]*)p, result);
                    
                case Type.WSTRING:
                    return Utf.fromString16(*cast(wchar[]*)p, result);
                    
                case Type.DSTRING:
                    return Utf.fromString32(*cast(dchar[]*)p, result);
                    
                case Type.CSTRING:
                    return Utf.fromStringz(*cast(char**)p);
                
                case Type.UNKNOWN:
                    return cast(T[])"{unknown type}";
                
                default:
                    return cast(T[])"{null}";
            }
        }

        /**********************************************************************

                Format an integer value

        **********************************************************************/

        protected T[] integer (T[] output, long v, const(T)[] format, ulong mask = ulong.max, const(T)[] def="d")
        {
                if (format.length is 0)
                    format = def;
                if (format[0] != 'd')
                    v &= mask;

                return Integer.format (output, v, format);
        }

        /**********************************************************************

                format a floating-point value. Defaults to 2 decimal places

        **********************************************************************/

        protected T[] floater (T[] output, real v, const(T)[] format)
        {
                uint dec = 2,
                     exp = 10;
                bool pad = true;

                for (auto p=format.ptr, e=p+format.length; p < e; ++p)
                     switch (*p)
                            {
                            case '.':
                                 pad = false;
                                 break;
                            case 'e':
                            case 'E':
                                 exp = 0;
                                 break;
                            case 'x':
                            case 'X':
                                 double d = v;
                                 return integer (output, *cast(long*) &d, "x#");
                            default:
                                 auto c = cast(T)*p;
                                 if (c >= '0' && c <= '9')
                                    {
                                    dec = c - '0', c = p[1];
                                    if (c >= '0' && c <= '9' && ++p < e)
                                        dec = dec * 10 + c - '0';
                                    }
                                 break;
                            }

                return Float.format (output, v, dec, exp, pad);
        }

        /**********************************************************************

        **********************************************************************/

        private void error (char[] msg)
        {
                throw new IllegalArgumentException (cast(immutable(char)[])msg);
        }

        /**********************************************************************

        **********************************************************************/

        private size_t spaces (Sink sink, size_t count)
        {
            assert(count > 0);
            size_t ret;

            enum immutable(T)[] Spaces = "                                ";
            while (count > Spaces.length) {
                ret += sink (Spaces);
                count -= Spaces.length;
            }
            return ret + sink (Spaces[0..count]);
        }

        /**********************************************************************

                format an imaginary value

        **********************************************************************/

        private T[] imaginary (T[] result, ireal val, const(T)[] format)
        {
                return floatingTail (result, val.im, format, "*1i");
        }

        /**********************************************************************

                format a complex value

        **********************************************************************/

        private T[] complex (T[] result, creal val, const(T)[] format)
        {
                static bool signed (real x)
                {
                        static if (real.sizeof is 4)
                                   return ((*cast(uint *)&x) & 0x8000_0000) != 0;
                        else
                        static if (real.sizeof is 8)
                                   return ((*cast(ulong *)&x) & 0x8000_0000_0000_0000) != 0;
                               else
                                  {
                                  auto pe = cast(ubyte *)&x;
                                  return (pe[9] & 0x80) != 0;
                                  }
                }
                enum immutable(T)[] plus = "+";

                auto len = floatingTail (result, val.re, format, signed(val.im) ? null : plus).length;
                return result [0 .. len + floatingTail (result[len..$], val.im, format, "*1i").length];
        }

        /**********************************************************************

                formats a floating-point value, and appends a tail to it

        **********************************************************************/

        private T[] floatingTail (T[] result, real val, const(T)[] format, const(T)[] tail)
        {
                assert (result.length > tail.length);

                auto res = floater (result[0..$-tail.length], val, format);
                auto len=res.length;
                if (res.ptr!is result.ptr)
                    result[0..len]=res;
                result [len .. len + tail.length] = tail;
                return result [0 .. len + tail.length];
        }
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        unittest
        {
        auto Formatter = Layout!(char).instance;

        // basic layout tests
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
        assert( Formatter( "{0:x4}", cast(ushort)0xafe ) == "0afe" );
        assert( Formatter( "{0:X4}", cast(ushort)0xafe ) == "0AFE" );

        assert( Formatter( "{0}", -2147483648 ) == "-2147483648" );
        assert( Formatter( "{0}", 2147483647 ) == "2147483647" );
        assert( Formatter( "{0}", 4294967295 ) == "4294967295" );
        
        assert( Formatter( "{0}", 'a') == "a" );
        assert( Formatter( "{0}{1}{2}", 'a', 'b', 'c') == "abc" );
        assert( Formatter( "{2}{1}{0}", 'a', 'b', 'c') == "cba" );

        // large integers
        assert( Formatter( "{0}", -9223372036854775807L) == "-9223372036854775807" );
        assert( Formatter( "{0}", 0x8000_0000_0000_0000L) == "9223372036854775808" );
        assert( Formatter( "{0}", 9223372036854775807L ) == "9223372036854775807" );
        assert( Formatter( "{0:X}", 0xFFFF_FFFF_FFFF_FFFF) == "FFFFFFFFFFFFFFFF" );
        assert( Formatter( "{0:x}", 0xFFFF_FFFF_FFFF_FFFF) == "ffffffffffffffff" );
        assert( Formatter( "{0:x}", 0xFFFF_1234_FFFF_FFFF) == "ffff1234ffffffff" );
        assert( Formatter( "{0:x19}", 0x1234_FFFF_FFFF) == "00000001234ffffffff" );
        assert( Formatter( "{0}", 18446744073709551615UL ) == "18446744073709551615" );
        assert( Formatter( "{0}", 18446744073709551615UL ) == "18446744073709551615" );

        // fragments before and after
        assert( Formatter( "d{0}d", "s" ) == "dsd" );
        assert( Formatter( "d{0}d", "1234567890" ) == "d1234567890d" );

        // brace escaping
        assert( Formatter( "d{0}d", "<string>" ) == "d<string>d");
        assert( Formatter( "d{{0}d", "<string>" ) == "d{0}d");
        assert( Formatter( "d{{{0}d", "<string>" ) == "d{<string>d");
        assert( Formatter( "d{0}}d", "<string>" ) == "d<string>}d");

        // hex conversions, where width indicates leading zeroes
        assert( Formatter( "{0:x}", 0xafe0000 ) == "afe0000" );
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

        // width & sign combinations
        assert( Formatter( "{0:d7}", -123 ) == "-0000123" );
        assert( Formatter( "{0,7:d6}", 123 ) == " 000123" );
        assert( Formatter( "{0,7:d7}", -123 ) == "-0000123" );
        assert( Formatter( "{0,8:d7}", -123 ) == "-0000123" );
        assert( Formatter( "{0,5:d7}", -123 ) == "-0000123" );

        // Negative numbers in various bases
        assert( Formatter( "{:b}", cast(byte) -1 ) == "11111111" );
        assert( Formatter( "{:b}", cast(short) -1 ) == "1111111111111111" );
        assert( Formatter( "{:b}", cast(int) -1 )
                == "11111111111111111111111111111111" );
        assert( Formatter( "{:b}", cast(long) -1 )
                == "1111111111111111111111111111111111111111111111111111111111111111" );

        assert( Formatter( "{:o}", cast(byte) -1 ) == "377" );
        assert( Formatter( "{:o}", cast(short) -1 ) == "177777" );
        assert( Formatter( "{:o}", cast(int) -1 ) == "37777777777" );
        assert( Formatter( "{:o}", cast(long) -1 ) == "1777777777777777777777" );

        assert( Formatter( "{:d}", cast(byte) -1 ) == "-1" );
        assert( Formatter( "{:d}", cast(short) -1 ) == "-1" );
        assert( Formatter( "{:d}", cast(int) -1 ) == "-1" );
        assert( Formatter( "{:d}", cast(long) -1 ) == "-1" );

        assert( Formatter( "{:x}", cast(byte) -1 ) == "ff" );
        assert( Formatter( "{:x}", cast(short) -1 ) == "ffff" );
        assert( Formatter( "{:x}", cast(int) -1 ) == "ffffffff" );
        assert( Formatter( "{:x}", cast(long) -1 ) == "ffffffffffffffff" );

        // argument index
        assert( Formatter( "a{0}b{1}c{2}", "x", "y", "z" ) == "axbycz" );
        assert( Formatter( "a{2}b{1}c{0}", "x", "y", "z" ) == "azbycx" );
        assert( Formatter( "a{1}b{1}c{1}", "x", "y", "z" ) == "aybycy" );

        // alignment does not restrict the length
        assert( Formatter( "{0,5}", "hellohello" ) == "hellohello" );

        // alignment fills with spaces
        assert( Formatter( "->{0,-10}<-", "hello" ) == "->hello     <-" );
        assert( Formatter( "->{0,10}<-", "hello" ) == "->     hello<-" );
        assert( Formatter( "->{0,-10}<-", 12345 ) == "->12345     <-" );
        assert( Formatter( "->{0,10}<-", 12345 ) == "->     12345<-" );

        // chop at maximum specified length; insert ellipses when chopped
        assert( Formatter( "->{.5}<-", "hello" ) == "->hello<-" );
        assert( Formatter( "->{.4}<-", "hello" ) == "->hell...<-" );
        assert( Formatter( "->{.-3}<-", "hello" ) == "->...llo<-" );

        // width specifier indicates number of decimal places
        assert( Formatter( "{0:f}", 1.23f ) == "1.23" );
        assert( Formatter( "{0:f4}", 1.23456789L ) == "1.2346" );
        assert( Formatter( "{0:e4}", 0.0001) == "1.0000e-04");

        assert( Formatter( "{0:f}", 1.23f*1i ) == "1.23*1i");
        assert( Formatter( "{0:f4}", 1.23456789L*1i ) == "1.2346*1i" );
        assert( Formatter( "{0:e4}", 0.0001*1i) == "1.0000e-04*1i");

        assert( Formatter( "{0:f}", 1.23f+1i ) == "1.23+1.00*1i" );
        assert( Formatter( "{0:f4}", 1.23456789L+1i ) == "1.2346+1.0000*1i" );
        assert( Formatter( "{0:e4}", 0.0001+1i) == "1.0000e-04+1.0000e+00*1i");
        assert( Formatter( "{0:f}", 1.23f-1i ) == "1.23-1.00*1i" );
        assert( Formatter( "{0:f4}", 1.23456789L-1i ) == "1.2346-1.0000*1i" );
        assert( Formatter( "{0:e4}", 0.0001-1i) == "1.0000e-04-1.0000e+00*1i");

        // 'f.' & 'e.' format truncates zeroes from floating decimals
        assert( Formatter( "{:f4.}", 1.230 ) == "1.23" );
        assert( Formatter( "{:f6.}", 1.230 ) == "1.23" );
        assert( Formatter( "{:f1.}", 1.230 ) == "1.2" );
        assert( Formatter( "{:f.}", 1.233 ) == "1.23" );
        assert( Formatter( "{:f.}", 1.237 ) == "1.24" );
        assert( Formatter( "{:f.}", 1.000 ) == "1" );
        assert( Formatter( "{:f2.}", 200.001 ) == "200");
        
        // array output
        int[] a = [ 51, 52, 53, 54, 55 ];
        assert( Formatter( "{}", a ) == "[51, 52, 53, 54, 55]" );
        assert( Formatter( "{:x}", a ) == "[33, 34, 35, 36, 37]" );
        assert( Formatter( "{,-4}", a ) == "[51  , 52  , 53  , 54  , 55  ]" );
        assert( Formatter( "{,4}", a ) == "[  51,   52,   53,   54,   55]" );
        int[][] b = [ [ 51, 52 ], [ 53, 54, 55 ] ];
        assert( Formatter( "{}", b ) == "[[51, 52], [53, 54, 55]]" );

        ushort[3] c = [ cast(ushort)51, 52, 53 ];
        assert( Formatter( "{}", c ) == "[51, 52, 53]" );

        // integer AA 
        ushort[long] d;
        d[234] = 2;
        d[345] = 3;
        assert( Formatter( "{}", d ) == "{234 => 2, 345 => 3}" ||
                Formatter( "{}", d ) == "{345 => 3, 234 => 2}");
        
        // bool/string AA 
        bool[char[]] e;
        e[ "key" ] = true;
        e[ "value" ] = false;
        assert( Formatter( "{}", e ) == "{key => true, value => false}" ||
                Formatter( "{}", e ) == "{value => false, key => true}");

        // string/double AA 
        char[][ double ] f;
        f[ 1.0 ] = "one".dup;
        f[ 3.14 ] = "PI".dup;
        assert( Formatter( "{}", f ) == "{1.00 => one, 3.14 => PI}" ||
                Formatter( "{}", f ) == "{3.14 => PI, 1.00 => one}");
        }
}



debug (Layout)
{
        import tango.io.Console;

        static if (is (typeof(Time)))
                   import tango.time.WallClock;

        void main ()
        {
                auto layout = Layout!(char).instance;

                layout.convert (Cout.stream, "hi {}", "there\n");

                Cout (layout.sprint (new char[1], "hi")).newline;
                Cout (layout.sprint (new char[10], "{.4}", "hello")).newline;
                Cout (layout.sprint (new char[10], "{.-4}", "hello")).newline;

                Cout (layout ("{:f1}", 3.0)).newline;
                Cout (layout ("{:g}", 3.00)).newline;
                Cout (layout ("{:f1}", -0.0)).newline;
                Cout (layout ("{:g1}", -0.0)).newline;
                Cout (layout ("{:d2}", 56)).newline;
                Cout (layout ("{:d4}", cast(byte) -56)).newline;
                Cout (layout ("{:f4}", 1.0e+12)).newline;
                Cout (layout ("{:f4}", 1.23e-2)).newline;
                Cout (layout ("{:f8}", 3.14159)).newline;
                Cout (layout ("{:e20}", 1.23e-3)).newline;
                Cout (layout ("{:e4.}", 1.23e-07)).newline;
                Cout (layout ("{:.}", 1.2)).newline;
                Cout (layout ("ptr:{}", &layout)).newline;
                Cout (layout ("ulong.max {}", ulong.max)).newline;

                struct S
                {
                   char[] toString () {return "foo";}      
                }

                S s;
                Cout (layout ("struct: {}", s)).newline;

                static if (is (typeof(Time)))
                           Cout (layout ("time: {}", WallClock.now)).newline;
        }
}

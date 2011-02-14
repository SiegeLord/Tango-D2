/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

        A set of functions for converting between string and integer 
        values. 

        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import Integer = tango.text.convert.Integer;

        auto i = Integer.parse ("32767");
        ---
        
*******************************************************************************/

module tango.text.convert.Integer;

private import tango.core.Exception;

/******************************************************************************

        Parse an integer value from the provided 'digits' string. 

        The string is inspected for a sign and an optional radix 
        prefix. A radix may be provided as an argument instead, 
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        Throws: IllegalArgumentException where the input text is not parsable
        in its entirety.

        See_also: the low level functions parse() and convert()

******************************************************************************/

int toInt(T, U=uint) (T[] digits, U radix=0)
{return toInt!(T)(digits, radix);}

int toInt(T) (T[] digits, uint radix=0)
{
        auto x = toLong (digits, radix);
        if (x > int.max)
            throw new IllegalArgumentException ("Integer.toInt :: integer overflow");
        return cast(int) x;
}

/******************************************************************************

        Parse an integer value from the provided 'digits' string.

        The string is inspected for a sign and an optional radix
        prefix. A radix may be provided as an argument instead,
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        Throws: IllegalArgumentException where the input text is not parsable
        in its entirety.

        See_also: the low level functions parse() and convert()

******************************************************************************/

long toLong(T, U=uint) (T[] digits, U radix=0)
{return toLong!(T)(digits, radix);}

long toLong(T) (T[] digits, uint radix=0)
{
        uint len;

        auto x = parse (digits, radix, &len);
        if (len < digits.length)
            throw new IllegalArgumentException ("Integer.toLong :: invalid literal");
        return x;
}

/******************************************************************************

        Wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

char[] toString (long i, char[] fmt = null)
{
        char[66] tmp = void;
        return format (tmp, i, fmt).dup;
}
               
/******************************************************************************

        Wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

wchar[] toString16 (long i, wchar[] fmt = null)
{
        wchar[66] tmp = void;
        return format (tmp, i, fmt).dup;
}
               
/******************************************************************************

        Wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

dchar[] toString32 (long i, dchar[] fmt = null)
{
        dchar[66] tmp = void;
        return format (tmp, i, fmt).dup;
}
               
/*******************************************************************************

        Supports format specifications via an array, where format follows
        the notation given below:
        ---
        type width prefix
        ---

        Type is one of [d, g, u, b, x, o] or uppercase equivalent, and
        dictates the conversion radix or other semantics.

        Width is optional and indicates a minimum width for zero-padding,
        while the optional prefix is one of ['#', ' ', '+'] and indicates
        what variety of prefix should be placed in the output. e.g.
        ---
        "d"     => integer
        "u"     => unsigned
        "o"     => octal
        "b"     => binary
        "x"     => hexadecimal
        "X"     => hexadecimal uppercase

        "d+"    => integer prefixed with "+"
        "b#"    => binary prefixed with "0b"
        "x#"    => hexadecimal prefixed with "0x"
        "X#"    => hexadecimal prefixed with "0X"

        "d8"    => decimal padded to 8 places as required
        "b8"    => binary padded to 8 places as required
        "b8#"   => binary padded to 8 places and prefixed with "0b"
        ---

        Note that the specified width is exclusive of the prefix, though
        the width padding will be shrunk as necessary in order to ensure
        a requested prefix can be inserted into the provided output.

*******************************************************************************/

T[] format(T, U=long) (T[] dst, U i, T[] fmt = null)
{return format!(T)(dst, cast(long) i, fmt);}

T[] format(T) (T[] dst, long i, T[] fmt = null)
{
        char    pre,
                type;
        int     width;

        decode (fmt, type, pre, width);
        return formatter (dst, i, type, pre, width);
} 

private void decode(T) (T[] fmt, ref char type, out char pre, out int width)
{
        if (fmt.length is 0)
            type = 'd';
        else
           {
           type = cast(char)fmt[0];
           if (fmt.length > 1)
              {
              auto p = &fmt[1];
              for (int j=1; j < fmt.length; ++j, ++p)
                   if (*p >= '0' && *p <= '9')
                       width = width * 10 + (*p - '0');
                   else
                      pre = cast(char)*p;
              }
           }
} 


T[] formatter(T, U=long, X=char, Y=char) (T[] dst, U i, X type, Y pre, int width)
{return formatter!(T)(dst, cast(long) i, type, pre, width);}


private struct _FormatterInfo(T)
{
		uint    radix;
		T[]     prefix;
		T[]     numbers;
}

T[] formatter(T) (T[] dst, long i, char type, char pre, int width)
{
        enum T[] lower = cast(T[])"0123456789abcdef".dup;
        enum T[] upper = cast(T[])"0123456789ABCDEF".dup;
        
        alias _FormatterInfo!(T) Info;

        enum   Info[] formats = 
                [
                {10, null, lower}, 
                {10, cast(T[])"-".dup,  lower}, 
                {10, cast(T[])" ".dup,  lower}, 
                {10, cast(T[])"+".dup,  lower}, 
                { 2, cast(T[])"0b".dup, lower}, 
                { 8, cast(T[])"0o".dup, lower}, 
                {16, cast(T[])"0x".dup, lower}, 
                {16, cast(T[])"0X".dup, upper},
                ];

        ubyte index;
        int len = dst.length;

        if (len)
           {
           switch (type)
                  {
                  case 'd':
                  case 'D':
                  case 'g':
                  case 'G':
                       if (i < 0)
                          {
                          index = 1;
                          i = -i;
                          }
                       else
                          if (pre is ' ')
                              index = 2;
                          else
                             if (pre is '+')
                                 index = 3;
                  case 'u':
                  case 'U':
                       pre = '#';
                       break;

                  case 'b':
                  case 'B':
                       index = 4;
                       break;

                  case 'o':
                  case 'O':
                       index = 5;
                       break;

                  case 'x':
                       index = 6;
                       break;

                  case 'X':
                       index = 7;
                       break;

                  default:
                        return cast(T[])"{unknown format '".dup~cast(T)type~cast(T[])"'}".dup;
                  }

           auto info = &formats[index];
           auto numbers = info.numbers;
           auto radix = info.radix;

           // convert number to text
           auto p = dst.ptr + len;
           if (uint.max >= cast(ulong) i)
              {
              auto v = cast (uint) i;
              do {
                 *--p = numbers [v % radix];
                 } while ((v /= radix) && --len);
              }
           else
              {
              auto v = cast (ulong) i;
              do {
                 *--p = numbers [cast(uint) (v % radix)];
                 } while ((v /= radix) && --len);
              }
        
           auto prefix = (pre is '#') ? info.prefix : null;
           if (len > prefix.length)
              {
              len -= prefix.length + 1;

              // prefix number with zeros? 
              if (width)
                 {
                 width = dst.length - width - prefix.length;
                 while (len > width && len > 0)
                       {
                       *--p = '0';
                       --len;
                       }
                 }
              // write optional prefix string ...
              dst [len .. len + prefix.length] = prefix;

              // return slice of provided output buffer
              return dst [len .. $];                               
              }
           }
        
        return cast(T[])"{output width too small}".dup;
} 


/******************************************************************************

        Parse an integer value from the provided 'digits' string. 

        The string is inspected for a sign and an optional radix 
        prefix. A radix may be provided as an argument instead, 
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        A non-null 'ate' will return the number of characters used
        to construct the returned value.

        Throws: none. The 'ate' param should be checked for valid input.

******************************************************************************/

long parse(T, U=uint) (T[] digits, U radix=0, uint* ate=null)
{return parse!(T)(digits, radix, ate);}

long parse(T) (T[] digits, uint radix=0, uint* ate=null)
{
        bool sign;

        auto eaten = trim (digits, sign, radix);
        auto value = convert (digits[eaten..$], radix, ate);

        // check *ate > 0 to make sure we don't parse "-" as 0.
        if (ate && *ate > 0)
            *ate += eaten;

        return cast(long) (sign ? -value : value);
}

/******************************************************************************

        Convert the provided 'digits' into an integer value,
        without checking for a sign or radix. The radix defaults
        to decimal (10).

        Returns the value and updates 'ate' with the number of
        characters consumed.

        Throws: none. The 'ate' param should be checked for valid input.

******************************************************************************/

ulong convert(T, U=uint) (T[] digits, U radix=10, uint* ate=null)
{return convert!(T)(digits, radix, ate);}

ulong convert(T) (T[] digits, uint radix=10, uint* ate=null)
{
        uint  eaten;
        ulong value;

        foreach (c; digits)
                {
                if (c >= '0' && c <= '9')
                   {}
                else
                   if (c >= 'a' && c <= 'z')
                       c -= 39;
                   else
                      if (c >= 'A' && c <= 'Z')
                          c -= 7;
                      else
                         break;

                if ((c -= '0') < radix)
                   {
                   value = value * radix + c;
                   ++eaten;
                   }
                else
                   break;
                }

        if (ate)
            *ate = eaten;

        return value;
}


/******************************************************************************

        Strip leading whitespace, extract an optional +/- sign,
        and an optional radix prefix. If the radix value matches
        an optional prefix, or the radix is zero, the prefix will
        be consumed and assigned. Where the radix is non zero and
        does not match an explicit prefix, the latter will remain 
        unconsumed. Otherwise, radix will default to 10.

        Returns the number of characters consumed.

******************************************************************************/

uint trim(T, U=uint) (T[] digits, ref bool sign, ref U radix)
{return trim!(T)(digits, sign, radix);}

uint trim(T) (T[] digits, ref bool sign, ref uint radix)
{
        T       c;
        T*      p = digits.ptr;
        size_t     len = digits.length;

        if (len)
           {
           // strip off whitespace and sign characters
           for (c = *p; len; c = *++p, --len)
                if (c is ' ' || c is '\t')
                   {}
                else
                   if (c is '-')
                       sign = true;
                   else
                      if (c is '+')
                          sign = false;
                   else
                      break;

           // strip off a radix specifier also?
           auto r = radix;
           if (c is '0' && len > 1)
               switch (*++p)
                      {
                      case 'x':
                      case 'X':
                           ++p;
                           r = 16;
                           break;
 
                      case 'b':
                      case 'B':
                           ++p;
                           r = 2;
                           break;
 
                      case 'o':
                      case 'O':
                           ++p;
                           r = 8;
                           break;
 
                      default: 
                            --p;
                           break;
                      } 

           // default the radix to 10
           if (r is 0)
               radix = 10;
           else
              // explicit radix must match (optional) prefix
              if (radix != r)
                  if (radix)
                      p -= 2;
                  else
                     radix = r;
           }

        // return number of characters eaten
        return (p - digits.ptr);
}


/******************************************************************************

        quick & dirty text-to-unsigned int converter. Use only when you
        know what the content is, or use parse() or convert() instead.

        Return the parsed uint
        
******************************************************************************/

uint atoi(T) (T[] s, int radix = 10)
{
        uint value;

        foreach (c; s)
                 if (c >= '0' && c <= '9')
                     value = value * radix + (c - '0');
                 else
                    break;
        return value;
}


/******************************************************************************

        quick & dirty unsigned to text converter, where the provided output
        must be large enough to house the result (10 digits in the largest
        case). For mainstream use, consider utilizing format() instead.

        Returns a populated slice of the provided output
        
******************************************************************************/

T[] itoa(T, U=uint) (T[] output, U value, int radix = 10)
{return itoa!(T)(output, value, radix);}

T[] itoa(T) (T[] output, uint value, int radix = 10)
{
        T* p = output.ptr + output.length;

        do {
           *--p = cast(T)(value % radix + '0');
           } while (value /= radix);
        return output[cast(size_t) (p-output.ptr) .. $];
}


/******************************************************************************

        Consume a number from the input without converting it. Argument
        'fp' enables floating-point consumption. Supports hex input for
        numbers which are prefixed appropriately

        Since version 0.99.9

******************************************************************************/

T[] consume(T) (T[] src, bool fp=false)
{
        T       c;
        bool    sign;
        uint    radix;

        // remove leading space, and sign
        auto e = src.ptr + src.length;
        auto p = src.ptr + trim (src, sign, radix);
        auto b = p;

        // bail out if the string is empty
        if (src.length is 0 || p > &src[$-1])
            return null;

        // read leading digits
        for (c=*p; p < e && ((c >= '0' && c <= '9') || 
            (radix is 16 && ((c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))));)
             c = *++p;

        if (fp)
           {
           // gobble up a point
           if (c is '.' && p < e)
               c = *++p;

           // read fractional digits
           while (c >= '0' && c <= '9' && p < e)
                  c = *++p;

           // did we consume anything?
           if (p > b)
              {
              // consume exponent?
              if ((c is 'e' || c is 'E') && p < e )
                 {
                 c = *++p;
                 if (c is '+' || c is '-')
                     c = *++p;
                 while (c >= '0' && c <= '9' && p < e)
                        c = *++p;
                 }
              }
           }
        return src [0 .. p-src.ptr];
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
    
        private T[] S(T)(immutable(T)[] s)
        {
            return cast(T[])s;
        }
        
        unittest
        {
        char[64] tmp;
        
        assert (toInt("1".dup) is 1);
        assert (toLong("1".dup) is 1);
        assert (toInt("1".dup, 10) is 1);
        assert (toLong("1".dup, 10) is 1);

        assert (atoi ("12345".dup) is 12345);
        assert (itoa (tmp, 12345) == "12345".dup);

        assert(parse( "0"w.dup ) ==  0 );
        assert(parse( "1"w.dup ) ==  1 );
        assert(parse( "-1"w.dup ) ==  -1 );
        assert(parse( "+1"w.dup ) ==  1 );

        // numerical limits
        assert(parse( "-2147483648".dup ) == int.min );
        assert(parse(  "2147483647".dup ) == int.max );
        assert(parse(  "4294967295".dup ) == uint.max );

        assert(parse( "-9223372036854775808".dup ) == long.min );
        assert(parse( "9223372036854775807".dup ) == long.max );
        assert(parse( "18446744073709551615".dup ) == ulong.max );

        // hex
        assert(parse( "a".dup, 16) == 0x0A );
        assert(parse( "b".dup, 16) == 0x0B );
        assert(parse( "c".dup, 16) == 0x0C );
        assert(parse( "d".dup, 16) == 0x0D );
        assert(parse( "e".dup, 16) == 0x0E );
        assert(parse( "f".dup, 16) == 0x0F );
        assert(parse( "A".dup, 16) == 0x0A );
        assert(parse( "B".dup, 16) == 0x0B );
        assert(parse( "C".dup, 16) == 0x0C );
        assert(parse( "D".dup, 16) == 0x0D );
        assert(parse( "E".dup, 16) == 0x0E );
        assert(parse( "F".dup, 16) == 0x0F );
        assert(parse( "FFFF".dup, 16) == ushort.max );
        assert(parse( "ffffFFFF".dup, 16) == uint.max );
        assert(parse( "ffffFFFFffffFFFF".dup, 16u ) == ulong.max );
        // oct
        assert(parse( "55".dup, 8) == 055 );
        assert(parse( "100".dup, 8) == 0100 );
        // bin
        assert(parse( "10000".dup, 2) == 0x10 );
        // trim
        assert(parse( "    \t20".dup) == 20 );
        assert(parse( "    \t-20".dup) == -20 );
        assert(parse( "-    \t 20".dup) == -20 );
        // recognise radix prefix
        assert(parse( "0xFFFF".dup ) == ushort.max );
        assert(parse( "0XffffFFFF".dup ) == uint.max );
        assert(parse( "0o55".dup) == 055 );
        assert(parse( "0O55".dup ) == 055 );
        assert(parse( "0b10000".dup) == 0x10 );
        assert(parse( "0B10000".dup) == 0x10 );

        // prefix tests
        char[] str = "0x".dup;
        assert(parse( str[0..1] ) ==  0 );
        assert(parse("0x10".dup, 10) == 0);
        assert(parse("0b10".dup, 10) == 0);
        assert(parse("0o10".dup, 10) == 0);
        assert(parse("0b10".dup) == 0b10);
        assert(parse("0o10".dup) == 010);
        assert(parse("0b10".dup, 2) == 0b10);
        assert(parse("0o10".dup, 8) == 010);

        // revised tests
        assert (format(tmp, 10, "d".dup) == "10".dup);
        assert (format(tmp, -10, "d".dup) == "-10".dup);

        assert (format(tmp, 10L, "u".dup) == "10".dup);
        assert (format(tmp, 10L, "U".dup) == "10".dup);
        assert (format(tmp, 10L, "g".dup) == "10".dup);
        assert (format(tmp, 10L, "G".dup) == "10".dup);
        assert (format(tmp, 10L, "o".dup) == "12".dup);
        assert (format(tmp, 10L, "O".dup) == "12".dup);
        assert (format(tmp, 10L, "b".dup) == "1010".dup);
        assert (format(tmp, 10L, "B".dup) == "1010".dup);
        assert (format(tmp, 10L, "x".dup) == "a".dup);
        assert (format(tmp, 10L, "X".dup) == "A".dup);

        assert (format(tmp, 10L, "d+".dup) == "+10".dup);
        assert (format(tmp, 10L, "d ".dup) == " 10".dup);
        assert (format(tmp, 10L, "d#".dup) == "10".dup);
        assert (format(tmp, 10L, "x#".dup) == "0xa".dup);
        assert (format(tmp, 10L, "X#".dup) == "0XA".dup);
        assert (format(tmp, 10L, "b#".dup) == "0b1010".dup);
        assert (format(tmp, 10L, "o#".dup) == "0o12".dup);

        assert (format(tmp, 10L, "d1".dup) == "10".dup);
        assert (format(tmp, 10L, "d8".dup) == "00000010".dup);
        assert (format(tmp, 10L, "x8".dup) == "0000000a".dup);
        assert (format(tmp, 10L, "X8".dup) == "0000000A".dup);
        assert (format(tmp, 10L, "b8".dup) == "00001010".dup);
        assert (format(tmp, 10L, "o8".dup) == "00000012".dup);

        assert (format(tmp, 10L, "d1#".dup) == "10".dup);
        assert (format(tmp, 10L, "d6#".dup) == "000010".dup);
        assert (format(tmp, 10L, "x6#".dup) == "0x00000a".dup);
        assert (format(tmp, 10L, "X6#".dup) == "0X00000A".dup);

        char[8] tmp1;
        assert (format(tmp1, 10L, "b12#".dup) == "0b001010".dup);
        assert (format(tmp1, 10L, "o12#".dup) == "0o000012".dup);
        }
}

/******************************************************************************

******************************************************************************/

debug (Integer)
{
        import tango.io.Stdout;

        void main()
        {
                char[8] tmp;

                Stdout.formatln ("d '{}'", format(tmp, 10));
                Stdout.formatln ("d '{}'", format(tmp, -10));

                Stdout.formatln ("u '{}'", format(tmp, 10L, "u"));
                Stdout.formatln ("U '{}'", format(tmp, 10L, "U"));
                Stdout.formatln ("g '{}'", format(tmp, 10L, "g"));
                Stdout.formatln ("G '{}'", format(tmp, 10L, "G"));
                Stdout.formatln ("o '{}'", format(tmp, 10L, "o"));
                Stdout.formatln ("O '{}'", format(tmp, 10L, "O"));
                Stdout.formatln ("b '{}'", format(tmp, 10L, "b"));
                Stdout.formatln ("B '{}'", format(tmp, 10L, "B"));
                Stdout.formatln ("x '{}'", format(tmp, 10L, "x"));
                Stdout.formatln ("X '{}'", format(tmp, 10L, "X"));

                Stdout.formatln ("d+ '{}'", format(tmp, 10L, "d+"));
                Stdout.formatln ("ds '{}'", format(tmp, 10L, "d "));
                Stdout.formatln ("d# '{}'", format(tmp, 10L, "d#"));
                Stdout.formatln ("x# '{}'", format(tmp, 10L, "x#"));
                Stdout.formatln ("X# '{}'", format(tmp, 10L, "X#"));
                Stdout.formatln ("b# '{}'", format(tmp, 10L, "b#"));
                Stdout.formatln ("o# '{}'", format(tmp, 10L, "o#"));

                Stdout.formatln ("d1 '{}'", format(tmp, 10L, "d1"));
                Stdout.formatln ("d8 '{}'", format(tmp, 10L, "d8"));
                Stdout.formatln ("x8 '{}'", format(tmp, 10L, "x8"));
                Stdout.formatln ("X8 '{}'", format(tmp, 10L, "X8"));
                Stdout.formatln ("b8 '{}'", format(tmp, 10L, "b8"));
                Stdout.formatln ("o8 '{}'", format(tmp, 10L, "o8"));

                Stdout.formatln ("d1# '{}'", format(tmp, 10L, "d1#"));
                Stdout.formatln ("d6# '{}'", format(tmp, 10L, "d6#"));
                Stdout.formatln ("x6# '{}'", format(tmp, 10L, "x6#"));
                Stdout.formatln ("X6# '{}'", format(tmp, 10L, "X6#"));

                Stdout.formatln ("b12# '{}'", format(tmp, 10L, "b12#"));
                Stdout.formatln ("o12# '{}'", format(tmp, 10L, "o12#")).newline;

                Stdout.formatln (consume("10"));
                Stdout.formatln (consume("0x1f"));
                Stdout.formatln (consume("0.123"));
                Stdout.formatln (consume("0.123", true));
                Stdout.formatln (consume("0.123e-10", true)).newline;

                Stdout.formatln (consume("10  s"));
                Stdout.formatln (consume("0x1f   s"));
                Stdout.formatln (consume("0.123  s"));
                Stdout.formatln (consume("0.123  s", true));
                Stdout.formatln (consume("0.123e-10  s", true)).newline;
        }
}




/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005

        author:         Kris

        A set of functions for converting between string and floating-
        point values.

        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import Float = tango.text.convert.Float;

        auto f = Float.parse ("3.14159");
        ---
        
*******************************************************************************/

module tango.text.convert.Float;

private import tango.core.Exception;

private extern (C) real log10l (real x);
private extern (C) double log10 (double x);

/******************************************************************************

        select a version
                
******************************************************************************/

version (DavidGay)
         private alias real NumType;
   else
      private alias real NumType;

/******************************************************************************

        Constants
                
******************************************************************************/

private enum 
{
        Dec = 2,                // default decimal places
        Exp = 10,               // default switch to scientific notation
}

/******************************************************************************

        Convert a formatted string of digits to a floating-point
        number. Throws an exception where the input text is not
        parsable in its entirety.
        
******************************************************************************/

NumType toFloat(T) (T[] src)
{
        uint len;

        auto x = parse (src, &len);
        if (len < src.length || len == 0)
            throw new IllegalArgumentException ("Float.toFloat :: invalid number");
        return x;
}

/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

char[] toString (NumType d, uint decimals=Dec, int e=Exp)
{
        char[64] tmp = void;
        
        return format (tmp, d, decimals, e).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

wchar[] toString16 (NumType d, uint decimals=Dec, int e=Exp)
{
        wchar[64] tmp = void;
        
        return format (tmp, d, decimals, e).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

dchar[] toString32 (NumType d, uint decimals=Dec, int e=Exp)
{
        dchar[64] tmp = void;
        
        return format (tmp, d, decimals, e).dup;
}
               
/******************************************************************************

        Truncate trailing '0' and '.' from a string, such that 200.000 
        becomes 200, and 20.10 becomes 20.1

        Returns a potentially shorter slice of what you give it.

******************************************************************************/

T[] truncate(T) (T[] s)
{
        auto tmp = s;
        int i = tmp.length;
        foreach (int idx, T c; tmp)
                 if (c is '.')
                     while (--i >= idx)
                            if (tmp[i] != '0')
                               {  
                               if (tmp[i] is '.')
                                   --i;
                               s = tmp [0 .. i+1];
                               while (--i >= idx)
                                      if (tmp[i] is 'e')
                                          return tmp;
                               break;
                               }
        return s;
}

/******************************************************************************

        Extract a sign-bit

******************************************************************************/

private bool negative (NumType x)
{
        static if (NumType.sizeof is 4) 
                   return ((*cast(uint *)&x) & 0x8000_0000) != 0;
        else
           static if (NumType.sizeof is 8) 
                      return ((*cast(ulong *)&x) & 0x8000_0000_0000_0000) != 0;
                else
                   {
                   auto pe = cast(ubyte *)&x;
                   return (pe[9] & 0x80) != 0;
                   }
}


/******************************************************************************

        David Gay's extended conversions between string and floating-point
        numeric representations. Use these where you need extended accuracy
        for convertions. 

        Note that this class requires the attendent file dtoa.c be compiled 
        and linked to the application.

******************************************************************************/

version (DavidGay)
{
        extern(C)
        {
        // these should be linked in via dtoa.c
        double strtod (char* s00, char** se);
        char*  dtoa (double d, int mode, int ndigits, int* decpt, int* sign, char** rve);
        }

        /**********************************************************************

                Convert a floating-point number to a string. Parameter 'mode'
                should be specified thusly:

                The e parameter controls the number of exponent places emitted, 
                and can thus control where the output switches to the scientific 
                notation. For example, setting e=2 for 0.01 or 10.0 would result
                in normal output. Whereas setting e=1 would result in both those
                values being rendered in scientific notation instead. Setting e
                to 0 forces that notation on for everything.

        **********************************************************************/

        T[] format(T, D=double, U=uint) (T[] dst, D x, U decimals=Dec, U e=Exp)
        {return format!(T)(dst, x, decimals, e);}

        T[] format(T) (T[] dst, NumType x, uint decimals=Dec, uint e=Exp)
        {
                char*   end,
                        str;
                int     sign,
                        decpt,
                        mode=5;

                if (x is 0)
                    return "0";

                // test exponent to determine mode
                auto exp = cast(int) log10l (x < 0 ? -x : x);
                if (exp < 0)
                    exp = -exp;
                if (exp > e)
                    mode = 2, ++decimals;

                str = dtoa (cast(double) x, mode, decimals, &decpt, &sign, &end);
                auto len = end - str;
                auto p = dst.ptr;

                if (sign)
                    *p++ = '-';

                if (decpt is 9999)
                    while (len--)
                           *p++ = *str++;
                else
                   {
                   if (exp > e)
                      {
                      *p++ = *str++;
                      if (str !is end)
                         {
                         *p++ = '.';
                         while (str < end)
                                *p++ = *str++;
                         }
                      *p++ = 'e';
                      *p++ = (decpt <= 0) ? '-' : '+';
   
                      if (exp >= 100)
                         {
                         *p++ = exp / 100 + '0';
                         exp %= 100;
                         }
                      *p++ = exp / 10 + '0';
                      *p++ = exp % 10 + '0';
                      }
                   else
                      {
                      if (decpt <= 0)
                          *p++ = '0';
                      else
                         while (decpt > 0)
                               {
                               *p++ = (str < end) ? *str++ : '0';
                               --decpt;
                               }

                      if (str < end)
                         {
                         *p++ = '.';
                         while (decpt < 0)
                               {
                               *p++ = '0';
                               ++decpt;
                               }
                         while (str < end)
                                *p++ = *str++;
                         }
                      } 
                   }

                // stuff a C terminator in there too ...
                *p = 0;
                return dst[0..(p - dst.ptr)];
        }

        /**********************************************************************

                Convert a formatted string of digits to a floating-
                point number. 

        **********************************************************************/

        NumType parse (char[] src, uint* ate=null)
        {
                char* end;

                auto value = strtod (src.ptr, &end);
                assert (end <= src.ptr + src.length);
                if (ate)
                    *ate = end - src.ptr;
                return value;
        }

        /**********************************************************************

                Convert a formatted string of digits to a floating-
                point number.

        **********************************************************************/

        NumType parse (wchar[] src, uint* ate=null)
        {
                // cheesy hack to avoid pre-parsing :: max digits == 100
                char[100] tmp = void;
                auto p = tmp.ptr;
                auto e = p + tmp.length;
                foreach (c; src)
                         if (p < e && (c & 0x80) is 0)
                             *p++ = c;
                return parse (tmp[0..p-tmp.ptr], ate);
        }

        /**********************************************************************

                Convert a formatted string of digits to a floating-
                point number. 

        **********************************************************************/

        NumType parse (dchar[] src, uint* ate=null)
        {
                // cheesy hack to avoid pre-parsing :: max digits == 100
                char[100] tmp = void;
                auto p = tmp.ptr;
                auto e = p + tmp.length;
                foreach (c; src)
                         if (p < e && (c & 0x80) is 0)
                             *p++ = c;
                return parse (tmp[0..p-tmp.ptr], ate);
        }
}

else

{
version = strip;

private import Integer = tango.text.convert.Integer;

/******************************************************************************

        Convert a float to a string. This produces pretty good results
        for the most part, though one should use David Gay's dtoa package
        for best accuracy.

        Note that the approach first normalizes a base10 mantissa, then
        pulls digits from the left side whilst emitting them (rightward)
        to the output.

        The e parameter controls the number of exponent places emitted, 
        and can thus control where the output switches to the scientific 
        notation. For example, setting e=2 for 0.01 or 10.0 would result
        in normal output. Whereas setting e=1 would result in both those
        values being rendered in scientific notation instead. Setting e
        to 0 forces that notation on for everything.

        TODO: this should be replaced, as it is not sufficiently accurate 

******************************************************************************/

T[] format(T, D=double, U=uint) (T[] dst, D x, U decimals=Dec, int e=Exp)
{return format!(T)(dst, x, decimals, e);}

T[] format(T) (T[] dst, NumType x, uint decimals=Dec, int e=Exp)
{
        static T[] inf = "-Infinity";
        static T[] nan = "-NaN";

        // strip digits from the left of a normalized base-10 number
        static int toDigit (ref NumType v, ref int count)
        {
                int digit;

                // Don't exceed max digits storable in a real
                // (-1 because the last digit is not always storable)
                if (--count <= 0)
                    digit = 0;
                else
                   {
                   // remove leading digit, and bump
                   digit = cast(int) v;
                   v = (v - digit) * 10.0;
                   }
                return digit + '0';
        }

        // extract the sign
        bool sign = negative (x);
        if (sign)
            x = -x;

        if (x !<>= x)
            return sign ? nan : nan[1..$];

        if (x is x.infinity)
            return sign ? inf : inf[1..$];

        // assume no exponent
        int exp = 0;

        // don't scale if zero
        if (x > 0.0)
           {
           // extract base10 exponent
           exp = cast(int) log10l (x);

           // round up a bit
           auto d = decimals;
           if (exp < 0)
               d -= exp;
           x += 0.5 / pow10 (d);

           // extract base10 exponent
           exp = cast(int) log10l (x);

           // normalize base10 mantissa (0 < m < 10)
           int len = exp;
           if (exp < 0)
               x *= pow10 (len = -exp);
           else
              x /= pow10 (exp);

           // switch to short display if not enough space
           if (len >= e)
               e = 0; 
           }

        T* p = dst.ptr;
        int count = NumType.dig;

        // emit sign
        if (sign)
            *p++ = '-';

        // are we doing +/-exp format?
        if (e is 0)
           {
           assert (dst.length > decimals + 7);

           // emit first digit, and decimal point
           *p++ = cast(T)toDigit (x, count);
           if (decimals)
              {
              *p++ = '.';

              // emit rest of mantissa
              while (decimals-- > 0)
                     *p++ = cast(T) toDigit (x, count);
              
              version (strip)
                      {
                      while (*(p-1) is '0')
                             --p;
                      if (*(p-1) is '.')
                           --p;
                      }
              }

           // emit exponent, if non zero
           if (exp)
              {
              *p++ = 'e';
              if (exp < 0)
                 {
                 exp = -exp;
                 *p++ = '-';
                 }
              else
                 *p++ = '+';

              if (exp >= 1000)
                 {
                 *p++ = cast(T)((exp/1000) + '0');
                 exp %= 1000;
                 *p++ = cast(T)((exp/100) + '0');
                 exp %= 100;
                 }
              else
                 if (exp >= 100)
                    {
                    *p++ = cast(T)((exp/100) + '0');
                    exp %= 100;
                    }

              *p++ = cast(T)((exp/10) + '0');
              *p++ = cast(T)((exp%10) + '0');
              }
           }
        else
           {
           assert (dst.length >= (((exp < 0) ? 0 : exp) + decimals + 1));

           // if fraction only, emit a leading zero
           if (exp < 0)
               *p++ = '0';
           else
              // emit all digits to the left of point
              for (; exp >= 0; --exp)
                     *p++ = cast(T)toDigit (x, count);

           // emit point
           if (decimals)
              {
              *p++ = '.';

              // emit leading fractional zeros?
              for (++exp; exp < 0 && decimals > 0; --decimals, ++exp)
                   *p++ = '0';

              // output remaining digits, if any. Trailing
              // zeros are also returned from toDigit()
              while (decimals-- > 0)
                     *p++ = cast(T) toDigit (x, count);

              version (strip)
                      {
                      while (*(p-1) is '0')
                             --p;
                      if (*(p-1) is '.')
                           --p;
                      }
              }
           }

        return dst [0..(p - dst.ptr)];
}


/******************************************************************************

        Convert a formatted string of digits to a floating-point number.
        Good for general use, but use David Gay's dtoa package if serious
        rounding adjustments should be applied.

******************************************************************************/

NumType parse(T) (T[] src, uint* ate=null)
{
        T               c;
        T*              p;
        int             exp;
        bool            sign;
        uint            radix;
        NumType         value = 0.0;

        static bool match (T* aa, T[] bb)
        {
                foreach (b; bb)
                        {
                        auto a = *aa++;
                        if (a >= 'A' && a <= 'Z')
                            a += 'a' - 'A';
                        if (a != b)
                            return false;
                        }
                return true;
        }

        // remove leading space, and sign
        p = src.ptr + Integer.trim (src, sign, radix);

        // bail out if the string is empty
        if (src.length is 0 || p > &src[$-1])
            return NumType.nan;
        c = *p;

        // handle non-decimal representations
        if (radix != 10)
           {
           long v = Integer.parse (src, radix, ate); 
           return cast(NumType) v;
           }

        // set begin and end checks
        auto begin = p;
        auto end = src.ptr + src.length;

        // read leading digits; note that leading
        // zeros are simply multiplied away
        while (c >= '0' && c <= '9' && p < end)
              {
              value = value * 10 + (c - '0');
              c = *++p;
              }

        // gobble up the point
        if (c is '.' && p < end)
            c = *++p;

        // read fractional digits; note that we accumulate
        // all digits ... very long numbers impact accuracy
        // to a degree, but perhaps not as much as one might
        // expect. A prior version limited the digit count,
        // but did not show marked improvement. For maximum
        // accuracy when reading and writing, use David Gay's
        // dtoa package instead
        while (c >= '0' && c <= '9' && p < end)
              {
              value = value * 10 + (c - '0');
              c = *++p;
              --exp;
              } 

        // did we get something?
        if (p > begin)
           {
           // parse base10 exponent?
           if ((c is 'e' || c is 'E') && p < end )
              {
              uint eaten;
              exp += Integer.parse (src[(++p-src.ptr) .. $], 0, &eaten);
              p += eaten;
              }

           // adjust mantissa; note that the exponent has
           // already been adjusted for fractional digits
           if (exp < 0)
               value /= pow10 (-exp);
           else
              value *= pow10 (exp);
           }
        else
           if (end - p >= 3)
               switch (*p)
                      {
                      case 'I': case 'i':
                           if (match (p+1, "nf"))
                              {
                              value = value.infinity;
                              p += 3;
                              if (end - p >= 5 && match (p, "inity"))
                                  p += 5;
                              }
                           break;

                      case 'N': case 'n':
                           if (match (p+1, "an"))
                              {
                              value = value.nan;
                              p += 3;
                              }
                           break;
                      }

        // set parse length, and return value
        if (ate)
            *ate = p - src.ptr;

        if (sign)
            value = -value;
        return value;
}

/******************************************************************************

        Internal function to convert an exponent specifier to a floating
        point value.

******************************************************************************/

private NumType pow10 (uint exp)
{
        static  NumType[] Powers = 
                [
                1.0e1L,
                1.0e2L,
                1.0e4L,
                1.0e8L,
                1.0e16L,
                1.0e32L,
                1.0e64L,
                1.0e128L,
                1.0e256L,
                1.0e512L,
                1.0e1024L,
                1.0e2048L,
                1.0e4096L,
                1.0e8192L,
                ];

        if (exp >= 16384)
            throw new IllegalArgumentException ("Float.pow10 :: exponent too large");

        NumType mult = 1.0;
        foreach (NumType power; Powers)
                {
                if (exp & 1)
                    mult *= power;
                if ((exp >>= 1) is 0)
                     break;
                }
        return mult;
}
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
        unittest
        {
                char[164] tmp;

                auto f = parse ("nan");
                assert (format(tmp, f) == "nan");
                f = parse ("inf");
                assert (format(tmp, f) == "inf");
                f = parse ("-nan");
                assert (format(tmp, f) == "-nan");
                f = parse (" -inf");
                assert (format(tmp, f) == "-inf");

                assert (format (tmp, 3.14159, 6) == "3.141590");
                assert (format (tmp, 3.14159, 4) == "3.1416");
                assert (parse ("3.5") == 3.5);
                assert (format(tmp, parse ("3.14159"), 6) == "3.141590");
        }
}


debug (Float)
{
        import tango.io.Console;

        void main() 
        {
                char[500] tmp;

                Cout (format(tmp, double.max)).newline;
                Cout (format(tmp, -double.nan)).newline;
                Cout (format(tmp, -double.infinity)).newline;
                Cout (format(tmp, toFloat("nan"w))).newline;
                Cout (format(tmp, toFloat("-nan"d))).newline;
                Cout (format(tmp, toFloat("inf"))).newline;
                Cout (format(tmp, toFloat("-inf"))).newline;
                Cout (format(tmp, toFloat ("0.000000e+00"))).newline;
                Cout (format(tmp, toFloat("0x8000000000000000"))).newline;
                Cout (format(tmp, 1)).newline;
                Cout (format(tmp, -0)).newline;
                Cout (format(tmp, 0.000001)).newline.newline;

                Cout (format(tmp, 3.14159, 6, 0)).newline;
                Cout (format(tmp, 3.0e10, 6, 3)).newline;
                Cout (format(tmp, 314159, 6)).newline;
                Cout (format(tmp, 314159123213, 6, 15)).newline;
                Cout (format(tmp, 3.14159, 6, 2)).newline;
                Cout (format(tmp, 3.14159, 3, 2)).newline;
                Cout (format(tmp, 0.00003333, 6, 2)).newline;
                Cout (format(tmp, 0.00333333, 6, 3)).newline;
                Cout (format(tmp, 0.03333333, 6, 2)).newline;
                Cout.newline;

                Cout (format(tmp, -3.14159, 6, 0)).newline;
                Cout (format(tmp, -3e100, 6, 3)).newline;
                Cout (format(tmp, -314159, 6)).newline;
                Cout (format(tmp, -314159123213, 6, 15)).newline;
                Cout (format(tmp, -3.14159, 6, 2)).newline;
                Cout (format(tmp, -3.14159, 2, 2)).newline;
                Cout (format(tmp, -0.00003333, 6, 2)).newline;
                Cout (format(tmp, -0.00333333, 6, 3)).newline;
                Cout (format(tmp, -0.03333333, 6, 2)).newline;
                Cout.newline;

                Cout (format(tmp, -3.0e100, 6, 3)).newline;
                Cout (truncate(format(tmp, 1.0, 6))).newline;
                Cout (truncate(format(tmp, 30, 6))).newline;
                Cout (truncate(format(tmp, 3.14159, 6, 0))).newline;
                Cout (truncate(format(tmp, 3e100, 6, 3))).newline;
                Cout (truncate(format(tmp, 314159, 6))).newline;
                Cout (truncate(format(tmp, 314159123213, 6, 15))).newline;
                Cout (truncate(format(tmp, 3.14159, 6, 2))).newline;
                Cout (truncate(format(tmp, 3.14159, 4, 2))).newline;
                Cout (truncate(format(tmp, 0.00003333, 6, 2))).newline;
                Cout (truncate(format(tmp, 0.00333333, 6, 3))).newline;
                Cout (truncate(format(tmp, 0.03333333, 6, 2))).newline;
                Cout (format(tmp, double.max, 6)).newline;
                Cout (format(tmp, -1)).newline;
                Cout (format(tmp, toFloat(format(tmp, -1)))).newline;
                Cout.newline;
        }
}

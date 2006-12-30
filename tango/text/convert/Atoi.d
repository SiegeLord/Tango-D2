/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

*******************************************************************************/

module tango.text.convert.Atoi;

/******************************************************************************

******************************************************************************/

struct AtoiT(T)
{
        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Template type must be char, wchar, or dchar");


        /**********************************************************************
        
                Strip leading whitespace, extract an optional +/- sign,
                and an optional radix prefix. This can be used as a
                precursor to the conversion of digits into a number.

                Returns the number of matching characters.

        **********************************************************************/

        static uint trim (T[] digits, inout bool sign, inout uint radix)
        {
                T       c;
                T*      p = digits.ptr;
                int     len = digits.length;

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
                if (c is '0' && len > 1)
                    switch (*++p)
                           {
                           case 'x':
                           case 'X':
                                ++p;
                                radix = 16;
                                break;

                           case 'b':
                           case 'B':
                                ++p;
                                radix = 2;
                                break;

                           case 'o':
                           case 'O':
                                ++p;
                                radix = 8;
                                break;

                           default:
                                break;
                           } 

                // return number of characters eaten
                return (p - digits.ptr);
        }

        /**********************************************************************

                Convert the provided 'digits' into an integer value,
                without looking for a sign or radix.

                Returns the value and updates 'ate' with the number
                of characters parsed.

        **********************************************************************/

        static ulong convert (T[] digits, int radix=10, uint* ate=null)
        {
                uint  eaten;
                ulong value;

                foreach (T c; digits)
                        {
                        if (c >= '0' && c <= '9')
                           {}
                        else
                           if (c >= 'a' && c <= 'f')
                               c -= 39;
                           else
                              if (c >= 'A' && c <= 'F')
                                  c -= 7;
                              else
                                 break;

                        value = value * radix + (c - '0');
                        ++eaten;
                        }

                if (ate)
                    *ate = eaten;

                return value;
        }

        /**********************************************************************

                Parse an integer value from the provided 'digits' string.
                The string is inspected for a sign and radix, where the
                latter will override the default radix provided.

                Returns the parsed value and updates 'ate' with the number
                of characters consumed

        **********************************************************************/

        static long parse (T[] digits, uint radix=10, uint* ate=null)
        {
                bool sign;

                auto eaten = trim (digits, sign, radix);
                auto value = convert (digits[eaten..$], radix, ate);

                if (ate)
                    *ate += eaten;

                return cast(long) (sign ? -value : value);
        }
}


/******************************************************************************

        Default instance of this template

******************************************************************************/

alias AtoiT!(char) Atoi;


debug (UnitTest)
{
unittest{

    assert( Atoi.parse( "0" ) ==  0 );
    assert( Atoi.parse( "1" ) ==  1 );
    assert( Atoi.parse( "-1" ) ==  -1 );
    assert( Atoi.parse( "+1" ) ==  1 );

    // numerical limits
    assert( Atoi.parse( "-2147483648" ) == int.min );
    assert( Atoi.parse(  "2147483647" ) == int.max );
    assert( Atoi.parse(  "4294967295" ) == uint.max );

    assert( Atoi.parse( "-9223372036854775808" ) == long.min );
    assert( Atoi.parse( "9223372036854775807" ) == long.max );
    assert( Atoi.parse( "18446744073709551615" ) == ulong.max );

    // hex
    assert( Atoi.parse( "a", 16 ) == 0x0A );
    assert( Atoi.parse( "b", 16 ) == 0x0B );
    assert( Atoi.parse( "c", 16 ) == 0x0C );
    assert( Atoi.parse( "d", 16 ) == 0x0D );
    assert( Atoi.parse( "e", 16 ) == 0x0E );
    assert( Atoi.parse( "f", 16 ) == 0x0F );
    assert( Atoi.parse( "A", 16 ) == 0x0A );
    assert( Atoi.parse( "B", 16 ) == 0x0B );
    assert( Atoi.parse( "C", 16 ) == 0x0C );
    assert( Atoi.parse( "D", 16 ) == 0x0D );
    assert( Atoi.parse( "E", 16 ) == 0x0E );
    assert( Atoi.parse( "F", 16 ) == 0x0F );
    assert( Atoi.parse( "FFFF", 16 ) == ushort.max );
    assert( Atoi.parse( "ffffFFFF", 16 ) == uint.max );
    assert( Atoi.parse( "ffffFFFFffffFFFF", 16 ) == ulong.max );
    // oct
    assert( Atoi.parse( "55", 8 ) == 055 );
    assert( Atoi.parse( "100", 8 ) == 0100 );
    // bin
    assert( Atoi.parse( "10000", 2 ) == 0x10 );
    // trim
    assert( Atoi.parse( "    \t20" ) == 20 );
    assert( Atoi.parse( "    \t-20" ) == -20 );
    assert( Atoi.parse( "-    \t 20" ) == -20 );
    // recognise radix prefix
    assert( Atoi.parse( "0xFFFF" ) == ushort.max );
    assert( Atoi.parse( "0XffffFFFF" ) == uint.max );
    assert( Atoi.parse( "0o55", 8 ) == 055 );
    assert( Atoi.parse( "0O55", 8 ) == 055 );
    assert( Atoi.parse( "0b10000", 2 ) == 0x10 );
    assert( Atoi.parse( "0B10000", 2 ) == 0x10 );

    // regression tests

    // ticket #90
    char[] str = "0x";
    assert( Atoi.parse( str[0..1] ) ==  0 );

}
}





/*******************************************************************************

        @file Atoi.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version, Nov 2005

        @author         Kris


*******************************************************************************/

module tango.convert.Atoi;

/******************************************************************************

******************************************************************************/

struct AtoiT(T)
{
        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Template type must be char, wchar, or dchar");


        /**********************************************************************
        
                Strip leading whitespace, extract an optional +/- sign,
                and an optional radix prefix.

                This can be used as a precursor to the conversion of digits
                into a number.

                Returns the number of matching characters.

        **********************************************************************/

        static uint trim (T[] digits, out bool sign, out uint radix)
        {
                T       c;
                T*      p = digits;
                int     len = digits.length;

                // set default radix
                radix = 10;

                // strip off whitespace and sign characters
                for (c = *p; len; c = *++p, --len)
                     if (c == ' ' || c == '\t')
                        {}
                     else
                        if (c == '-')
                            sign = true;
                        else
                           if (c == '+')
                               sign = false;
                        else
                           break;

                // strip off a radix specifier also?
                if (c == '0' && len)
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
                ulong value;
                uint  eaten;

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

                Parse an integer value from the provided 'src' string. The
                string is also inspected for a sign and radix (defaults to 
                10), which can be overridden by setting 'radix' to non-zero. 

                Returns the value and updates 'ate' with the number of
                characters parsed.

        **********************************************************************/

        static long parse (T[] digits, uint radix=0, uint* ate=null)
        {
                uint rdx;
                bool sign;

                int eaten = trim (digits, sign, rdx);

                if (radix)
                    rdx = radix;

                ulong result = convert (digits[eaten..length], rdx, ate);

                if (ate)
                    ate += eaten;

                return cast(long) (sign ? -result : result);
        }
}


/******************************************************************************

        Default instance of this template

******************************************************************************/

alias AtoiT!(char) Atoi;

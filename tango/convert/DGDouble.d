/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Feb 2005

        author:         Kris

*******************************************************************************/

module tango.convert.DGDouble;

/*******************************************************************************
        
        External requirements for this package    

*******************************************************************************/

extern (C)
{
        // these should be linked in via dtoa.c
        char*  dtoa (double d, int mode, int ndigits, int* decpt, int* sign, char** rve);
        double atod (char* s00, int len, char** se);


        // callback for dtoa allocation function
        void* __dToaMalloc (uint size)
        {
                throw new Exception ("unexpected memory request from DGDouble");
                //return new byte[2048];
        }
}


/******************************************************************************

        David Gay's extended conversions between string and floating-point
        numeric representations. Use these where you need extended accuracy
        for convertions. 

        Note that this class requires the attendent file dtoa.c be compiled 
        and linked to the application.

        While these functions are all static, they are encapsulated within 
        a class inheritance to preserve some namespace cohesion. One might 
        use structs for encapsualtion instead, but then inheritance would 
        be lost. Note that the root class, Styled, is abstract to prevent 
        accidental instantiation of these classes.

******************************************************************************/

struct DGDouble
{
        /**********************************************************************

                Convert a formatted string of digits to a floating-
                point number. 

        **********************************************************************/

        final static double parse (char[] src, uint* ate=null)
        {
                char* end;

                double x = atod (src.ptr, src.length, &end);
                if (ate)
                    *ate = end - src.ptr;
                return x;
        }


        /**********************************************************************

                Signature for use with Format module

        **********************************************************************/

        static final char[] format (char[] dst, double x, uint decimals, bool scientific)
        {
                return format (dst, x, decimals, scientific, 3);
        }


        /**********************************************************************

                Convert a floating-point number to a string. Parameter 'mode'
                should be specified thusly:

		0 ==> shortest string that yields d when read in
			and rounded to nearest.

		1 ==> like 0, but with Steele & White stopping rule;
			e.g. with IEEE P754 arithmetic , mode 0 gives
			1e23 whereas mode 1 gives 9.999999999999999e22.

		2 ==> max(1,ndigits) significant digits.  This gives a
			return value similar to that of ecvt, except
			that trailing zeros are suppressed.

		3 ==> through ndigits past the decimal point.  This
			gives a return value similar to that from fcvt,
			except that trailing zeros are suppressed, and
			ndigits can be negative.

		4,5 ==> similar to 2 and 3, respectively, but (in
			round-nearest mode) with the tests of mode 0 to
			possibly return a shorter string that rounds to d.
			With IEEE arithmetic and compilation with
			-DHonor_FLT_ROUNDS, modes 4 and 5 behave the same
			as modes 2 and 3 when FLT_ROUNDS != 1.

		6-9 ==> Debugging modes similar to mode - 4:  don't try
			fast floating-point estimate (if applicable).

        **********************************************************************/

        static final char[] format (char[] dst, double x, uint decimals = 6, bool scientific = false, uint mode=3)
        in {
           assert (dst.length >= 32);
           }
        body
        {
                char*   end,
                        str;
                int     sign,
                        decpt;
                  
                str = dtoa (x, mode, decimals, &decpt, &sign, &end);
                
                char *p = dst;
                int len = end - str;

                if (sign)
                    *p++ = '-';

                if (decpt == 9999)
                    p[0..len] = str[0..len];
                else
                   {
                   int exp = decpt - 1;
                   sign = 0;
                   if (exp < 0)
                      {
                      exp = -exp;
                      sign = 1;
                      }

                   // force scientific format if too long ...
                   if ((exp + len + 2) > dst.length)
                        scientific = true;

                   if (scientific)
                      {
                      *p++ = *str++;
                      *p++ = '.';
                      while (str < end)
                             *p++ = *str++;
                      *p++ = 'e';
                      *p++ = (sign) ? '-' : '+';
   
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
                         {
                         while (decpt > 0)
                               {
                               *p++ = (str < end) ? *str++ : '0';
                               --decpt;
                               }
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
                         
                return dst[0..(p - dst.ptr)];
        }
}



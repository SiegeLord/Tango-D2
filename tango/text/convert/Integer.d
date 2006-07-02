/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

*******************************************************************************/

module tango.text.convert.Integer;

private import tango.text.convert.Atoi;

/******************************************************************************

        A set of functions for converting between string and integer 
        values. 

******************************************************************************/

struct IntegerT(T)
{       
        private alias AtoiT!(T) Atoi;

        /**********************************************************************

                Format identifiers 

        **********************************************************************/

        enum Format 
        {
                Integer  = 'd', 
                String   = 's',
                Binary   = 'b', 
                Octal    = 'o', 
                Hex      = 'x', 
                HexUpper = 'X', 
                Unsigned = 'u', 
        }

        /**********************************************************************

                Style flags 

        **********************************************************************/

        enum Flags 
        {
                None    = 0,                    // no flags
                Fill    = 1,                    // do some kind of padding
                Left    = Fill << 1,            // left justify
                Prec	= Left << 1,            // precision was provided
                Hash	= Prec << 1,            // prefix integer with type
                Space	= Hash << 1,            // prefix with space
                Zero	= Space << 1,           // prefix integer with zero
                Sign	= Zero << 1,            // unused
                Comma	= Sign << 1,            // unused
                Plus	= Comma << 1,           // prefix decimal with '+'
                Array	= Plus << 1,            // array flag
        }


        /***********************************************************************
        
                Format numeric values into the provided output buffer. The
                traditional printf() conversion specifiers are adhered to,
                and the following types are supported:

                u - unsigned decimal
                d - signed decimal
                o - octal
                x - lowercase hexadecimal
                X - uppercase hexadecimal
                b - binary

                Modifiers supported include:

                #      : prefix the conversion with a type identifier
                +      : prefix positive decimals with a '+'
                space  : prefix positive decimals with one space
                0      : left-pad the number with zeros

                These modifiers are specifed via the 'flags' provided, 
                and are represented via these identifiers:

                #     : Flags.Hash
                +     : Flags.Plus
                space : Flags.Space
                0     : Flags.Zero

                The provided 'dst' buffer should be sufficiently large
                enough to house the output. A 64-element array is often
                the maximum required (for a padded binary 64-bit string)

        ***********************************************************************/

        final static T[] format (T[] dst, long i, Format fmt = Format.Integer, Flags flags = Flags.None)
        {
                T[]     prefix;
                int     len = dst.length;
                   
                // must have some buffer space to operate within! 
                if (len)
                   {
                   uint radix;
                   T[]  numbers = "0123456789abcdef";

                   // pre-conversion setup
                   switch (fmt)
                          {
                          case Format.Integer:
                          case Format.String:
                               if (i < 0)
                                  {
                                  prefix = "-";
                                  i = -i;
                                  }
                               else
                                  if (flags & Flags.Space)
                                      prefix = " ";
                                  else
                                     if (flags & Flags.Plus)
                                         prefix = "+";
                               // fall through!
                          case Format.Unsigned:
                               radix = 10;
                               break;

                          case Format.Binary:
                               radix = 2;
                               if (flags & Flags.Hash)
                                   prefix = "0b";
                               break;

                          case Format.Octal:
                               radix = 8;
                               if (flags & Flags.Hash)
                                   prefix = "0o";
                               break;

                          case Format.Hex:
                               radix = 16;
                               if (flags & Flags.Hash)
                                   prefix = "0x";
                               break;

                          case Format.HexUpper:
                               radix = 16;
                               numbers = "0123456789ABCDEF";
                               if (flags & Flags.Hash)
                                   prefix = "0X";
                               break;

                          default:
                               // raw output; no formatting
                               if (fmt >= 2 && fmt <= 16)
                                   radix = fmt;
                               else
                                  error ("Integer.format : invalid numeric format identifier '"~cast(char) fmt~
                                         "'. Expected s, u, d, o, x, X, b, or a radix between 2 and 16");
                               break;
                          }
        
                   // convert number to text
                   T* p = dst.ptr + len;
                   if (uint.max >= cast(ulong) i)
                      {
                      uint v = cast (uint) i;
                      do {
                         *--p = numbers[v % radix];
                         } while ((v /= radix) && --len);
                      }
                   else
                      {
                      ulong v = cast (ulong) i;
                      do {
                         *--p = numbers[cast(uint) (v % radix)];
                         } while ((v /= radix) && --len);
                      }
                   }

                // are we about to overflow?
                if (--len < 0 || 0 > (len -= prefix.length))
                    error ("Integer.format : output buffer too small");

                // prefix number with zeros? 
                if (flags & Flags.Zero)
                   {
                   dst [prefix.length .. len + prefix.length] = '0';
                   len = 0;
                   }
                
                // write optional prefix string ...
                dst [len .. len + prefix.length] = prefix[];

                // return slice of provided output buffer
                return dst [len .. dst.length];                               
        } 


        /**********************************************************************

                Parse an integer value from the provided 'src' string. 
                The string is also inspected for a radix (defaults to 10), 
                which can be overridden by setting 'radix' to non-zero. 

                A non-null 'ate' will return the number of characters used
                to construct the returned value.

        **********************************************************************/

        final static long parse (T[] src, uint radix=0, uint* ate=null)
        {
                return Atoi.parse (src, radix, ate);
        }


        /**********************************************************************

                Throw a format error. This is used by a number of other
                modules in this package

        **********************************************************************/

        package final static void error (char[] msg)
        {
                static class FormatException : Exception
                {
                        this (char[] msg)
                        {
                                super (msg);
                        }
                }

                throw new FormatException (msg);
        }
}


/******************************************************************************

******************************************************************************/

alias IntegerT!(char) Integer;


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005

        author:         Kris

*******************************************************************************/

module tango.convert.Format;

private import  tango.core.Vararg;
  
private import  tango.convert.Type,
                tango.convert.Integer;


/******************************************************************************

        Functions for styled, readable, output. See parse() for the 
        list of format specifiers.

******************************************************************************/

struct FormatStructT(T)
{       
        public  alias print opCall;

        private alias IntegerT!(T) Integer;

        private alias Integer.Flags Flags;

        typedef T[] function (T[], double, uint, bool) DblFormat;

        typedef uint delegate (void[], uint type) Emitter;

        private Emitter         sink;           // text emitter
        private int             style,          // character following %
                                width,          // width specifier
                                precision;      // number of decimals
        private Flags           flags;          // format controls
        private T[]             head,           // start of format string
                                tail,           // end of format string
                                meta;           // current format string
        private DblFormat       dFormat;        // floating-point handler
        private T[]             workspace;      // formatting buffer


        private static T[]      Left   = "[",
                                Right  = "]",
                                Comma  = ", ";
        private static T[64]    Spaces = ' ';   // for padding the output

        mixin Type.TextType!(T);

        /**********************************************************************

                Default styles for supported styles. This is used to 
                format discrete values, or those provided without a 
                specified format-string. 

        **********************************************************************/

        private static ubyte DefaultStyle[] = ['s', 's', 'd', 'u', 'd', 
                                               'u', 'd', 'u', 'd', 'u',
                                               'f', 'f', 'f', 's', 's', 
                                               's', 'x', 's'];


        /**********************************************************************

                Configure this Format with an output handler, a
                workspace area, and a floating point handler.
                The latter is optional.

        **********************************************************************/

        public void ctor (Emitter sink, T[] workspace, DblFormat dFormat = null)
        {
                this.sink = sink;
                this.dFormat = dFormat;
                this.workspace = workspace;
        }

        /***********************************************************************
        
                Emit a newline

        ***********************************************************************/

        public int newline ()
        {
                version (Posix)
                         static T[] Newline = "\n";
                   else
                      static T[] Newline = "\r\n";

                return sink (Newline, TextType);
        }

        /***********************************************************************
        
        ***********************************************************************/

        public int print (TypeInfo[] arguments, va_list argptr, bool nl)
        {      
                return print (null, arguments, argptr, nl);
        }

        /***********************************************************************
        
                General purpose va_arg format routine, used by a number of
                classes and structs to emit printf() styled text. 

                This implementation simply converts its arguments into the
                appropriate internal style, and invokes the standard Mango
                style-formatter for each.

                Note that this can handle arrays of type in addition to the
                usual char[] ~ e.g. one can print an array of integers just
                as easily as a single integer.

                See parse() for the list of format specifiers.

        ***********************************************************************/

        public int print (T[] format, TypeInfo[] arguments, va_list argptr, bool nl = false)
        {      
                int length;

                // set the format string
                meta = format;

                // traverse the arguments ...
                foreach (TypeInfo ti; arguments)
                        {
                        uint t = ti.classinfo.name[9];

                        // is this an array style?
                        if (t is 'A')
                           {
                           void[] q = *cast(void[]*) argptr;
                           t = getType (ti.classinfo.name[10]);

                           // print this argument ...
                           length += emit (q.ptr, Type.widths[t] * q.length, t);

                           // bump to next argument ...
                           argptr += (void[]).sizeof;
                           }                
                        else
                           {
                           t = getType (t);
                           int width = Type.widths[t];

                           // print this argument ...
                           length += emit (argptr, width, t);

                           // bump to next argument ...
                           argptr += ((width + int.sizeof - 1) & ~(int.sizeof - 1));
                           }
                        }

                // flush any remaining format text
                if (meta.length)
                   {
                   length += sink (meta, TextType);
                   meta = null;
                   }

                // add an optional newline
                if (nl)
                    length += newline();

                return length;
        }

        /***********************************************************************
        
                Emit a single formatted argument. Format may be null

        ***********************************************************************/

        public int print (T[] format, void* src, uint bytes, uint type)
        {
                meta = format;
                int length = emit (src, bytes, type);

                // flush any remaining format text
                if (meta.length)
                   {
                   length += sink (meta, TextType);
                   meta = null;
                   }
                return length;
        }

        /***********************************************************************
        
                Emit a single formatted argument.

                Note that emit() can handle type-arrays in addition to the
                usual char[]; e.g. one can print an array of integers just
                as easily as a single integer. To support this, a new style
                flag has been introduced to terminate the format string at
                the point of use. That is, the rest of the format string is
                considered to be part of the current format specifier, and
                will be repeated for each array element. For example, the
                format string " %@x," has a preceeding space, a trailing
                comma, and the array flag '@'. This will output an array of 
                numeric values (char, byte, short, int, long, float, double,
                real, pointer) as a set of formatted hexadecimal strings.

                See parse() for the list of format specifiers.

        ***********************************************************************/

        public int emit (void* src, uint bytes, uint type)
        {
                return header(type) + emit(src, bytes, type, style);           
        }                 

        /**********************************************************************

                Throw an error

        **********************************************************************/

        public static void error (char[] msg)
        {
                Integer.error(msg);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private int emit (void* src, uint bytes, uint type, uint style)
        {
                int     iValue;
                long    lValue;
                double  fValue;
                uint    length;

                // get width of elements (note: does not work for bit[])
                int size = Type.widths[type];

                // for all bytes in source ...
                while (bytes)
                      {
                      switch (type)
                             {
                             case Type.Bool:
                                  iValue = *cast(bool*) src;
                                  if (style != 's')
                                      goto int32Format;

                                  static T[] True = "true",
                                             False = "false";

                                  length += sink (iValue ? True : False, TextType);
                                  break;

                             case Type.Byte:
                                  iValue = *cast(byte*) src;
                                  goto int32Format;

                             case Type.UByte:
                                  iValue = *cast(ubyte*) src;
                                  goto int32Format;

                             case Type.Short:
                                  iValue = *cast(short*) src;
                                  goto int32Format;

                             case Type.UShort:
                                  iValue = *cast(ushort*) src;
                                  goto int32Format;

                             case Type.Int:
                             case Type.UInt:
                             case Type.Pointer:
int32:
                                  iValue = *cast(int*) src;
int32Format:
                                  length += emit (cast(long) iValue);
                                  break;

                             case Type.Long:
                             case Type.ULong:
int64:
                                  lValue = *cast(long*) src;
int64Format:
                                  length += emit (lValue);
                                  break;

                             case Type.Float:
                                  if (style is 'x' || 
                                      style is 'X')
                                      goto int32;
                                  fValue = *cast(float*) src;
                                  goto floating;

                             case Type.Double:
                                  if (style is 'x' || 
                                      style is 'X')
                                      goto int64;
                                  fValue = *cast(double*) src;
floating:
                                  length += emit (fValue);
                                  break;

                             case Type.Real:
                                  fValue = *cast(real*) src;
                                  goto floating;

                             case Type.Obj:
                                  char[] tmp = (*cast(Object*) src).toString;
                                  length += emit (tmp.ptr, tmp.length, Type.Utf8, style); 
                                  break;

                             case Type.Utf8:
                             case Type.Utf16:
                             case Type.Utf32:

                                  int len = bytes;
                                  if (style is 's')
                                     {
                                     // emit as a string
                                     if (flags & Flags.Prec)
                                         if (precision < len)
                                             len = precision;
                                     bytes = size;
                                     }
                                  else
                                     if (style is 'c')
                                         // emit a single character
                                         len = size;
                                     else
                                        {
                                        // emit as a number
                                        if (type is Type.Utf16)
                                            type = Type.UShort;
                                        else
                                        if (type is Type.Utf32)
                                            type = Type.UInt;
                                        else
                                           type = Type.UByte;
                                        continue;
                                        }

                                  // emit as a string segment
                                  length += emit (src[0..len], type);
                                  break;

                             default:
                                  Integer.error ("Format.emit : unexpected argument type");
                             }

                      // bump counters and loop around for next instance
                      if (bytes -= size)
                          length += sink (Comma, TextType);
                      src += size;
                      }
                return length;
        }

        /**********************************************************************

                internal method to map data styles 

        **********************************************************************/

        private static int getType (int t)
        {
                static  byte xlate[] = 
                        [
                        Type.Utf8, Type.Bool, -1, Type.Double, Type.Real, 
                        Type.Float, Type.Byte, Type.UByte, Type.Int, -1, 
                        Type.UInt, Type.Long, Type.ULong, -1, -1, -1, -1, -1, 
                        Type.Short, Type.UShort, Type.Utf16, -1, Type.Utf32, 
                        ];

                if (t >= 'a' && t <= 'w')
                   {
                   auto tt = xlate[t - 'a'];
                   if (tt >= 0)
                       return tt;
                   }
                else
                   if (t is 'P')
                       return Type.Pointer;
                    else
                       if (t is 'C')
                           return Type.Obj;

                Integer.error ("Format.getType : unexpected argument type " ~ cast(char) t);
                return 0;
        }

        /**********************************************************************

                Clear the current state. This is typically used internally 
                only.

        **********************************************************************/

        private void reset ()
        {
                flags = 0;
                head = tail = null;   
                width = workspace.length;
        }

        /**********************************************************************

                Emit some spaces. This was originally an inner method, 
                but that caused the code size to inexplicably increase
                by a large amount. A regular private function does not
                have that effect.

        **********************************************************************/

        private int spaces (int count)
        {       
                int ret;

                while (count > Spaces.length)
                      {
                      ret += sink (Spaces, TextType);
                      count -= Spaces.length;
                      }
                return ret + sink (Spaces[0..count], TextType);
        }

        /**********************************************************************

                Emit a field, surrounded by optional prefix and postfix 
                strings, and optionally padded with spaces.

        **********************************************************************/

        private int emit (void[] field, int type = TextType)
        {
                int i = 0;
                int pad = 0;

                // emit prefix?
                //if (head.length)
                    //i += sink (head, TextType);                   

                // should we pad output?
                if (flags & Flags.Fill && flags & Flags.Space)
                   {
                   pad = width - field.length;
                   if (pad < 0)
                       pad = 0;

                   // right-aligned?
                   if ((flags & Flags.Left) == 0)
                      {
                      i += spaces (pad);
                      pad = 0;
                      }                        
                   }

                // emit field itself, indicating provided type
                i += sink (field, type);

                // any trailing padding?
                if (pad)
                    i += spaces (pad);

                // emit postfix
                if (tail.length)
                    i += sink (tail, TextType);   

                return i;
        }

        /**********************************************************************

                Emit an integer field

        **********************************************************************/

        private int emit (long field)
        {
                return emit (Integer.format (workspace[0..width], field, 
                             cast(Integer.Format) style, flags));
        }

        /**********************************************************************

                Emit a floating-point field

        **********************************************************************/

        private int emit (double field)
        {
                if (dFormat == null)
                    Integer.error ("Format.emit : decimal formatting not configured");

                return emit (dFormat (workspace, field, 
                            (flags & Flags.Prec) ? precision : 6, 
                             cast(bool) (style == 'e')));
        }

        /**********************************************************************

                test for a digit

        **********************************************************************/

        private static final bool isDigit (T t)
        {
                return cast(bool) (t >= '0' && t <= '9');
        }

        /***********************************************************************

                Emit the text prior to a format specifier
        
        ***********************************************************************/

        private int header (uint type)
        {
                // convert format segment to Style
                if (parse (meta) is 0)
                    style = DefaultStyle[type];

                if (flags & Flags.Array)
                    meta = null;
                else
                   {
                   // flip remaining format, if array not specified
                   meta = tail;
                   tail = null;
                   }

                // always emit prefix text 
                if (head.length)
                    return sink (head, TextType);  
         
                return 0;
        }                 

        /**********************************************************************

                Parse a format specifier into its constituent
                flags and values. Syntax follows the traditional
                printf() approach, as follows:

                %[flags][width][.precision]style

                Where 'style' is one of:

                s : string format
                c : character format
                d : signed format
                u : unsigned format
                x : hexadecimal format
                X : uppercase hexadecimal format
                e : scientific notation 
                f : floating point format
                g : 'e' or 'f', based upon width

                Note that there are no variants on the format
                styles ~ long, int, short, and byte differences
                are all handled internally.

                The 'flags' supported:

                space : prefix negative integer with one space;
                        pad any style when combined with a width
                        specifier
                -     : left-align fields padded with spaces
                +     : prefix positive integer with one '+'
                0     : prefix integers with zeroes; requires a
                        width specification
                #     : prefix integers with a style specifier
                @     : Array specifier

                The 'width' should be specified for either zero or
                space padding, and may be used with all formatting
                styles.

                A 'precision' can be used to stipulate the number
                of decimal-places, or a slice of a text string.

                Note that the Format package supports array-output
                in addition to the usual printf() output.

        **********************************************************************/

        private T parse (T[] format)
        {
                reset ();
                head = format;
                T* p = format.ptr;

                for (int i = format.length; --i > 0; ++p)
                     if (*p == '%')
                         if (p[1] == '%')
                             ++p;
                         else
                            {
                            int len = p - format.ptr;
                            head = format [0..len];   
                            while (1)
                                  {
                                  switch (--i, *++p)
                                         {
                                         case '-': 
                                              flags |= Flags.Left;
                                              continue;

                                         case '+': 
                                              flags |= Flags.Plus;
                                              continue;

                                         case '#': 
                                              flags |= Flags.Hash;
                                              continue;

                                         case ' ': 
                                              flags |= Flags.Space;
                                              continue;

                                         case '0': 
                                              flags |= Flags.Zero;
                                              continue;

                                         case '@': 
                                              flags |= Flags.Array;
                                              continue;

                                         default: 
                                              ++i;
                                              break;
                                         }
                                  break;
                                  }

                            if (isDigit(*p))
                               {
                               int tmp;
                               do {
                                  tmp = tmp * 10 + (*p - '0');
                                  } while (--i && isDigit(*++p));

                               flags |= Flags.Fill;
                               width = tmp;
                               }
                            else
                               flags &= ~Flags.Zero;


                            if (*p == '.')
                               {
                               int tmp;
                               while (i-- && isDigit(*++p))
                                      tmp = tmp * 10 + (*p - '0');

                               flags |= Flags.Prec;
                               precision = tmp;
                               }

                            if (--i < 0)
                                Integer.error ("Format.parse : missing format specifier");

                            tail = format [format.length-i..format.length];
                            return style = *p;
                            }

                return style = 0;
        }
}


/******************************************************************************

        Functions for styled, readable, output. See Format.parse() for the 
        list of format specifiers.

******************************************************************************/

alias FormatStructT!(char) FormatStruct;


/******************************************************************************

******************************************************************************/

class FormatClassT(T)
{
        public  alias print     opCall;

        package alias FormatStructT!(T) Format;

        private T[128]          tmp;
        private Format          format;

        /**********************************************************************

        **********************************************************************/

        this (Format.Emitter sink, Format.DblFormat df = null)
        {
                format.ctor (sink, tmp, df);
        }

        /**********************************************************************

        **********************************************************************/

        int print (T[] fmt, ...)
        {
                return format.print (fmt, _arguments, _argptr);
        }

        /**********************************************************************

        **********************************************************************/

        int println (T[] fmt, ...)
        {
                return format.print (fmt, _arguments, _argptr, true);
        }
}


alias FormatClassT!(char) Format;

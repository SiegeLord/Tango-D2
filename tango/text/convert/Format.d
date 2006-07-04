/**
This module provides a general-purpose formatting system to convert values to strings suitable for display. There is support
for alignment and justification, common _format specifiers for numbers and date/time data, and culture-specific output.
Custom formats are also supported.

The _format notation is influenced by that used in the .NET framework rather than the C-style printf or D-style writef.

Examples:
--------
// Format with the user's current culture (for example, en-GB).
Formatter.format("General: {0} Hexadecimal: 0x{0:x4} Numeric: {0:N}", 1000);
// -> General: 1000 Hexadecimal: 0x03e8 Numeric: 1,000.00

// Format using a custom display format, substituting groups with those
// appropriate for Germany.
Formatter.format(Culture.getCulture("de-DE"), "{0:#,#}", 12345678);
// -> 12.345.678

// Format as a monetary value appropriate for Spain.
Formatter.format(Culture.getCulture("es-ES"), "{0:C}", 59.99);
// -> 59,99 €

// Format today's date as appropriate for France.
Formatter.format(Culture.getCulture("fr-FR"), "{0:D}", DateTime.today);
// -> vendredi 3 mars 2006
--------
**/
module tango.text.convert.Format;

/+
import tango.io.Console;


void main ()
{
        Formatter.format( "d{{0}d", "s" );
        Cout (Formatter.format ("{0:x20} green bottles", 1234455)) ();
}


/*******************************************************************************

*******************************************************************************/

private struct Stdout
{
        alias format opCall;

        Stdout format (bool v)
        {
                Cout (Formatter.format ("{0}", v));
                return *this;
        }

        Stdout format (long v)
        {
                Cout (Formatter.format ("{0}", v));
                return *this;
        }

        Stdout format (char[] s, ...)
        {
                Cout (Formatter.format (s));
                return *this;
        }
}

+/

/*******************************************************************************

*******************************************************************************/

public class IFormatService
{
        /**
         * $(ANCHOR IFormatService_getFormat)
         * Retrieves an object that supports formatting for the specified _type.
         * Returns: The current instance if type is the same _type as the current instance; otherwise, null.
         * Params: type = An object that specifies the _type of formatting to retrieve.
         */
        abstract Object getFormat(TypeInfo type);

}



// For Number.opCall(double).
version (mlfp)
         private extern (C) private char* ecvt(double d, int digits, out int decpt, out bool sign);


/*******************************************************************************

*******************************************************************************/

private enum TypeCode 
        {
        EMPTY = 0,
        BOOL = 'x',
        UBYTE = 'h',
        BYTE = 'g',
        USHORT = 't',
        SHORT = 's',
        UINT = 'k',
        INT = 'i',
        ULONG = 'm',
        LONG = 'l',
        FLOAT = 'f',
        DOUBLE = 'd',
        CHAR = 'a',
        ARRAY = 'A',
        CLASS = 'C',
        STRUCT = 'S',
        ENUM = 'E',
        POINTER = 'P'
        }

/*******************************************************************************

*******************************************************************************/

// Wraps a variadic argument.
private struct Argument
{

        private TypeInfo type_;
        private void* value_;
        private TypeCode typeCode_;

        /**********************************************************************

        **********************************************************************/

        public static Argument opCall (TypeInfo type, void* value)
        {
                Argument arg;

                arg.type_ = type;
                arg.value_ = value;
                arg.typeCode_ = cast(TypeCode)type.classinfo.name[9];
                return arg;
        }

        /**********************************************************************

        **********************************************************************/

        public final TypeInfo getType ()
        {
                return type_;
        }

        /**********************************************************************

        **********************************************************************/

        public final TypeCode getTypeCode ()
        {
                return typeCode_;
        }

        /**********************************************************************

        **********************************************************************/

        public final void* getValue ()
        {
                return value_;
        }

}


/*******************************************************************************

*******************************************************************************/

struct Result
{
        private uint index;
        private char[] target_;

        /**********************************************************************

        **********************************************************************/

        static Result opCall (char[] target)
        {
                Result result;

                result.target_ = target;
                return result;
        }

        /**********************************************************************

        **********************************************************************/

        void opCatAssign (char[] rhs)
        {
                uint end = index + rhs.length;

                target_[index .. end] = rhs;
                index = end;
        }

        /**********************************************************************

        **********************************************************************/

        void opCatAssign (char rhs)
        {
                target_[index++] = rhs;
        }

        /**********************************************************************

        **********************************************************************/

        char[] get ()
        {
                return target_[0..index];
        }

        /**********************************************************************

        **********************************************************************/

        char[] scratch ()
        {
                return target_;
        }
}


private alias uint delegate (char[] s) Sink;


/*******************************************************************************

*******************************************************************************/

// Wraps variadic arguments.
private struct ArgumentIterator
{
        private int size_;
        private Argument[32] args_ = void;

        /**********************************************************************

        **********************************************************************/

        public static ArgumentIterator opCall (TypeInfo[] types, void* argptr)
        {
                ArgumentIterator it;

                foreach (TypeInfo type; types)
                        {
                        it.args_[it.size_] = Argument(type, argptr);
                        argptr += (type.tsize() + int.sizeof - 1) & ~ (int.sizeof - 1);

                        if (it.size_++ >= args_.length)
                            throw new Exception ("too many arguments");
                        }
                return it;
        }

        /**********************************************************************

        **********************************************************************/

        public Argument opIndex (int index)
        {
                return args_[index];
        }

        /**********************************************************************

        **********************************************************************/

        public int count ()
        {
                return size_;
        }

        /**********************************************************************

        **********************************************************************/

        public int opApply (int delegate(inout Argument) del)
        {
                int r;
                foreach (Argument arg; args_)
                        {
                        if ((r = del(arg)) != 0)
                             break;
                        }
                return r;
        }
}


/*******************************************************************************

*******************************************************************************/

/**
 * Contains methods for replacing format items in a string with string equivalents of each argument.
 * Remarks: This struct is not intended to be instantiated. It is a container for various methods.
**/
public struct Formatter
{
        /**
         * Replaces the _format item in a string with the string equivalent of each argument.
         * Params:
         *   formatStr  = A string containing _format items.
         *   args       = A list of arguments.
         * Returns: A copy of formatStr in which the items have been replaced by the string equivalent of the arguments.
         * Remarks: The formatStr parameter is embedded with _format items of the form: $(BR)$(BR)
         *   {index[,alignment][:_format-string]}$(BR)$(BR)
         *   $(UL $(LI index $(BR)
         *     An integer indicating the element in a list to _format.)
         *   $(LI alignment $(BR)
         *     An optional integer indicating the minimum width. The result is padded with spaces if the length of the value is less than alignment.)
         *   $(LI _format-string $(BR)
         *     An optional string of formatting codes.)
         * )$(BR)
         * The leading and trailing braces are required. To include a literal brace character, use two leading or trailing brace characters.$(BR)$(BR)
         * If formatStr is "{0} bottles of beer on the wall" and the argument is an int with the value of 99, the return value will be:$(BR)
         * "99 bottles of beer on the wall".
        **/
        public static char[] format (char[] formatStr, ...)
        {
                char[] output;

                uint sink (char[] s)
                {
                        output ~= s;
                        return s.length;
                }

                format (&sink, _arguments, _argptr, formatStr);
                return output;
        }

        /**********************************************************************

        **********************************************************************/

        public static void error (char[] msg)
        {
                throw new Exception (msg);
        }

        /**********************************************************************

        **********************************************************************/

        public static uint format (Sink sink, char[] formatStr, ...)
        {
                return format (sink, _arguments, _argptr, formatStr);
        }

        /**********************************************************************

        **********************************************************************/

        public static uint format (Sink sink, TypeInfo[] arguments, void* args, char[] formatStr)
        {
                auto it = ArgumentIterator (arguments, args);
                return parse (null, formatStr, it, sink);
        }

        /**********************************************************************

        **********************************************************************/

        public static char[] format (inout Result result, TypeInfo ti, void* arg)
        {
                auto argument = Argument (ti, arg);

                return formatArgument (result, null, argument, null);
        }

        /**********************************************************************

        **********************************************************************/

        private static uint spaces (Sink sink, int count)
        {
                uint ret;

                static const char[32] Spaces = ' ';
                while (count > Spaces.length)
                      {
                      ret += sink (Spaces);
                      count -= Spaces.length;
                      }
                return ret + sink (Spaces[0..count]);
        }

/+
        /**********************************************************************

        **********************************************************************/

        private static uint internalFormat (IFormatService formatService, char[] format, inout ArgumentIterator it, Sink sink)
        {
                char[256] output = void;
                auto result = Result (output);

                char c;
                int pos;
                uint length;
		
		// todo: without the .dup we get a segmentation fault on linux, if format is
		// a string literal. With the dup, the fault is gone.
		// Is there a memory write protection for string literal with MMU in linux?
		// This method need review
                // original: char[] chars = format;
                char[] chars = format.dup;

                while (true)
                      {
                      int p = pos, i = pos;
                      while (pos < format.length)
                            {
                            c = chars[pos++];
                            if (c == '{')
                               {
                               // Handle '{{' indicating a literal brace char.
                               if (pos < format.length && chars[pos] == '{')
                                   pos++;
                               else
                                  {
                                  pos--;
                                  break;
                                  }
                               }
                            else 
                               if (c == '}')
                                  {
                                  // Handle '}}' indicating a literal brace char.
                                  if (pos < format.length && chars[pos] == '}')
                                      pos++;
                                  }
                            chars[i++] = c;
                            }

                      if (i > p)
                          length += sink (chars[p .. i]);

                      if (pos == format.length)
                          break;
                      pos++;

                      if (pos == format.length || (c = chars[pos]) < '0' || c > '9')
                          throw new Exception("Input string was invalid.");

                     int index;
                     while (c >= '0' && c <= '9')
                           {
                           index = index * 10 + c - '0';
                           pos++;
                           c = chars[pos];
                           }

                     while (pos < format.length)
                           {
                           if ((c = chars[pos]) != ' ')
                                break;
                           pos++;
                           }

                     int width;
                     bool leftAlign;

                     // Alignment.
                     if (c == ',')
                        {
                        pos++;
                        // Eat spaces.
                        while (pos < format.length)
                              {
                              if ((c = chars[pos]) != ' ')
                                   break;
                              pos++;
                              }

                        c = chars[pos];
                        if (c == '-')
                           {
                           leftAlign = true;
                           pos++;
                           c = chars[pos];
                           }

                        while (c >= '0' && c <= '9')
                              {
                              width = width * 10 + c - '0';
                              pos++;
                              c = chars[pos];
                              }
                        }

                     // Eat spaces.
                     while (pos < format.length)
                           {
                           if ((c = chars[pos]) != ' ')
                                break;
                           pos++;
                           }

                     // Interpolated format.
                     char[] f;
                     if (c == ':')
                        {
                        pos++;
                        p = pos, i = pos;
                        while (true)
                              {
                              c = chars[pos++];
                              if (c == '{')
                                 {
                                 if (pos < format.length && chars[pos] == '{')
                                 pos++;
                                 }
                              else 
                                 if (c == '}')
                                    {
                                    if (pos < format.length && chars[pos] == '}')
                                        pos++;
                                    else
                                       {
                                       pos--;
                                       break;
                                       }
                                    }
                              chars[i++] = c;
                              }

                        if (i > p)
                            f = chars[p .. i];
                        }

                     pos++;

                     // Convert argument to a string using interpolated format.
                     Argument arg = it[index];
                     char[] str = formatArgument (result, f, arg, formatService);
                     int padding = width - str.length;

                     // If not left aligned, pad out with spaces.
                     if (! leftAlign && padding > 0)
                           length += spaces (sink, padding);
        
                     length += sink (str);
        
                     // Finally, pad out on right.
                     if (leftAlign && padding > 0)
                         length += spaces (sink, padding);
                     }
                return length;
        }
+/

        /**********************************************************************

                Parse the format-string, emitting formatted args and text
                fragments as we go.

        **********************************************************************/

        private static uint parse (IFormatService formatService, char[] layout, inout ArgumentIterator it, Sink sink)
        {
                char[256] output = void;
                auto result = Result (output);

                int length;

                char* s = layout;
                char* fragment = s;
                char* end = s + layout.length;

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

                      // extract index 
                      int index;
                      while (*s >= '0' && *s <= '9')
                             index = index * 10 + *s++ -'0';

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
                      
                      char[] format;

                      // has a format string?
                      if (*s is ':' && s < end)
                         {
                         char* fs = ++s;

                         // eat everything up to closing brace
                         while (s < end && *s != '}')
                                ++s;
                         format = fs [0 .. s - fs];
                         }   
                        
                      // insist on a closing brace
                      if (*s != '}')
                          throw new Exception ("Invalid format string in Formatter.parse()");
                        
                      // next char is start of following fragment
                      fragment = ++s;

                      // convert argument to a string
                      Argument arg = it [index];
                      char[] str = formatArgument (result, format, arg, formatService);
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
}


/*******************************************************************************

*******************************************************************************/


private char[] formatArgument (inout Result result, char[] format, inout Argument arg, IFormatService service)
{
        switch (arg.getTypeCode())
               {
                    // Currently we only format char[] arrays.
               case TypeCode.ARRAY:
                    if (arg.getType() is typeid(char[]))
                        return *cast(char[]*)arg.getValue();

                    return arg.getType().toString();
        
               case TypeCode.BOOL:
                    return *cast(bool*)arg.getValue() ? "True" : "False";
        
               case TypeCode.UBYTE:
                    return formatInteger(result, cast(long)*cast(ubyte*)arg.getValue(), format, service);
        
               case TypeCode.BYTE:
                    return formatInteger(result, cast(long)*cast(byte*)arg.getValue(), format, service);
        
               case TypeCode.USHORT:
                    return formatInteger(result, cast(long)*cast(ushort*)arg.getValue(), format, service);
        
               case TypeCode.SHORT:
                    return formatInteger(result, cast(long)*cast(short*)arg.getValue(), format, service);
        
               case TypeCode.UINT:
                    return formatInteger(result, cast(long)*cast(uint*)arg.getValue(), format, service);
        
               case TypeCode.INT:
                    return formatInteger(result, cast(long)*cast(int*)arg.getValue(), format, service);
        
               case TypeCode.ULONG:
                    return formatInteger(result, cast(long)*cast(ulong*)arg.getValue(), format, service);
        
               case TypeCode.LONG:
                    return formatInteger(result, *cast(long*)arg.getValue(), format, service);
        
               version (mlfp)
               case TypeCode.FLOAT:
                    return formatDouble(result, cast(double)*cast(float*)arg.getValue(), format, service);
        
               version (mlfp)
               case TypeCode.DOUBLE:
                    return formatDouble(result, *cast(double*)arg.getValue(), format, service);
        
               case TypeCode.CHAR:
                    return (cast(char*)arg.getValue())[0..1];
        
               case TypeCode.CLASS:
                    return (*cast(Object*)arg.getValue()).toString();
        
               case TypeCode.POINTER:
                    return arg.getType().toString();
        
               default:
                    break;
               }
        
        // For everything else, return an empty string.
        return "<unknown argument type>";
}




/*******************************************************************************

*******************************************************************************/

private struct Number
{

        int scale;
        bool sign;
        int precision;
        char[32] digits = void;

        /**********************************************************************

        **********************************************************************/

        static Number opCall (long value)
        {
                Number number;
                number.precision = 20;

                if (value < 0)
                   {
                   number.sign = true;
                   value = -value;
                   }

                char[20] buffer = void;
                int n = buffer.length;

                while (value != 0)
                      {
                      buffer[--n] = value % 10 + '0';
                      value /= 10;
                      }

                int end = number.scale = -(n - buffer.length);
                number.digits[0 .. end] = buffer[n .. n + end];
                number.digits[end] = '\0';

                return number;
        }


        /**********************************************************************

        **********************************************************************/

        // Only if floating-point support is enabled.
        version (mlfp)
        static Number opCall (double value, int precision)
        {
                Number number;
                number.precision = precision;

                char* p = number.digits;
                long bits = *cast(long*) & value;
                long mant = bits & 0x000FFFFFFFFFFFFFL;
                int exp = cast(int)((bits >> 52) & EXP);

                if (exp == EXP)
                   {
                   number.scale = (mant != 0) ? NAN_FLAG : INFINITY_FLAG;
                   if (((bits >> 63) & 1) != 0)
                         number.sign = true;
                   }
                else
                   {
                   // Get the digits, decimal point and sign.
                   char* chars = ecvt(value, number.precision, number.scale, number.sign);
                   if (*chars != '\0')
                      {
                      while (*chars != '\0')
                             *p++ = *chars++;
                      }
                   }

                *p = '\0';
                return number;
        }

        /**********************************************************************

        **********************************************************************/

        version (mlfp)
        private bool toDouble(out double value)
        {
                const   ulong[] pow10 = 
                        [
                        0xa000000000000000UL,
                        0xc800000000000000UL,
                        0xfa00000000000000UL,
                        0x9c40000000000000UL,
                        0xc350000000000000UL,
                        0xf424000000000000UL,
                        0x9896800000000000UL,
                        0xbebc200000000000UL,
                        0xee6b280000000000UL,
                        0x9502f90000000000UL,
                        0xba43b74000000000UL,
                        0xe8d4a51000000000UL,
                        0x9184e72a00000000UL,
                        0xb5e620f480000000UL,
                        0xe35fa931a0000000UL,
                        0xcccccccccccccccdUL,
                        0xa3d70a3d70a3d70bUL,
                        0x83126e978d4fdf3cUL,
                        0xd1b71758e219652eUL,
                        0xa7c5ac471b478425UL,
                        0x8637bd05af6c69b7UL,
                        0xd6bf94d5e57a42beUL,
                        0xabcc77118461ceffUL,
                        0x89705f4136b4a599UL,
                        0xdbe6fecebdedd5c2UL,
                        0xafebff0bcb24ab02UL,
                        0x8cbccc096f5088cfUL,
                        0xe12e13424bb40e18UL,
                        0xb424dc35095cd813UL,
                        0x901d7cf73ab0acdcUL,
                        0x8e1bc9bf04000000UL,
                        0x9dc5ada82b70b59eUL,
                        0xaf298d050e4395d6UL,
                        0xc2781f49ffcfa6d4UL,
                        0xd7e77a8f87daf7faUL,
                        0xefb3ab16c59b14a0UL,
                        0x850fadc09923329cUL,
                        0x93ba47c980e98cdeUL,
                        0xa402b9c5a8d3a6e6UL,
                        0xb616a12b7fe617a8UL,
                        0xca28a291859bbf90UL,
                        0xe070f78d39275566UL,
                        0xf92e0c3537826140UL,
                        0x8a5296ffe33cc92cUL,
                        0x9991a6f3d6bf1762UL,
                        0xaa7eebfb9df9de8aUL,
                        0xbd49d14aa79dbc7eUL,
                        0xd226fc195c6a2f88UL,
                        0xe950df20247c83f8UL,
                        0x81842f29f2cce373UL,
                        0x8fcac257558ee4e2UL,
                        ];
        
                const   uint[] pow10Exp = 
                        [
                        4, 7, 10, 14, 17, 20, 24, 27, 30, 34,
                        37, 40, 44, 47, 50, 54, 107, 160, 213, 266,
                        319, 373, 426, 479, 532, 585, 638, 691, 745, 798,
                        851, 904, 957, 1010, 1064, 1117 
                        ];

                uint getDigits(char* p, int len)
                {
                        char* end = p + len;
                        uint r = *p - '0';
                        p++;
                        while (p < end)
                              {
                              r = 10 * r + *p - '0';
                              p++;
                              }
                        return r;
                }

                ulong mult64(uint val1, uint val2)
                {
                        return cast(ulong)val1 * cast(ulong)val2;
                }

                ulong mult64L(ulong val1, ulong val2)
                {
                        ulong v = mult64(cast(uint)(val1 >> 32), cast(uint)(val2 >> 32));
                        v += mult64(cast(uint)(val1 >> 32), cast(uint)val2) >> 32;
                        v += mult64(cast(uint)val1, cast(uint)(val2 >> 32)) >> 32;
                        return v;
                }

                char* p = digits;
                int count = charTerm(p);
                int left = count;

                while (*p == '0')
                      {
                      left--;
                      p++;
                      }

                // If the digits consist of nothing but zeros...
                if (left == 0)
                   {       
                   value = 0.0;
                   return true;
                   }

                // Get digits, 9 at a time.
                int n = (left > 9) ? 9 : left;
                left -= n;
                ulong bits = getDigits(p, n);
                if (left > 0)
                   {
                   n = (left > 9) ? 9 : left;
                   left -= n;
                   bits = mult64(cast(uint)bits, cast(uint)(pow10[n - 1] >>> (64 - pow10Exp[n - 1])));
                   bits += getDigits(p + 9, n);
                   }

                int scale = this.scale - (count - left);
                int s = (scale < 0) ? -scale : scale;

                if (s >= 352)
                   {
                   *cast(long*)&value = (scale > 0) ? 0x7FF0000000000000 : 0;
                   return false;
                   }

                // Normalise mantissa and bits.
                int bexp = 64;
                int nzero;
                if ((bits >> 32) != 0)
                     nzero = 32;

                if ((bits >> (16 + nzero)) != 0)
                     nzero += 16;

                if ((bits >> (8 + nzero)) != 0)
                     nzero += 8;

                if ((bits >> (4 + nzero)) != 0)
                     nzero += 4;

                if ((bits >> (2 + nzero)) != 0)
                     nzero += 2;

                if ((bits >> (1 + nzero)) != 0)
                     nzero++;

                if ((bits >> nzero) != 0)
                     nzero++;

                bits <<= 64 - nzero;
                bexp -= 64 - nzero;

                // Get decimal exponent.
                if ((s & 15) != 0)
                   {
                   int expMult = pow10Exp[(s & 15) - 1];
                   bexp += (scale < 0) ? ( -expMult + 1) : expMult;
                   bits = mult64L(bits, pow10[(s & 15) + ((scale < 0) ? 15 : 0) - 1]);
                   if ((bits & 0x8000000000000000L) == 0)
                      {
                      bits <<= 1;
                      bexp--;
                      }
                   }

                if ((s >> 4) != 0)
                   {
                   int expMult = pow10Exp[15 + ((s >> 4) - 1)];
                   bexp += (scale < 0) ? ( -expMult + 1) : expMult;
                   bits = mult64L(bits, pow10[30 + ((s >> 4) + ((scale < 0) ? 21 : 0) - 1)]);
                   if ((bits & 0x8000000000000000L) == 0)
                      {
                      bits <<= 1;
                      bexp--;
                      }
                   } 

                // Round and scale.
                if (cast(uint)bits & (1 << 10) != 0)
                   {
                   bits += (1 << 10) - 1 + (bits >>> 11) & 1;
                   bits >>= 11;
                   if (bits == 0)
                       bexp++;
                   }
                else
                   bits >>= 11;

                bexp += 1022;
                if (bexp <= 0)
                   {
                   if (bexp < -53)
                       bits = 0;
                   else
                      bits >>= ( -bexp + 1);
                   }
                bits = (cast(ulong)bexp << 52) + (bits & 0x000FFFFFFFFFFFFFL);

                if (sign)
                    bits |= 0x8000000000000000L;

                value = *cast(double*) & bits;
                return true;
        }



        /**********************************************************************

        **********************************************************************/

        private char[] toString (inout Result result, char format, int length, NumberFormat nf)
        {
                switch (format)
                       {
                       case 'c':
                       case 'C':
                             // Currency
                             if (length < 0)
                                 length = nf.currencyDecimalDigits;

                             round(scale + length);
                             formatCurrency (*this, result, length, nf);
                             break;

                       case 'f':
                       case 'F':
                             // Fixed
                             if (length < 0)
                                 length = nf.numberDecimalDigits;

                             round(scale + length);
                             if (sign)
                                 result ~= nf.negativeSign;

                             formatFixed (*this, result, length, null, nf.numberDecimalSeparator, null);
                             break;

                       case 'n':
                       case 'N':
                             // Number
                                if (length < 0)
                                    length = nf.numberDecimalDigits;

                             round(scale + length);
                             formatNumber (*this, result, length, nf);
                             break;

                       case 'g':
                       case 'G':
                             // General
                             if (length < 1)
                                 length = precision;

                             round(length);
                             if (sign)
                                 result ~= nf.negativeSign;

                             formatGeneral (*this, result, length, (format == 'g') ? 'e' : 'E', nf);
                             break;

                       default:
                             throw new Exception ("Invalid format specifier.");
                       }
                return result.get;
        }


        /**********************************************************************

        **********************************************************************/

        private char[] toStringFormat (inout Result result, char[] format, NumberFormat nf)
        {
                bool hasGroups;
                int groupCount;
                int groupPos = -1, pointPos = -1;
                int first = int.max, last, count;
                bool scientific;
                int n;
                char c;

                while (n < format.length)
                      {
                      c = format[n++];
                      switch (c)
                             {
                             case '#':
                                  count++;
                                  break;

                             case '0':
                                  if (first == int.max)
                                      first = count;
                                  count++;
                                  last = count;
                                  break;

                             case '.':
                                  if (pointPos < 0)
                                      pointPos = count;
                                  break;

                             case ',':
                                  if (count > 0 && pointPos < 0)
                                     {
                                     if (groupPos >= 0)
                                        {
                                        if (groupPos == count)
                                           {
                                           groupCount++;
                                           break;
                                           }
                                        hasGroups = true;
                                        }
                                     groupPos = count;
                                     groupCount = 1;
                                     }
                                  break;

                             case '\'':
                             case '\"':
                                   while (n < format.length && format[n++] != c)
                                         {}
                                   break;

                             case '\\':
                                  if (n < format.length)
                                      n++;
                                  break;

                             default:
                                  break;
                             }
                      }

                if (pointPos < 0)
                    pointPos = count;

                int adjust;
                if (groupPos >= 0)
                   {
                   if (groupPos == pointPos)
                       adjust -= groupCount * 3;
                   else
                      hasGroups = true;
                   }

                if (digits[0] != '\0')
                   {
                   scale += adjust;
                   round(scientific ? count : scale + count - pointPos);
                   }

                first = (first < pointPos) ? pointPos - first : 0;
                last = (last > pointPos) ? pointPos - last : 0;

                int pos = pointPos;
                int extra;
                if (!scientific)
                   {
                   pos = (scale > pointPos) ? scale : pointPos;
                   extra = scale - pointPos;
                   }

                char[] groupSeparator = nf.numberGroupSeparator;
                char[] decimalSeparator = nf.numberDecimalSeparator;

                // Work out the positions of the group separator.
                int[] groupPositions;
                int groupIndex = -1;
                if (hasGroups)
                   {
                   if (nf.numberGroupSizes.length == 0)
                       hasGroups = false;
                   else
                      {
                      int groupSizesTotal = nf.numberGroupSizes[0];
                      int groupSize = groupSizesTotal;
                      int digitsTotal = pos + ((extra < 0) ? extra : 0);
                      int digitCount = (first > digitsTotal) ? first : digitsTotal;
        
                      int sizeIndex;
                      while (digitCount > groupSizesTotal)
                            {
                            if (groupSize == 0)
                                break;

                            groupPositions ~= groupSizesTotal;
                            groupIndex++;

                            if (sizeIndex < nf.numberGroupSizes.length - 1)
                                groupSize = nf.numberGroupSizes[++sizeIndex];

                            groupSizesTotal += groupSize;
                            }
                      }
                }

                //char[] result;
                if (sign)
                    result ~= nf.negativeSign;

                char* p = digits;
                n = 0;
                bool pointWritten;

                while (n < format.length)
                      {
                      c = format[n++];
                      if (extra > 0 && (c == '#' || c == '0' || c == '.'))
                         {
                         while (extra > 0)
                               {
                               result ~= (*p != '\0') ? *p++ : '0';
        
                               if (hasGroups && pos > 1 && groupIndex >= 0)
                                  {
                                  if (pos == groupPositions[groupIndex] + 1)
                                     {
                                     result ~= groupSeparator;
                                     groupIndex--;
                                     }
                                  }
                               pos--;
                               extra--;
                               }
                         }

                      switch (c)
                             {
                             case '#':
                             case '0':
                                  if (extra < 0)
                                     {
                                     extra++;
                                     c = (pos <= first) ? '0' : char.init;
                                     }
                                  else
                                     c = (*p != '\0') ? *p++ : pos > last ? '0' : char.init;

                                  if (c != char.init)
                                     {
                                     result ~= c;
        
                                     if (hasGroups && pos > 1 && groupIndex >= 0)
                                        {
                                        if (pos == groupPositions[groupIndex] + 1)
                                           {
                                           result ~= groupSeparator;
                                           groupIndex--;
                                           }
                                        }
                                     }
                                  pos--;
                                  break;

                             case '.':
                                  if (pos != 0 || pointWritten)
                                      break;
                                  if (last < 0 || (pointPos < count && *p != '\0'))
                                     {
                                     result ~= decimalSeparator;
                                     pointWritten = true;
                                     }
                                  break;

                             case ',':
                                  break;

                             case '\'':
                             case '\"':
                                  if (n < format.length)
                                      n++;
                                  break;

                             case '\\':
                                  if (n < format.length)
                                      result ~= format[n++];
                                  break;

                             default:
                                  result ~= c;
                                  break;
                             }
                      }
                return result.get;
        }


        /**********************************************************************

        **********************************************************************/

        private void round (int pos)
        {
                int index;
                while (index < pos && digits[index] != '\0')
                       index++;

                if (index == pos && digits[index] >= '5')
                   {       
                   while (index > 0 && digits[index - 1] == '9')
                          index--;
                   
                   if (index > 0)
                       digits[index - 1]++;
                   else
                      {
                      scale++;
                      digits[0] = '1';
                      index = 1;
                      }
                   }
                else
                   while (index > 0 && digits[index - 1] == '0')
                          index--;

                if (index == 0)
                   {
                   scale = 0;
                   sign = false;
                   }       

                digits[index] = '\0';
        }

}

/*******************************************************************************

*******************************************************************************/

// Must match NumberFormat.decimalPositivePattern
private const   char[] positiveNumberFormat = "#";

// Must match NumberFormat.decimalNegativePattern
private const   char[][] negativeNumberFormats = 
                [ 
                "(#)", "-#", "- #", "#-", "# -" 
                ];

// Must match NumberFormat.currencyPositivePattern
private const   char[][] positiveCurrencyFormats = 
                [ 
                "$#", "#$", "$ #", "# $" 
                ];

// Must match NumberFormat.currencyNegativePattern
private const   char[][] negativeCurrencyFormats = 
                [ 
                "($#)", "-$#", "$-#", "$#-", "(#$)", 
                "-#$", "#-$", "#$-", "-# $", "-$ #", 
                "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)" 
                ];


/*******************************************************************************

*******************************************************************************/

template charTerm (T)
{

        /**********************************************************************

        **********************************************************************/

        private int charTerm(T* s)
        {
                int i;
                while (*s++ != '\0')
                        i++;
                return i;
        }

}

/*******************************************************************************

*******************************************************************************/

private char[] longToString (char[] buffer, long value, int digits, char[] negativeSign)
{
        if (digits < 1)
            digits = 1;

        int n = buffer.length;
        ulong uv = (value >= 0) ? value : cast(ulong) - value;

        if (uv > uint.max)
           {
           while (--digits >= 0 || uv != 0)
                 {
                 buffer[--n] = uv % 10 + '0';
                 uv /= 10;
                 }
           }
        else
           {
           uint v = cast(uint) uv;
           while (--digits >= 0 || v != 0)
                 {
                 buffer[--n] = v % 10 + '0';
                 v /= 10;
                 }
           }


        if (value < 0)
           {
           for (int i = negativeSign.length - 1; i >= 0; i--)
                buffer[--n] = negativeSign[i];
           }

        return buffer[n .. $];
}

/*******************************************************************************

*******************************************************************************/

private char[] longToHexString (char[] buffer, ulong value, int digits, char format)
{
        if (digits < 1)
            digits = 1;

        int n = buffer.length;
        while (--digits >= 0 || value != 0)
              {
              ulong v = value & 0xF;
              buffer[--n] = (v < 10) ? v + '0' : v + format - ('X' - 'A' + 10);
              value >>= 4;
              }

        return buffer[n .. $];
}

/*******************************************************************************

*******************************************************************************/

private char parseFormatSpecifier (char[] format, out int length)
{
        length = -1;
        char specifier = 'G';

        if (format != null)
           {
           int pos = 0;
           char c = format[pos];
        
           if (c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z')
              {
              specifier = c;
              pos++;
              if (pos == format.length)
                  return specifier;

              c = format[pos];

              if (c >= '0' && c <= '9')
                 {
                 length = c - '0';
                 pos++;
                 if (pos == format.length)
                     return specifier;

                 c = format[pos];

                 while (c >= '0' && c <= '9')
                       {
                       length = length * 10 + c - '0';
                       pos++;
                       if (length >= 10 || pos == format.length)
                           return specifier;

                       c = format[pos];
                       }
                 }
              }
           return char.init;
           }

        return specifier;
}

/*******************************************************************************

*******************************************************************************/

private char[] formatInteger (inout Result result, long value, char[] format, IFormatService formatService)
{
        NumberFormat nf = NumberFormat.getInstance (formatService);
        int length;
        char specifier = parseFormatSpecifier (format, length);

        switch (specifier)
               {
               case 'g':
               case 'G':
                    if (length > 0)
                       {
                       Number number = Number (value);
                       if (specifier != char.init)
                           return number.toString (result, specifier, length, nf);
        
                       return number.toStringFormat (result, format, nf);
                       }
                    // Fall through.

               case 'd':
               case 'D':
                    return longToString (result.scratch, value, length, nf.negativeSign);

               case 'x':
               case 'X':
                    return longToHexString (result.scratch, cast(ulong)value, length, specifier);

               default:
                    break;
               }

        Number number = Number (value);
        if (specifier != char.init)
            return number.toString (result, specifier, length, nf);

        return number.toStringFormat (result, format, nf);
}

/*******************************************************************************

*******************************************************************************/

// Only if floating-point support is enabled.
version (mlfp)
{

        private enum 
                {
                NAN_FLAG = 0x80000000,
                INFINITY_FLAG = 0x7fffffff,
                EXP = 0x7ff
                }

        private char[] formatDouble (inout Result result, double value, char[] format, IFormatService formatService)
        {
                NumberFormat nf = NumberFormat.getInstance (formatService);
                int length;
                char specifier = parseFormatSpecifier (format, length);
                int precision = 15;

                switch (specifier)
                       {
                       case 'r':
                       case 'R':
                            Number number = Number (value, 15);

                            if (number.scale == NAN_FLAG)
                                return nf.nanSymbol;
                         
                            if (number.scale == INFINITY_FLAG)
                                return number.sign ? nf.negativeInfinitySymbol 
                                                   : nf.positiveInfinitySymbol;

                            double d;
                            number.toDouble(d);
                            if (d == value)
                                return number.toString (result, 'G', 15, nf);

                            number = Number(value, 17);
                            return number.toString (result, 'G', 17, nf);

                       case 'g':
                       case 'G':
                            if (length > 15)
                                precision = 17;
                            // Fall through.

                       default:
                            break;
                }

                Number number = Number(value, precision);

                if (number.scale == NAN_FLAG)
                    return nf.nanSymbol;

                if (number.scale == INFINITY_FLAG)
                    return number.sign ? nf.negativeInfinitySymbol 
                                       : nf.positiveInfinitySymbol;

                if (specifier != char.init)
                    return number.toString (result, specifier, length, nf);

                return number.toStringFormat (result, format, nf);
        }

} // version (mlfp)


/*******************************************************************************

*******************************************************************************/

private void formatGeneral (inout Number number, inout Result target, int length, char format, NumberFormat nf)
{
        int pos = number.scale;

        char* p = number.digits;
        if (pos > 0)
           {
           while (pos > 0)
                 {
                 target ~= (*p != '\0') ? *p++ : '0';
                 pos--;
                 }
           }
        else
           target ~= '0';

        if (*p != '\0')
           {
           target ~= nf.numberDecimalSeparator;
           while (pos < 0)
                 {
                 target ~= '0';
                 pos++;
                 }
                        
           while (*p != '\0')
                  target ~= *p++;
           }
}

/*******************************************************************************

*******************************************************************************/

private void formatNumber (inout Number number, inout Result target, int length, NumberFormat nf)
{
        char[] format = number.sign ? negativeNumberFormats[nf.numberNegativePattern] 
                                    : positiveNumberFormat;

        // Parse the format.
        foreach (char c; format)
                {
                switch (c)
                       {
                       case '#':
                            formatFixed (number, target, length, nf.numberGroupSizes, 
                                         nf.numberDecimalSeparator, nf.numberGroupSeparator);
                            break;

                       case '-':
                            target ~= nf.negativeSign;
                            break;

                       default:
                            target ~= c;
                            break;
                       }
                }
}

/*******************************************************************************

*******************************************************************************/

private void formatCurrency (inout Number number, inout Result target, int length, NumberFormat nf)
{
        char[] format = number.sign ? negativeCurrencyFormats[nf.currencyNegativePattern] 
                                    : positiveCurrencyFormats[nf.currencyPositivePattern];

        // Parse the format.
        foreach (char c; format)
                {
                switch (c)
                       {
                       case '#':
                            formatFixed (number, target, length, nf.currencyGroupSizes, 
                                         nf.currencyDecimalSeparator, nf.currencyGroupSeparator);
                            break;

                       case '-':
                            target ~= nf.negativeSign;
                            break;

                       case '$':
                            target ~= nf.currencySymbol;
                            break;

                       default:
                            target ~= c;
                            break;
                       }
                }
}

/*******************************************************************************

*******************************************************************************/

private void formatFixed (inout Number number, inout Result target, int length, 
                          int[] groupSizes, char[] decimalSeparator, char[] groupSeparator)
{
        int pos = number.scale;
        char* p = number.digits;

        if (pos > 0)
           {
           if (groupSizes.length != 0)
              {
              // Calculate whether we have enough digits to format.
              int count = groupSizes[0];
              int index, size;

              while (pos > count)
                    {
                    size = groupSizes[index];
                    if (size == 0)
                        break;

                    if (index < groupSizes.length - 1)
                       index++;

                    count += groupSizes[index];
                    }

              size = (count == 0) ? 0 : groupSizes[0];

              // Insert the separator according to groupSizes.
              int end = charTerm(p);
              int start = (pos < end) ? pos : end;

        
              char[] separator = groupSeparator;
              index = 0;

              // questionable: use the back end of the output buffer to
              // format the separators, and then copy back to start
              char[] temp = target.scratch;
              uint ii = temp.length;

              for (int c, i = pos - 1; i >= 0; i--)
                  {
                  temp[--ii] = (i < start) ? number.digits[i] : '0';
                  if (size > 0)
                     {
                     c++;
                     if (c == size && i != 0)
                        {
                        uint iii = ii - separator.length;
                        temp[iii .. ii] = separator;
                        ii = iii;
 
                        if (index < groupSizes.length - 1)
                            size = groupSizes[++index];
 
                        c = 0;
                        }
                     }
                  }
              target ~= temp[ii..$];
              p += start;
              }
           else
              {
              while (pos > 0)
                    {
                    target ~= (*p != '\0') ? *p++ : '0';
                    pos--;
                    }
              }
           }
        else
           // Negative scale.
           target ~= '0';

        if (length > 0)
           {
           target ~= decimalSeparator;
           while (pos < 0 && length > 0)
                 {
                 target ~= '0';
                 pos++;
                 length--;
                 }

           while (length > 0)
                 {
                 target ~= (*p != '\0') ? *p++ : '0';
                 length--;
                 }
           }
}





/*******************************************************************************

*******************************************************************************/

class NumberFormat
{
        /**********************************************************************

        **********************************************************************/

        public final int numberDecimalDigits ()
        {
                return 2;
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] negativeSign ()
        {
                return "-";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] numberDecimalSeparator ()
        {
                return ".";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] numberGroupSeparator ()
        {
                return ",";
        }

        /**********************************************************************

        **********************************************************************/

        public final int[] numberGroupSizes ()
        {
                static int[] groups = [3, 3, 3];
                return groups;
        }

        /**********************************************************************

        **********************************************************************/

        public final int numberNegativePattern ()
        {
                return 1;
        }

        /**********************************************************************

        **********************************************************************/

        public final int currencyNegativePattern ()
        {
                return 1;
        }

        /**********************************************************************

        **********************************************************************/

        public final int currencyPositivePattern ()
        {
                return 0;
        }

        /**********************************************************************

        **********************************************************************/

        public final int[] currencyGroupSizes ()
        {
                static int[] groups = [3, 3, 3];
                return groups;
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] currencyGroupSeparator ()
        {
                return ",";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] currencyDecimalSeparator ()
        {
                return ".";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] currencySymbol ()
        {
                return "$";
        }

        /**********************************************************************

        **********************************************************************/

        public final int currencyDecimalDigits ()
        {
                return 2;
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] negativeInfinitySymbol ()
        {
                return "-infinity";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] positiveInfinitySymbol ()
        {
                return "+infinity";
        }

        /**********************************************************************

        **********************************************************************/

        public final char[] nanSymbol ()
        {
                return "NaN";
        }

        /**********************************************************************

        **********************************************************************/

        public static NumberFormat getInstance (IFormatService formatService)
        {
                static NumberFormat current;

                if (current is null)
                        current = new NumberFormat;

                return current;
        }

}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
unittest{
    assert( Formatter.format( "abc" ) == "abc" );
    
    assert( Formatter.format( "{0}", 1 ) == "1" );
    assert( Formatter.format( "{0}", -1 ) == "-1" );
    
    assert( Formatter.format( "{0}", true ) == "True" );
    assert( Formatter.format( "{0}", false ) == "False" );
    
    assert( Formatter.format( "{0}", cast(byte)-128 ) == "-128" );
    assert( Formatter.format( "{0}", cast(byte)127 ) == "127" );
    assert( Formatter.format( "{0}", cast(ubyte)255 ) == "255" );
    
    assert( Formatter.format( "{0}", cast(short)-32768  ) == "-32768" );
    assert( Formatter.format( "{0}", cast(short)32767 ) == "32767" );
    assert( Formatter.format( "{0}", cast(ushort)65535 ) == "65535" );
    // assert( Formatter.format( "{0:x4}", cast(ushort)0xafe ) == "0afe" );
    // assert( Formatter.format( "{0:X4}", cast(ushort)0xafe ) == "0AFE" );
    
    assert( Formatter.format( "{0}", -2147483648 ) == "-2147483648" );
    assert( Formatter.format( "{0}", 2147483647 ) == "2147483647" );
    assert( Formatter.format( "{0}", 4294967295 ) == "4294967295" );
    // compiler error
    //assert( Formatter.format( "{0}", -9223372036854775808L) == "-9223372036854775808" );
    assert( Formatter.format( "{0}", 0x8000_0000_0000_0000L) == "-9223372036854775808" );
    assert( Formatter.format( "{0}", 9223372036854775807L ) == "9223372036854775807" );
    // Error: prints -1
    // assert( Formatter.format( "{0}", 18446744073709551615UL ) == "18446744073709551615" );
    
    assert( Formatter.format( "{0}", "s" ) == "s" );
    // fragments before and after
    assert( Formatter.format( "d{0}d", "s" ) == "dsd" );
    // brace escaping
    assert( Formatter.format( "d{{0}d", "s" ) == "d{0}d");
    
    // assert( Formatter.format( "{0:x}", 0xafe0000 ) == "afe0000" );
    // // todo: is it correct to print 7 instead of 6 chars???
    // assert( Formatter.format( "{0:x6}", 0xafe0000 ) == "afe0000" );
    // assert( Formatter.format( "{0:x8}", 0xafe0000 ) == "0afe0000" );
    // assert( Formatter.format( "{0:X8}", 0xafe0000 ) == "0AFE0000" );
    // assert( Formatter.format( "{0:X9}", 0xafe0000 ) == "00AFE0000" );
    // assert( Formatter.format( "{0:X13}", 0xafe0000 ) == "000000AFE0000" );
    // assert( Formatter.format( "{0:x13}", 0xafe0000 ) == "000000afe0000" );
    // // compiler error
    // //assert( Formatter.format( "{0}", -9223372036854775808L) == "-9223372036854775808" );
    // assert( Formatter.format( "{0}", 0x8000_0000_0000_0000L) == "-9223372036854775808" );
    // assert( Formatter.format( "{0}", 9223372036854775807L ) == "9223372036854775807" );
    // assert( Formatter.format( "{0:X}", 0xFFFF_FFFF_FFFF_FFFF) == "FFFFFFFFFFFFFFFF" );
    // assert( Formatter.format( "{0:x}", 0xFFFF_FFFF_FFFF_FFFF) == "ffffffffffffffff" );
    // assert( Formatter.format( "{0:x}", 0xFFFF_1234_FFFF_FFFF) == "ffff1234ffffffff" );
    // assert( Formatter.format( "{0:x19}", 0x1234_FFFF_FFFF) == "00000001234ffffffff" );
    // // Error: prints -1
    // // assert( Formatter.format( "{0}", 18446744073709551615UL ) == "18446744073709551615" );
    // assert( Formatter.format( "{0}", "s" ) == "s" );
    // // fragments before and after
    // assert( Formatter.format( "d{0}d", "s" ) == "dsd" );
    // // brace escaping
    // assert( Formatter.format( "d{{0}}d", "s" ) == "d{0}d" );

    // argument index
    assert( Formatter.format( "a{0}b{1}c{2}", "x", "y", "z" ) == "axbycz" );
    assert( Formatter.format( "a{2}b{1}c{0}", "x", "y", "z" ) == "azbycx" );
    assert( Formatter.format( "a{1}b{1}c{1}", "x", "y", "z" ) == "aybycy" );
    
    // alignment
    assert( Formatter.format( "->{0,-10}<-", "hello" ) == "->hello     <-" );
    assert( Formatter.format( "->{0,10}<-", "hello" ) == "->     hello<-" );
    assert( Formatter.format( "->{0,-10}<-", 12345 ) == "->12345     <-" );
    assert( Formatter.format( "->{0,10}<-", 12345 ) == "->     12345<-" );
    
    assert( Formatter.format("General: {0} Hexadecimal: 0x{0:x4} Numeric: {0:N}", 1000) 
	    == "General: 1000 Hexadecimal: 0x03e8 Numeric: 1,000.00" );
//    assert( Formatter.format(Culture.getCulture("de-DE"), "{0:#,#}", 12345678)
//	    == "12.345.678" );
//    assert( Formatter.format(Culture.getCulture("es-ES"), "{0:C}", 59.99)
//	    == "59,99 €" );
//    assert( Formatter.format(Culture.getCulture("fr-FR"), "{0:D}", DateTime.today)
//	    == "vendredi 3 mars 2006" );
    
    version( mlfp ){
	assert( Formatter.format( "{0:f}", 1.23f ) == "1.23" );
	assert( Formatter.format( "{0:f}", 1.23 ) == "1.23" );
    }
}
}


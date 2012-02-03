/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2004

        authors:        Kris

        Fast Unicode transcoders. These are particularly sensitive to
        minor changes on 32bit x86 devices, because the register set of
        those devices is so small. Beware of subtle changes which might
        extend the execution-period by as much as 200%. Because of this,
        three of the six transcoders might read past the end of input by
        one, two, or three bytes before arresting themselves. Note that
        support for streaming adds a 15% overhead to the dchar => char
        conversion, but has little effect on the others.

        These routines were tuned on an Intel P4; other devices may work
        more efficiently with a slightly different approach, though this
        is likely to be reasonably optimal on AMD x86 CPUs also. These
        algorithms would benefit significantly from those extra AMD64
        registers. On a 3GHz P4, the dchar/char conversions take around
        2500ns to process an array of 1000 ASCII elements. Invoking the
        memory manager doubles that period, and quadruples the time for
        arrays of 100 elements. Memory allocation can slow down notably
        in a multi-threaded environment, so avoid that where possible.

        Surrogate-pairs are dealt with in a non-optimal fashion when
        transcoding between utf16 and utf8. Such cases are considered
        to be boundary-conditions for this module.

        There are three common cases where the input may be incomplete,
        including each 'widening' case of utf8 => utf16, utf8 => utf32,
        and utf16 => utf32. An edge-case is utf16 => utf8, if surrogate
        pairs are present. Such cases will throw an exception, unless
        streaming-mode is enabled ~ in the latter mode, an additional
        integer is returned indicating how many elements of the input
        have been consumed. In all cases, a correct slice of the output
        is returned.

        For details on Unicode processing see:
        $(UL $(LINK http://www.utf-8.com/))
        $(UL $(LINK http://www.hackcraft.net/xmlUnicode/))
        $(UL $(LINK http://www.azillionmonkeys.com/qed/unicode.html/))
        $(UL $(LINK http://icu.sourceforge.net/docs/papers/forms_of_unicode/))

*******************************************************************************/

module tango.text.convert.Utf;

public extern (C) void onUnicodeError (const(char[]) msg, size_t idx = 0);

/*******************************************************************************

        Symmetric calls for equivalent types; these return the provided
        input with no conversion

*******************************************************************************/

inout(char[])  toString (inout(char[]) src, char[] dst = null, size_t* ate=null) {return src;}
inout(wchar[]) toString16 (inout(wchar[]) src, wchar[] dst = null, size_t* ate=null) {return src;}
inout(dchar[]) toString32 (inout(dchar[]) src, dchar[] dst = null, size_t* ate=null) {return src;}

/*******************************************************************************

        Encode Utf8 up to a maximum of 4 bytes long (five & six byte
        variations are not supported).

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.
        For example:

        ---
        char[] output;

        char[] result = toString (input, output);

        // reset output after a realloc
        if (result.length > output.length)
            output = result;
        ---

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

char[] toString (const(wchar[]) input, char[] output=null, size_t* ate=null)
{
        if (ate)
            *ate = input.length;
        else
           {
           // potentially reallocate output
           auto estimate = input.length * 2 + 3;
           if (output.length < estimate)
               output.length = estimate;
           }

        char* pOut = output.ptr;
        char* pMax = pOut + output.length - 3;

        foreach (int eaten, wchar b; input)
                {
                // about to overflow the output?
                if (pOut > pMax)
                   {
                   // if streaming, just return the unused input
                   if (ate)
                      {
                      *ate = eaten;
                      break;
                      }

                   // reallocate the output buffer
                   auto len = pOut - output.ptr;
                   output.length = len + len / 2;
                   pOut = output.ptr + len;
                   pMax = output.ptr + output.length - 3;
                   }

                if (b < 0x80)
                    *pOut++ = cast(char)b;
                else
                   if (b < 0x0800)
                      {
                      pOut[0] = cast(wchar)(0xc0 | ((b >> 6) & 0x3f));
                      pOut[1] = cast(wchar)(0x80 | (b & 0x3f));
                      pOut += 2;
                      }
                   else
                      if (b < 0xd800 || b > 0xdfff)
                         {
                         pOut[0] = cast(wchar)(0xe0 | ((b >> 12) & 0x3f));
                         pOut[1] = cast(wchar)(0x80 | ((b >> 6)  & 0x3f));
                         pOut[2] = cast(wchar)(0x80 | (b & 0x3f));
                         pOut += 3;
                         }
                      else
                         // deal with surrogate-pairs
                         return toString (toString32(input, null, ate), output);
                }

        // return the produced output
        return output [0..(pOut - output.ptr)];
}

/*******************************************************************************

        Decode Utf8 produced by the above toString() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

wchar[] toString16 (const(char[]) input, wchar[] output=null, size_t* ate=null)
{
        int     produced;
        const(char)*   pIn = input.ptr;
        const(char)*   pMax = pIn + input.length;
        const(char)*   pValid;

        if (ate is null)
            if (input.length > output.length)
                output.length = input.length;

        if (input.length)
        foreach (ref wchar d; output)
        {
                pValid = pIn;
                wchar b = cast(wchar) *pIn;

                if (b & 0x80)
                {
                    if (b < 0xe0)
                       {
                       b &= 0x1f;
                       b = cast(wchar)((b << 6) | (*++pIn & 0x3f));
                       }
                    else
                       {
                       if (b < 0xf0)
                          {
                          b &= 0x0f;
                          b = cast(wchar)((b << 6) | (pIn[1] & 0x3f));
                          b = cast(wchar)((b << 6) | (pIn[2] & 0x3f));
                          pIn += 2;
                          }
                       else
                          // deal with surrogate-pairs
                          return toString16 (toString32(input, null, ate), output);
                       }
                }
                d = b;
                ++produced;

                // did we read past the end of the input?
                if (++pIn >= pMax)
                {
                    if (pIn > pMax)
                       {
                       // yep ~ return tail or throw error?
                       if (ate)
                          {
                          pIn = pValid;
                          --produced;
                          break;
                          }
                       onUnicodeError ("Unicode.toString16 : incomplete utf8 input", pIn - input.ptr);
                       }
                    else
                       break;
                }
        }

        // do we still have some input left?
        if (ate)
            *ate = pIn - input.ptr;
        else
           if (pIn < pMax)
               // this should never happen!
               onUnicodeError ("Unicode.toString16 : utf8 overflow", pIn - input.ptr);

        // return the produced output
        return output [0..produced];
}


/*******************************************************************************

        Encode Utf8 up to a maximum of 4 bytes long (five & six
        byte variations are not supported). Throws an exception
        where the input dchar is greater than 0x10ffff.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

char[] toString (const(dchar[]) input, char[] output=null, size_t* ate=null)
{
        if (ate)
            *ate = input.length;
        else
           {
           // potentially reallocate output
           auto estimate = input.length * 2 + 4;
           if (output.length < estimate)
               output.length = estimate;
           }

        char* pOut = output.ptr;
        char* pMax = pOut + output.length - 4;

        foreach (int eaten, dchar b; input)
                {
                // about to overflow the output?
                if (pOut > pMax)
                   {
                   // if streaming, just return the unused input
                   if (ate)
                      {
                      *ate = eaten;
                      break;
                      }

                   // reallocate the output buffer
                   auto len = pOut - output.ptr;
                   output.length = len + len / 2;
                   pOut = output.ptr + len;
                   pMax = output.ptr + output.length - 4;
                   }

                if (b < 0x80)
                    *pOut++ = cast(char)b;
                else
                   if (b < 0x0800)
                      {
                      pOut[0] = cast(wchar)(0xc0 | ((b >> 6) & 0x3f));
                      pOut[1] = cast(wchar)(0x80 | (b & 0x3f));
                      pOut += 2;
                      }
                   else
                      if (b < 0x10000)
                         {
                         pOut[0] = cast(wchar)(0xe0 | ((b >> 12) & 0x3f));
                         pOut[1] = cast(wchar)(0x80 | ((b >> 6)  & 0x3f));
                         pOut[2] = cast(wchar)(0x80 | (b & 0x3f));
                         pOut += 3;
                         }
                      else
                         if (b < 0x110000)
                            {
                            pOut[0] = cast(wchar)(0xf0 | ((b >> 18) & 0x3f));
                            pOut[1] = cast(wchar)(0x80 | ((b >> 12) & 0x3f));
                            pOut[2] = cast(wchar)(0x80 | ((b >> 6)  & 0x3f));
                            pOut[3] = cast(wchar)(0x80 | (b & 0x3f));
                            pOut += 4;
                            }
                         else
                            onUnicodeError ("Unicode.toString : invalid dchar", eaten);
                }

        // return the produced output
        return output [0..(pOut - output.ptr)];
}


/*******************************************************************************

        Decode Utf8 produced by the above toString() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

dchar[] toString32 (const(char[]) input, dchar[] output=null, size_t* ate=null)
{
        int     produced;
        const(char)*   pIn = input.ptr;
        const(char)*   pMax = pIn + input.length;
        const(char)*   pValid;

        if (ate is null)
            if (input.length > output.length)
                output.length = input.length;

        if (input.length)
        foreach (ref dchar d; output)
        {
                pValid = pIn;
                dchar b = cast(dchar) *pIn;

                if (b & 0x80)
                {
                    if (b < 0xe0)
                       {
                       b &= 0x1f;
                       b = (b << 6) | (*++pIn & 0x3f);
                       }
                    else
                       {
                       if (b < 0xf0)
                          {
                          b &= 0x0f;
                          b = (b << 6) | (pIn[1] & 0x3f);
                          b = (b << 6) | (pIn[2] & 0x3f);
                          pIn += 2;
                          }
                       else
                          {
                          b &= 0x07;
                          b = (b << 6) | (pIn[1] & 0x3f);
                          b = (b << 6) | (pIn[2] & 0x3f);
                          b = (b << 6) | (pIn[3] & 0x3f);

                          if (b >= 0x110000)
                              onUnicodeError ("Unicode.toString32 : invalid utf8 input", pIn - input.ptr);
                          pIn += 3;
                          }
                       }
                }
                d = b;
                ++produced;

                // did we read past the end of the input?
                if (++pIn >= pMax)
                {
                    if (pIn > pMax)
                       {
                       // yep ~ return tail or throw error?
                       if (ate)
                          {
                          pIn = pValid;
                          --produced;
                          break;
                          }
                       onUnicodeError ("Unicode.toString32 : incomplete utf8 input", pIn - input.ptr);
                       }
                    else
                       break;
                }
        }

        // do we still have some input left?
        if (ate)
            *ate = pIn - input.ptr;
        else
           if (pIn < pMax)
               // this should never happen!
               onUnicodeError ("Unicode.toString32 : utf8 overflow", pIn - input.ptr);

        // return the produced output
        return output [0..produced];
}

/*******************************************************************************

        Encode Utf16 up to a maximum of 2 bytes long. Throws an exception
        where the input dchar is greater than 0x10ffff.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

wchar[] toString16 (const(dchar[]) input, wchar[] output=null, size_t* ate=null)
{
        if (ate)
            *ate = input.length;
        else
           {
           size_t estimate = input.length * 2 + 2;
           if (output.length < estimate)
               output.length = estimate;
           }

        wchar* pOut = output.ptr;
        wchar* pMax = pOut + output.length - 2;

        foreach (int eaten, dchar b; input)
                {
                // about to overflow the output?
                if (pOut > pMax)
                   {
                   // if streaming, just return the unused input
                   if (ate)
                      {
                      *ate = eaten;
                      break;
                      }

                   // reallocate the output buffer
                   size_t len = pOut - output.ptr;
                   output.length = len + len / 2;
                   pOut = output.ptr + len;
                   pMax = output.ptr + output.length - 2;
                   }

                if (b < 0x10000)
                    *pOut++ = cast(wchar)b;
                else
                   if (b < 0x110000)
                      {
                      pOut[0] = cast(wchar)(0xd800 | (((b - 0x10000) >> 10) & 0x3ff));
                      pOut[1] = cast(wchar)(0xdc00 | ((b - 0x10000) & 0x3ff));
                      pOut += 2;
                      }
                   else
                      onUnicodeError ("Unicode.toString16 : invalid dchar", eaten);
                }

        // return the produced output
        return output [0..(pOut - output.ptr)];
}

/*******************************************************************************

        Decode Utf16 produced by the above toString16() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

        Where 'ate' is provided, it will be set to the number of 
        elements consumed from the input, and the output buffer 
        will not be resized (or allocated). This represents a
        streaming mode, where slices of the input are processed
        in sequence rather than all at one time (should use 'ate'
        as an index for slicing into unconsumed input).

*******************************************************************************/

dchar[] toString32 (const(wchar[]) input, dchar[] output=null, size_t* ate=null)
{
        int     produced;
        const(wchar)*  pIn = input.ptr;
        const(wchar)*  pMax = pIn + input.length;
        const(wchar)*  pValid;

        if (ate is null)
            if (input.length > output.length)
                output.length = input.length;

        if (input.length)
        foreach (ref dchar d; output)
        {
                pValid = pIn;
                dchar b = cast(dchar) *pIn;

                // simple conversion ~ see http://www.unicode.org/faq/utf_bom.html#35
                if (b >= 0xd800 && b <= 0xdfff)
                    b = ((b - 0xd7c0) << 10) + (*++pIn - 0xdc00);

                if (b >= 0x110000)
                    onUnicodeError ("Unicode.toString32 : invalid utf16 input", pIn - input.ptr);

                d = b;
                ++produced;

                if (++pIn >= pMax)
                {
                    if (pIn > pMax)
                       {
                       // yep ~ return tail or throw error?
                       if (ate)
                          {
                          pIn = pValid;
                          --produced;
                          break;
                          }
                       onUnicodeError ("Unicode.toString32 : incomplete utf16 input", pIn - input.ptr);
                       }
                    else
                       break;
                }
        }

        // do we still have some input left?
        if (ate)
            *ate = pIn - input.ptr;
        else
           if (pIn < pMax)
               // this should never happen!
               onUnicodeError ("Unicode.toString32 : utf16 overflow", pIn - input.ptr);

        // return the produced output
        return output [0..produced];
}


/*******************************************************************************

        Decodes a single dchar from the given src text, and indicates how
        many chars were consumed from src to do so.

*******************************************************************************/

dchar decode (const(char[]) src, ref size_t ate)
{
        dchar[1] ret;
        return toString32 (src, ret, &ate)[0];
}

/*******************************************************************************

        Decodes a single dchar from the given src text, and indicates how
        many wchars were consumed from src to do so.

*******************************************************************************/

dchar decode (const(wchar[]) src, ref size_t ate)
{
        dchar[1] ret;
        return toString32 (src, ret, &ate)[0];
}

/*******************************************************************************

        Encode a dchar into the provided dst array, and return a slice of 
        it representing the encoding

*******************************************************************************/

char[] encode (char[] dst, dchar c)
{
        return toString ((&c)[0..1], dst);
}

/*******************************************************************************

        Encode a dchar into the provided dst array, and return a slice of 
        it representing the encoding

*******************************************************************************/

wchar[] encode (wchar[] dst, dchar c)
{
        return toString16 ((&c)[0..1], dst);
}

/*******************************************************************************

        Is the given character valid?

*******************************************************************************/

bool isValid (dchar c)
{
        return (c < 0xD800 || (c > 0xDFFF && c <= 0x10FFFF));
}

/*******************************************************************************

        Convert from a char[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

inout(T[]) fromString8(T) (inout(char[]) s, T[] dst) if (is (T == char))
{
    return s;
}

T[] fromString8(T) (const(char[]) s, T[] dst) if (!is (T == char))
{
        static if (is (T == wchar))
                   return .toString16 (s, dst);

        static if (is (T == dchar))
                   return .toString32 (s, dst);
}

/*******************************************************************************

        Convert from a wchar[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

inout(T[]) fromString16(T) (inout(wchar[]) s, T[] dst) if (is (T == wchar))
{
    return s;
}

T[] fromString16(T) (const(wchar[]) s, T[] dst) if (!is (T == wchar))
{
        static if (is (T == char))
                   return .toString (s, dst);

        static if (is (T == dchar))
                   return .toString32 (s, dst);
}

/*******************************************************************************

        Convert from a dchar[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

inout(T[]) fromString32(T) (inout(dchar[]) s, T[] dst) if (is (T == dchar))
{
    return s;
}

T[] fromString32(T) (const(dchar[]) s, T[] dst) if (!is (T == dchar))
{
        static if (is (T == char))
                   return .toString (s, dst);

        static if (is (T == wchar))
                   return .toString16 (s, dst);
}

/*******************************************************************************

        Adjust the content such that no partial encodings exist on the 
        left side of the provided text.

        Returns a slice of the input

*******************************************************************************/

T[] cropLeft(T) (T[] s)
{
        static if (is (T == char))
                   for (int i=0; i < s.length && (s[i] & 0x80); ++i)
                        if ((s[i] & 0xc0) is 0xc0)
                             return s [i..$];

        static if (is (T == wchar))
                   // skip if first char is a trailing surrogate
                   if ((s[0] & 0xfffffc00) is 0xdc00)
                        return s [1..$];

        return s;
}

/*******************************************************************************

        Adjust the content such that no partial encodings exist on the 
        right side of the provided text.

        Returns a slice of the input

*******************************************************************************/

T[] cropRight(T) (T[] s)
{
        if (s.length)
           {
           size_t i = s.length - 1;
           static if (is (T == char))
                      while (i && (s[i] & 0x80))
                      {
                             if ((s[i] & 0xc0) is 0xc0)
                                {
                                // located the first byte of a sequence
                                ubyte b = s[i];
                                size_t d = s.length - i;

                                // is it a 3 byte sequence?
                                if (b & 0x20)
                                    --d;
   
                                // or a four byte sequence?
                                if (b & 0x10)
                                    --d;

                                // is the sequence complete?
                                if (d is 2)
                                    i = s.length;
                                return s [0..i];
                                }
                             else 
                                --i;
                      }

           static if (is (T == wchar))
                      // skip if last char is a leading surrogate
                      if ((s[i] & 0xfffffc00) is 0xd800)
                           return s [0..$-1];
           }
        return s;
}



/*******************************************************************************

*******************************************************************************/

debug (Utf)
{
        import tango.io.Console;

        void main()
        {
                auto s = "[\xc2\xa2\xc2\xa2\xc2\xa2]";
                Cout (s).newline;

                Cout (cropLeft(s[0..$])).newline;
                Cout (cropLeft(s[1..$])).newline;
                Cout (cropLeft(s[2..$])).newline;
                Cout (cropLeft(s[3..$])).newline;
                Cout (cropLeft(s[4..$])).newline;
                Cout (cropLeft(s[5..$])).newline;

                Cout (cropRight(s[0..$])).newline;
                Cout (cropRight(s[0..$-1])).newline;
                Cout (cropRight(s[0..$-2])).newline;
                Cout (cropRight(s[0..$-3])).newline;
                Cout (cropRight(s[0..$-4])).newline;
                Cout (cropRight(s[0..$-5])).newline;
        }
}

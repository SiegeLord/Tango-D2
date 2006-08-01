/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2004

        authors:        Kris

*******************************************************************************/

module tango.text.convert.Unicode;

private import tango.text.convert.Type;

private extern (C) void onUnicodeError( char[] msg, size_t idx );

/*******************************************************************************

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

struct Unicode
{
        // see http://icu.sourceforge.net/docs/papers/forms_of_unicode/#t2
        enum    {
                Unknown,
                UTF_8,
                UTF_8N,
                UTF_16,
                UTF_16BE,
                UTF_16LE,
                UTF_32,
                UTF_32BE,
                UTF_32LE,
                };

        /***********************************************************************

        ***********************************************************************/

        static bool isValid (int encoding)
        {
                return cast(bool) (encoding >= Unknown && encoding <= UTF_32LE);
        }

        /***********************************************************************

        ***********************************************************************/

        package static final void error (char[] msg, size_t idx = 0)
        {
                onUnicodeError (msg, idx);
        }

        /***********************************************************************

                Encode Utf8 up to a maximum of 4 bytes long (five & six byte
                variations are not supported).

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.
                For example:

                char[] output;

                char[] result = toUtf8 (input, output);

                // reset output after a realloc
                if (result.length > output.length)
                    output = result;

        ***********************************************************************/

        static final char[] toUtf8 (wchar[] input, char[] output=null, uint* ate=null)
        {
                if (ate)
                    *ate = input.length;
                else
                   {
                   // potentially reallocate output
                   int estimate = input.length * 2 + 3;
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
                           int len = pOut - output.ptr;
                           output.length = len + len / 2;
                           pOut = output.ptr + len;
                           pMax = output.ptr + output.length - 3;
                           }

                        if (b < 0x80)
                            *pOut++ = b;
                        else
                           if (b < 0x0800)
                              {
                              pOut[0] = 0xc0 | ((b >> 6) & 0x3f);
                              pOut[1] = 0x80 | (b & 0x3f);
                              pOut += 2;
                              }
                           else
                              if (b < 0xd800 || b > 0xdfff)
                                 {
                                 pOut[0] = 0xe0 | ((b >> 12) & 0x3f);
                                 pOut[1] = 0x80 | ((b >> 6)  & 0x3f);
                                 pOut[2] = 0x80 | (b & 0x3f);
                                 pOut += 3;
                                 }
                              else
                                 // deal with surrogate-pairs
                                 return toUtf8 (toUtf32(input, null, ate), output);
                        }

                // return the produced output
                return output [0..(pOut - output.ptr)];
        }


        /***********************************************************************

                Decode Utf8 produced by the above toUtf8() method.

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.

        ***********************************************************************/

        static final wchar[] toUtf16 (char[] input, wchar[] output=null, uint* ate=null)
        {
                int     produced;
                char*   pIn = input;
                char*   pMax = pIn + input.length;
                char*   pValid;

                if (ate is null)
                    if (input.length > output.length)
                        output.length = input.length;

                if (input.length)
                foreach (inout wchar d; output)
                        {
                        pValid = pIn;
                        wchar b = cast(wchar) *pIn;

                        if (b & 0x80)
                            if (b < 0xe0)
                               {
                               b &= 0x1f;
                               b = (b << 6) | (*++pIn & 0x3f);
                               }
                            else
                               if (b < 0xf0)
                                  {
                                  b &= 0x0f;
                                  b = (b << 6) | (pIn[1] & 0x3f);
                                  b = (b << 6) | (pIn[2] & 0x3f);
                                  pIn += 2;
                                  }
                               else
                                  // deal with surrogate-pairs
                                  return toUtf16 (toUtf32(input, null, ate), output);

                        d = b;
                        ++produced;

                        // did we read past the end of the input?
                        if (++pIn >= pMax)
                            if (pIn > pMax)
                               {
                               // yep ~ return tail or throw error?
                               if (ate)
                                  {
                                  pIn = pValid;
                                  --produced;
                                  break;
                                  }
                               error ("Unicode.toUtf16 : incomplete utf8 input", pIn - input.ptr);
                               }
                            else
                               break;
                        }

                // do we still have some input left?
                if (ate)
                    *ate = pIn - input.ptr;
                else
                   if (pIn < pMax)
                       // this should never happen!
                       error ("Unicode.toUtf16 : utf8 overflow", pIn - input.ptr);

                // return the produced output
                return output [0..produced];
        }


        /***********************************************************************

                Encode Utf8 up to a maximum of 4 bytes long (five & six
                byte variations are not supported). Throws an exception
                where the input dchar is greater than 0x10ffff.

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.

        ***********************************************************************/

        static final char[] toUtf8 (dchar[] input, char[] output=null, uint* ate=null)
        {
                if (ate)
                    *ate = input.length;
                else
                   {
                   // potentially reallocate output
                   int estimate = input.length * 2 + 4;
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
                           int len = pOut - output.ptr;
                           output.length = len + len / 2;
                           pOut = output.ptr + len;
                           pMax = output.ptr + output.length - 4;
                           }

                        if (b < 0x80)
                            *pOut++ = b;
                        else
                           if (b < 0x0800)
                              {
                              pOut[0] = 0xc0 | ((b >> 6) & 0x3f);
                              pOut[1] = 0x80 | (b & 0x3f);
                              pOut += 2;
                              }
                           else
                              if (b < 0x10000)
                                 {
                                 pOut[0] = 0xe0 | ((b >> 12) & 0x3f);
                                 pOut[1] = 0x80 | ((b >> 6)  & 0x3f);
                                 pOut[2] = 0x80 | (b & 0x3f);
                                 pOut += 3;
                                 }
                              else
                                 if (b < 0x110000)
                                    {
                                    pOut[0] = 0xf0 | ((b >> 18) & 0x3f);
                                    pOut[1] = 0x80 | ((b >> 12) & 0x3f);
                                    pOut[2] = 0x80 | ((b >> 6)  & 0x3f);
                                    pOut[3] = 0x80 | (b & 0x3f);
                                    pOut += 4;
                                    }
                                 else
                                    error ("Unicode.toUtf8 : invalid dchar", eaten);
                        }

                // return the produced output
                return output [0..(pOut - output.ptr)];
        }


        /***********************************************************************

                Decode Utf8 produced by the above toUtf8() method.

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.

        ***********************************************************************/

        static final dchar[] toUtf32 (char[] input, dchar[] output=null, uint* ate=null)
        {
                int     produced;
                char*   pIn = input;
                char*   pMax = pIn + input.length;
                char*   pValid;

                if (ate is null)
                    if (input.length > output.length)
                        output.length = input.length;

                if (input.length)
                foreach (inout dchar d; output)
                        {
                        pValid = pIn;
                        dchar b = cast(dchar) *pIn;

                        if (b & 0x80)
                            if (b < 0xe0)
                               {
                               b &= 0x1f;
                               b = (b << 6) | (*++pIn & 0x3f);
                               }
                            else
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
                                      error ("Unicode.toUtf32 : invalid utf8 input", pIn - input.ptr);
                                  pIn += 3;
                                  }

                        d = b;
                        ++produced;

                        // did we read past the end of the input?
                        if (++pIn >= pMax)
                            if (pIn > pMax)
                               {
                               // yep ~ return tail or throw error?
                               if (ate)
                                  {
                                  pIn = pValid;
                                  --produced;
                                  break;
                                  }
                               error ("Unicode.toUtf32 : incomplete utf8 input", pIn - input.ptr);
                               }
                            else
                               break;
                        }

                // do we still have some input left?
                if (ate)
                    *ate = pIn - input.ptr;
                else
                   if (pIn < pMax)
                       // this should never happen!
                       error ("Unicode.toUtf32 : utf8 overflow", pIn - input.ptr);

                // return the produced output
                return output [0..produced];
        }

        /***********************************************************************

                Encode Utf16 up to a maximum of 2 bytes long. Throws an exception
                where the input dchar is greater than 0x10ffff.

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.

        ***********************************************************************/

        static final wchar[] toUtf16 (dchar[] input, wchar[] output=null, uint* ate=null)
        {
                if (ate)
                    *ate = input.length;
                else
                   {
                   int estimate = input.length * 2 + 2;
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
                           int len = pOut - output.ptr;
                           output.length = len + len / 2;
                           pOut = output.ptr + len;
                           pMax = output.ptr + output.length - 2;
                           }

                        if (b < 0x10000)
                            *pOut++ = b;
                        else
                           if (b < 0x110000)
	                      {
                              pOut[0] = 0xd800 | (((b - 0x10000) >> 10) & 0x3ff);
                              pOut[1] = 0xdc00 | ((b - 0x10000) & 0x3ff);
                              pOut += 2;
                              }
                           else
                              error ("Unicode.toUtf16 : invalid dchar", eaten);
                        }

                // return the produced output
                return output [0..(pOut - output.ptr)];
        }

        /***********************************************************************

                Decode Utf16 produced by the above toUtf16() method.

                If the output is provided off the stack, it should be large
                enough to encompass the entire transcoding; failing to do
                so will cause the output to be moved onto the heap instead.

                Returns a slice of the output buffer, corresponding to the
                converted characters. For optimum performance, the returned
                buffer should be specified as 'output' on subsequent calls.

        ***********************************************************************/

        static final dchar[] toUtf32 (wchar[] input, dchar[] output=null, uint* ate=null)
        {
                int     produced;
                wchar*  pIn = input;
                wchar*  pMax = pIn + input.length;
                wchar*  pValid;

                if (ate is null)
                    if (input.length > output.length)
                        output.length = input.length;

                if (input.length)
                foreach (inout dchar d; output)
                        {
                        pValid = pIn;
                        dchar b = cast(dchar) *pIn;

                        // simple conversion ~ see http://www.unicode.org/faq/utf_bom.html#35
                        if (b >= 0xd800 && b <= 0xdfff)
                            b = ((b - 0xd7c0) << 10) + (*++pIn - 0xdc00);

                        if (b >= 0x110000)
                            error ("Unicode.toUtf32 : invalid utf16 input", pIn - input.ptr);

                        d = b;
                        ++produced;

                        if (++pIn >= pMax)
                            if (pIn > pMax)
                               {
                               // yep ~ return tail or throw error?
                               if (ate)
                                  {
                                  pIn = pValid;
                                  --produced;
                                  break;
                                  }
                               error ("Unicode.toUtf32 : incomplete utf16 input", pIn - input.ptr);
                               }
                            else
                               break;
                        }

                // do we still have some input left?
                if (ate)
                    *ate = pIn - input.ptr;
                else
                   if (pIn < pMax)
                       // this should never happen!
                       error ("Unicode.toUtf32 : utf16 overflow", pIn - input.ptr);

                // return the produced output
                return output [0..produced];
        }


        /***********************************************************************

                Convert from an external coding of 'type' to an internally
                normalized representation of T.

                T refers to the destination, whereas 'type' refers to the
                source.

        ***********************************************************************/

        struct Into(T)
        {
                /***************************************************************

                ***************************************************************/

                static uint type ()
                {
                        static if (is (T == char))
                                   return Type.Utf8;
                        static if (is (T == wchar))
                                   return Type.Utf16;
                        static if (is (T == dchar))
                                   return Type.Utf32;
                }

                /***************************************************************

                ***************************************************************/

                static void[] convert (void[] x, uint type, void[] dst=null, uint* ate=null)
                {
                        void[] ret;

                        static if (is (T == char))
                                  {
                                  if (type == Type.Utf8)
                                      return x;

                                  if (type == Type.Utf16)
                                      ret = toUtf8 (cast(wchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf8 (cast(dchar[]) x, cast(char[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (type == Type.Utf16)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf16 (cast(char[]) x, cast(wchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf16 (cast(dchar[]) x, cast(wchar[]) dst, ate);
                                  }

                        static if (is (T == dchar))
                                  {
                                  if (type == Type.Utf32)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf32 (cast(char[]) x, cast(dchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf16)
                                      ret = toUtf32 (cast(wchar[]) x, cast(dchar[]) dst, ate);
                                  }
                        if (ate)
                            *ate *= Type.widths[type];
                        return ret;
                }
        }


        /***********************************************************************

                Convert to an external coding of 'type' from an internally
                normalized representation of T.

                T refers to the source, whereas 'type' is the destination.

        ***********************************************************************/

        struct From(T)
        {
                /***************************************************************

                ***************************************************************/

                static uint type ()
                {
                        static if (is (T == char))
                                   return Type.Utf8;
                        static if (is (T == wchar))
                                   return Type.Utf16;
                        static if (is (T == dchar))
                                   return Type.Utf32;
                }

                /***************************************************************

                ***************************************************************/

                static void[] convert (void[] x, uint type, void[] dst=null, uint* ate=null)
                {
                        void[] ret;

                        static if (is (T == char))
                                  {
                                  if (type == Type.Utf8)
                                      return x;

                                  if (type == Type.Utf16)
                                      ret = toUtf16 (cast(char[]) x, cast(wchar[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf32 (cast(char[]) x, cast(dchar[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (type == Type.Utf16)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf8 (cast(wchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf32)
                                      ret = toUtf32 (cast(wchar[]) x, cast(dchar[]) dst, ate);
                                  }

                        static if (is (T == dchar))
                                  {
                                  if (type == Type.Utf32)
                                      return x;

                                  if (type == Type.Utf8)
                                      ret = toUtf8 (cast(dchar[]) x, cast(char[]) dst, ate);
                                  else
                                  if (type == Type.Utf16)
                                      ret = toUtf16 (cast(dchar[]) x, cast(wchar[]) dst, ate);
                                  }

                        static if (is (T == wchar))
                                  {
                                  if (ate)
                                      *ate *= 2;
                                  }
                        static if (is (T == dchar))
                                  {
                                  if (ate)
                                      *ate *= 4;
                                  }
                        return ret;
                }
        }


        /***********************************************************************

                Transcodes the UTF string src to the UTF format required by dst.

                Params:
                        src = The source string to convert.
                        dst = The destination buffer.
                        ate = The number of elements consumed from src.

                Returns:
                        The converted string.

                Throws:
                        UnicodeException.

        ***********************************************************************/

        DstElem[] convert (DstElem, SrcElem) (SrcElem[] src, DstElem[] dst=null, uint* ate=null)
        {
                static if (is (DstElem == FromElem))
                          {
                          return src;
                          }
                else
                          {
                          DstElem[] ret;

                          static if (is (DstElem == char))
                                     ret = toUtf8 (src, dst, ate);
                          else
                          static if (is (DstElem == wchar))
                                     ret = toUtf16 (src, dst, ate);
                          else
                          static if (is (DstElem == dchar))
                                     ret = toUtf32 (src, dst, ate);
                          else
                                     static assert (false, "Invalid destination type.");
                          if (ate)
                              *ate *= SrcElem.sizeof;
                          return ret;
                          }
        }
}
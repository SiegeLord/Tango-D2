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

public extern (C) void onUnicodeError(char[] msg, size_t idx = 0);

private const ubyte[256] UTF8_BYTES_NEEDED =
[
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
    4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0
];

private bool invalidContChar(char c)
{
    return (c & 0xC0) != 0x80;
}

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

*******************************************************************************/

char[] toString(wchar[] input, char[] output = null, uint* ate = null)
{
    if(ate)
        *ate = input.length;
    else
    {
        // potentially reallocate output
        int estimate = input.length * 2 + 4;
        
        if(output.length < estimate)
            output.length = estimate;
    }

    wchar* pIn = input.ptr;
    wchar* pInMax = pIn + input.length;
    char* pOut = output.ptr;
    char* pMax = pOut + output.length - 4;

    while(pIn < pInMax)
    {
        // about to overflow the output?
        if(pOut > pMax)
        {
            // if streaming, just return the unused input
            if(ate)
            {
                *ate = pIn - input.ptr;
                break;
            }

            // reallocate the output buffer
            int len = pOut - output.ptr;
            output.length = len + (len / 2);
            pOut = output.ptr + len;
            pMax = output.ptr + output.length - 4;
        }
        
        dchar b = cast(dchar)*pIn;

        if(b < 0x80)
            *pOut++ = b;
        else if(b < 0x0800)
        {
            pOut[0] = cast(char)(0xc0 | ((b >> 6) & 0x3f));
            pOut[1] = cast(char)(0x80 | (b & 0x3f));
            pOut += 2;
        }
        else if(b < 0xd800 || b > 0xdfff)
        {
            pOut[0] = cast(char)(0xe0 | ((b >> 12) & 0x3f));
            pOut[1] = cast(char)(0x80 | ((b >> 6)  & 0x3f));
            pOut[2] = cast(char)(0x80 | (b & 0x3f));
            pOut += 3;
        }
        else
        {
            // deal with surrogate-pairs

            if(pIn + 1 >= pInMax)
                onUnicodeError("Unicode.toString : leading surrogate followed by end-of-text", pIn - input.ptr);
            else if(pIn[1] < 0xdc00 || pIn[1] > 0xdfff)
                onUnicodeError("Unicode.toString : leading surrogate followed by non-trailing surrogate", pIn - input.ptr);

            b = ((b - 0xd7c0) << 10) + (pIn[1] - 0xdc00);
            pIn++;

            pOut[0] = cast(char)(0xf0 | (b >> 18));
            pOut[1] = cast(char)(0x80 | ((b >> 12) & 0x3f));
            pOut[2] = cast(char)(0x80 | ((b >> 6) & 0x3f));
            pOut[3] = cast(char)(0x80 | (b & 0x3f));
            pOut += 4;
        }

        pIn++;
        assert(pIn <= pInMax);
    }

    // return the produced output
    return output[0 .. (pOut - output.ptr)];
}

/*******************************************************************************

        Decode Utf8 produced by the above toString() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

*******************************************************************************/

wchar[] toString16(char[] input, wchar[] output = null, uint* ate = null)
{
    char*   pIn = input.ptr;
    char*   pMax = pIn + input.length;
    char*   pValid;
    
    if(ate is null && input.length > output.length)
        output.length = input.length;

    wchar* pOut = output.ptr;
    wchar* pOutMax = pOut + output.length - 2;

    if(input.length)
    {

        while(pIn < pMax)
        {
            // about to overflow the output?
            if(pOut > pOutMax)
            {
                // if streaming, just return the unused input
                if(ate)
                {
                    *ate = pIn - input.ptr;
                    break;
                }

                // reallocate the output buffer
                int len = pOut - output.ptr;
                output.length = len + (len / 2);
                pOut = output.ptr + len;
                pOutMax = output.ptr + output.length - 2;
            }

            pValid = pIn;
            dchar b = cast(dchar)*pIn;

            // do we have a multibyte encoding?
            if(b & 0x80)
            {
                // those with 0 needed bytes are either overlong (5 or 6 bytes) or just invalid
                if(UTF8_BYTES_NEEDED[b] == 0)
                    onUnicodeError("Unicode.toString16 : invalid char", pIn - input.ptr);

                // will we read past the end of the input?
                if(pIn + UTF8_BYTES_NEEDED[b] > pMax) // just >, not >=, since pIn counts as one char
                {
                    // yep.  return tail or throw error?
                    if(ate)
                    {
                        pIn = pValid;
                        break;
                    }

                    onUnicodeError("Unicode.toString16 : incomplete utf8 input", pIn - input.ptr);
                }

                if(b < 0xe0) // 2-byte char?
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]))
                        onUnicodeError("Unicode.toString16 : invalid continuation byte", pIn - input.ptr);

                    b &= 0x1f;
                    b = cast(dchar)((b << 6) | (*++pIn & 0x3f));

                    if(b < 0x80)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
                else if(b < 0xf0) // 3-byte char?
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]) || invalidContChar(pIn[2]))
                        onUnicodeError("Unicode.toString16 : invalid continuation bytes", pIn - input.ptr);

                    b &= 0x0f;
                    b = cast(dchar)((b << 6) | (pIn[1] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[2] & 0x3f));
                    pIn += 2;
                    
                    if(b < 0x800)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
                else // 4-byte char
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]) || invalidContChar(pIn[2]) || invalidContChar(pIn[3]))
                        onUnicodeError("Unicode.toString16 : invalid continuation bytes", pIn - input.ptr);

                    b &= 0x07;
                    b = cast(dchar)((b << 6) | (pIn[1] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[2] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[3] & 0x3f));
                    pIn += 3;
                    
                    if(b < 0x10000)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
            }

            // did they encode an invalid character for some reason?
            if(!isValid(b))
                onUnicodeError("Unicode.toString16 : correctly-encoded but invalid char", pIn - input.ptr);

            // is it surrogate time?
            if(b > 0xFFFF)
            {
                pOut[0] = cast(wchar)(0xd800 | (((b - 0x10000) >> 10) & 0x3ff));
                pOut[1] = cast(wchar)(0xdc00 | ((b - 0x10000) & 0x3ff));
                pOut += 2;
            }
            else
                *pOut++ = b;

            ++pIn;
            assert(pIn <= pMax); // > pMax should already have been handled
        }
    }

    // do we still have some input left?
    if(ate)
        *ate = pIn - input.ptr;
    else if(pIn < pMax)
        // this should never happen!
        onUnicodeError("Unicode.toString16 : utf8 overflow", pIn - input.ptr);

    // return the produced output
    return output[0 .. pOut - output.ptr];
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

*******************************************************************************/

char[] toString(dchar[] input, char[] output = null, uint* ate = null)
{
    if(ate)
        *ate = input.length;
    else
    {
        // potentially reallocate output
        int estimate = input.length * 2 + 4;

        if(output.length < estimate)
            output.length = estimate;
    }

    char* pOut = output.ptr;
    char* pMax = pOut + output.length - 4;

    foreach(int eaten, dchar b; input)
    {
        // about to overflow the output?
        if(pOut > pMax)
        {
            // if streaming, just return the unused input
            if(ate)
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

        if(b < 0x80)
            *pOut++ = b;
        else if(b < 0x0800)
        {
            pOut[0] = cast(char)(0xc0 | ((b >> 6) & 0x3f));
            pOut[1] = cast(char)(0x80 | (b & 0x3f));
            pOut += 2;
        }
        else if(b >= 0xd800 && b <= 0xdfff)
            onUnicodeError("Unicode.toString : invalid dchar", eaten);
        else if(b < 0x10000)
        {
            pOut[0] = cast(char)(0xe0 | ((b >> 12) & 0x3f));
            pOut[1] = cast(char)(0x80 | ((b >> 6)  & 0x3f));
            pOut[2] = cast(char)(0x80 | (b & 0x3f));
            pOut += 3;
        }
        else if(b < 0x110000)
        {
            pOut[0] = cast(char)(0xf0 | ((b >> 18) & 0x3f));
            pOut[1] = cast(char)(0x80 | ((b >> 12) & 0x3f));
            pOut[2] = cast(char)(0x80 | ((b >> 6)  & 0x3f));
            pOut[3] = cast(char)(0x80 | (b & 0x3f));
            pOut += 4;
        }
        else
            onUnicodeError("Unicode.toString : invalid dchar", eaten);
    }

    // return the produced output
    return output[0 .. (pOut - output.ptr)];
}


/*******************************************************************************

        Decode Utf8 produced by the above toString() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

*******************************************************************************/

dchar[] toString32(char[] input, dchar[] output = null, uint* ate = null)
{
    char*   pIn = input.ptr;
    char*   pMax = pIn + input.length;
    char*   pValid;

    if(ate is null && input.length > output.length)
        output.length = input.length;

    dchar* pOut = output.ptr;
    dchar* pOutMax = pOut + output.length - 1;

    if(input.length)
    {
        while(pIn < pMax)
        {
            // about to overflow the output?
            if(pOut > pOutMax)
            {
                // if streaming, just return the unused input
                if(ate)
                {
                    *ate = pIn - input.ptr;
                    break;
                }

                // reallocate the output buffer
                int len = pOut - output.ptr;
                output.length = len + (len / 2);
                pOut = output.ptr + len;
                pOutMax = output.ptr + output.length - 1;
            }

            pValid = pIn;
            dchar b = cast(dchar)*pIn;

            // do we have a multibyte encoding?
            if(b & 0x80)
            {
                // those with 0 needed bytes are either overlong (5 or 6 bytes) or just invalid
                if(UTF8_BYTES_NEEDED[b] == 0)
                    onUnicodeError("Unicode.toString16 : invalid char", pIn - input.ptr);

                // will we read past the end of the input?
                if(pIn + UTF8_BYTES_NEEDED[b] > pMax) // just >, not >=, since pIn counts as one char
                {
                    // yep.  return tail or throw error?
                    if(ate)
                    {
                        pIn = pValid;
                        break;
                    }

                    onUnicodeError("Unicode.toString16 : incomplete utf8 input", pIn - input.ptr);
                }

                if(b < 0xe0) // 2-byte char?
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]))
                        onUnicodeError("Unicode.toString16 : invalid continuation byte", pIn - input.ptr);

                    b &= 0x1f;
                    b = cast(dchar)((b << 6) | (*++pIn & 0x3f));

                    if(b < 0x80)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
                else if(b < 0xf0) // 3-byte char?
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]) || invalidContChar(pIn[2]))
                        onUnicodeError("Unicode.toString16 : invalid continuation bytes", pIn - input.ptr);

                    b &= 0x0f;
                    b = cast(dchar)((b << 6) | (pIn[1] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[2] & 0x3f));
                    pIn += 2;
                    
                    if(b < 0x800)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
                else // 4-byte char
                {
                    // check that following bytes are good
                    if(invalidContChar(pIn[1]) || invalidContChar(pIn[2]) || invalidContChar(pIn[3]))
                        onUnicodeError("Unicode.toString16 : invalid continuation bytes", pIn - input.ptr);

                    b &= 0x07;
                    b = cast(dchar)((b << 6) | (pIn[1] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[2] & 0x3f));
                    b = cast(dchar)((b << 6) | (pIn[3] & 0x3f));
                    pIn += 3;
                    
                    if(b < 0x10000)
                        onUnicodeError("Unicode.toString16 : non-canonical character encoding", pIn - input.ptr);
                }
            }

            // did they encode an invalid character for some reason?
            if(!isValid(b))
                onUnicodeError("Unicode.toString16 : correctly-encoded but invalid char", pIn - input.ptr);

            *pOut++ = b;
            ++pIn;
            assert(pIn <= pMax); // > pMax should already have been handled
        }
    }
    
    // do we still have some input left?
    if(ate)
        *ate = pIn - input.ptr;
    else if(pIn < pMax)
        // this should never happen!
        onUnicodeError("Unicode.toString32 : utf8 overflow", pIn - input.ptr);

    // return the produced output
    return output[0 .. pOut - output.ptr];
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

*******************************************************************************/

wchar[] toString16(dchar[] input, wchar[] output = null, uint* ate = null)
{
    if(ate)
        *ate = input.length;
    else
    {
        int estimate = input.length * 2 + 2;
        
        if(output.length < estimate)
            output.length = estimate;
    }

    wchar* pOut = output.ptr;
    wchar* pMax = pOut + output.length - 2;

    foreach(int eaten, dchar b; input)
    {
        // about to overflow the output?
        if(pOut > pMax)
        {
            // if streaming, just return the unused input
            if(ate)
            {
                *ate = eaten;
                break;
            }
            
            // reallocate the output buffer
            int len = pOut - output.ptr;
            output.length = len + (len / 2);
            pOut = output.ptr + len;
            pMax = output.ptr + output.length - 2;
        }

        if(b >= 0xd800 && b <= 0xdfff)
            onUnicodeError("Unicode.toString16 : invalid dchar", eaten);
        else if(b < 0x10000)
            *pOut++ = b;
        else if(b < 0x110000)
        {
            pOut[0] = cast(wchar)(0xd800 | (((b - 0x10000) >> 10) & 0x3ff));
            pOut[1] = cast(wchar)(0xdc00 | ((b - 0x10000) & 0x3ff));
            pOut += 2;
        }
        else
            onUnicodeError("Unicode.toString16 : invalid dchar", eaten);
    }

    // return the produced output
    return output[0 .. (pOut - output.ptr)];
}

/*******************************************************************************

        Decode Utf16 produced by the above toString16() method.

        If the output is provided off the stack, it should be large
        enough to encompass the entire transcoding; failing to do
        so will cause the output to be moved onto the heap instead.

        Returns a slice of the output buffer, corresponding to the
        converted characters. For optimum performance, the returned
        buffer should be specified as 'output' on subsequent calls.

*******************************************************************************/

dchar[] toString32(wchar[] input, dchar[] output = null, uint* ate = null)
{
    int     produced;
    wchar*  pIn = input.ptr;
    wchar*  pMax = pIn + input.length;
    wchar*  pValid;
    
    if(ate is null && input.length > output.length)
        output.length = input.length;

    if(input.length)
    {
        foreach(inout dchar d; output)
        {
            pValid = pIn;
            dchar b = cast(dchar)*pIn;

            if(b >= 0xd800 && b <= 0xdbff)
            {
                if(pIn + 1 >= pMax)
                    onUnicodeError("Unicode.toString : leading surrogate followed by end-of-text", pIn - input.ptr);
                else if(pIn[1] < 0xdc00 || pIn[1] > 0xdfff)
                    onUnicodeError("Unicode.toString : leading surrogate followed by non-trailing surrogate", pIn - input.ptr);
                
                // simple conversion ~ see http://www.unicode.org/faq/utf_bom.html#35
                b = ((b - 0xd7c0) << 10) + (*++pIn - 0xdc00);
            }
            else if(b >= 0xdc00 && b <= 0xbfff)
                onUnicodeError("Unicode.toString32 : trailing surrogate without leading surrogate", pIn - input.ptr);

            if(!isValid(b))
                onUnicodeError("Unicode.toString32 : invalid utf16 input", pIn - input.ptr);

            d = b;
            ++produced;

            if(++pIn >= pMax)
            {
                if(pIn > pMax)
                {
                    // yep ~ return tail or throw error?
                    if(ate)
                    {
                        pIn = pValid;
                        --produced;
                        break;
                    }
                    
                    onUnicodeError("Unicode.toString32 : incomplete utf16 input", pIn - input.ptr);
                }
                else
                    break;
            }
        }
    }

    // do we still have some input left?
    if(ate)
        *ate = pIn - input.ptr;
    else if(pIn < pMax)
        // this should never happen!
        onUnicodeError("Unicode.toString32 : utf16 overflow", pIn - input.ptr);

    // return the produced output
    return output[0 .. produced];
}


/*******************************************************************************

        Decodes a single dchar from the given src text, and indicates how
        many chars were consumed from src to do so.

*******************************************************************************/

dchar decode(char[] src, inout uint ate)
{
    dchar[1] ret;
    return toString32(src, ret, &ate)[0];
}

/*******************************************************************************

        Decodes a single dchar from the given src text, and indicates how
        many wchars were consumed from src to do so.

*******************************************************************************/

dchar decode(wchar[] src, inout uint ate)
{
    dchar[1] ret;
    return toString32(src, ret, &ate)[0];
}

/*******************************************************************************

        Encode a dchar into the provided dst array, and return a slice of 
        it representing the encoding

*******************************************************************************/

char[] encode(char[] dst, dchar c)
{
    return toString((&c)[0..1], dst);
}

/*******************************************************************************

        Encode a dchar into the provided dst array, and return a slice of 
        it representing the encoding

*******************************************************************************/

wchar[] encode(wchar[] dst, dchar c)
{
    return toString16((&c)[0..1], dst);
}

/*******************************************************************************

        Is the given character valid?

*******************************************************************************/

bool isValid(dchar c)
{
    return (c < 0xD800 || (c > 0xDFFF && c <= 0x10FFFF));
}

/*******************************************************************************

        Convert from a char[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

T[] fromString8(T)(char[] s, T[] dst)
{
    static if(is(T == char))
        return s;
    else static if(is(T == wchar))
        return .toString16(s, dst);
    else static if(is(T == dchar))
        return .toString32(s, dst);
    else
        static assert(false, "Unicode.fromString8 : invalid destination array element type");
}

/*******************************************************************************

        Convert from a wchar[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

T[] fromString16(T)(wchar[] s, T[] dst)
{
    static if(is(T == wchar))
        return s;
    else static if(is(T == char))
        return .toString(s, dst);
    else static if(is(T == dchar))
        return .toString32(s, dst);
    else
        static assert(false, "Unicode.fromString16 : invalid destination array element type");
}

/*******************************************************************************

        Convert from a dchar[] into the type of the dst provided. 

        Returns a slice of the given dst, where it is sufficiently large
        to house the result, or a heap-allocated array otherwise. Returns
        the original input where no conversion is required.

*******************************************************************************/

T[] fromString32(T)(dchar[] s, T[] dst)
{
    static if(is(T == dchar))
        return s;
    else static if(is(T == char))
        return .toString(s, dst);
    else static if(is(T == wchar))
        return .toString16 (s, dst);
    else
        static assert(false, "Unicode.fromString32 : invalid destination array element type");
}

/*******************************************************************************

        Adjust the content such that no partial encodings exist on the 
        left side of the provided text.

        Returns a slice of the input

*******************************************************************************/

T[] cropLeft(T)(T[] s)
{
    static if(is(T == char))
    {
        for(int i = 0; i < s.length && (s[i] & 0x80); ++i)
            if((s[i] & 0xc0) is 0xc0)
                return s [i .. $];
    }
    else static if(is(T == wchar))
    {
        // skip if first char is a trailing surrogate
        if((s[0] & 0xfffffc00) is 0xdc00)
            return s [1 .. $];
    }
    else
        static assert(is(T == dchar), "Unicode.cropLeft : invalid array element type");

    return s;
}

/*******************************************************************************

        Adjust the content such that no partial encodings exist on the 
        right side of the provided text.

        Returns a slice of the input

*******************************************************************************/

T[] cropRight(T)(T[] s)
{
    auto i = s.length - 1;

    static if (is (T == char))
    {
        while(i && (s[i] & 0x80))
        {
            if((s[i] & 0xc0) is 0xc0)
            {
                // located the first byte of a sequence
                ubyte b = s[i];
                int d = s.length - i;

                // is it a 3 byte sequence?
                if(b & 0x20)
                    --d;
                // or a four byte sequence?
                if(b & 0x10)
                    --d;
                // is the sequence complete?
                if(d is 2)
                    i = s.length;

                return s[0 .. i];
            }
            else
                --i;
        }
    }
    else static if(is(T == wchar))
    {
        // skip if last char is a leading surrogate
        if((s[i] & 0xfffffc00) is 0xd800)
            return s[0 .. $ - 1];
    }
    else
        static assert(is(T == dchar), "Unicode.cropRight : invalid array element type");

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

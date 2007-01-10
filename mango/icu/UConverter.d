/*******************************************************************************

        @file UConverter.d
        
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


        @version        Initial version, October 2004      
        @author         Kris

        Note that this package and documentation is built around the ICU 
        project (http://oss.software.ibm.com/icu/). Below is the license 
        statement as specified by that software:


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        ICU License - ICU 1.8.1 and later

        COPYRIGHT AND PERMISSION NOTICE

        Copyright (c) 1995-2003 International Business Machines Corporation and 
        others.

        All rights reserved.

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, and/or sell copies of the Software, and to permit persons
        to whom the Software is furnished to do so, provided that the above
        copyright notice(s) and this permission notice appear in all copies of
        the Software and that both the above copyright notice(s) and this
        permission notice appear in supporting documentation.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
        OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
        HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL
        INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING
        FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
        NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
        WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

        Except as contained in this notice, the name of a copyright holder
        shall not be used in advertising or otherwise to promote the sale, use
        or other dealings in this Software without prior written authorization
        of the copyright holder.

        ----------------------------------------------------------------------

        All trademarks and registered trademarks mentioned herein are the 
        property of their respective owners.

*******************************************************************************/

module mango.icu.UConverter;

private import mango.icu.ICU;

/*******************************************************************************

*******************************************************************************/

struct  UAdjust                 // used with encode() & decode() methods
{
        uint    input,          // how much was read from the input
                output;         // how much was written to the output
}

/*******************************************************************************

*******************************************************************************/

interface ITranscoder
{
        void reset ();

        bool convert (void[] input, void[] output, inout UAdjust x, bool flush);
}

/*******************************************************************************

        This API is used to convert codepage or character encoded data to 
        and from UTF-16. You can open a converter with ucnv_open(). With 
        that converter, you can get its properties, set options, convert 
        your data and close the converter.

        Since many software programs recogize different converter names 
        for different types of converters, there are other functions in 
        this API to iterate over the converter aliases. 

        See <A HREF="http://oss.software.ibm.com/icu/apiref/ucnv_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UConverter : ICU
{
        private Handle handle;

        

        /***********************************************************************
        
                Creates a UConverter object with the names specified as a 
                string. 
                
                The actual name will be resolved with the alias file using 
                a case-insensitive string comparison that ignores delimiters 
                '-', '_', and ' ' (dash, underscore, and space). E.g., the 
                names "UTF8", "utf-8", and "Utf 8" are all equivalent. If null
                is passed for the converter name, it will create one with the 
                getDefaultName() return value.

                A converter name may contain options like a locale specification 
                to control the specific behavior of the converter instantiated. 
                The meaning of the options depends on the particular converter: 
                if an option is not defined for or recognized, it is ignored.

                Options are appended to the converter name string, with an 
                OptionSepChar between the name and the first option and also 
                between adjacent options.

                The conversion behavior and names can vary between platforms, 
                and ICU may convert some characters differently from other 
                platforms. Details on this topic are in the User's Guide.
                
        ***********************************************************************/

        this (char[] name)
        {
                Error e;

                handle = ucnv_open (toString (name), e);
                if (isError (e))
                    exception ("failed to create converter for '"~name~"'");
        }

        /***********************************************************************

                Deletes the unicode converter and releases resources 
                associated with just this instance. Does not free up 
                shared converter tables.        

        ***********************************************************************/

        ~this ()
        {
                ucnv_close (handle);
        }

        /***********************************************************************

                Do a fuzzy compare of two converter/alias names. The 
                comparison is case-insensitive. It also ignores the 
                characters '-', '_', and ' ' (dash, underscore, and space). 
                Thus the strings "UTF-8", "utf_8", and "Utf 8" are exactly 
                equivalent
        
        ***********************************************************************/

        static final int compareNames (char[] a, char[] b)
        {
                return ucnv_compareNames (toString(a), toString(b));
        }

        /***********************************************************************
        
                Resets the state of this converter to the default state.

                This is used in the case of an error, to restart a 
                conversion from a known default state. It will also 
                empty the internal output buffers.

        ***********************************************************************/

        void reset ()
        {
                ucnv_reset (handle);
        }

        /***********************************************************************
        
                Resets the from-Unicode part of this converter state to the 
                default state.

                This is used in the case of an error to restart a conversion 
                from Unicode to a known default state. It will also empty the 
                internal output buffers used for the conversion from Unicode 
                codepoints. 

        ***********************************************************************/

        void resetDecoder ()
        {
                ucnv_resetToUnicode (handle);
        }

        /***********************************************************************
        
                Resets the from-Unicode part of this converter state to the 
                default state.

                This is used in the case of an error to restart a conversion
                from Unicode to a known default state. It will also empty the 
                internal output buffers used for the conversion from Unicode 
                codepoints. 

        ***********************************************************************/

        void resetEncoder ()
        {
                ucnv_resetFromUnicode (handle);
        }

        /***********************************************************************
        
                Returns the maximum number of bytes that are output per 
                UChar in conversion from Unicode using this converter.

                The returned number can be used to calculate the size of 
                a target buffer for conversion from Unicode.

                This number may not be the same as the maximum number of 
                bytes per "conversion unit". In other words, it may not 
                be the intuitively expected number of bytes per character 
                that would be published for a charset, and may not fulfill 
                any other purpose than the allocation of an output buffer 
                of guaranteed sufficient size for a given input length and 
                converter.

                Examples for special cases that are taken into account:

                * Supplementary code points may convert to more bytes than 
                  BMP code points. This function returns bytes per UChar 
                  (UTF-16 code unit), not per Unicode code point, for efficient 
                  buffer allocation.
                * State-shifting output (SI/SO, escapes, etc.) from stateful 
                  converters.
                * When m input UChars are converted to n output bytes, then 
                  the maximum m/n is taken into account.

                The number returned here does not take into account:

                * callbacks which output more than one charset character 
                  sequence per call, like escape callbacks
                * initial and final non-character bytes that are output by 
                  some converters (automatic BOMs, initial escape sequence, 
                  final SI, etc.)

                Examples for returned values:

                * SBCS charsets: 1
                * Shift-JIS: 2
                * UTF-16: 2 (2 per BMP, 4 per surrogate _pair_, BOM not counted)
                * UTF-8: 3 (3 per BMP, 4 per surrogate _pair_)
                * EBCDIC_STATEFUL (EBCDIC mixed SBCS/DBCS): 3 (SO + DBCS)
                * ISO-2022: 3 (always outputs UTF-8)
                * ISO-2022-JP: 6 (4-byte escape sequences + DBCS)
                * ISO-2022-CN: 8 (4-byte designator sequences + 2-byte SS2/SS3 
                  + DBCS)

        ***********************************************************************/

        ubyte getMaxCharSize ()
        {
                return ucnv_getMaxCharSize (handle);
        }

        /***********************************************************************

                Returns the minimum byte length for characters in this 
                codepage. This is usually either 1 or 2.         

        ***********************************************************************/

        ubyte getMinCharSize ()
        {
                return ucnv_getMinCharSize (handle);
        }

        /***********************************************************************

                Gets the internal, canonical name of the converter (zero-
                terminated). 

        ***********************************************************************/

        char[] getName ()
        {
                Error e;

                char[] name = toArray (ucnv_getName (handle, e));
                testError (e, "failed to get converter name");
                return name;
        }

        /***********************************************************************

                Determines if the converter contains ambiguous mappings of 
                the same character or not

        ***********************************************************************/

        bool isAmbiguous ()
        {
                return cast(bool) ucnv_isAmbiguous (handle);
        }

        /***********************************************************************

                Detects Unicode signature byte sequences at the start 
                of the byte stream and returns the charset name of the 
                indicated Unicode charset. A null is returned where no 
                Unicode signature is recognized. 
                
                A caller can create a UConverter using the charset name. 
                The first code unit (wchar) from the start of the stream 
                will be U+FEFF (the Unicode BOM/signature character) and 
                can usually be ignored.

        ***********************************************************************/

        static final char[] detectSignature (void[] input)
        {
                Error   e;
                uint    len;
                char*   name;

                name = ucnv_detectUnicodeSignature (input.ptr, input.length, len, e);
                if (name == null || isError (e))
                    return null;
                return toArray (name);                
        }

        /***********************************************************************

                Converts an array of unicode characters to an array of 
                codepage characters.

                This function is optimized for converting a continuous 
                stream of data in buffer-sized chunks, where the entire 
                source and target does not fit in available buffers.

                The source pointer is an in/out parameter. It starts out 
                pointing where the conversion is to begin, and ends up 
                pointing after the last UChar consumed.

                Target similarly starts out pointer at the first available 
                byte in the output buffer, and ends up pointing after the 
                last byte written to the output.

                The converter always attempts to consume the entire source 
                buffer, unless (1.) the target buffer is full, or (2.) a 
                failing error is returned from the current callback function. 
                When a successful error status has been returned, it means 
                that all of the source buffer has been consumed. At that 
                point, the caller should reset the source and sourceLimit 
                pointers to point to the next chunk.

                At the end of the stream (flush==true), the input is completely 
                consumed when *source==sourceLimit and no error code is set. 
                The converter object is then automatically reset by this 
                function. (This means that a converter need not be reset 
                explicitly between data streams if it finishes the previous 
                stream without errors.)

                This is a stateful conversion. Additionally, even when all 
                source data has been consumed, some data may be in the 
                converters' internal state. Call this function repeatedly, 
                updating the target pointers with the next empty chunk of 
                target in case of a U_BUFFER_OVERFLOW_ERROR, and updating 
                the source pointers with the next chunk of source when a 
                successful error status is returned, until there are no more 
                chunks of source data.

                Parameters:

                    converter       the Unicode converter
                    target          I/O parameter. Input : Points to the 
                                    beginning of the buffer to copy codepage 
                                    characters to. Output : points to after 
                                    the last codepage character copied to 
                                    target.
                    targetLimit     the pointer just after last of the 
                                    target buffer
                    source          I/O parameter, pointer to pointer to 
                                    the source Unicode character buffer.
                    sourceLimit     the pointer just after the last of 
                                    the source buffer
                    offsets         if NULL is passed, nothing will happen
                                    to it, otherwise it needs to have the 
                                    same number of allocated cells as target. 
                                    Will fill in offsets from target to source 
                                    pointer e.g: offsets[3] is equal to 6, it 
                                    means that the target[3] was a result of 
                                    transcoding source[6] For output data 
                                    carried across calls, and other data 
                                    without a specific source character 
                                    (such as from escape sequences or 
                                    callbacks) -1 will be placed for offsets.
                    flush           set to TRUE if the current source buffer 
                                    is the last available chunk of the source,
                                    FALSE otherwise. Note that if a failing 
                                    status is returned, this function may 
                                    have to be called multiple times with 
                                    flush set to TRUE until the source buffer 
                                    is consumed.

        ***********************************************************************/

        bool encode (wchar[] input, void[] output, inout UAdjust x, bool flush)
        {
                Error   e;
                wchar*  src = input.ptr;
                void*   dst = output.ptr;
                wchar*  srcLimit = src + input.length;
                void*   dstLimit = dst + output.length;

                ucnv_fromUnicode (handle, &dst, dstLimit, &src, srcLimit, null, flush, e);
                x.input = src - input.ptr;
                x.output = dst - output.ptr;

                if (e == e.BufferOverflow)
                    return true;

                testError (e, "failed to encode");
                return false;
        }

        /***********************************************************************

                Encode the Unicode string into a codepage string.

                This function is a more convenient but less powerful version 
                of encode(). It is only useful for whole strings, not 
                for streaming conversion. The maximum output buffer capacity 
                required (barring output from callbacks) should be calculated
                using getMaxCharSize().

        ***********************************************************************/

        uint encode (wchar[] input, void[] output)
        {
                Error e;
                uint  len;

                len = ucnv_fromUChars (handle, output.ptr, output.length, input.ptr, input.length, e);
                testError (e, "failed to encode");
                return len;                
        }

        /***********************************************************************

                Converts a buffer of codepage bytes into an array of unicode 
                UChars characters.

                This function is optimized for converting a continuous stream 
                of data in buffer-sized chunks, where the entire source and 
                target does not fit in available buffers.

                The source pointer is an in/out parameter. It starts out pointing 
                where the conversion is to begin, and ends up pointing after the 
                last byte of source consumed.

                Target similarly starts out pointer at the first available UChar 
                in the output buffer, and ends up pointing after the last UChar 
                written to the output. It does NOT necessarily keep UChar sequences 
                together.

                The converter always attempts to consume the entire source buffer, 
                unless (1.) the target buffer is full, or (2.) a failing error is 
                returned from the current callback function. When a successful 
                error status has been returned, it means that all of the source 
                buffer has been consumed. At that point, the caller should reset 
                the source and sourceLimit pointers to point to the next chunk.

                At the end of the stream (flush==true), the input is completely 
                consumed when *source==sourceLimit and no error code is set The 
                converter object is then automatically reset by this function. 
                (This means that a converter need not be reset explicitly between 
                data streams if it finishes the previous stream without errors.)

                This is a stateful conversion. Additionally, even when all source 
                data has been consumed, some data may be in the converters' internal 
                state. Call this function repeatedly, updating the target pointers 
                with the next empty chunk of target in case of a BufferOverflow, and 
                updating the source pointers with the next chunk of source when a 
                successful error status is returned, until there are no more chunks 
                of source data.

                Parameters:
                    converter       the Unicode converter
                    target  I/O     parameter. Input : Points to the beginning 
                                    of the buffer to copy UChars into. Output : 
                                    points to after the last UChar copied.
                    targetLimit     the pointer just after the end of the target 
                                    buffer
                    source  I/O     parameter, pointer to pointer to the source 
                                    codepage buffer.
                    sourceLimit     the pointer to the byte after the end of the 
                                    source buffer
                    offsets         if NULL is passed, nothing will happen to 
                                    it, otherwise it needs to have the same 
                                    number of allocated cells as target. Will 
                                    fill in offsets from target to source pointer
                                    e.g: offsets[3] is equal to 6, it means that 
                                    the target[3] was a result of transcoding 
                                    source[6] For output data carried across 
                                    calls, and other data without a specific 
                                    source character (such as from escape 
                                    sequences or callbacks) -1 will be placed 
                                    for offsets.
                    flush           set to true if the current source buffer 
                                    is the last available chunk of the source, 
                                    false otherwise. Note that if a failing 
                                    status is returned, this function may have 
                                    to be called multiple times with flush set 
                                    to true until the source buffer is consumed.

        ***********************************************************************/
        
        bool decode (void[] input, wchar[] output, inout UAdjust x, bool flush)
        {
                Error   e;
                void*   src = input.ptr;
                wchar*  dst = output.ptr;
                void*   srcLimit = src + input.length;
                wchar*  dstLimit = dst + output.length;

                ucnv_toUnicode (handle, &dst, dstLimit, &src, srcLimit, null, flush, e);
                x.input = src - input.ptr;
                x.output = dst - output.ptr;

                if (e == e.BufferOverflow)
                    return true;

                testError (e, "failed to decode");
                return false;
        }

        /***********************************************************************

                Decode the codepage string into a Unicode string.

                This function is a more convenient but less powerful version 
                of decode(). It is only useful for whole strings, not for 
                streaming conversion. The maximum output buffer capacity 
                required (barring output from callbacks) will be 2*src.length 
                (each char may be converted into a surrogate pair)

        ***********************************************************************/

        uint decode (void[] input, wchar[] output)
        {
                Error e;
                uint  len;

                len = ucnv_toUChars (handle, output.ptr, output.length, input.ptr, input.length, e);
                testError (e, "failed to decode");
                return len;                
        }

        /**********************************************************************

                Iterate over the available converter names

        **********************************************************************/

        static int opApply (int delegate(inout char[] element) dg)
        {
                char[]          name;
                int             result;
                uint            count = ucnv_countAvailable ();

                for (uint i=0; i < count; ++i)
                    {
                    name = toArray (ucnv_getAvailableName (i));
                    result = dg (name);
                    if (result)
                        break;
                    }
                return result;
        }

        /***********************************************************************

        ***********************************************************************/

        ITranscoder createTranscoder (UConverter dst)
        {
                return new UTranscoder (this, dst);
        }

        /**********************************************************************

        **********************************************************************/

        private class UTranscoder : ITranscoder
        {
                private UConverter      cSrc,
                                        cDst;
                private bool            clear = true;

                /**************************************************************

                **************************************************************/

                this (UConverter src, UConverter dst)
                {
                        cSrc = src;
                        cDst = dst;
                }

                /**************************************************************

                **************************************************************/

                void reset ()
                {       
                        clear = true;
                }

                /**************************************************************

                **************************************************************/

                bool convert (void[] input, void[] output, inout UAdjust x, bool flush)
                {
                        Error   e;
                        void*   src = input.ptr;
                        void*   dst = output.ptr;
                        void*   srcLimit = src + input.length;
                        void*   dstLimit = dst + output.length;

                        ucnv_convertEx (cDst.handle, cSrc.handle, &dst, dstLimit, 
                                        &src, srcLimit, null, null, null, null, 
                                        clear, flush, e);
                        clear = false;
                        x.input = src - input.ptr;
                        x.output = dst - output.ptr;

                        if (e == e.BufferOverflow)
                            return true;

                        testError (e, "failed to decode");
                        return false;
                }
        }


        /***********************************************************************
        
                Bind the ICU functions from a shared library. This is
                complicated by the issues regarding D and DLLs on the
                Windows platform

        ***********************************************************************/

        private static void* library;

        /***********************************************************************

        ***********************************************************************/

        private static extern (C) 
        {
                int    function (char*, char*) ucnv_compareNames;
                Handle function (char*, inout Error) ucnv_open;
                char*  function (void*, uint, inout uint, inout Error) ucnv_detectUnicodeSignature;
                void   function (Handle) ucnv_close;
                void   function (Handle) ucnv_reset;
                int    function (Handle) ucnv_resetToUnicode;
                int    function (Handle) ucnv_resetFromUnicode;
                ubyte  function (Handle) ucnv_getMaxCharSize;
                ubyte  function (Handle) ucnv_getMinCharSize;
                char*  function (Handle, inout Error) ucnv_getName;
                uint   function (Handle, wchar*, uint, void*, uint, inout Error) ucnv_toUChars;
                uint   function (Handle, void*, uint, wchar*, uint, inout Error) ucnv_fromUChars;
                void   function (Handle, void**, void*, wchar**, wchar*, int*, ubyte, inout Error) ucnv_fromUnicode;
                void   function (Handle, wchar**, wchar*, void**, void*, int*, ubyte, inout Error)  ucnv_toUnicode;
                void   function (Handle, Handle, void**, void*, void**, void*, wchar*, wchar*, wchar*, wchar*, ubyte, ubyte, inout Error) ucnv_convertEx;
                ubyte  function (Handle) ucnv_isAmbiguous;
                char*  function (uint) ucnv_getAvailableName;
                uint   function () ucnv_countAvailable;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &ucnv_open,                   "ucnv_open"}, 
                {cast(void**) &ucnv_close,                  "ucnv_close"},
                {cast(void**) &ucnv_reset,                  "ucnv_reset"},
                {cast(void**) &ucnv_resetToUnicode,         "ucnv_resetToUnicode"},
                {cast(void**) &ucnv_resetFromUnicode,       "ucnv_resetFromUnicode"},
                {cast(void**) &ucnv_compareNames,           "ucnv_compareNames"},
                {cast(void**) &ucnv_getMaxCharSize,         "ucnv_getMaxCharSize"},
                {cast(void**) &ucnv_getMinCharSize,         "ucnv_getMinCharSize"},
                {cast(void**) &ucnv_getName,                "ucnv_getName"},
                {cast(void**) &ucnv_detectUnicodeSignature, "ucnv_detectUnicodeSignature"},
                {cast(void**) &ucnv_toUChars,               "ucnv_toUChars"},
                {cast(void**) &ucnv_fromUChars,             "ucnv_fromUChars"},
                {cast(void**) &ucnv_toUnicode,              "ucnv_toUnicode"},
                {cast(void**) &ucnv_fromUnicode,            "ucnv_fromUnicode"},
                {cast(void**) &ucnv_convertEx,              "ucnv_convertEx"},
                {cast(void**) &ucnv_isAmbiguous,            "ucnv_isAmbiguous"},
                {cast(void**) &ucnv_countAvailable,         "ucnv_countAvailable"},
                {cast(void**) &ucnv_getAvailableName,       "ucnv_getAvailableName"},
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (icuuc, targets);
/+
                foreach (char[] name; UConverter)
                         printf ("%.*s\n", name);
+/
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }
}

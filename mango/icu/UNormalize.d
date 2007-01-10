/*******************************************************************************

        @file UNormalize.d
        
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

module mango.icu.UNormalize;

private import  mango.icu.ICU,
                mango.icu.UString,
                mango.icu.ULocale;

/*******************************************************************************

        transforms Unicode text into an equivalent composed or 
        decomposed form, allowing for easier sorting and searching 
        of text. UNormalize supports the standard normalization forms 
        described in http://www.unicode.org/unicode/reports/tr15/

        Characters with accents or other adornments can be encoded 
        in several different ways in Unicode. For example, take the 
        character A-acute. In Unicode, this can be encoded as a single 
        character (the "composed" form):
        
                00C1 LATIN CAPITAL LETTER A WITH ACUTE

        or as two separate characters (the "decomposed" form):

                0041 LATIN CAPITAL LETTER A 0301 COMBINING ACUTE ACCENT

        To a user of your program, however, both of these sequences 
        should be treated as the same "user-level" character "A with 
        acute accent". When you are searching or comparing text, you 
        must ensure that these two sequences are treated equivalently. 
        In addition, you must handle characters with more than one 
        accent. Sometimes the order of a character's combining accents 
        is significant, while in other cases accent sequences in different 
        orders are really equivalent.

        Similarly, the string "ffi" can be encoded as three separate 
        letters:

                0066 LATIN SMALL LETTER F 0066 LATIN SMALL LETTER F 
                0069 LATIN SMALL LETTER I

        or as the single character

                FB03 LATIN SMALL LIGATURE FFI

        The ffi ligature is not a distinct semantic character, and strictly 
        speaking it shouldn't be in Unicode at all, but it was included for 
        compatibility with existing character sets that already provided it. 
        The Unicode standard identifies such characters by giving them 
        "compatibility" decompositions into the corresponding semantic 
        characters. When sorting and searching, you will often want to use 
        these mappings.

        unorm_normalize helps solve these problems by transforming text into 
        the canonical composed and decomposed forms as shown in the first 
        example above. In addition, you can have it perform compatibility 
        decompositions so that you can treat compatibility characters the 
        same as their equivalents. Finally, UNormalize rearranges 
        accents into the proper canonical order, so that you do not have 
        to worry about accent rearrangement on your own.

        Form FCD, "Fast C or D", is also designed for collation. It allows 
        to work on strings that are not necessarily normalized with an 
        algorithm (like in collation) that works under "canonical closure", 
        i.e., it treats precomposed characters and their decomposed 
        equivalents the same.

        It is not a normalization form because it does not provide for 
        uniqueness of representation. Multiple strings may be canonically 
        equivalent (their NFDs are identical) and may all conform to FCD 
        without being identical themselves.

        The form is defined such that the "raw decomposition", the 
        recursive canonical decomposition of each character, results 
        in a string that is canonically ordered. This means that 
        precomposed characters are allowed for as long as their 
        decompositions do not need canonical reordering.

        Its advantage for a process like collation is that all NFD 
        and most NFC texts - and many unnormalized texts - already 
        conform to FCD and do not need to be normalized (NFD) for 
        such a process. The FCD quick check will return UNORM_YES 
        for most strings in practice.

        For more details on FCD see the collation design document: 
        http://oss.software.ibm.com/cvs/icu/~checkout~/icuhtml/design/collation/ICU_collation_design.htm

        ICU collation performs either NFD or FCD normalization 
        automatically if normalization is turned on for the collator 
        object. Beyond collation and string search, normalized strings 
        may be useful for string equivalence comparisons, transliteration/
        transcription, unique representations, etc.

        The W3C generally recommends to exchange texts in NFC. Note also 
        that most legacy character encodings use only precomposed forms 
        and often do not encode any combining marks by themselves. For 
        conversion to such character encodings the Unicode text needs to 
        be normalized to NFC. For more usage examples, see the Unicode 
        Standard Annex.         

        See <A HREF="http://oss.software.ibm.com/icu/apiref/unorm_8h.html">
        this page</A> for full details.


*******************************************************************************/

class UNormalize : ICU
{
        enum    Mode 
                {
                None    = 1, 
                NFD     = 2, 
                NFKD    = 3, 
                NFC     = 4,
                Default = NFC, 
                NFKC    = 5, 
                FCD     = 6, 
                Count
                }

        enum    Check 
                { 
                No, 
                Yes, 
                Maybe  
                }

        enum    Options
                { 
                None      = 0x00,
                Unicode32 = 0x20 
                }

        /***********************************************************************

                Normalize a string. The string will be normalized according 
                the specified normalization mode and options        

        ***********************************************************************/

        static void normalize (UText src, UString dst, Mode mode, Options o = Options.None)
        {
                uint fmt (wchar* dst, uint len, inout Error e)
                {
                        return unorm_normalize (src.get.ptr, src.len, mode, o, dst, len, e);
                }

                dst.format (&fmt, "failed to normalize");
        }

        /***********************************************************************

                Performing quick check on a string, to quickly determine 
                if the string is in a particular normalization format.

                Three types of result can be returned: Yes, No or Maybe. 
                Result Yes indicates that the argument string is in the 
                desired normalized format, No determines that argument 
                string is not in the desired normalized format. A Maybe 
                result indicates that a more thorough check is required, 
                the user may have to put the string in its normalized 
                form and compare the results.        

        ***********************************************************************/

        static Check check (UText t, Mode mode, Options o = Options.None)
        {      
                Error e; 

                Check c = cast(Check) unorm_quickCheckWithOptions (t.get.ptr, t.len, mode, o, e);
                testError (e, "failed to perform normalization check");
                return c;
        }

        /***********************************************************************

                Test if a string is in a given normalization form. 

                Unlike check(), this function returns a definitive result, 
                never a "maybe". For NFD, NFKD, and FCD, both functions 
                work exactly the same. For NFC and NFKC where quickCheck 
                may return "maybe", this function will perform further 
                tests to arrive at a TRUE/FALSE result.        

        ***********************************************************************/

        static bool isNormalized (UText t, Mode mode, Options o = Options.None)
        {      
                Error e; 

                byte b = unorm_isNormalizedWithOptions (t.get.ptr, t.len, mode, o, e);
                testError (e, "failed to perform normalization test");
                return b != 0;
        }

        /***********************************************************************

                Concatenate normalized strings, making sure that the result 
                is normalized as well. If both the left and the right strings 
                are in the normalization form according to "mode/options", 
                then the result will be

                        dest=normalize(left+right, mode, options)

                With the input strings already being normalized, this function 
                will use unorm_next() and unorm_previous() to find the adjacent 
                end pieces of the input strings. Only the concatenation of these 
                end pieces will be normalized and then concatenated with the 
                remaining parts of the input strings.

                It is allowed to have dst==left to avoid copying the entire 
                left string.        

        ***********************************************************************/

        static void concatenate (UText left, UText right, UString dst, Mode mode, Options o = Options.None)
        {      
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return unorm_concatenate (left.get.ptr, left.len, right.get.ptr, right.len, p, len, mode, o, e);
                }

                dst.format (&fmt, "failed to concatenate");
        }

        /***********************************************************************
        
                Compare two strings for canonical equivalence. Further 
                options include case-insensitive comparison and code 
                point order (as opposed to code unit order).

                Canonical equivalence between two strings is defined as 
                their normalized forms (NFD or NFC) being identical. 
                This function compares strings incrementally instead of
                normalizing (and optionally case-folding) both strings 
                entirely, improving performance significantly.

                Bulk normalization is only necessary if the strings do 
                not fulfill the FCD conditions. Only in this case, and 
                only if the strings are relatively long, is memory 
                allocated temporarily. For FCD strings and short non-FCD 
                strings there is no memory allocation.

        ***********************************************************************/

        static int compare (UText left, UText right, Options o = Options.None)
        {      
                Error e; 

                int i = unorm_compare (left.get.ptr, left.len, right.get.ptr, right.len, o, e);
                testError (e, "failed to compare");
                return i;
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
                uint  function (wchar*, uint, uint, uint, wchar*, uint, inout Error) unorm_normalize;
                uint  function (wchar*, uint, uint, uint, inout Error) unorm_quickCheckWithOptions;
                byte  function (wchar*, uint, uint, uint, inout Error) unorm_isNormalizedWithOptions;
                uint  function (wchar*, uint, wchar*, uint, wchar*, uint, uint, uint, inout Error) unorm_concatenate;
                uint  function (wchar*, uint, wchar*, uint, uint, inout Error) unorm_compare;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &unorm_normalize,                 "unorm_normalize"},
                {cast(void**) &unorm_quickCheckWithOptions,     "unorm_quickCheckWithOptions"},
                {cast(void**) &unorm_isNormalizedWithOptions,   "unorm_isNormalizedWithOptions"},
                {cast(void**) &unorm_concatenate,               "unorm_concatenate"},
                {cast(void**) &unorm_compare,                   "unorm_compare"},
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (icuuc, targets);
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }
}

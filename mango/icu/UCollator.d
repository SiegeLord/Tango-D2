/*******************************************************************************

        @file UCollator.d
        
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


        @version        Initial version, November 2004      
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

module mango.icu.UCollator;

private import  mango.icu.ICU,
                mango.icu.USet,
                mango.icu.ULocale,
                mango.icu.UString;

/*******************************************************************************

        The API for Collator performs locale-sensitive string comparison. 
        You use this service to build searching and sorting routines for 
        natural language text. Important: The ICU collation service has been 
        reimplemented in order to achieve better performance and UCA compliance. 
        For details, see the collation design document.

        For more information about the collation service see the users guide.

        Collation service provides correct sorting orders for most locales 
        supported in ICU. If specific data for a locale is not available, 
        the orders eventually falls back to the UCA sort order.

        Sort ordering may be customized by providing your own set of rules. 
        For more on this subject see the Collation customization section of 
        the users guide. 

        See <A HREF="http://oss.software.ibm.com/icu/apiref/ucol_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UCollator : ICU
{       
        package Handle handle;
        
        typedef void* UParseError;

        enum    Attribute 
                {
                FrenchCollation, 
                AlternateHandling, 
                CaseFirst, 
                CaseLevel,
                NormalizationMode, 
                DecompositionMode = NormalizationMode, 
                strength, 
                HiraganaQuaternaryMode,
                NumericCollation, 
                AttributeCount
                }

        enum    AttributeValue 
                {
                Default = -1, 
                Primary = 0, 
                Secondary = 1, 
                Tertiary = 2,
                DefaultStrength = Tertiary, 
                CeStrengthLimit, 
                Quaternary = 3, 
                Identical = 15,
                strengthLimit, 
                Off = 16, 
                On = 17, 
                Shifted = 20,
                NonIgnorable = 21, 
                LowerFirst = 24, 
                UpperFirst = 25, 
                AttributeValueCount
                }

         enum   RuleOption 
                { 
                TailoringOnly, 
                FullRules  
                }

         enum   BoundMode 
                { 
                BoundLower = 0, 
                BoundUpper = 1, 
                BoundUpperLong = 2, 
                BoundValueCount  
                }

        typedef AttributeValue Strength;

        /***********************************************************************

                Open a UCollator for comparing strings. The locale specified
                determines the required collation rules. Special values for 
                locales can be passed in - if ULocale.Default is passed for 
                the locale, the default locale collation rules will be used. 
                If ULocale.Root is passed, UCA rules will be used

        ***********************************************************************/

        this (ULocale locale)
        {
                Error e;

                handle = ucol_open (toString(locale.name), e);
                testError (e, "failed to open collator");
        }

        /***********************************************************************

                Produce a UCollator instance according to the rules supplied.
        
                The rules are used to change the default ordering, defined in 
                the UCA in a process called tailoring. For the syntax of the 
                rules please see users guide

        ***********************************************************************/

        this (UText rules, AttributeValue mode, Strength strength)
        {
                Error e;

                handle = ucol_openRules (rules.get.ptr, rules.len, mode, strength, null, e);
                testError (e, "failed to open rules-based collator");
        }

        /***********************************************************************

                Open a collator defined by a short form string. The 
                structure and the syntax of the string is defined in 
                the "Naming collators" section of the users guide: 
                http://oss.software.ibm.com/icu/userguide/Collate_Concepts.html#Naming_Collators 
                Attributes are overriden by the subsequent attributes. 
                So, for "S2_S3", final strength will be 3. 3066bis 
                locale overrides individual locale parts. 
                
                The call to this constructor is equivalent to a plain 
                constructor, followed by a series of calls to setAttribute 
                and setVariableTop

        ***********************************************************************/

        this (char[] shortName, bool forceDefaults)
        {
                Error e;

                handle = ucol_openFromShortString (toString(shortName), forceDefaults, null, e);
                testError (e, "failed to open short-name collator");
        }

        /***********************************************************************

                Internal constructor invoked via USearch

        ***********************************************************************/

        package this (Handle handle)
        {
                this.handle = handle;
        }

        /***********************************************************************
        
                Close a UCollator

        ***********************************************************************/

        ~this ()
        {
                ucol_close (handle);
        }

        /***********************************************************************
        
                Get a set containing the contractions defined by the 
                collator.

                The set includes both the UCA contractions and the 
                contractions defined by the collator. This set will 
                contain only strings. If a tailoring explicitly 
                suppresses contractions from the UCA (like Russian), 
                removed contractions will not be in the resulting set. 

        ***********************************************************************/

        void getContractions (USet set)
        {
                Error e;

                ucol_getContractions (handle, set.handle, e);
                testError (e, "failed to get collator contractions");
        }

        /***********************************************************************
        
                Compare two strings. Return value is -, 0, +

        ***********************************************************************/

        int strcoll (UText source, UText target)
        {
                return ucol_strcoll (handle, source.get.ptr, source.len, target.get.ptr, target.len);
        }
       
        /***********************************************************************
        
                Determine if one string is greater than another. This 
                function is equivalent to strcoll() > 1 

        ***********************************************************************/

        bool greater (UText source, UText target)
        {
                return ucol_greater (handle, source.get.ptr, source.len, target.get.ptr, target.len) != 0;
        }
       
        /***********************************************************************
        
                Determine if one string is greater than or equal to 
                another. This function is equivalent to strcoll() >= 0
                 
        ***********************************************************************/

        bool greaterOrEqual (UText source, UText target)
        {
                return ucol_greaterOrEqual (handle, source.get.ptr, source.len, target.get.ptr, target.len) != 0;
        }
       
        /***********************************************************************
        
                This function is equivalent to strcoll() == 0

        ***********************************************************************/

        bool equal (UText source, UText target)
        {
                return ucol_equal (handle, source.get.ptr, source.len, target.get.ptr, target.len) != 0;
        }
       
        /***********************************************************************
        
                Get the collation strength used in a UCollator. The 
                strength influences how strings are compared. 

        ***********************************************************************/

        Strength getStrength ()
        {
                return ucol_getStrength (handle);
        }
       
        /***********************************************************************
        
                Set the collation strength used in this UCollator. The 
                strength influences how strings are compared. one of 
                Primary, Secondary, Tertiary, Quaternary, Dentical, or
                Default

        ***********************************************************************/

        void setStrength (Strength s)
        {
                ucol_setStrength (handle, s);
        }
       
        /***********************************************************************
        
                Get the display name for a UCollator. The display name is 
                suitable for presentation to a user

        ***********************************************************************/

        void getDisplayName (ULocale obj, ULocale display, UString dst)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return ucol_getDisplayName (toString(obj.name), toString(display.name), dst.get.ptr, dst.len, e);
                }

                dst.format (&fmt, "failed to get collator display name");
        }
       
        /***********************************************************************
        
                Returns current rules. Options define whether full rules 
                are returned or just the tailoring. 

        ***********************************************************************/

        void getRules (UString dst, RuleOption o = RuleOption.FullRules)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        uint needed = ucol_getRulesEx (handle, o, dst.get.ptr, dst.len);
                        if (needed > len)
                            e = e.BufferOverflow;
                        return needed;
                }

                dst.format (&fmt, "failed to get collator rules");
        }
       
        /***********************************************************************
        
                Get the short definition string for a collator.

                This API harvests the collator's locale and the attribute 
                set and produces a string that can be used for opening a 
                collator with the same properties using the char[] style 
                constructor. This string will be normalized. 
                
                The structure and the syntax of the string is defined in the 
                "Naming collators" section of the users guide: 
                http://oss.software.ibm.com/icu/userguide/Collate_Concepts.html#Naming_Collators

        ***********************************************************************/

        char[] getShortDefinitionString (ULocale locale = ULocale.Default)
        {
                Error    e;
                char[64] dst;

                uint len = ucol_getShortDefinitionString (handle, toString(locale.name), dst.ptr, dst.length, e);
                testError (e, "failed to get collator short name");
                return dst[0..len].dup;
        }
       
        /***********************************************************************
        
                Verifies and normalizes short definition string. Normalized 
                short definition string has all the option sorted by the 
                argument name, so that equivalent definition strings are the 
                same

        ***********************************************************************/

        char[] normalizeShortDefinitionString (char[] source)
        {
                Error    e;
                char[64] dst;

                uint len = ucol_normalizeShortDefinitionString (toString(source), dst.ptr, dst.length, null, e);
                testError (e, "failed to normalize collator short name");
                return dst[0..len].dup;
        }
       
        /***********************************************************************
                
                  Get a sort key for a string from a UCollator. Sort keys 
                  may be compared using strcmp. 

        ***********************************************************************/

        ubyte[] getSortKey (UText t, ubyte[] result)
        {
                uint len = ucol_getSortKey (handle, t.get.ptr, t.len, result.ptr, result.length);
                if (len < result.length) 
                    return result [0..len];
                 return null;
        }
       
        /***********************************************************************
                
                Merge two sort keys. The levels are merged with their 
                corresponding counterparts (primaries with primaries, 
                secondaries with secondaries etc.). Between the values 
                from the same level a separator is inserted. example 
                (uncompressed): 191B1D 01 050505 01 910505 00 and 
                1F2123 01 050505 01 910505 00 will be merged as 
                191B1D 02 1F212301 050505 02 050505 01 910505 02 910505 00 
                This allows for concatenating of first and last names for 
                sorting, among other things. If the destination buffer is 
                not big enough, the results are undefined. If any of source 
                lengths are zero or any of source pointers are null/undefined, 
                result is of size zero. 

        ***********************************************************************/

        ubyte[] mergeSortkeys (ubyte[] left, ubyte[] right, ubyte[] result)
        {
                uint len = ucol_mergeSortkeys (left.ptr, left.length, right.ptr, right.length, result.ptr, result.length);
                if (len < result.length) 
                    return result [0..len];
                 return null;
        }
       
        /***********************************************************************
        
                Produce a bound for a given sortkey and a number of levels.

                Return value is always the number of bytes needed, regardless 
                of whether the result buffer was big enough or even valid.

                Resulting bounds can be used to produce a range of strings 
                that are between upper and lower bounds. For example, if 
                bounds are produced for a sortkey of string "smith", strings 
                between upper and lower bounds with one level would include 
                "Smith", "SMITH", "sMiTh".

                There are two upper bounds that can be produced. If BoundUpper 
                is produced, strings matched would be as above. However, if 
                bound produced using BoundUpperLong is used, the above example 
                will also match "Smithsonian" and similar.

        ***********************************************************************/

        ubyte[] getBound (BoundMode mode, ubyte[] source, ubyte[] result, uint levels = 1)
        {
                Error e;

                uint len = ucol_getBound (source.ptr, source.length, mode, levels, result.ptr, result.length, e);
                testError (e, "failed to get sortkey bound");
                if (len < result.length) 
                    return result [0..len];
                 return null;
        }
       
        /***********************************************************************
        
                Gets the version information for a Collator.

                Version is currently an opaque 32-bit number which depends, 
                among other things, on major versions of the collator 
                tailoring and UCA

        ***********************************************************************/

        void getVersion (inout Version v)
        {
                ucol_getVersion (handle, v);
        }

        /***********************************************************************
        
                Gets the UCA version information for this Collator

        ***********************************************************************/

        void getUCAVersion (inout Version v)
        {
                ucol_getUCAVersion (handle, v);
        }

        /***********************************************************************
        
                Universal attribute setter

        ***********************************************************************/

        void setAttribute (Attribute attr, AttributeValue value)
        {
                Error e;

                ucol_setAttribute (handle, attr, value, e);
                testError (e, "failed to set collator attribute");
        }

        /***********************************************************************
        
                Universal attribute getter

        ***********************************************************************/

        AttributeValue getAttribute (Attribute attr)
        {
                Error e;

                AttributeValue v = ucol_getAttribute (handle, attr, e);
                testError (e, "failed to get collator attribute");
                return v;
        }

        /***********************************************************************
        
                Variable top is a two byte primary value which causes all 
                the codepoints with primary values that are less or equal 
                than the variable top to be shifted when alternate handling 
                is set to Shifted.

        ***********************************************************************/

        void setVariableTop (UText t)
        {
                Error e;

                ucol_setVariableTop (handle, t.get.ptr, t.len, e);
                testError (e, "failed to set variable-top");
        }

        /***********************************************************************
        
                Sets the variable top to a collation element value 
                supplied.Variable top is set to the upper 16 bits. 
                Lower 16 bits are ignored. 
                
        ***********************************************************************/

        void setVariableTop (uint x)
        {
                Error e;

                ucol_restoreVariableTop (handle, x, e);
                testError (e, "failed to restore variable-top");
        }

        /***********************************************************************
                
                Gets the variable top value of this Collator. Lower 16 bits 
                are undefined and should be ignored. 

        ***********************************************************************/

        uint getVariableTop ()
        {
                Error e;

                uint x = ucol_getVariableTop (handle, e);
                testError (e, "failed to get variable-top");
                return x;
        }

        /***********************************************************************
        
                Gets the locale name of the collator. If the collator is 
                instantiated from the rules, then this function will throw
                an exception

        ***********************************************************************/

        void getLocale (ULocale locale, ULocale.Type type)
        {
                Error e;

                locale.name = toArray (ucol_getLocaleByType (handle, type, e));
                if (isError(e) || locale.name is null)
                    exception ("failed to get collator locale");
        }

        /***********************************************************************
        
                Get the Unicode set that contains all the characters and 
                sequences tailored in this collator.

        ***********************************************************************/

        USet getTailoredSet ()
        {
                Error e;

                Handle h = ucol_getTailoredSet (handle, e);
                testError (e, "failed to get tailored set");
                return new USet (h);
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
                void            function (Handle) ucol_close;
                Handle          function (char *loc, inout Error e) ucol_open;
                Handle          function (wchar* rules, uint rulesLength, AttributeValue normalizationMode, Strength strength, UParseError *parseError, inout Error e) ucol_openRules;
                Handle          function (char *definition, byte forceDefaults, UParseError *parseError, inout Error e) ucol_openFromShortString;
                uint            function (Handle, Handle conts, inout Error e) ucol_getContractions;
                int             function (Handle, wchar* source, uint sourceLength, wchar* target, uint targetLength) ucol_strcoll;
                byte            function (Handle, wchar* source, uint sourceLength, wchar* target, uint targetLength) ucol_greater;
                byte            function (Handle, wchar* source, uint sourceLength, wchar* target, uint targetLength) ucol_greaterOrEqual;
                byte            function (Handle, wchar* source, uint sourceLength, wchar* target, uint targetLength) ucol_equal;
                Strength        function (Handle) ucol_getStrength;
                void            function (Handle, Strength strength) ucol_setStrength;
                uint            function (char *objLoc, char *dispLoc, wchar* result, uint resultLength, inout Error e) ucol_getDisplayName;
                uint            function (Handle, char *locale, char *buffer, uint capacity, inout Error e) ucol_getShortDefinitionString;
                uint            function (char *source, char *destination, uint capacity, UParseError *parseError, inout Error e) ucol_normalizeShortDefinitionString;
                uint            function (Handle, wchar* source, uint sourceLength, ubyte *result, uint resultLength) ucol_getSortKey;
                uint            function (ubyte *source, uint sourceLength, BoundMode boundType, uint noOfLevels, ubyte *result, uint resultLength, inout Error e) ucol_getBound;
                void            function (Handle, Version info) ucol_getVersion;
                void            function (Handle, Version info) ucol_getUCAVersion;
                uint            function (ubyte *src1, uint src1Length, ubyte *src2, uint src2Length, ubyte *dest, uint destCapacity) ucol_mergeSortkeys;
                void            function (Handle, Attribute attr, AttributeValue value, inout Error e) ucol_setAttribute;
                AttributeValue  function (Handle, Attribute attr, inout Error e) ucol_getAttribute;
                uint            function (Handle, wchar* varTop, uint len, inout Error e) ucol_setVariableTop;
                uint            function (Handle, inout Error e) ucol_getVariableTop;
                void            function (Handle, uint varTop, inout Error e) ucol_restoreVariableTop;
                uint            function (Handle, RuleOption delta, wchar* buffer, uint bufferLen) ucol_getRulesEx;
                char*           function (Handle, ULocale.Type type, inout Error e) ucol_getLocaleByType;
                Handle          function (Handle, inout Error e) ucol_getTailoredSet;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &ucol_open,                               "ucol_open"}, 
                {cast(void**) &ucol_close,                              "ucol_close"},
                {cast(void**) &ucol_openRules,                          "ucol_openRules"},
                {cast(void**) &ucol_openFromShortString,                "ucol_openFromShortString"},
                {cast(void**) &ucol_getContractions,                    "ucol_getContractions"},
                {cast(void**) &ucol_strcoll,                            "ucol_strcoll"},
                {cast(void**) &ucol_greater,                            "ucol_greater"},
                {cast(void**) &ucol_greaterOrEqual,                     "ucol_greaterOrEqual"},
                {cast(void**) &ucol_equal,                              "ucol_equal"},
                {cast(void**) &ucol_getStrength,                        "ucol_getStrength"},
                {cast(void**) &ucol_setStrength,                        "ucol_setStrength"},
                {cast(void**) &ucol_getDisplayName,                     "ucol_getDisplayName"},
                {cast(void**) &ucol_getShortDefinitionString,           "ucol_getShortDefinitionString"},
                {cast(void**) &ucol_normalizeShortDefinitionString,     "ucol_normalizeShortDefinitionString"},
                {cast(void**) &ucol_getSortKey,                         "ucol_getSortKey"},
                {cast(void**) &ucol_getBound,                           "ucol_getBound"},
                {cast(void**) &ucol_getVersion,                         "ucol_getVersion"},
                {cast(void**) &ucol_getUCAVersion,                      "ucol_getUCAVersion"},
                {cast(void**) &ucol_mergeSortkeys,                      "ucol_mergeSortkeys"},
                {cast(void**) &ucol_setAttribute,                       "ucol_setAttribute"},
                {cast(void**) &ucol_getAttribute,                       "ucol_getAttribute"},
                {cast(void**) &ucol_setVariableTop,                     "ucol_setVariableTop"},
                {cast(void**) &ucol_getVariableTop,                     "ucol_getVariableTop"},
                {cast(void**) &ucol_restoreVariableTop,                 "ucol_restoreVariableTop"},
                {cast(void**) &ucol_getRulesEx,                         "ucol_getRulesEx"},
                {cast(void**) &ucol_getLocaleByType,                    "ucol_getLocaleByType"},
                {cast(void**) &ucol_getTailoredSet,                     "ucol_getTailoredSet"},
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (icuin, targets);
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }
}


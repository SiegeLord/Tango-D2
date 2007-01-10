/*******************************************************************************

        @file UChar.d
        
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

module mango.icu.UChar;

private import  mango.icu.ICU;

/*******************************************************************************

        This API provides low-level access to the Unicode Character 
        Database. In addition to raw property values, some convenience 
        functions calculate derived properties, for example for Java-style 
        programming.

        Unicode assigns each code point (not just assigned character) 
        values for many properties. Most of them are simple boolean 
        flags, or constants from a small enumerated list. For some 
        properties, values are strings or other relatively more complex 
        types.

        For more information see "About the Unicode Character Database" 
        (http://www.unicode.org/ucd/) and the ICU User Guide chapter on 
        Properties (http://oss.software.ibm.com/icu/userguide/properties.html).

        Many functions are designed to match java.lang.Character functions. 
        See the individual function documentation, and see the JDK 1.4.1 
        java.lang.Character documentation at 
        http://java.sun.com/j2se/1.4.1/docs/api/java/lang/Character.html

        There are also functions that provide easy migration from C/POSIX 
        functions like isblank(). Their use is generally discouraged because 
        the C/POSIX standards do not define their semantics beyond the ASCII 
        range, which means that different implementations exhibit very different 
        behavior. Instead, Unicode properties should be used directly.

        There are also only a few, broad C/POSIX character classes, and they 
        tend to be used for conflicting purposes. For example, the "isalpha()" 
        class is sometimes used to determine word boundaries, while a more 
        sophisticated approach would at least distinguish initial letters from 
        continuation characters (the latter including combining marks). (In 
        ICU, BreakIterator is the most sophisticated API for word boundaries.) 
        Another example: There is no "istitle()" class for titlecase characters.

        A summary of the behavior of some C/POSIX character classification 
        implementations for Unicode is available at 
        http://oss.software.ibm.com/cvs/icu/~checkout~/icuhtml/design/posix_classes.html

        See <A HREF="http://oss.software.ibm.com/icu/apiref/uchar_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UChar : ICU
{
        public enum     Property
                        {
                        Alphabetic = 0, 
                        BinaryStart = Alphabetic, 
                        AsciiHexDigit, 
                        BidiControl,
                        BidiMirrored, 
                        Dash, 
                        DefaultIgnorableCodePoint, 
                        Deprecated,
                        Diacritic, 
                        Extender, 
                        FullCompositionExclusion, 
                        GraphemeBase,
                        GraphemeExtend, 
                        GraphemeLink, 
                        HexDigit, 
                        Hyphen,
                        IdContinue, 
                        IdStart, 
                        Ideographic, 
                        IdsBinaryOperator,
                        IdsTrinaryOperator, 
                        JoinControl, 
                        LogicalOrderException, 
                        Lowercase,
                        Math, 
                        NoncharacterCodePoint, 
                        QuotationMark, 
                        Radical,
                        SoftDotted, 
                        TerminalPunctuation, 
                        UnifiedIdeograph, 
                        Uppercase,
                        WhiteSpace, 
                        XidContinue, 
                        XidStart, 
                        CaseSensitive,
                        STerm, 
                        VariationSelector, 
                        NfdInert, 
                        NfkdInert,
                        NfcInert, 
                        NfkcInert, 
                        SegmentStarter, 
                        BinaryLimit,
                        BidiClass = 0x1000, 
                        IntStart = BidiClass, 
                        Block, CanonicalCombiningClass,
                        DecompositionType, 
                        EastAsianWidth, 
                        GeneralCategory, 
                        JoiningGroup,
                        JoiningType, 
                        LineBreak, 
                        NumericType, 
                        Script,
                        HangulSyllableType, 
                        NfdQuickCheck, 
                        NfkdQuickCheck, 
                        NfcQuickCheck,
                        NfkcQuickCheck, 
                        LeadCanonicalCombiningClass,
                        TrailCanonicalCombiningClass, 
                        IntLimit,
                        GeneralCategoryMask = 0x2000, 
                        MaskStart = GeneralCategoryMask, 
                        MaskLimit, 
                        NumericValue = 0x3000,
                        DoubleStart = NumericValue, 
                        DoubleLimit, 
                        Age = 0x4000, 
                        StringStart = Age,
                        BidiMirroringGlyph, 
                        CaseFolding, 
                        IsoComment, 
                        LowercaseMapping,
                        Name, 
                        SimpleCaseFolding, 
                        SimpleLowercaseMapping, 
                        SimpleTitlecaseMapping,
                        SimpleUppercaseMapping, 
                        TitlecaseMapping, 
                        Unicode1Name, 
                        UppercaseMapping,
                        StringLimit, 
                        InvalidCode = -1
                        }
        
        public enum     Category
                        {
                        Unassigned = 0, 
                        GeneralOtherTypes = 0,
                        UppercaseLetter = 1, 
                        LowercaseLetter = 2,
                        TitlecaseLetter = 3, 
                        ModifierLetter = 4, 
                        OtherLetter = 5, 
                        NonSpacingMark = 6,
                        EnclosingMark = 7, 
                        CombiningSpacingMark = 8, 
                        DecimalDigitNumber = 9, 
                        LetterNumber = 10,
                        OtherNumber = 11, 
                        SpaceSeparator = 12, 
                        LineSeparator = 13, 
                        ParagraphSeparator = 14,
                        ControlChar = 15, 
                        FormatChar = 16, 
                        PrivateUseChar = 17, 
                        Surrogate = 18,
                        DashPunctuation = 19, 
                        StartPunctuation = 20, 
                        EndPunctuation = 21, 
                        ConnectorPunctuation = 22,
                        OtherPunctuation = 23,
                        MathSymbol = 24, 
                        CurrencySymbol = 25, 
                        ModifierSymbol = 26,
                        OtherSymbol = 27, 
                        InitialPunctuation = 28, 
                        FinalPunctuation = 29, 
                        Count 
                        }

        public enum     Direction
                        {
                        LeftToRight = 0, 
                        RightToLeft = 1, 
                        EuropeanNumber = 2, 
                        EuropeanNumberSeparator = 3,
                        EuropeanNumberTerminator = 4, 
                        ArabicNumber = 5, 
                        CommonNumberSeparator = 6, 
                        BlockSeparator = 7,
                        SegmentSeparator = 8, 
                        WhiteSpaceNeutral = 9, 
                        OtherNeutral = 10, 
                        LeftToRightEmbedding = 11,
                        LeftToRightOverride = 12, 
                        RightToLeftArabic = 13, 
                        RightToLeftEmbedding = 14, 
                        RightToLeftOverride = 15,
                        PopDirectionalFormat = 16, 
                        DirNonSpacingMark = 17, 
                        BoundaryNeutral = 18, 
                        Count
                        }

        public enum     BlockCode
                        {
                        NoBlock = 0, 
                        BasicLatin = 1, 
                        Latin1Supplement = 2, 
                        LatinExtendedA = 3,
                        LatinExtendedB = 4, 
                        IpaExtensions = 5, 
                        SpacingModifierLetters = 6, 
                        CombiningDiacriticalMarks = 7,
                        Greek = 8, 
                        Cyrillic = 9, 
                        Armenian = 10, 
                        Hebrew = 11,
                        Arabic = 12, 
                        Syriac = 13, 
                        Thaana = 14, 
                        Devanagari = 15,
                        Bengali = 16, 
                        Gurmukhi = 17, 
                        Gujarati = 18, 
                        Oriya = 19,
                        Tamil = 20, 
                        Telugu = 21, 
                        Kannada = 22, 
                        Malayalam = 23,
                        Sinhala = 24, 
                        Thai = 25, 
                        Lao = 26, 
                        Tibetan = 27,
                        Myanmar = 28, 
                        Georgian = 29, 
                        HangulJamo = 30, 
                        Ethiopic = 31,
                        Cherokee = 32, 
                        UnifiedCanadianAboriginalSyllabics = 33, 
                        Ogham = 34, 
                        Runic = 35,
                        Khmer = 36, 
                        Mongolian = 37, 
                        LatinExtendedAdditional = 38, 
                        GreekExtended = 39,
                        GeneralPunctuation = 40, 
                        SuperscriptsAndSubscripts = 41, 
                        CurrencySymbols = 42, 
                        CombiningMarksForSymbols = 43,
                        LetterlikeSymbols = 44, 
                        NumberForms = 45, 
                        Arrows = 46, 
                        MathematicalOperators = 47,
                        MiscellaneousTechnical = 48, 
                        ControlPictures = 49, 
                        OpticalCharacterRecognition = 50, 
                        EnclosedAlphanumerics = 51,
                        BoxDrawing = 52, 
                        BlockElements = 53, 
                        GeometricShapes = 54, 
                        MiscellaneousSymbols = 55,
                        Dingbats = 56, 
                        BraillePatterns = 57, 
                        CjkRadicalsSupplement = 58, 
                        KangxiRadicals = 59,
                        IdeographicDescriptionCharacters = 60, 
                        CjkSymbolsAndPunctuation = 61, 
                        Hiragana = 62, 
                        Katakana = 63,
                        Bopomofo = 64, 
                        HangulCompatibilityJamo = 65, 
                        Kanbun = 66, 
                        BopomofoExtended = 67,
                        EnclosedCjkLettersAndMonths = 68, 
                        CjkCompatibility = 69, 
                        CjkUnifiedIdeographsExtensionA = 70, 
                        CjkUnifiedIdeographs = 71,
                        YiSyllables = 72, 
                        YiRadicals = 73, 
                        HangulSyllables = 74, 
                        HighSurrogates = 75,
                        HighPrivateUseSurrogates = 76, 
                        LowSurrogates = 77, 
                        PrivateUse = 78, 
                        PrivateUseArea = PrivateUse,
                        CjkCompatibilityIdeographs = 79, 
                        AlphabeticPresentationForms = 80, 
                        ArabicPresentationFormsA = 81, 
                        CombiningHalfMarks = 82,
                        CjkCompatibilityForms = 83, 
                        SmallFormVariants = 84, 
                        ArabicPresentationFormsB = 85, 
                        Specials = 86,
                        HalfwidthAndFullwidthForms = 87, 
                        OldItalic = 88, 
                        Gothic = 89, 
                        Deseret = 90,
                        ByzantineMusicalSymbols = 91, 
                        MusicalSymbols = 92, 
                        MathematicalAlphanumericSymbols = 93, 
                        CjkUnifiedIdeographsExtensionB = 94,
                        CjkCompatibilityIdeographsSupplement = 95, 
                        Tags = 96, 
                        CyrillicSupplementary = 97, 
                        CyrillicSupplement = CyrillicSupplementary,
                        Tagalog = 98, 
                        Hanunoo = 99, 
                        Buhid = 100, 
                        Tagbanwa = 101,
                        MiscellaneousMathematicalSymbolsA = 102, 
                        SupplementalArrowsA = 103, 
                        SupplementalArrowsB = 104, 
                        MiscellaneousMathematicalSymbolsB = 105,
                        SupplementalMathematicalOperators = 106, 
                        KatakanaPhoneticExtensions = 107, 
                        VariationSelectors = 108, 
                        SupplementaryPrivateUseAreaA = 109,
                        SupplementaryPrivateUseAreaB = 110, 
                        Limbu = 111, 
                        TaiLe = 112, 
                        KhmerSymbols = 113,
                        PhoneticExtensions = 114, 
                        MiscellaneousSymbolsAndArrows = 115, 
                        YijingHexagramSymbols = 116, 
                        LinearBSyllabary = 117,
                        LinearBIdeograms = 118, 
                        AegeanNumbers = 119, 
                        Ugaritic = 120, 
                        Shavian = 121,
                        Osmanya = 122, 
                        CypriotSyllabary = 123, 
                        TaiXuanJingSymbols = 124, 
                        VariationSelectorsSupplement = 125,
                        Count, 
                        InvalidCode = -1
                        }

        public enum     EastAsianWidth
                        {
                        Neutral, 
                        Ambiguous, 
                        Halfwidth, 
                        Fullwidth,
                        Narrow, 
                        Wide, 
                        Count
                        }

        public enum     CharNameChoice
                        {
                        Unicode, 
                        Unicode10, 
                        Extended, 
                        Count
                        }
                     
        public enum     NameChoice
                        {
                        Short, 
                        Long, 
                        Count
                        }

        public enum     DecompositionType
                        {
                        None, 
                        Canonical, 
                        Compat, 
                        Circle,
                        Final, 
                        Font, 
                        Fraction, 
                        Initial,
                        Isolated, 
                        Medial, 
                        Narrow, 
                        Nobreak,
                        Small, 
                        Square, 
                        Sub, 
                        Super,
                        Vertical, 
                        Wide, 
                        Count
                        }

        public enum     JoiningType
                        {
                        NonJoining, 
                        JoinCausing, 
                        DualJoining, 
                        LeftJoining,
                        RightJoining, 
                        Transparent, 
                        Count
                        }

        public enum     JoiningGroup
                        {
                        NoJoiningGroup, 
                        Ain, 
                        Alaph, 
                        Alef,
                        Beh, 
                        Beth, 
                        Dal, 
                        DalathRish,
                        E, 
                        Feh, 
                        FinalSemkath, 
                        Gaf,
                        Gamal, 
                        Hah, 
                        HamzaOnHehGoal, 
                        He,
                        Heh, 
                        HehGoal, 
                        Heth, 
                        Kaf,
                        Kaph, 
                        KnottedHeh, 
                        Lam, 
                        Lamadh,
                        Meem, 
                        Mim, 
                        Noon, 
                        Nun,
                        Pe, 
                        Qaf, 
                        Qaph, 
                        Reh,
                        Reversed_Pe, 
                        Sad, 
                        Sadhe, 
                        Seen,
                        Semkath, 
                        Shin, 
                        Swash_Kaf, 
                        Syriac_Waw,
                        Tah, 
                        Taw, 
                        Teh_Marbuta, 
                        Teth,
                        Waw, 
                        Yeh, 
                        Yeh_Barree, 
                        Yeh_With_Tail,
                        Yudh, 
                        Yudh_He, 
                        Zain, 
                        Fe,
                        Khaph, 
                        Zhain, 
                        Count
                        }

        public enum     LineBreak
                        {
                        Unknown, 
                        Ambiguous, 
                        Alphabetic, 
                        BreakBoth,
                        BreakAfter, 
                        BreakBefore, 
                        MandatoryBreak, 
                        ContingentBreak,
                        ClosePunctuation, 
                        CombiningMark, 
                        CarriageReturn, 
                        Exclamation,
                        Glue, 
                        Hyphen, 
                        Ideographic, 
                        Inseperable,
                        Inseparable = Inseperable, 
                        InfixNumeric, 
                        LineFeed, 
                        Nonstarter,
                        Numeric, 
                        OpenPunctuation, 
                        PostfixNumeric, 
                        PrefixNumeric,
                        Quotation, 
                        ComplexContext, 
                        Surrogate, 
                        Space,
                        BreakSymbols, 
                        Zwspace, 
                        NextLine, 
                        WordJoiner,
                        Count
                        }

        public enum     NumericType
                        {
                        None, 
                        Decimal, 
                        Digit, 
                        Numeric,
                        Count
                        }

        public enum     HangulSyllableType
                        {
                        NotApplicable, 
                        LeadingJamo, 
                        VowelJamo, 
                        TrailingJamo,
                        LvSyllable, 
                        LvtSyllable, 
                        Count
                        }

        /***********************************************************************
        
                Get the property value for an enumerated or integer 
                Unicode property for a code point. Also returns binary 
                and mask property values.

                Unicode, especially in version 3.2, defines many more 
                properties than the original set in UnicodeData.txt.

                The properties APIs are intended to reflect Unicode 
                properties as defined in the Unicode Character Database 
                (UCD) and Unicode Technical Reports (UTR). For details 
                about the properties see http://www.unicode.org/ . For 
                names of Unicode properties see the file PropertyAliases.txt

        ***********************************************************************/

        uint getProperty (dchar c, Property p)
        {
                return u_getIntPropertyValue (cast(uint) c, cast(uint) p);
        }

        /***********************************************************************
        
                Get the minimum value for an enumerated/integer/binary 
                Unicode property

        ***********************************************************************/

        uint getPropertyMinimum (Property p)
        {
                return u_getIntPropertyMinValue (p);
        }

        /***********************************************************************
        
                Get the maximum value for an enumerated/integer/binary 
                Unicode property

        ***********************************************************************/

        uint getPropertyMaximum (Property p)
        {
                return u_getIntPropertyMaxValue (p);
        }
       
        /***********************************************************************
        
                Returns the bidirectional category value for the code 
                point, which is used in the Unicode bidirectional algorithm 
                (UAX #9 http://www.unicode.org/reports/tr9/).

        ***********************************************************************/

        Direction charDirection (dchar c)
        {
                return cast(Direction) u_charDirection (c);
        }

        /***********************************************************************
        
                Returns the Unicode allocation block that contains the 
                character

        ***********************************************************************/

        BlockCode getBlockCode (dchar c)
        {
                return cast(BlockCode) ublock_getCode (c);
        }
        
        /***********************************************************************
        
                Retrieve the name of a Unicode character.

        ***********************************************************************/

        char[] getCharName (dchar c, CharNameChoice choice, inout char[] dst)
        {
                Error e;

                uint len = u_charName (c, choice, dst.ptr, dst.length, e);
                testError (e, "failed to extract char name (buffer too small?)");
                return dst [0..len];
        }
        
        /***********************************************************************
        
                Get the ISO 10646 comment for a character.

        ***********************************************************************/

        char[] getComment (dchar c, inout char[] dst)
        {
                Error e;

                uint len = u_getISOComment (c, dst.ptr, dst.length, e);
                testError (e, "failed to extract comment (buffer too small?)");
                return dst [0..len];
        }
        
        /***********************************************************************
        
                Find a Unicode character by its name and return its code 
                point value.

        ***********************************************************************/

        dchar charFromName (CharNameChoice choice, char[] name)
        {
                Error e;

                dchar c = u_charFromName (choice, toString(name), e);
                testError (e, "failed to locate char name");
                return c;
        }
        
        /***********************************************************************
        
                Return the Unicode name for a given property, as given in the 
                Unicode database file PropertyAliases.txt

        ***********************************************************************/

        char[] getPropertyName (Property p, NameChoice choice)
        {
                return toArray (u_getPropertyName (p, choice));
        }
        
        /***********************************************************************
        
                Return the Unicode name for a given property value, as given 
                in the Unicode database file PropertyValueAliases.txt. 

        ***********************************************************************/

        char[] getPropertyValueName (Property p, NameChoice choice, uint value)
        {
                return toArray (u_getPropertyValueName (p, value, choice));
        }
        
        /***********************************************************************
        
                Gets the Unicode version information

        ***********************************************************************/

        void getUnicodeVersion (inout Version v)
        {
                u_getUnicodeVersion (v);
        }
        
        /***********************************************************************
        
                Get the "age" of the code point

        ***********************************************************************/

        void getCharAge (dchar c, inout Version v)
        {
                u_charAge (c, v);
        }
        

        /***********************************************************************
        
                These are externalised directly to the client (sans wrapper),
                but this may have to change for linux, depending upon the
                ICU function-naming conventions within the Posix libraries.

        ***********************************************************************/

        final static extern (C) 
        {
                /***************************************************************

                        Check if a code point has the Alphabetic Unicode 
                        property.

                ***************************************************************/

                bool function (dchar c) isUAlphabetic;

                /***************************************************************

                        Check if a code point has the Lowercase Unicode 
                        property.

                ***************************************************************/

                bool function (dchar c) isULowercase;

                /***************************************************************

                        Check if a code point has the Uppercase Unicode 
                        property.

                ***************************************************************/

                bool function (dchar c) isUUppercase;

                /***************************************************************

                        Check if a code point has the White_Space Unicode 
                        property.

                ***************************************************************/

                bool function (dchar c) isUWhiteSpace;

                /***************************************************************

                        Determines whether the specified code point has the 
                        general category "Ll" (lowercase letter).

                ***************************************************************/

                bool function (dchar c) isLower;

                /***************************************************************

                        Determines whether the specified code point has the 
                        general category "Lu" (uppercase letter).

                ***************************************************************/

                bool function (dchar c) isUpper;

                /***************************************************************

                        Determines whether the specified code point is a 
                        titlecase letter.

                ***************************************************************/

                bool function (dchar c) isTitle;

                /***************************************************************

                        Determines whether the specified code point is a 
                        digit character according to Java.

                ***************************************************************/

                bool function (dchar c) isDigit;

                /***************************************************************

                        Determines whether the specified code point is a 
                        letter character.

                ***************************************************************/

                bool function (dchar c) isAlpha;

                /***************************************************************

                        Determines whether the specified code point is an 
                        alphanumeric character (letter or digit) according 
                        to Java.

                ***************************************************************/

                bool function (dchar c) isAlphaNumeric;

                /***************************************************************

                        Determines whether the specified code point is a 
                        hexadecimal digit.

                ***************************************************************/

                bool function (dchar c) isHexDigit;

                /***************************************************************

                        Determines whether the specified code point is a 
                        punctuation character.

                ***************************************************************/

                bool function (dchar c) isPunct;

                /***************************************************************

                        Determines whether the specified code point is a 
                        "graphic" character (printable, excluding spaces).

                ***************************************************************/

                bool function (dchar c) isGraph;

                /***************************************************************

                        Determines whether the specified code point is a 
                        "blank" or "horizontal space", a character that 
                        visibly separates words on a line.

                ***************************************************************/

                bool function (dchar c) isBlank;

                /***************************************************************

                        Determines whether the specified code point is 
                        "defined", which usually means that it is assigned 
                        a character.

                ***************************************************************/

                bool function (dchar c) isDefined;

                /***************************************************************

                        Determines if the specified character is a space 
                        character or not.

                ***************************************************************/

                bool function (dchar c) isSpace;

                /***************************************************************

                        Determine if the specified code point is a space 
                        character according to Java.

                ***************************************************************/

                bool function (dchar c) isJavaSpaceChar;

                /***************************************************************

                        Determines if the specified code point is a whitespace 
                        character according to Java/ICU.

                ***************************************************************/

                bool function (dchar c) isWhiteSpace;

                /***************************************************************

                        Determines whether the specified code point is a 
                        control character (as defined by this function).

                ***************************************************************/

                bool function (dchar c) isCtrl;

                /***************************************************************

                        Determines whether the specified code point is an ISO 
                        control code.

                ***************************************************************/

                bool function (dchar c) isISOControl;

                /***************************************************************

                        Determines whether the specified code point is a 
                        printable character.

                ***************************************************************/

                bool function (dchar c) isPrint;

                /***************************************************************

                        Determines whether the specified code point is a 
                        base character.

                ***************************************************************/

                bool function (dchar c) isBase;

                /***************************************************************

                        Determines if the specified character is permissible 
                        as the first character in an identifier according to 
                        Unicode (The Unicode Standard, Version 3.0, chapter 
                        5.16 Identifiers).

                ***************************************************************/

                bool function (dchar c) isIDStart;

                /***************************************************************

                        Determines if the specified character is permissible 
                        in an identifier according to Java.

                ***************************************************************/

                bool function (dchar c) isIDPart;

                /***************************************************************

                        Determines if the specified character should be 
                        regarded as an ignorable character in an identifier, 
                        according to Java.

                ***************************************************************/

                bool function (dchar c) isIDIgnorable;

                /***************************************************************

                        Determines if the specified character is permissible 
                        as the first character in a Java identifier.

                ***************************************************************/

                bool function (dchar c) isJavaIDStart;

                /***************************************************************

                        Determines if the specified character is permissible 
                        in a Java identifier.

                ***************************************************************/

                bool function (dchar c) isJavaIDPart;

                /***************************************************************

                        Determines whether the code point has the 
                        Bidi_Mirrored property.

                ***************************************************************/

                bool function (dchar c) isMirrored;

                /***************************************************************

                        Returns the decimal digit value of a decimal digit 
                        character.

                ***************************************************************/

                ubyte function (dchar c) charDigitValue;

                /***************************************************************

                        Maps the specified character to a "mirror-image" 
                        character.

                ***************************************************************/

                dchar function (dchar c) charMirror;

                /***************************************************************

                        Returns the general category value for the code point.

                ***************************************************************/

                ubyte function (dchar c) charType;

                /***************************************************************

                        Returns the combining class of the code point as 
                        specified in UnicodeData.txt.

                ***************************************************************/

                ubyte function (dchar c) getCombiningClass;

                /***************************************************************

                        The given character is mapped to its lowercase 
                        equivalent according to UnicodeData.txt; if the 
                        character has no lowercase equivalent, the 
                        character itself is returned.

                ***************************************************************/

                dchar function (dchar c) toLower;

                /***************************************************************

                        The given character is mapped to its uppercase equivalent 
                        according to UnicodeData.txt; if the character has no 
                        uppercase equivalent, the character itself is returned.

                ***************************************************************/

                dchar function (dchar c) toUpper;

                /***************************************************************

                        The given character is mapped to its titlecase 
                        equivalent according to UnicodeData.txt; if none 
                        is defined, the character itself is returned.

                ***************************************************************/

                dchar function (dchar c) toTitle;

                /***************************************************************

                        The given character is mapped to its case folding 
                        equivalent according to UnicodeData.txt and 
                        CaseFolding.txt; if the character has no case folding 
                        equivalent, the character itself is returned.

                ***************************************************************/

                dchar function (dchar c, uint options) foldCase;

                /***************************************************************

                        Returns the decimal digit value of the code point in 
                        the specified radix.

                ***************************************************************/

                uint function (dchar ch, ubyte radix) digit;

                /***************************************************************

                        Determines the character representation for a specific 
                        digit in the specified radix.

                ***************************************************************/

                dchar function (uint digit, ubyte radix) forDigit;

                /***************************************************************

                        Get the numeric value for a Unicode code point as 
                        defined in the Unicode Character Database.

                ***************************************************************/

                double function (dchar c) getNumericValue;
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
                uint   function (uint, uint) u_getIntPropertyValue;
                uint   function (uint) u_getIntPropertyMinValue;
                uint   function (uint) u_getIntPropertyMaxValue;
                uint   function (dchar) u_charDirection;
                uint   function (dchar) ublock_getCode;
                uint   function (dchar, uint, char*, uint, inout Error) u_charName;
                uint   function (dchar, char*, uint, inout Error) u_getISOComment;
                uint   function (uint, char*, inout Error) u_charFromName;
                char*  function (uint, uint) u_getPropertyName;
                char*  function (uint, uint, uint) u_getPropertyValueName;
                void   function (inout Version) u_getUnicodeVersion;
                void   function (dchar, inout Version) u_charAge;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &forDigit,                "u_forDigit"},
                {cast(void**) &digit,                   "u_digit"},
                {cast(void**) &foldCase,                "u_foldCase"},
                {cast(void**) &toTitle,                 "u_totitle"},
                {cast(void**) &toUpper,                 "u_toupper"},
                {cast(void**) &toLower,                 "u_tolower"},
                {cast(void**) &charType,                "u_charType"},
                {cast(void**) &charMirror,              "u_charMirror"},
                {cast(void**) &charDigitValue,          "u_charDigitValue"},
                {cast(void**) &isJavaIDPart,            "u_isJavaIDPart"},
                {cast(void**) &isJavaIDStart,           "u_isJavaIDStart"},
                {cast(void**) &isIDIgnorable,           "u_isIDIgnorable"},
                {cast(void**) &isIDPart,                "u_isIDPart"},
                {cast(void**) &isIDStart,               "u_isIDStart"},
                {cast(void**) &isMirrored,              "u_isMirrored"},
                {cast(void**) &isBase,                  "u_isbase"},
                {cast(void**) &isPrint,                 "u_isprint"},
                {cast(void**) &isISOControl,            "u_isISOControl"},
                {cast(void**) &isCtrl,                  "u_iscntrl"},
                {cast(void**) &isWhiteSpace,            "u_isWhitespace"},
                {cast(void**) &isJavaSpaceChar,         "u_isJavaSpaceChar"},
                {cast(void**) &isSpace,                 "u_isspace"},
                {cast(void**) &isDefined,               "u_isdefined"},
                {cast(void**) &isBlank,                 "u_isblank"},
                {cast(void**) &isGraph,                 "u_isgraph"},
                {cast(void**) &isPunct,                 "u_ispunct"},
                {cast(void**) &isHexDigit,              "u_isxdigit"},
                {cast(void**) &isAlpha,                 "u_isalpha"},
                {cast(void**) &isAlphaNumeric,          "u_isalnum"},
                {cast(void**) &isDigit,                 "u_isdigit"},
                {cast(void**) &isTitle,                 "u_istitle"},
                {cast(void**) &isUpper,                 "u_isupper"},
                {cast(void**) &isLower,                 "u_islower"},
                {cast(void**) &isUAlphabetic,           "u_isUAlphabetic"},
                {cast(void**) &isUWhiteSpace,           "u_isUWhiteSpace"},
                {cast(void**) &isUUppercase,            "u_isUUppercase"},
                {cast(void**) &isULowercase,            "u_isULowercase"},
                {cast(void**) &getNumericValue,         "u_getNumericValue"},
                {cast(void**) &getCombiningClass,       "u_getCombiningClass"},
                {cast(void**) &u_getIntPropertyValue,   "u_getIntPropertyValue"},
                {cast(void**) &u_getIntPropertyMinValue,"u_getIntPropertyMinValue"},
                {cast(void**) &u_getIntPropertyMaxValue,"u_getIntPropertyMaxValue"},
                {cast(void**) &u_charDirection,         "u_charDirection"},
                {cast(void**) &ublock_getCode,          "ublock_getCode"},
                {cast(void**) &u_charName,              "u_charName"},
                {cast(void**) &u_getISOComment,         "u_getISOComment"},
                {cast(void**) &u_charFromName,          "u_charFromName"},
                {cast(void**) &u_getPropertyName,       "u_getPropertyName"},
                {cast(void**) &u_getPropertyValueName,  "u_getPropertyValueName"},
                {cast(void**) &u_getUnicodeVersion,     "u_getUnicodeVersion"},
                {cast(void**) &u_charAge,               "u_charAge"},
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

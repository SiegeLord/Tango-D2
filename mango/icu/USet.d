/*******************************************************************************

        @file USet.d
        
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

module mango.icu.USet;

private import  mango.icu.ICU,
                mango.icu.UString;

/*******************************************************************************

        A mutable set of Unicode characters and multicharacter strings.

        Objects of this class represent character classes used in regular 
        expressions. A character specifies a subset of Unicode code points. 
        Legal code points are U+0000 to U+10FFFF, inclusive.

        UnicodeSet supports two APIs. The first is the operand API that 
        allows the caller to modify the value of a UnicodeSet object. It 
        conforms to Java 2's java.util.Set interface, although UnicodeSet
        does not actually implement that interface. All methods of Set are 
        supported, with the modification that they take a character range 
        or single character instead of an Object, and they take a UnicodeSet
        instead of a Collection. The operand API may be thought of in terms
        of boolean logic: a boolean OR is implemented by add, a boolean AND 
        is implemented by retain, a boolean XOR is implemented by complement
        taking an argument, and a boolean NOT is implemented by complement 
        with no argument. In terms of traditional set theory function names, 
        add is a union, retain is an intersection, remove is an asymmetric
        difference, and complement with no argument is a set complement with
        respect to the superset range MIN_VALUE-MAX_VALUE

        The second API is the applyPattern()/toPattern() API from the 
        java.text.Format-derived classes. Unlike the methods that add 
        characters, add categories, and control the logic of the set, 
        the method applyPattern() sets all attributes of a UnicodeSet 
        at once, based on a string pattern.

        See <A HREF="http://oss.software.ibm.com/icu/apiref/uset_8h.html">
        this page</A> for full details.

*******************************************************************************/

class USet : ICU
{       
        package Handle handle;

        enum    Options
                {
                None            = 0,
                IgnoreSpace     = 1, 
                CaseInsensitive = 2, 
                }


        /***********************************************************************

                Creates a USet object that contains the range of characters 
                start..end, inclusive

        ***********************************************************************/

        this (wchar start, wchar end)
        {
                handle = uset_open (start, end);
        }

        /***********************************************************************

                Creates a set from the given pattern. See the UnicodeSet 
                class description for the syntax of the pattern language

        ***********************************************************************/

        this (UText pattern, Options o = Options.None)
        {
                Error e;

                handle = uset_openPatternOptions (pattern.get.ptr, pattern.len, o, e);
                testError (e, "failed to open pattern-based charset");
        }

        /***********************************************************************

                Internal constructor invoked via UCollator

        ***********************************************************************/

        package this (Handle handle)
        {
                this.handle = handle;
        }

        /***********************************************************************
        
                Disposes of the storage used by a USet object

        ***********************************************************************/

        ~this ()
        {
                uset_close (handle);
        }

        /***********************************************************************

                Modifies the set to represent the set specified by the 
                given pattern. See the UnicodeSet class description for 
                the syntax of the pattern language. See also the User 
                Guide chapter about UnicodeSet. Empties the set passed 
                before applying the pattern. 

        ***********************************************************************/
        
        void applyPattern (UText pattern, Options o = Options.None)
        {
                Error e;

                uset_applyPattern (handle, pattern.get.ptr, pattern.len, o, e);
                testError (e, "failed to apply pattern");
        }

        /***********************************************************************

                Returns a string representation of this set. If the result 
                of calling this function is passed to a uset_openPattern(), 
                it will produce another set that is equal to this one. 

        ***********************************************************************/
        
        void toPattern (UString dst, bool escape)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return uset_toPattern (handle, p, len, escape, e);
                }

                dst.format (&fmt, "failed to convert charset to a pattern");
        }

        /***********************************************************************
                
                Adds the given character to the given USet. After this call, 
                contains (c) will return true. 

        ***********************************************************************/

        void add (wchar c)
        {
                uset_add (handle, c);
        }

        /***********************************************************************
        
                Adds all of the elements in the specified set to this set 
                if they're not already present. This operation effectively 
                modifies this set so that its value is the union of the two 
                sets. The behavior of this operation is unspecified if the 
                specified collection is modified while the operation is in 
                progress.

        ***********************************************************************/

        void addSet (USet other)
        {
                uset_addAll (handle, other.handle);
        }

        /***********************************************************************
        
                Adds the given range of characters to the given USet. After 
                this call, contains(start, end) will return true

        ***********************************************************************/

        void addRange (wchar start, wchar end)
        {
                uset_addRange (handle, start, end);
        }

        /***********************************************************************
        
                Adds the given string to the given USet. After this call, 
                containsString (str, strLen) will return true

        ***********************************************************************/

        void addString (UText t)
        {
                uset_addString (handle, t.get.ptr, t.len);
        }

        /***********************************************************************
        
                Removes the given character from this USet. After the 
                call, contains(c) will return false

        ***********************************************************************/

        void remove (wchar c)
        {
                uset_remove (handle, c);
        }

        /***********************************************************************
        
                Removes the given range of characters from this USet.
                After the call, contains(start, end) will return false

        ***********************************************************************/

        void removeRange (wchar start, wchar end)
        {
                uset_removeRange (handle, start, end);
        }

        /***********************************************************************
        
                Removes the given string from this USet. After the call, 
                containsString (str, strLen) will return false

        ***********************************************************************/

        void removeString (UText t)
        {
                uset_removeString (handle, t.get.ptr, t.len);
        }

        /***********************************************************************
        
                Inverts this set. This operation modifies this set so 
                that its value is its complement. This operation does 
                not affect the multicharacter strings, if any

        ***********************************************************************/

        void complement ()
        {
                uset_complement (handle);
        }

        /***********************************************************************
        
                Removes all of the elements from this set. This set will 
                be empty after this call returns. 

        ***********************************************************************/

        void clear ()
        {
                uset_clear (handle);
        }

        /***********************************************************************
        
                Returns true if this USet contains no characters and no 
                strings

        ***********************************************************************/

        bool isEmpty ()
        {
                return uset_isEmpty (handle) != 0;
        }

        /***********************************************************************
        
                Returns true if this USet contains the given character

        ***********************************************************************/

        bool contains (wchar c)
        {
                return uset_contains (handle, c) != 0;
        }

        /***********************************************************************
        
                Returns true if this USet contains all characters c where 
                start <= c && c <= end

        ***********************************************************************/

        bool containsRange (wchar start, wchar end)
        {
                return uset_containsRange (handle, start, end) != 0;
        }

        /***********************************************************************
        
                Returns true if this USet contains the given string

        ***********************************************************************/

        bool containsString (UText t)
        {
                return uset_containsString (handle, t.get.ptr, t.len) != 0;
        }

        /***********************************************************************
        
        ***********************************************************************/

        uint size ()
        {
                return uset_size (handle);
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
                Handle function (wchar start, wchar end) uset_open;
                void   function (Handle) uset_close;
                Handle function (wchar* pattern, uint patternLength, uint options, inout Error e) uset_openPatternOptions;                        
                uint   function (Handle, wchar* pattern, uint patternLength, uint options, inout Error e) uset_applyPattern;
                uint   function (Handle, wchar* result, uint resultCapacity, byte escapeUnprintable, inout Error e) uset_toPattern;
                void   function (Handle, wchar c) uset_add;
                void   function (Handle, Handle additionalSet) uset_addAll;
                void   function (Handle, wchar start, wchar end) uset_addRange;                        
                void   function (Handle, wchar* str, uint strLen) uset_addString;
                void   function (Handle, wchar c) uset_remove;
                void   function (Handle, wchar start, wchar end) uset_removeRange;
                void   function (Handle, wchar* str, uint strLen) uset_removeString;                       
                void   function (Handle) uset_complement;
                void   function (Handle) uset_clear;
                byte   function (Handle) uset_isEmpty;
                byte   function (Handle, wchar c) uset_contains;
                byte   function (Handle, wchar start, wchar end) uset_containsRange;
                byte   function (Handle, wchar* str, uint strLen) uset_containsString;
                uint   function (Handle) uset_size;
         }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &uset_open,               "uset_open"}, 
                {cast(void**) &uset_close,              "uset_close"},
                {cast(void**) &uset_openPatternOptions, "uset_openPatternOptions"},
                {cast(void**) &uset_applyPattern,       "uset_applyPattern"},
                {cast(void**) &uset_toPattern,          "uset_toPattern"},
                {cast(void**) &uset_add,                "uset_add"},
                {cast(void**) &uset_addAll,             "uset_addAll"},
                {cast(void**) &uset_addRange,           "uset_addRange"},
                {cast(void**) &uset_addString,          "uset_addString"},
                {cast(void**) &uset_remove,             "uset_remove"},
                {cast(void**) &uset_removeRange,        "uset_removeRange"},
                {cast(void**) &uset_removeString,       "uset_removeString"},
                {cast(void**) &uset_complement,         "uset_complement"},
                {cast(void**) &uset_clear,              "uset_clear"},
                {cast(void**) &uset_isEmpty,            "uset_isEmpty"},
                {cast(void**) &uset_contains,           "uset_contains"},
                {cast(void**) &uset_containsRange,      "uset_containsRange"},
                {cast(void**) &uset_containsString,     "uset_containsString"},
                {cast(void**) &uset_size,               "uset_size"},
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


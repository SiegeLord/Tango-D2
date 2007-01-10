/*******************************************************************************

        @file UStringPrep.d
        
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

module mango.icu.UStringPrep;

private import  mango.icu.ICU,
                mango.icu.UString;

/*******************************************************************************

        StringPrep API implements the StingPrep framework as described 
        by RFC 3454.

        StringPrep prepares Unicode strings for use in network protocols. 
        Profiles of StingPrep are set of rules and data according to with 
        the Unicode Strings are prepared. Each profiles contains tables 
        which describe how a code point should be treated. The tables are 
        broadly classied into

        - Unassinged Table: Contains code points that are unassigned 
          in the Unicode Version supported by StringPrep. Currently 
          RFC 3454 supports Unicode 3.2.

        - Prohibited Table: Contains code points that are prohibted 
          from the output of the StringPrep processing function.

        - Mapping Table: Contains code ponts that are deleted from the 
          output or case mapped.

        The procedure for preparing Unicode strings:

        1. Map: For each character in the input, check if it has a mapping 
           and, if so, replace it with its mapping.

        2. Normalize: Possibly normalize the result of step 1 using Unicode 
           normalization.

        3. Prohibit: Check for any characters that are not allowed in the 
           output. If any are found, return an error.

        4. Check bidi: Possibly check for right-to-left characters, and if 
           any are found, make sure that the whole string satisfies the 
           requirements for bidirectional strings. If the string does not 
           satisfy the requirements for bidirectional strings, return an 
           error.

        See <A HREF="http://oss.software.ibm.com/icu/apiref/usprep_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UStringPrep : ICU
{       
        private Handle handle;

        enum    Options
                {
                Strict,
                Lenient
                }


        /***********************************************************************

                Creates a StringPrep profile from the data file.

                path            string containing the full path pointing 
                                to the directory where the profile reside 
                                followed by the package name e.g. 
                                "/usr/resource/my_app/profiles/mydata" on 
                                a Unix system. if NULL, ICU default data 
                                files will be used.

                fileName        name of the profile file to be opened
        
        ***********************************************************************/

        this (char[] path, char[] filename)
        {
                Error e;

                handle = usprep_open (toString(path), toString(filename), e);
                testError (e, "failed to open string-prep");
        }

        /***********************************************************************
                
                Close this profile

        ***********************************************************************/

        ~this ()
        {
                usprep_close (handle);
        }

        /***********************************************************************

                Prepare the input buffer

                This operation maps, normalizes(NFKC), checks for prohited
                and BiDi characters in the order defined by RFC 3454 depending 
                on the options specified in the profile

        ***********************************************************************/

        void prepare (UText src, UString dst, Options o = Options.Strict)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return usprep_prepare (handle, src.get.ptr, src.len, p, len, o, null, e);
                }
                
                dst.format (&fmt, "failed to prepare text");
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
                Handle  function (char*, char*, inout Error) usprep_open;
                void    function (Handle) usprep_close;
                uint    function (Handle, wchar*, uint, wchar*, uint, uint, void*, inout Error) usprep_prepare;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &usprep_open,             "usprep_open"}, 
                {cast(void**) &usprep_close,            "usprep_close"},
                {cast(void**) &usprep_prepare,          "usprep_prepare"},
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


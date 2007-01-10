/*******************************************************************************

        @file UTransform.d
        
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

module mango.icu.UTransform;

private import  mango.icu.ICU,
                mango.icu.UString;

/*******************************************************************************

        See <A HREF="http://oss.software.ibm.com/icu/apiref/utrans_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UTransform : ICU
{       
        private Handle handle;

        enum    Direction
                {
                Forward,
                Reverse
                }


        /***********************************************************************

        ***********************************************************************/

        this (UText id)
        {
                Error e;

                handle = utrans_openU (id.get.ptr, id.len, 0, null, 0, null, e);
                testError (e, "failed to open ID transform");
        }

        /***********************************************************************

        ***********************************************************************/

        this (UText rule, Direction dir)
        {
                Error e;

                handle = utrans_openU (null, 0, dir, rule.get.ptr, rule.len, null, e);
                testError (e, "failed to open rule-based transform");
        }

        /***********************************************************************
        
        ***********************************************************************/

        ~this ()
        {
                utrans_close (handle);
        }

        /***********************************************************************

        ***********************************************************************/

        UText getID ()
        {
                uint len;
                wchar *s = utrans_getUnicodeID (handle, len);
                return new UText (s[0..len]);
        }

        /***********************************************************************

        ***********************************************************************/

        UTransform setFilter (UText filter)
        {
                Error e;

                if (filter.length)
                    utrans_setFilter (handle, filter.get.ptr, filter.len, e);
                else
                   utrans_setFilter (handle, null, 0, e);
                   
                testError (e, "failed to set transform filter");
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        UTransform execute (UString text)
        {
                Error   e;
                uint    textLen = text.len;

                utrans_transUChars (handle, text.get.ptr, &textLen, text.content.length, 0, &text.len, e);
                testError (e, "failed to execute transform");
                return this;
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
                Handle  function (wchar*, uint, uint, wchar*, uint, void*, inout Error) utrans_openU;
                void    function (Handle) utrans_close;
                wchar*  function (Handle, inout uint) utrans_getUnicodeID;
                void    function (Handle, wchar*, uint, inout Error) utrans_setFilter;
                void    function (Handle, wchar*, uint*, uint, uint, uint*, inout Error) utrans_transUChars;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &utrans_openU,            "utrans_openU"}, 
                {cast(void**) &utrans_close,            "utrans_close"},
                {cast(void**) &utrans_getUnicodeID,     "utrans_getUnicodeID"},
                {cast(void**) &utrans_setFilter,        "utrans_setFilter"},
                {cast(void**) &utrans_transUChars,      "utrans_transUChars"},
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


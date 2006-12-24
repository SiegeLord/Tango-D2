/*******************************************************************************

        @file UEnumeration.d
        
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

module mango.icu.UEnumeration;

private import  mango.icu.ICU;

/*******************************************************************************

        UEnumeration is returned by a number of ICU classes, for providing
        access to such things as ULocale lists and so on,

*******************************************************************************/

class UEnumeration : ICU
{
        package Handle handle;

        /***********************************************************************

        ***********************************************************************/

        this (Handle handle)
        {
                this.handle = handle;
        }

        /***********************************************************************
        
                Disposes of the storage used by a UEnumeration object

        ***********************************************************************/

        ~this ()
        {
                uenum_close (handle);
        }

        /***********************************************************************
        
                Returns the next element in the iterator's list.

                If there are no more elements, returns NULL. If the 
                iterator is out-of-sync with its service, status is 
                set to U_ENUM_OUT_OF_SYNC_ERROR and NULL is returned. 
                If the native service string is a UChar* string, it 
                is converted to char* with the invariant converter. 
                The result is terminated by (char)0. If the conversion 
                fails (because a character cannot be converted) then 
                status is set to U_INVARIANT_CONVERSION_ERROR and the 
                return value is undefined (but non-NULL). 

        ***********************************************************************/

        uint count ()
        {   
                Error e;
                
                uint x = uenum_count (handle, e);
                testError (e, "enumeration out of sync");    
                return x;
        }

        /***********************************************************************
                
                Resets the iterator to the current list of service IDs.

                This re-establishes sync with the service and rewinds 
                the iterator to start at the first element

        ***********************************************************************/

        void reset ()
        {       
                ICU.Error e;

                uenum_reset (handle, e);
                testError (e, "failed to reset enumeration");                
        }

        /***********************************************************************
        
                Returns the next element in the iterator's list.

                If there are no more elements, returns NULL. If the 
                iterator is out-of-sync with its service, status is 
                set to U_ENUM_OUT_OF_SYNC_ERROR and NULL is returned. 
                If the native service string is a char* string, it is 
                converted to UChar* with the invariant converter.

        ***********************************************************************/

        bool next (out char[] dst)
        {       
                ICU.Error e;
                uint      len;

                char* p = uenum_next (handle, &len, e);
                testError (e, "failed to traverse enumeration");   
                if (p)
                    return dst = p[0..len], true;             
                return false;
        }

        /***********************************************************************
        
                Returns the next element in the iterator's list.

                If there are no more elements, returns NULL. If the 
                iterator is out-of-sync with its service, status is 
                set to U_ENUM_OUT_OF_SYNC_ERROR and NULL is returned. 
                If the native service string is a char* string, it is 
                converted to UChar* with the invariant converter.

        ***********************************************************************/

        bool next (inout wchar[] dst)
        {       
                ICU.Error e;
                uint      len;

                wchar* p = uenum_unext (handle, &len, e);
                testError (e, "failed to traverse enumeration");   
                if (p)
                    return dst = p[0..len], true;             
                return false;
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
                void   function (Handle) uenum_close;
                uint   function (Handle, inout Error) uenum_count;
                void   function (Handle, inout Error) uenum_reset;
                char*  function (Handle, uint*, inout Error) uenum_next;
                wchar* function (Handle, uint*, inout Error) uenum_unext;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &uenum_close, "uenum_close"}, 
                {cast(void**) &uenum_count, "uenum_count"}, 
                {cast(void**) &uenum_reset, "uenum_reset"}, 
                {cast(void**) &uenum_next,  "uenum_next"}, 
                {cast(void**) &uenum_unext, "uenum_unext"}, 
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

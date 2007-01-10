/*******************************************************************************

        @file UDomainName.d
        
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

module mango.icu.UDomainName;

private import  mango.icu.ICU,
                mango.icu.UString;

/*******************************************************************************

        UIDNA API implements the IDNA protocol as defined in the 
        IDNA RFC (http://www.ietf.org/rfc/rfc3490.txt).

        The RFC defines 2 operations: toAscii and toUnicode. Domain 
        labels containing non-ASCII code points are required to be 
        processed by toAscii operation before passing it to resolver 
        libraries. Domain names that are obtained from resolver 
        libraries are required to be processed by toUnicode operation 
        before displaying the domain name to the user. IDNA requires 
        that implementations process input strings with Nameprep 
        (http://www.ietf.org/rfc/rfc3491.txt), which is a profile of 
        Stringprep (http://www.ietf.org/rfc/rfc3454.txt), and then with 
        Punycode (http://www.ietf.org/rfc/rfc3492.txt). Implementations 
        of IDNA MUST fully implement Nameprep and Punycode; neither 
        Nameprep nor Punycode are optional. 
        
        The input and output of toAscii() and ToUnicode() operations are 
        Unicode and are designed to be chainable, i.e., applying toAscii() 
        or toUnicode() operations multiple times to an input string will 
        yield the same result as applying the operation once.

        See <A HREF="http://oss.software.ibm.com/icu/apiref/uidna_8h.html">
        this page</A> for full details.

*******************************************************************************/

class UDomainName : ICU
{       
        private UText  text;
        private Handle handle;

        enum    Options
                {
                Strict,
                Lenient,
                Std3
                }


        /***********************************************************************

        
        ***********************************************************************/

        this (UText text)
        {
                this.text = text;
        }

        /***********************************************************************

                This function implements the ToASCII operation as 
                defined in the IDNA RFC.

                This operation is done on single labels before sending 
                it to something that expects ASCII names. A label is an 
                individual part of a domain name. Labels are usually 
                separated by dots; e.g." "www.example.com" is composed 
                of 3 labels "www","example", and "com".

        ***********************************************************************/

        void toAscii (UString dst, Options o = Options.Strict)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return uidna_toASCII (text.get.ptr, text.len, p, len, o, null, e);
                }
                
                dst.format (&fmt, "failed to convert IDN to ASCII");
        }

        /***********************************************************************

                This function implements the ToUnicode operation as 
                defined in the IDNA RFC.

                This operation is done on single labels before sending 
                it to something that expects Unicode names. A label is 
                an individual part of a domain name. Labels are usually 
                separated by dots; for e.g." "www.example.com" is composed 
                of 3 labels "www","example", and "com".

        ***********************************************************************/

        void toUnicode (UString dst, Options o = Options.Strict)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return uidna_toUnicode (text.get.ptr, text.len, p, len, o, null, e);
                }
                
                dst.format (&fmt, "failed to convert IDN to Unicode");
        }

        /***********************************************************************

                Convenience function that implements the IDNToASCII 
                operation as defined in the IDNA RFC.

                This operation is done on complete domain names, e.g: 
                "www.example.com". It is important to note that this 
                operation can fail. If it fails, then the input domain 
                name cannot be used as an Internationalized Domain Name 
                and the application should have methods defined to deal 
                with the failure.

                Note: IDNA RFC specifies that a conformant application 
                should divide a domain name into separate labels, decide 
                whether to apply allowUnassigned and useSTD3ASCIIRules 
                on each, and then convert. This function does not offer 
                that level of granularity. The options once set will apply 
                to all labels in the domain name

        ***********************************************************************/

        void IdnToAscii (UString dst, Options o = Options.Strict)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return uidna_IDNToASCII (text.get.ptr, text.len, p, len, o, null, e);
                }
                
                dst.format (&fmt, "failed to convert IDN to ASCII");
        }

        /***********************************************************************

                Convenience function that implements the IDNToUnicode 
                operation as defined in the IDNA RFC.

                This operation is done on complete domain names, e.g: 
                "www.example.com".

                Note: IDNA RFC specifies that a conformant application 
                should divide a domain name into separate labels, decide 
                whether to apply allowUnassigned and useSTD3ASCIIRules 
                on each, and then convert. This function does not offer 
                that level of granularity. The options once set will apply 
                to all labels in the domain name

        ***********************************************************************/

        void IdnToUnicode (UString dst, Options o = Options.Strict)
        {
                uint fmt (wchar* p, uint len, inout Error e)
                {
                        return uidna_IDNToUnicode (text.get.ptr, text.len, p, len, o, null, e);
                }
                
                dst.format (&fmt, "failed to convert IDN to Unicode");
        }

        /***********************************************************************

                Compare two IDN strings for equivalence.

                This function splits the domain names into labels and 
                compares them. According to IDN RFC, whenever two labels 
                are compared, they are considered equal if and only if 
                their ASCII forms (obtained by applying toASCII) match 
                using an case-insensitive ASCII comparison. Two domain 
                names are considered a match if and only if all labels 
                match regardless of whether label separators match

        ***********************************************************************/

        int compare (UString other, Options o = Options.Strict)
        {
                Error e;
                int i = uidna_compare (text.get.ptr, text.len, other.get.ptr, other.len, o, e);
                testError (e, "failed to compare IDN strings");
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
                uint    function (wchar*, uint, wchar*, uint, uint, void*, inout Error) uidna_toASCII;
                uint    function (wchar*, uint, wchar*, uint, uint, void*, inout Error) uidna_toUnicode;
                uint    function (wchar*, uint, wchar*, uint, uint, void*, inout Error) uidna_IDNToASCII;
                uint    function (wchar*, uint, wchar*, uint, uint, void*, inout Error) uidna_IDNToUnicode;
                int     function (wchar*, uint, wchar*, uint, uint, inout Error) uidna_compare;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &uidna_toASCII,           "uidna_toASCII"}, 
                {cast(void**) &uidna_toUnicode,         "uidna_toUnicode"},
                {cast(void**) &uidna_IDNToASCII,        "uidna_IDNToASCII"},
                {cast(void**) &uidna_IDNToUnicode,      "uidna_IDNToUnicode"},
                {cast(void**) &uidna_compare,           "uidna_compare"},
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


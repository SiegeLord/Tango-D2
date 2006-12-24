/*******************************************************************************

        @file ULocale.d
        
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

module mango.icu.ULocale;

private import mango.icu.ICU;

/*******************************************************************************

        Note that this is a struct rather than a class. This is so 
        that one can easily construct these on the stack, plus the 
        'convenience' instances can be created statically.

*******************************************************************************/

struct ULocale 
{
        public char[] name;

        /***********************************************************************
        
        ***********************************************************************/

        public static ULocale Root               = {""};
        public static ULocale Default            = {null};
        public static ULocale English            = {"en"};
        public static ULocale Chinese            = {"zh"};
        public static ULocale French             = {"fr"};
        public static ULocale German             = {"de"};
        public static ULocale Italian            = {"it"};
        public static ULocale Japanese           = {"ja"};
        public static ULocale Korean             = {"ko"};
        public static ULocale SimplifiedChinese  = {"zh_CN"};
        public static ULocale TraditionalChinese = {"zh_TW"};
        public static ULocale Canada             = {"en_CA"};
        public static ULocale CanadaFrench       = {"fr_CA"};
        public static ULocale China              = {"zh_CN"};
        public static ULocale PRC                = {"zh_CN"};
        public static ULocale France             = {"fr_FR"};
        public static ULocale Germany            = {"de_DE"};
        public static ULocale Italy              = {"it_IT"};
        public static ULocale Japan              = {"jp_JP"};
        public static ULocale Korea              = {"ko_KR"};
        public static ULocale Taiwan             = {"zh_TW"};
        public static ULocale UK                 = {"en_GB"};
        public static ULocale US                 = {"en_US"};
        
        /***********************************************************************
        
        ***********************************************************************/

        public enum     Type 
                        { 
                        Actual    = 0, 
                        Valid     = 1, 
                        Requested = 2, 
                        }

        /***********************************************************************
        
        ***********************************************************************/

        public  const  uint     LanguageCapacity = 12;
        public  const  uint     CountryCapacity = 4;
        public  const  uint     FullNameCapacity = 56;
        public  const  uint     ScriptCapacity = 6;
        public  const  uint     KeywordsCapacity = 50;
        public  const  uint     KeywordAndValuesCapacity = 100;
        public  const  char     KeywordItemSeparator = ':';
        public  const  char     KeywordSeparator = '@';
        public  const  char     KeywordAssign = '=';
        

        /***********************************************************************
        
        ***********************************************************************/

        static void getDefault (inout ULocale locale)
        {       
                locale.name = ICU.toArray (uloc_getDefault());
                if (! locale.name)
                      ICU.exception ("failed to get default locale");
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        static void setDefault (inout ULocale locale)
        {
                ICU.Error e;
                
                uloc_setDefault (ICU.toString(locale.name), e);
                
                if (ICU.isError (e))
                        ICU.exception ("invalid locale '"~locale.name~"'");   
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
                char* function () uloc_getDefault;
                void  function (char*, inout ICU.Error) uloc_setDefault;
        }

        /**********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &uloc_getDefault, "uloc_getDefault"}, 
                {cast(void**) &uloc_setDefault, "uloc_setDefault"},
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (ICU.icuuc, targets);
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }
}

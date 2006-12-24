/*******************************************************************************

        @file UTimeZone.d
        
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

module mango.icu.UTimeZone;

private import  mango.icu.ICU,
                mango.icu.UString,
                mango.icu.UEnumeration;

/*******************************************************************************

        A representation of a TimeZone. Unfortunately, ICU does not expose
        this as a seperate entity from the C-API, so we have to make do 
        with an approximation instead.

*******************************************************************************/

struct UTimeZone 
{
        public wchar[]  name;

        public static UTimeZone Default =       {null};
        public static UTimeZone Gmt =           {"Etc/GMT"};
        public static UTimeZone Greenwich =     {"Etc/Greenwich"};
        public static UTimeZone Uct =           {"Etc/UCT"};
        public static UTimeZone Utc =           {"Etc/UTC"};
        public static UTimeZone Universal =     {"Etc/Universal"};

        public static UTimeZone GmtPlus0 =      {"Etc/GMT+0"};
        public static UTimeZone GmtPlus1 =      {"Etc/GMT+1"};
        public static UTimeZone GmtPlus2 =      {"Etc/GMT+2"};
        public static UTimeZone GmtPlus3 =      {"Etc/GMT+3"};
        public static UTimeZone GmtPlus4 =      {"Etc/GMT+4"};
        public static UTimeZone GmtPlus5 =      {"Etc/GMT+5"};
        public static UTimeZone GmtPlus6 =      {"Etc/GMT+6"};
        public static UTimeZone GmtPlus7 =      {"Etc/GMT+7"};
        public static UTimeZone GmtPlus8 =      {"Etc/GMT+8"};
        public static UTimeZone GmtPlus9 =      {"Etc/GMT+9"};
        public static UTimeZone GmtPlus10 =     {"Etc/GMT+10"};
        public static UTimeZone GmtPlus11 =     {"Etc/GMT+11"};
        public static UTimeZone GmtPlus12 =     {"Etc/GMT+12"};

        public static UTimeZone GmtMinus0 =     {"Etc/GMT-0"};
        public static UTimeZone GmtMinus1 =     {"Etc/GMT-1"};
        public static UTimeZone GmtMinus2 =     {"Etc/GMT-2"};
        public static UTimeZone GmtMinus3 =     {"Etc/GMT-3"};
        public static UTimeZone GmtMinus4 =     {"Etc/GMT-4"};
        public static UTimeZone GmtMinus5 =     {"Etc/GMT-5"};
        public static UTimeZone GmtMinus6 =     {"Etc/GMT-6"};
        public static UTimeZone GmtMinus7 =     {"Etc/GMT-7"};
        public static UTimeZone GmtMinus8 =     {"Etc/GMT-8"};
        public static UTimeZone GmtMinus9 =     {"Etc/GMT-9"};
        public static UTimeZone GmtMinus10 =    {"Etc/GMT-10"};
        public static UTimeZone GmtMinus11 =    {"Etc/GMT-11"};
        public static UTimeZone GmtMinus12 =    {"Etc/GMT-12"};

        /***********************************************************************
        
                Get the default time zone.

        ***********************************************************************/

        static void getDefault (inout UTimeZone zone)
        {       
                uint format (wchar* dst, uint length, inout ICU.Error e)
                {
                        return ucal_getDefaultTimeZone (dst, length, e);
                }

                UString s = new UString(64);
                s.format (&format, "failed to get default time zone");
                zone.name = s.get();
        }

        /***********************************************************************
        
                Set the default time zone.

        ***********************************************************************/

        static void setDefault (inout UTimeZone zone)
        {       
                ICU.Error e;

                ucal_setDefaultTimeZone (ICU.toString (zone.name), e);
                ICU.testError (e, "failed to set default time zone");                
        }

        /***********************************************************************
        
                Return the amount of time in milliseconds that the clock 
                is advanced during daylight savings time for the given 
                time zone, or zero if the time zone does not observe daylight 
                savings time

        ***********************************************************************/

        static uint getDSTSavings (inout UTimeZone zone)
        {       
                ICU.Error e;

                uint x = ucal_getDSTSavings (ICU.toString (zone.name), e);
                ICU.testError (e, "failed to get DST savings");                
                return x;
        }


        /**********************************************************************

                Iterate over the available timezone names

        **********************************************************************/

        static int opApply (int delegate(inout wchar[] element) dg)
        {
                ICU.Error       e;
                wchar[]         name;
                int             result;

                void* h = ucal_openTimeZones (e);
                ICU.testError (e, "failed to open timeszone iterator");

                UEnumeration zones = new UEnumeration (cast(UEnumeration.Handle) h);               
                while (zones.next(name) && (result = dg(name)) != 0) {}
                delete zones;
                return result;
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
                void* function (inout ICU.Error) ucal_openTimeZones;
                uint  function (wchar*, uint, inout ICU.Error) ucal_getDefaultTimeZone;
                void  function (wchar*, inout ICU.Error) ucal_setDefaultTimeZone;
                uint  function (wchar*, inout ICU.Error) ucal_getDSTSavings;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &ucal_openTimeZones,      "ucal_openTimeZones"}, 
                {cast(void**) &ucal_getDefaultTimeZone, "ucal_getDefaultTimeZone"}, 
                {cast(void**) &ucal_setDefaultTimeZone, "ucal_setDefaultTimeZone"}, 
                {cast(void**) &ucal_getDSTSavings,      "ucal_getDSTSavings"}, 
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (ICU.icuin, targets);
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }
}

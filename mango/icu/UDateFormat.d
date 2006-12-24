/*******************************************************************************

        @file UDateFormat.d
        
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

module mango.icu.UDateFormat;

private import  mango.icu.ICU,
                mango.icu.UString,
                mango.icu.UCalendar,
                mango.icu.UNumberFormat;

/*******************************************************************************

        UDateFormat consists of functions that convert dates and 
        times from their internal representations to textual form and back 
        again in a language-independent manner. Converting from the internal 
        representation (milliseconds since midnight, January 1, 1970) to text 
        is known as "formatting," and converting from text to millis is known 
        as "parsing." We currently define one concrete structure UDateFormat, 
        which can handle pretty much all normal date formatting and parsing 
        actions.

        UDateFormat helps you to format and parse dates for any locale. 
        Your code can be completely independent of the locale conventions 
        for months, days of the week, or even the calendar format: lunar 
        vs. solar. 

        See <A HREF="http://oss.software.ibm.com/icu/apiref/udat_8h.html">
        this page</A> for full details.

*******************************************************************************/

private class UDateFormat : ICU
{       
        private Handle  handle;  
        
        alias UCalendar.UDate UDate;

        typedef void*   UFieldPos;

        public  enum    Style     
                        {  
                        Full, 
                        Long, 
                        Medium, 
                        Short,
                        Default                 = Medium, 
                        None                    = -1, 
                        Ignore                  = -2 
                        };

        public enum     Field    
                        {  
                        EraField                = 0, 
                        YearField               = 1, 
                        MonthField              = 2, 
                        DateField               = 3,
                        HourOfDay1Field         = 4, 
                        HourOfDay0Field         = 5, 
                        MinuteField             = 6, 
                        SecondField             = 7,
                        FractionalSecondField   = 8, 
                        DayOfWeekField          = 9, 
                        DayOfYearField          = 10, 
                        DayOfWeekInMonthField   = 11,
                        WeekOfYearField         = 12, 
                        WeekOfMonthField        = 13, 
                        AmPmField               = 14, 
                        Hour1Field              = 15,
                        Hour0Field              = 16, 
                        TimezoneField           = 17, 
                        YearWoyField            = 18, 
                        DowLocalField           = 19,
                        ExtendedYearField       = 20, 
                        JulianDayField          = 21, 
                        MillisecondsInDayField  = 22, 
                        TimezoneRfcField        = 23,
                        FieldCount              = 24 
                        };

        private enum    Symbol     
                        {
                        Eras, 
                        Months, 
                        ShortMonths, 
                        Weekdays,
                        ShortWeekdays, 
                        AmPms, 
                        LocalizedChars
                        };
                        

        /***********************************************************************
        
                Open a new UDateFormat for formatting and parsing dates 
                and time.

        ***********************************************************************/

        this (Style time, Style date, inout ULocale locale, inout UTimeZone tz, UText pattern)
        {
                Error e;

                handle = udat_open (time, date, toString(locale.name), tz.name, tz.name.length, pattern.get, pattern.length, e);
                testError (e, "failed to create DateFormat");
        }

        /***********************************************************************
        
                Close a UDateFormat

        ***********************************************************************/

        ~this ()
        {
                udat_close (handle);
        }

        /***********************************************************************
        
                Format a date using an UDateFormat

        ***********************************************************************/

        void format (UString dst, UDate date, UFieldPos p = null)
        {
                uint fmat (wchar* result, uint len, inout Error e)
                {
                        return udat_format (handle, date, result, len, p, e);
                }

                dst.format (&fmat, "date format failed");
        }

        /***********************************************************************
        
                Parse a string into an date/time using a UDateFormat

        ***********************************************************************/

        UDate parse (UText src, uint* index=null)
        {
                Error e;

                UDate x = udat_parse (handle, src.content, src.len, index, e); 
                testError (e, "failed to parse date");
                return x;
        }

        /***********************************************************************
        
                Set the UCalendar associated with an UDateFormat. A 
                UDateFormat uses a UCalendar to convert a raw value 
                to, for example, the day of the week.

        ***********************************************************************/

        void setCalendar (UCalendar c)
        {
                udat_setCalendar (handle, c.handle); 
        }

        /***********************************************************************
        
                Get the UCalendar associated with this UDateFormat

        ***********************************************************************/

        UCalendar getCalendar ()
        {
                Handle h = udat_getCalendar (handle); 
                return new UCalendar (h);
        }

        /***********************************************************************

                Set the UNumberFormat associated with an UDateFormat.A 
                UDateFormat uses a UNumberFormat to format numbers within 
                a date, for example the day number.         

        ***********************************************************************/

        void setNumberFormat (UNumberFormat n)
        {
                udat_setCalendar (handle, n.handle); 
        }

        /***********************************************************************

                Get the year relative to which all 2-digit years are 
                interpreted

        ***********************************************************************/

        UDate getTwoDigitYearStart ()
        {
                Error e;

                UDate x = udat_get2DigitYearStart (handle, e); 
                testError (e, "failed to get two digit year start");
                return x;
        }

        /***********************************************************************

                Set the year relative to which all 2-digit years are 
                interpreted

        ***********************************************************************/

        void setTwoDigitYearStart (UDate start)
        {
                Error e;

                udat_set2DigitYearStart (handle, start, e); 
                testError (e, "failed to set two digit year start");
        }

        /***********************************************************************
        
                Extract the pattern from a UDateFormat

        ***********************************************************************/

        void getPattern (UString dst, bool localize)
        {
                uint fmat (wchar* result, uint len, inout Error e)
                {
                        return udat_toPattern (handle, localize, result, len, e);
                }

                dst.format (&fmat, "failed to retrieve date format pattern");
        }

        /***********************************************************************
        
                Set the pattern for a UDateFormat

        ***********************************************************************/

        void setPattern (UText pattern, bool localized)
        {
                udat_applyPattern (handle, localized, pattern.get, pattern.length);        
        }

        /***********************************************************************
        
                Specify whether an UDateFormat will perform lenient parsing.

        ***********************************************************************/

        void setLenient (bool yes)
        {
                udat_setLenient (handle, yes);
        }

        /***********************************************************************
        
                Determine if an UDateFormat will perform lenient parsing. 

        ***********************************************************************/

        bool isLenient ()
        {
                return udat_isLenient (handle) != 0;
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
                Handle function (uint, uint, char*, wchar*, uint, wchar*, uint, inout Error) udat_open;
                void   function (Handle) udat_close;
                uint   function (Handle, UDate, wchar*, uint, UFieldPos, inout Error) udat_format;
                UDate  function (Handle, wchar*, uint, uint*, inout Error) udat_parse;
                void   function (Handle, Handle) udat_setCalendar;
                void   function (Handle, Handle) udat_setNumberFormat;
                UDate  function (Handle, inout Error) udat_get2DigitYearStart;
                void   function (Handle, UDate, inout Error) udat_set2DigitYearStart;
                uint   function (Handle, byte, wchar*, uint, inout Error) udat_toPattern;
                void   function (Handle, byte, wchar*, uint) udat_applyPattern;
                void   function (Handle, byte) udat_setLenient;
                byte   function (Handle) udat_isLenient;
                Handle function (Handle) udat_getCalendar;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &udat_open,               "udat_open"}, 
                {cast(void**) &udat_close,              "udat_close"},
                {cast(void**) &udat_format,             "udat_format"},
                {cast(void**) &udat_parse,              "udat_parse"},
                {cast(void**) &udat_setCalendar,        "udat_setCalendar"},
                {cast(void**) &udat_setNumberFormat,    "udat_setNumberFormat"},
                {cast(void**) &udat_get2DigitYearStart, "udat_get2DigitYearStart"},
                {cast(void**) &udat_set2DigitYearStart, "udat_set2DigitYearStart"},
                {cast(void**) &udat_toPattern,          "udat_toPattern"},
                {cast(void**) &udat_applyPattern,       "udat_applyPattern"},
                {cast(void**) &udat_setLenient,         "udat_setLenient"},
                {cast(void**) &udat_isLenient,          "udat_isLenient"},
                {cast(void**) &udat_getCalendar,        "udat_getCalendar"},
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



/*******************************************************************************

        @file UCalendar.d
        
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

module mango.icu.UCalendar;

private import  mango.icu.ICU,
                mango.icu.UString;

public  import  mango.icu.ULocale,
                mango.icu.UTimeZone;

/*******************************************************************************

        UCalendar is used for converting between a UDate object and 
        a set of integer fields such as Year, Month, Day, 
        Hour, and so on. (A UDate object represents a specific instant 
        in time with millisecond precision. See UDate for information about 
        the UDate)

        Types of UCalendar interpret a UDate according to the rules of a 
        specific calendar system. UCalendar supports Traditional & Gregorian.

        A UCalendar object can produce all the time field values needed to 
        implement the date-time formatting for a particular language and 
        calendar style (for example, Japanese-Gregorian, Japanese-Traditional).

        When computing a UDate from time fields, two special circumstances 
        may arise: there may be insufficient information to compute the UDate 
        (such as only year and month but no day in the month), or there may be 
        inconsistent information (such as "Tuesday, July 15, 1996" -- July 15, 
        1996 is actually a Monday).

        Insufficient information. The calendar will use default information 
        to specify the missing fields. This may vary by calendar; for the 
        Gregorian calendar, the default for a field is the same as that of 
        the start of the epoch: i.e., Year = 1970, Month = January, 
        Date = 1, etc.

        Inconsistent information. If fields conflict, the calendar will give 
        preference to fields set more recently. For example, when determining 
        the day, the calendar will look for one of the following combinations 
        of fields. The most recent combination, as determined by the most 
        recently set single field, will be used.

        See http://oss.software.ibm.com/icu/apiref/udat_8h.html for full 
        details.

*******************************************************************************/

class UCalendar : ICU
{       
        package Handle handle;

        typedef double UDate;

        //Possible types of UCalendars
        public enum     Type 
                        {
                        Traditional, 
                        Gregorian  
                        }

        // Possible fields in a UCalendar
        public enum     DateFields 
                        {
                        Era, 
                        Year, 
                        Month, 
                        WeekOfYear,
                        WeekOfMonth, 
                        Date, 
                        DayOfYear, 
                        DayOfWeek,
                        DayOfWeekInMonth, 
                        AmPm, 
                        Hour, 
                        HourOfDay,
                        Minute, 
                        Second, 
                        Millisecond, 
                        ZoneOffset,
                        DstOffset, 
                        YearWoy, 
                        DowLocal, 
                        ExtendedYear,
                        JulianDay, 
                        MillisecondsInDay, 
                        FieldCount, 
                        DayOfMonth = Date
                        }

        // Possible days of the week in a UCalendar
        public enum     DaysOfWeek 
                        {
                        Sunday = 1, 
                        Monday, 
                        Tuesday, 
                        Wednesday,
                        Thursday, 
                        Friday, 
                        Saturday
                        }

        // Possible months in a UCalendar
        public enum     Months 
                        {
                        January, 
                        February, 
                        March, 
                        April,
                        May, 
                        June, 
                        July, 
                        August,
                        September, 
                        October, 
                        November, 
                        December,
                        UnDecimber
                        }

        // Possible AM/PM values in a UCalendar
        public enum     AMPMs 
                        { 
                        AM, 
                        PM 
                        }

        // Possible formats for a UCalendar's display name
        public enum     DisplayNameType 
                        { 
                        Standard, 
                        ShortStandard, 
                        DST, 
                        ShortDST 
                        }

        // Possible limit values for a UCalendar
        public enum     Limit 
                        {
                        Minimum, 
                        Maximum, 
                        GreatestMinimum, 
                        LeastMaximum,
                        ActualMinimum, 
                        ActualMaximum
                        }

        // Types of UCalendar attributes
        private enum    Attribute 
                        { 
                        Lenient, // unused: set from UDateFormat instead
                        FirstDayOfWeek, 
                        MinimalDaysInFirstWeek 
                        }

        /***********************************************************************

                Open a UCalendar. A UCalendar may be used to convert a 
                millisecond value to a year, month, and day

        ***********************************************************************/

        this (inout UTimeZone zone, inout ULocale locale, Type type = Type.Traditional)
        {
                Error e;

                handle = ucal_open (zone.name.ptr, zone.name.length, toString(locale.name), type, e);
                testError (e, "failed to open calendar");
        }

        /***********************************************************************

                Internal only: Open a UCalendar with the given handle

        ***********************************************************************/

        package this (Handle handle)
        {
                this.handle = handle;
        }

        /***********************************************************************
        
                Close this UCalendar

        ***********************************************************************/

        ~this ()
        {
                ucal_close (handle);
        }

        /***********************************************************************
        
                Set the TimeZone used by a UCalendar

        ***********************************************************************/

        void setTimeZone (inout UTimeZone zone)
        {
                Error e;

                ucal_setTimeZone (handle, zone.name.ptr, zone.name.length, e);
                testError (e, "failed to set calendar time zone");
        }

        /***********************************************************************
        
                Get display name of the TimeZone used by this UCalendar

        ***********************************************************************/

        void getTimeZoneName (UString s, inout ULocale locale, DisplayNameType type=DisplayNameType.Standard)
        {       
                uint format (wchar* dst, uint length, inout ICU.Error e)
                {
                        return ucal_getTimeZoneDisplayName (handle, type, toString(locale.name), dst, length, e);
                }

                s.format (&format, "failed to get time zone name");
        }

        /***********************************************************************
        
                Determine if a UCalendar is currently in daylight savings 
                time

        ***********************************************************************/

        bool inDaylightTime ()
        {
                Error e;

                auto x = ucal_inDaylightTime (handle, e);
                testError (e, "failed to test calendar daylight time");
                return x != 0;
        }

        /***********************************************************************
        
                Get the current date and time

        ***********************************************************************/

        UDate getNow ()
        {
                return ucal_getNow ();
        }

        /***********************************************************************
        
                Get a UCalendar's current time in millis. The time is 
                represented as milliseconds from the epoch 

        ***********************************************************************/

        UDate getMillis ()
        {
                Error e;

                auto x = ucal_getMillis (handle, e);
                testError (e, "failed to get time");
                return x;
        }

        /***********************************************************************
        
                Set a UCalendar's current time in millis. The time is 
                represented as milliseconds from the epoch               

        ***********************************************************************/

        void setMillis (UDate date)
        {
                Error e;

                ucal_setMillis (handle, date, e);
                testError (e, "failed to set time");
        }

        /***********************************************************************
        
                Set a UCalendar's current date 

        ***********************************************************************/

        void setDate (uint year, Months month, uint date)
        {
                Error e;

                ucal_setDate (handle, year, month, date, e);
                testError (e, "failed to set date");
        }

        /***********************************************************************
        
                Set a UCalendar's current date 

        ***********************************************************************/

        void setDateTime (uint year, Months month, uint date, uint hour, uint minute, uint second)
        {
                Error e;

                ucal_setDateTime (handle, year, month, date, hour, minute, second, e);
                testError (e, "failed to set date/time");
        }

        /***********************************************************************
        
                Returns TRUE if the given Calendar object is equivalent 
                to this one

        ***********************************************************************/

        bool isEquivalent (UCalendar when)
        {
                return ucal_equivalentTo (handle, when.handle) != 0;
        }

        /***********************************************************************
        
                Compares the Calendar time

        ***********************************************************************/

        bool isEqual (UCalendar when)
        {
                return (this is when || getMillis == when.getMillis);
        }

        /***********************************************************************
        
                Returns true if this Calendar's current time is before 
                "when"'s current time

        ***********************************************************************/

        bool isBefore (UCalendar when)
        {
                return (this !is when || getMillis < when.getMillis);
        }

        /***********************************************************************
        
                Returns true if this Calendar's current time is after 
                "when"'s current time

        ***********************************************************************/

        bool isAfter (UCalendar when)
        {
                return (this !is when || getMillis > when.getMillis);
        }

        /***********************************************************************
        
                Add a specified signed amount to a particular field in a 
                UCalendar

        ***********************************************************************/

        void add (DateFields field, uint amount)
        {
                Error e;

                ucal_add (handle, field, amount, e);
                testError (e, "failed to add to calendar");
        }

        /***********************************************************************
        
                Add a specified signed amount to a particular field in a 
                UCalendar                 

        ***********************************************************************/

        void roll (DateFields field, uint amount)
        {
                Error e;

                ucal_roll (handle, field, amount, e);
                testError (e, "failed to roll calendar");
        }

        /***********************************************************************
        
                Get the current value of a field from a UCalendar
                        
        ***********************************************************************/

        uint get (DateFields field)
        {
                Error e;

                auto x = ucal_get (handle, field, e);
                testError (e, "failed to get calendar field");
                return x;
        }

        /***********************************************************************
        
                Set the value of a field in a UCalendar
                        
        ***********************************************************************/

        void set (DateFields field, uint value)
        {
                ucal_set (handle, field, value);
        }

        /***********************************************************************
        
                Determine if a field in a UCalendar is set
                              
        ***********************************************************************/

        bool isSet (DateFields field)
        {
                return ucal_isSet (handle, field) != 0;
        }

        /***********************************************************************
        
                Clear a field in a UCalendar
                              
        ***********************************************************************/

        void clearField (DateFields field)
        {
                ucal_clearField (handle, field);
        }

        /***********************************************************************
        
                Clear all fields in a UCalendar
                              
        ***********************************************************************/

        void clear ()
        {
                ucal_clear (handle);
        }

        /***********************************************************************
        
                Determine a limit for a field in a UCalendar. A limit is a 
                maximum or minimum value for a field
                        
        ***********************************************************************/

        uint getLimit (DateFields field, Limit type)
        {
                Error e;

                auto x = ucal_getLimit (handle, field, type, e);
                testError (e, "failed to get calendar limit");
                return x;
        }

        /***********************************************************************
        
        ***********************************************************************/

        uint getDaysInFirstWeek ()
        {
                return ucal_getAttribute (handle, Attribute.MinimalDaysInFirstWeek);
        }

        /***********************************************************************
        
        ***********************************************************************/

        uint getFirstDayOfWeek ()
        {
                return ucal_getAttribute (handle, Attribute.FirstDayOfWeek);
        }

        /***********************************************************************
        
        ***********************************************************************/

        void setDaysInFirstWeek (uint value)
        {
                ucal_setAttribute (handle, Attribute.MinimalDaysInFirstWeek, value);
        }

        /***********************************************************************
        
        ***********************************************************************/

        void setFirstDayOfWeek (uint value)
        {
                ucal_setAttribute (handle, Attribute.FirstDayOfWeek, value);
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
                Handle  function (wchar*, uint, char*, Type, inout Error) ucal_open;
                void    function (Handle) ucal_close;
                UDate   function () ucal_getNow;
                UDate   function (Handle, inout Error) ucal_getMillis;
                void    function (Handle, UDate, inout Error) ucal_setMillis;
                void    function (Handle, uint, uint, uint, inout Error) ucal_setDate;
                void    function (Handle, uint, uint, uint, uint, uint, uint, inout Error) ucal_setDateTime;
                byte    function (Handle, Handle) ucal_equivalentTo;
                void    function (Handle, uint, uint, inout Error) ucal_add;
                void    function (Handle, uint, uint, inout Error) ucal_roll;
                uint    function (Handle, uint, inout Error) ucal_get;
                void    function (Handle, uint, uint) ucal_set;
                byte    function (Handle, uint) ucal_isSet;
                void    function (Handle, uint) ucal_clearField;
                void    function (Handle) ucal_clear;
                uint    function (Handle, uint, uint, inout Error) ucal_getLimit;
                void    function (Handle, wchar*, uint, inout Error) ucal_setTimeZone;
                byte    function (Handle, uint) ucal_inDaylightTime;
                uint    function (Handle, uint) ucal_getAttribute;
                void    function (Handle, uint, uint) ucal_setAttribute;
                uint    function (Handle, uint, char*, wchar*, uint, inout Error) ucal_getTimeZoneDisplayName;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &ucal_open,               "ucal_open"}, 
                {cast(void**) &ucal_close,              "ucal_close"},
                {cast(void**) &ucal_getNow,             "ucal_getNow"},
                {cast(void**) &ucal_getMillis,          "ucal_getMillis"},
                {cast(void**) &ucal_setMillis,          "ucal_setMillis"},
                {cast(void**) &ucal_setDate,            "ucal_setDate"},
                {cast(void**) &ucal_setDateTime,        "ucal_setDateTime"},
                {cast(void**) &ucal_equivalentTo,       "ucal_equivalentTo"},
                {cast(void**) &ucal_add,                "ucal_add"},
                {cast(void**) &ucal_roll,               "ucal_roll"},
                {cast(void**) &ucal_get,                "ucal_get"},
                {cast(void**) &ucal_set,                "ucal_set"},
                {cast(void**) &ucal_clearField,         "ucal_clearField"},
                {cast(void**) &ucal_clear,              "ucal_clear"},
                {cast(void**) &ucal_getLimit,           "ucal_getLimit"},
                {cast(void**) &ucal_setTimeZone,        "ucal_setTimeZone"},
                {cast(void**) &ucal_inDaylightTime,     "ucal_inDaylightTime"},
                {cast(void**) &ucal_getAttribute,       "ucal_getAttribute"},
                {cast(void**) &ucal_setAttribute,       "ucal_setAttribute"},
                {cast(void**) &ucal_isSet,              "ucal_isSet"},
                {cast(void**) &ucal_getTimeZoneDisplayName, "ucal_getTimeZoneDisplayName"},
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

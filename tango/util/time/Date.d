/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: May 2005

        author:         Kris

*******************************************************************************/

module tango.util.time.Date;

private import tango.sys.Common;

private import tango.util.time.Utc;

public  import tango.core.Type : Time;

/*******************************************************************************

        Date exposes the underlying OS support for splitting date fields
        to and from a set of discrete attributes. For example, to set all
        fields to the current local time:
        ---
        Date date;

        date.set (Utc.time);
        ---

        Attributes exposed include year, month, day, hour, minute, second,
        millisecond, and day of week. Methods exposed include setting each
        of discrete time & date values, and converting fields to instances
        of Time. Note that the conversion is limited by the underlying OS,
        and will not operate correctly with Time values beyond the domain.
        On Win32 the earliest representable date is 1601. On linux it is
        1970. Both systems have limitations upon future dates also.

        Note that Utc does not provide general conversion to and from
        textual representations, since that requires support for both I18N
        and wide characters. However, it does support basic short English
        names that are used in a variety of text representations.

        See TimeStamp.d for an example of a simple derivation, and see
        http://en.wikipedia.org/wiki/Unix_time for details on UTC time.

*******************************************************************************/

struct Date
{
        public int      year,           /// fully defined year ~ e.g. 2005
                        month,          /// 1 through 12
                        day,            /// 1 through 31
                        hour,           /// 0 through 23
                        min,            /// 0 through 59
                        sec,            /// 0 through 59
                        ms,             /// 0 through 999
                        dow;            /// 0 through 6; sunday == 0

        /// list of english day names
        public static char[][] Days =
        [
                        "Sun",
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
        ];

        /// list of english month names
        public static char[][] Months =
        [
                        "Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec",
        ];

        /**********************************************************************

                Get the english short month name

        **********************************************************************/

        char[] asMonth ()
        {
                assert (month > 0);
                return Months [month-1];
        }

        /**********************************************************************

                Get the english short day name

        **********************************************************************/

        char[] asDay ()
        {
                return Days [dow];
        }

        /**********************************************************************

                Set the date-related values

                year  : fully defined year ~ e.g. 2005
                month : 1 through 12
                day   : 1 through 31
                dow   : 0 through 6; sunday=0 (typically set by O/S)

        **********************************************************************/

        void setDate (int year, int month, int day, int dow = 0)
        {
                this.year = year;
                this.month = month;
                this.day = day;
                this.dow = dow;
        }

        /**********************************************************************

                Set the time-related values

                hour : 0 through 23
                min  : 0 through 59
                sec  : 0 through 59
                ms   : 0 through 999

        **********************************************************************/

        void setTime (int hour, int min, int sec, int ms = 0)
        {
                this.hour = hour;
                this.min = min;
                this.sec = sec;
                this.ms = ms;
        }

        /***********************************************************************

                Win32 implementation

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        Convert fields to UTC time

                ***************************************************************/

                Time get ()
                {
                        SYSTEMTIME sTime = void;
                        FILETIME   fTime = void;

                        sTime.wYear = cast(ushort) year;
                        sTime.wMonth = cast(ushort) month;
                        sTime.wDayOfWeek = 0;
                        sTime.wDay = cast(ushort) day;
                        sTime.wHour = cast(ushort) hour;
                        sTime.wMinute = cast(ushort) min;
                        sTime.wSecond = cast(ushort) sec;
                        sTime.wMilliseconds = cast(ushort) ms;

                        SystemTimeToFileTime (&sTime, &fTime);
                        return Utc.convert (fTime);
                }

                /***************************************************************

                        Set fields to represent the provided time. The
                        value must fall within the domain supported by
                        the OS

                ***************************************************************/

                void set (Time time)
                {
                        SYSTEMTIME sTime = void;

                        auto fTime = Utc.convert (time);
                        FileTimeToSystemTime (&fTime, &sTime);

                        year = sTime.wYear;
                        month = sTime.wMonth;
                        day = sTime.wDay;
                        hour = sTime.wHour;
                        min = sTime.wMinute;
                        sec = sTime.wSecond;
                        ms = sTime.wMilliseconds;
                        dow = sTime.wDayOfWeek;
                }
        }


        /***********************************************************************

                Posix implementation

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Convert fields to UTC time

                ***************************************************************/

                Time get ()
                {
                        tm t;

                        t.tm_year = year - 1900;
                        t.tm_mon = month - 1;
                        t.tm_mday = day;
                        t.tm_hour = hour;
                        t.tm_min = min;
                        t.tm_sec = sec;

                        return cast(Time) (Time.TicksTo1970 +
                                           Time.TicksPerSecond * timegm(&t) +
                                           Time.TicksPerMillisecond * ms);
                }

                /***************************************************************

                        Set fields to represent the provided time. The
                        value must fall within the domain supported by
                        the OS

                **************************************************************/

                void set (Time time)
                {
                        auto timeval = Utc.convert (time);
                        ms = timeval.tv_usec / 1000;

                        tm result;
                        tm* t = gmtime_r (&timeval.tv_sec, &result);
                        assert (t, "gmtime failed");
        
                        year = t.tm_year + 1900;
                        month = t.tm_mon + 1;
                        day = t.tm_mday;
                        hour = t.tm_hour;
                        min = t.tm_min;
                        sec = t.tm_sec;
                        dow = t.tm_wday;
                }
        }
}

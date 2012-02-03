/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Kris

*******************************************************************************/

module tango.time.Clock;

public  import  tango.time.Time;

private import  tango.sys.Common;

private import  tango.core.Exception;

/******************************************************************************

        Exposes UTC time relative to Jan 1st, 1 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. These units of time are the foundation of most
        time and date functionality in Tango.

        Interval is another type of time period, used for measuring a
        much shorter duration; typically used for timeout periods and
        for high-resolution timers. These intervals are measured in
        units of 1 second, and support fractional units (0.001 = 1ms).

*******************************************************************************/

struct Clock
{
        // copied from Gregorian.  Used while we rely on OS for toDate.
        package enum uint[] DaysToMonthCommon = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
        package static void setDoy(ref DateTime dt)
        {
            uint doy = dt.date.day + DaysToMonthCommon[dt.date.month - 1];
            uint year = dt.date.year;

            if(dt.date.month > 2 && (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)))
                doy++;

            dt.date.doy = doy;
        }

        version (Win32)
        {
                /***************************************************************

                        Return the current time as UTC since the epoch

                ***************************************************************/

                @property static Time now ()
                {
                        FILETIME fTime = void;
                        GetSystemTimeAsFileTime (&fTime);
                        return convert (fTime);
                }

                /***************************************************************

                        Set Date fields to represent the current time. 

                ***************************************************************/

                static DateTime toDate ()
                {
                        return toDate (now);
                }


                /***************************************************************

                        Set fields to represent the provided UTC time. Note 
                        that the conversion is limited by the underlying OS,
                        and will fail to operate correctly with Time
                        values beyond the domain. On Win32 the earliest
                        representable date is 1601. On linux it is 1970. Both
                        systems have limitations upon future dates also. Date
                        is limited to millisecond accuracy at best.

                ***************************************************************/

                static DateTime toDate (const(Time) time)
                {
                        DateTime dt = void;
                        SYSTEMTIME sTime = void;

                        auto fTime = convert (time);
                        FileTimeToSystemTime (&fTime, &sTime);

                        dt.date.year    = sTime.wYear;
                        dt.date.month   = sTime.wMonth;
                        dt.date.day     = sTime.wDay;
                        dt.date.dow     = sTime.wDayOfWeek;
                        dt.date.era     = 0;
                        dt.time.hours   = sTime.wHour;
                        dt.time.minutes = sTime.wMinute;
                        dt.time.seconds = sTime.wSecond;
                        dt.time.millis  = sTime.wMilliseconds;

                        // Calculate the day-of-year
                        setDoy(dt);

                        return dt;
                }

                /***************************************************************

                        Convert Date fields to Time

                        Note that the conversion is limited by the underlying 
                        OS, and will not operate correctly with Time
                        values beyond the domain. On Win32 the earliest
                        representable date is 1601. On linux it is 1970. Both
                        systems have limitations upon future dates also. Date
                        is limited to millisecond accuracy at best.

                ***************************************************************/

                static Time fromDate (ref const(DateTime) dt)
                {
                        SYSTEMTIME sTime = void;
                        FILETIME   fTime = void;

                        sTime.wYear         = cast(ushort) dt.date.year;
                        sTime.wMonth        = cast(ushort) dt.date.month;
                        sTime.wDayOfWeek    = 0;
                        sTime.wDay          = cast(ushort) dt.date.day;
                        sTime.wHour         = cast(ushort) dt.time.hours;
                        sTime.wMinute       = cast(ushort) dt.time.minutes;
                        sTime.wSecond       = cast(ushort) dt.time.seconds;
                        sTime.wMilliseconds = cast(ushort) dt.time.millis;

                        SystemTimeToFileTime (&sTime, &fTime);
                        return convert (fTime);
                }

                /***************************************************************

                        Convert FILETIME to a Time

                ***************************************************************/

                package static Time convert (const(FILETIME) time)
                {
                        auto t = *cast(long*) &time;
                        t *= 100 / TimeSpan.NanosecondsPerTick;
                        return Time.epoch1601 + TimeSpan(t);
                }

                /***************************************************************

                        Convert Time to a FILETIME

                ***************************************************************/

                package static FILETIME convert (const(Time) dt)
                {
                        FILETIME time = void;

                        TimeSpan span = dt - Time.epoch1601;
                        assert (span >= TimeSpan.zero);
                        *cast(long*) &time.dwLowDateTime = span.ticks;
                        return time;
                }
        }

        version (Posix)
        {
                /***************************************************************

                        Return the current time as UTC since the epoch

                ***************************************************************/

                @property static Time now ()
                {
                        timeval tv = void;
                        if (gettimeofday (&tv, null))
                            throw new PlatformException ("Clock.now :: Posix timer is not available");

                        return convert (tv);
                }

                /***************************************************************

                        Set Date fields to represent the current time. 

                ***************************************************************/

                static DateTime toDate ()
                {
                        return toDate (now);
                }

                /***************************************************************

                        Set fields to represent the provided UTC time. Note 
                        that the conversion is limited by the underlying OS,
                        and will fail to operate correctly with Time
                        values beyond the domain. On Win32 the earliest
                        representable date is 1601. On linux it is 1970. Both
                        systems have limitations upon future dates also. Date
                        is limited to millisecond accuracy at best.

                **************************************************************/

                static DateTime toDate (const(Time) time)
                {
                        DateTime dt = void;
                        auto timeval = convert (time);
                        dt.time.millis = cast(uint)timeval.tv_usec / 1000;

                        tm t = void;
                        gmtime_r (&timeval.tv_sec, &t);

                        dt.date.year    = t.tm_year + 1900;
                        dt.date.month   = t.tm_mon + 1;
                        dt.date.day     = t.tm_mday;
                        dt.date.dow     = t.tm_wday;
                        dt.date.era     = 0;
                        dt.time.hours   = t.tm_hour;
                        dt.time.minutes = t.tm_min;
                        dt.time.seconds = t.tm_sec;

                        // Calculate the day-of-year
                        setDoy(dt);

                        return dt;
                }

                /***************************************************************

                        Convert Date fields to Time

                        Note that the conversion is limited by the underlying 
                        OS, and will not operate correctly with Time
                        values beyond the domain. On Win32 the earliest
                        representable date is 1601. On linux it is 1970. Both
                        systems have limitations upon future dates also. Date
                        is limited to millisecond accuracy at best.

                ***************************************************************/

                static Time fromDate (ref const(DateTime) dt)
                {
                        tm t = void;

                        t.tm_year = dt.date.year - 1900;
                        t.tm_mon  = dt.date.month - 1;
                        t.tm_mday = dt.date.day;
                        t.tm_hour = dt.time.hours;
                        t.tm_min  = dt.time.minutes;
                        t.tm_sec  = dt.time.seconds;

                        auto seconds = timegm (&t);
                        return Time.epoch1970 + 
                               TimeSpan.fromSeconds(seconds) + 
                               TimeSpan.fromMillis(dt.time.millis);
                }

                /***************************************************************

                        Convert timeval to a Time

                ***************************************************************/

                package static Time convert (ref const(timeval) tv)
                {
                        return Time.epoch1970 + 
                               TimeSpan.fromSeconds(tv.tv_sec) + 
                               TimeSpan.fromMicros(tv.tv_usec);
                }

                /***************************************************************

                        Convert Time to a timeval

                ***************************************************************/

                package static timeval convert (const(Time) time)
                {
                        timeval tv = void;

                        TimeSpan span = time - time.epoch1970;
                        assert (span >= TimeSpan.zero);
                        tv.tv_sec  = cast(typeof(tv.tv_sec)) span.seconds;
                        tv.tv_usec = cast(typeof(tv.tv_usec)) (span.micros % 1_000_000L);
                        return tv;
                }
        }
}



debug (UnitTest)
{
        unittest 
        {
                auto time = Clock.now;
                auto clock=Clock.convert(time);
                assert (Clock.convert(clock) is time);

                time -= TimeSpan(time.ticks % TimeSpan.TicksPerSecond);
                auto date = Clock.toDate(time);

                assert (time is Clock.fromDate(date));
        }
}

debug (Clock)
{
        void main() 
        {
                auto time = Clock.now;
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Kris

*******************************************************************************/

module tango.util.time.Clock;

private import  tango.sys.Common;

private import  tango.util.time.Date;

private import  tango.core.Exception;

public  import  tango.core.Type : Time;

/******************************************************************************

        Exposes UTC time relative to Jan 1st, 1 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. Units of Time are the foundation of most time
        and date functionality in Tango.

        Interval is another type of time period, used for measuring a
        much shorter duration; typically used for timeout periods and
        for high-resolution timers. These intervals are measured in
        units of 1 second, and support fractional units (0.001 = 1ms).

*******************************************************************************/

struct Clock
{
        version (Win32)
        {
                /***************************************************************

                        Return the current time as UTC since the epoch

                ***************************************************************/

                static Time now ()
                {
                        FILETIME fTime = void;
                        GetSystemTimeAsFileTime (&fTime);
                        return convert (fTime);
                }

                /***************************************************************

                        Set Date fields to represent the current time. 

                ***************************************************************/

                static Date toDate ()
                {
                        return toDate (now);
                }

                /***************************************************************

                        Set fields to represent the provided UTC time. Note 
                        that the conversion is limited by the underlying OS,
                        and will fail to operate correctly with Time values 
                        beyond the domain. On Win32 the earliest representable 
                        date is 1601. On linux it is 1970. Both systems have 
                        limitations upon future dates also. Date is limited 
                        to millisecond accuracy at best.

                ***************************************************************/

                static Date toDate (Time time)
                {
                        Date date = void;
                        SYSTEMTIME sTime = void;

                        auto fTime = convert (time);
                        FileTimeToSystemTime (&fTime, &sTime);

                        date.year  = sTime.wYear;
                        date.month = sTime.wMonth;
                        date.day   = sTime.wDay;
                        date.hour  = sTime.wHour;
                        date.min   = sTime.wMinute;
                        date.sec   = sTime.wSecond;
                        date.ms    = sTime.wMilliseconds;
                        date.dow   = sTime.wDayOfWeek;
                        return date;
                }

                /***************************************************************

                        Convert Date fields to UTC

                        Note that the conversion is limited by the underlying 
                        OS, and will not operate correctly with Time values 
                        beyond the domain. On Win32 the earliest representable 
                        date is 1601. On linux it is 1970. Both systems have 
                        limitations upon future dates also. Date is limited 
                        to millisecond accuracy at best.

                ***************************************************************/

                static Time fromDate (inout Date date)
                {
                        SYSTEMTIME sTime = void;
                        FILETIME   fTime = void;

                        sTime.wYear         = cast(ushort) date.year;
                        sTime.wMonth        = cast(ushort) date.month;
                        sTime.wDayOfWeek    = 0;
                        sTime.wDay          = cast(ushort) date.day;
                        sTime.wHour         = cast(ushort) date.hour;
                        sTime.wMinute       = cast(ushort) date.min;
                        sTime.wSecond       = cast(ushort) date.sec;
                        sTime.wMilliseconds = cast(ushort) date.ms;

                        SystemTimeToFileTime (&sTime, &fTime);
                        return convert (fTime);
                }

                /***************************************************************

                        Convert FILETIME to a Time

                ***************************************************************/

                package static Time convert (FILETIME time)
                {
                        return cast(Time) (Time.TicksTo1601 + *cast(ulong*) &time);
                }

                /***************************************************************

                        Convert Time to a FILETIME

                ***************************************************************/

                package static FILETIME convert (Time span)
                {
                        FILETIME time = void;

                        span -= span.TicksTo1601;
                        assert (span >= 0);
                        *cast(long*) &time.dwLowDateTime = span;
                        return time;
                }
        }

        version (Posix)
        {
                /***************************************************************

                        Return the current time as UTC since the epoch

                ***************************************************************/

                static Time now ()
                {
                        timeval tv = void;
                        if (gettimeofday (&tv, null))
                            throw new PlatformException ("Time.utc :: Posix timer is not available");

                        return convert (tv);
                }

                /***************************************************************

                        Set Date fields to represent the current time. 

                ***************************************************************/

                static Date toDate ()
                {
                        return toDate (now);
                }

                /***************************************************************

                        Set fields to represent the provided UTC time. Note 
                        that the conversion is limited by the underlying OS,
                        and will fail to operate correctly with Time values 
                        beyond the domain. On Win32 the earliest representable 
                        date is 1601. On linux it is 1970. Both systems have 
                        limitations upon future dates also. Date is limited 
                        to millisecond accuracy at best.

                **************************************************************/

                static Date toDate (Time time)
                {
                        Date date = void;
                        auto timeval = convert (time);
                        date.ms = timeval.tv_usec / 1000;

                        tm t = void;
                        gmtime_r (&timeval.tv_sec, &t);
        
                        date.year  = t.tm_year + 1900;
                        date.month = t.tm_mon + 1;
                        date.day   = t.tm_mday;
                        date.hour  = t.tm_hour;
                        date.min   = t.tm_min;
                        date.sec   = t.tm_sec;
                        date.dow   = t.tm_wday;
                        return date;
                }

                /***************************************************************

                        Convert Date fields to UTC

                        Note that the conversion is limited by the underlying 
                        OS, and will not operate correctly with Time values 
                        beyond the domain. On Win32 the earliest representable 
                        date is 1601. On linux it is 1970. Both systems have 
                        limitations upon future dates also. Date is limited 
                        to millisecond accuracy at best.

                ***************************************************************/

                static Time fromDate (inout Date date)
                {
                        tm t = void;

                        t.tm_year = date.year - 1900;
                        t.tm_mon  = date.month - 1;
                        t.tm_mday = date.day;
                        t.tm_hour = date.hour;
                        t.tm_min  = date.min;
                        t.tm_sec  = date.sec;

                        auto seconds = timegm (&t);
                        return cast(Time) (Time.TicksTo1970 +
                                           Time.TicksPerSecond * seconds +
                                           Time.TicksPerMillisecond * date.ms);
                }

                /***************************************************************

                        Convert timeval to a Time

                ***************************************************************/

                package static Time convert (inout timeval tv)
                {
                        return cast(Time) (Time.TicksTo1970 + (1_000_000L * tv.tv_sec + tv.tv_usec) * 10);
                }

                /***************************************************************

                        Convert Time to a timeval

                ***************************************************************/

                package static timeval convert (Time time)
                {
                        timeval tv = void;

                        time -= time.TicksTo1970;
                        assert (time >= 0);
                        time /= 10L;
                        tv.tv_sec  = cast (typeof(tv.tv_sec))  (time / 1_000_000L);
                        tv.tv_usec = cast (typeof(tv.tv_usec)) (time - 1_000_000L * tv.tv_sec);
                        return tv;
                }
        }
}



debug (UnitTest)
{
        unittest 
        {
                auto time = Clock.now;
                assert (Clock.convert(Clock.convert(time)) is time);

                time = cast(Time) ((time / Time.TicksPerSecond) * Time.TicksPerSecond);
                auto date = Clock.toDate(time);

                assert (time is Clock.fromDate(date));
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Feb 2007: Initial release
        
        author:         Kris

*******************************************************************************/

module tango.core.Time;

private import tango.sys.Common;

private import tango.core.Exception;

/******************************************************************************

        Represents UTC time relative to Jan 1st, 0 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. These Time.Span values are the foundation of
        most time & date functionality in Tango.

        Interval is another type of time period, used for measuring a
        much shorter duration; typically used for timeout periods and
        for high-resolution timers. These intervals are measured in
        units of 1 second, and support fractional units (0.001 = 1ms).
        We use interval here to represent a local timezone offset.

******************************************************************************/

struct Time
{
        typedef ulong Span;
        typedef float Interval;

        private static Span began;

        /***********************************************************************
                
                Time constants for Span

        ***********************************************************************/

        enum : ulong 
        {
                Invalid = Span.max,

                TicksPerMillisecond = 10000,
                TicksPerSecond = TicksPerMillisecond * 1000,
                TicksPerMinute = TicksPerSecond * 60,
                TicksPerHour = TicksPerMinute * 60,
                TicksPerDay = TicksPerHour * 24,

                MillisPerSecond = 1000,
                MillisPerMinute = MillisPerSecond * 60,
                MillisPerHour = MillisPerMinute * 60,
                MillisPerDay = MillisPerHour * 24,

                DaysPerYear = 365,
                DaysPer4Years = DaysPerYear * 4 + 1,
                DaysPer100Years = DaysPer4Years * 25 - 1,
                DaysPer400Years = DaysPer100Years * 4 + 1,

                DaysTo1601 = DaysPer400Years * 4,
                DaysTo10000 = DaysPer400Years * 25 - 366,

                TicksTo1601 = DaysTo1601 * TicksPerDay,
                TicksTo1970 = 116444736000000000L + TicksTo1601,
        }

        /***********************************************************************
                
                initialize ourselves

        ***********************************************************************/

        static this()
        {
                began = utc();
        }

        /***********************************************************************
                
                Utc time this executable started 

        ***********************************************************************/

        final static Span started ()
        {
                return began;
        }

        /***********************************************************************
                
                Return the local time since the epoch

        ***********************************************************************/

        static Span local ()
        {
                return utc() + cast(Span) (cast(double) zone * TicksPerSecond);
        }

        /***********************************************************************
                        
                Basic functions for epoch time

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************
                
                        Return the current time as UTC since the epoch

                ***************************************************************/

                static Span utc ()
                {
                        FILETIME fTime = void;
                        GetSystemTimeAsFileTime (&fTime);
                        return toSpan (fTime);
                }

                /***************************************************************
                
                        Convert timeval to a Span

                ***************************************************************/

                static Span toSpan (FILETIME time)
                {
                        return cast(Span) (*cast(ulong*) &time + TicksTo1601);
                }

                /***************************************************************
                
                        Convert Span to a FILETIME

                ***************************************************************/

                static FILETIME fromSpan (Span span)
                {
                        FILETIME time = void;

                        span -= TicksTo1601;
                        *cast(ulong*) &time.dwLowDateTime = span;
                        return time;
                }

                /***************************************************************
                
                        Return the timezone seconds relative to GMT

                ***************************************************************/

                static Interval zone ()
                {
                        TIME_ZONE_INFORMATION tz = void;

                        auto tmp = GetTimeZoneInformation (&tz);
                        return cast(Interval) (-tz.Bias * 60);
                }
        }

        version (Posix)
        {
                /***************************************************************
                
                        Return the current time as UTC since the epoch

                ***************************************************************/

                static Span utc ()
                {
                        timeval tv;
                        if (gettimeofday (&tv, null))
                            throw new PlatformException ("Time.utc :: linux timer is not available");

                        return toSpan (tv);
                }

                /***************************************************************
                
                        Convert timeval to a Span

                ***************************************************************/

                static Span toSpan (inout timeval tv)
                {
                        return cast(Span) ((1_000_000L * cast(ulong) tv.tv_sec + tv.tv_usec) * 10 + TicksTo1970);
                }

                /***************************************************************
                
                        Convert Span to a timeval

                ***************************************************************/

                static timeval fromSpan (Span span)
                {
                        timeval tv;

                        span -= TicksTo1970;
                        span /= 10;
                        tv.tv_sec = span / 1_000_000;
                        tv.tv_usec = span - tv.tv_sec;
                        return tv;
                }

                /***************************************************************
                
                        Return the timezone seconds relative to GMT

                ***************************************************************/

                static Interval zone ()
                {
                        return cast(Interval) -timezone;
                }
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Feb 2007: Initial release
        
        author:         Kris

*******************************************************************************/

module tango.util.time.Utc;

private import  tango.sys.Common;

private import  tango.core.Exception;

public  import  tango.core.Type : Interval, Time;

/******************************************************************************

        Exposes UTC time relative to Jan 1st, 1 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. Units of Time are the foundation of most time 
        and date functionality in Tango.

        Interval is another type of time period, used for measuring a
        much shorter duration; typically used for timeout periods and
        for high-resolution timers. These intervals are measured in
        units of 1 second, and support fractional units (0.001 = 1ms).
        We use interval here to represent a local timezone offset.

******************************************************************************/

struct Utc
{
        /***********************************************************************
                
                Return the local time since the epoch

        ***********************************************************************/

        static Time local ()
        {
                return toLocal (time);
        }

        /***********************************************************************
                
                Convert UTC time to local time

        ***********************************************************************/

        static Time toLocal (Time time)
        {
                return cast(Time) (time + zone * Time.TicksPerSecond);
        }

        /***********************************************************************
                
                Convert local time to UTC time

        ***********************************************************************/

        static Time fromLocal (Time time)
        {
                return cast(Time) (time - zone * Time.TicksPerSecond);
        }

        /***********************************************************************
                        
                Basic functions for epoch time

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************
                
                        Return the current time as UTC since the epoch

                ***************************************************************/

                static Time time ()
                {
                        FILETIME fTime = void;
                        GetSystemTimeAsFileTime (&fTime);
                        return convert (fTime);
                }

                /***************************************************************
                
                        Convert FILETIME to a Time

                ***************************************************************/

                static Time convert (FILETIME time)
                {
                        return cast(Time) (Time.TicksTo1601 + *cast(ulong*) &time);
                }

                /***************************************************************
                
                        Convert Time to a FILETIME

                ***************************************************************/

                static FILETIME convert (Time span)
                {
                        FILETIME time = void;

                        span -= span.TicksTo1601;
                        *cast(ulong*) &time.dwLowDateTime = span;
                        return time;
                }

                /***************************************************************
                
                        Return the timezone seconds relative to GMT. The
                        value is negative when west of GMT

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

                static Time time ()
                {
                        timeval tv;
                        if (gettimeofday (&tv, null))
                            throw new PlatformException ("Time.utc :: linux timer is not available");

                        return convert (tv);
                }

                /***************************************************************
                
                        Convert timeval to a Time

                ***************************************************************/

                static Time convert (inout timeval tv)
                {
                        return cast(Time) (Time.TicksTo1970 + (1_000_000L * tv.tv_sec + tv.tv_usec) * 10);
                }

                /***************************************************************
                
                        Convert Time to a timeval

                ***************************************************************/

                static timeval convert (Time span)
                {
                        timeval tv;

                        span -= span.TicksTo1970;
                        span /= 10L;
                        tv.tv_sec  = cast (typeof(tv.tv_sec))  (span / 1_000_000L);
                        tv.tv_usec = cast (typeof(tv.tv_usec)) (span - tv.tv_sec);
                        return tv;
                }

                /***************************************************************
                
                        Return the timezone seconds relative to GMT. The
                        value is negative when west of GMT

                ***************************************************************/

                static Interval zone ()
                {
                        return cast(Interval) -timezone;
                }
        }
}

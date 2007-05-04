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

*******************************************************************************/

struct Utc
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

                        Convert timeval to a Time

                ***************************************************************/

                static Time convert (inout timeval tv)
                {
                        return cast(Time) (Time.TicksTo1970 + (1_000_000L * tv.tv_sec + tv.tv_usec) * 10);
                }

                /***************************************************************

                        Convert Time to a timeval

                ***************************************************************/

                static timeval convert (Time time)
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
                auto time = Utc.now;
                assert (Utc.convert(Utc.convert(time)) is time);
        }
}

/**
 * The config module contains utility routines and configuration information
 * specific to this package.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.sync.Config;


public import tango.util.time.TimeSpan;
public import tango.core.Exception : SyncException;


version( Posix )
{
    private import tango.stdc.posix.time;
    private import tango.stdc.posix.sys.time;


    void getTimespec( inout timespec t )
    {
        static if( is( typeof( clock_gettime ) ) )
        {
            clock_gettime( CLOCK_REALTIME, &t );
        }
        else
        {
            timeval tv;

            gettimeofday( &tv, null );
            (cast(byte*) &t)[0 .. t.sizeof] = 0;
            t.tv_sec  = cast(typeof(t.tv_sec))  tv.tv_sec;
            t.tv_nsec = cast(typeof(t.tv_nsec)) tv.tv_usec * 1_000;
        }
    }


    void adjTimespec( inout timespec t, TimeSpan i )
    {
        enum
        {
            SECS_TO_NANOS = 1_000_000_000
        }

        if( t.tv_sec.max - t.tv_sec < i.seconds )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = 0;
        }
        else
        {
            t.tv_sec  += i.seconds;
            long ns = i.nanoseconds % SECS_TO_NANOS;
            if( SECS_TO_NANOS - t.tv_nsec < ns )
            {
                t.tv_sec += 1;
                ns -= SECS_TO_NANOS;
            }
            t.tv_nsec += cast(typeof(t.tv_sec)) ns;
        }
    }
}

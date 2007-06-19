/**
 * The semaphore module provides a general use semaphore for synchronization.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.sync.Config;


public import tango.core.Type;
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


    void adjTimespec( inout timespec t, Interval i )
    {
        if( (cast(Interval) t.tv_sec.max) - i < cast(Interval) t.tv_sec )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = t.tv_nsec.max;
        }
        else
        {
            t.tv_sec  += cast(typeof(t.tv_sec)) i;
            t.tv_nsec += cast(typeof(t.tv_sec))( (i % 1.0) * 1_000_000_000 );
        }
    }
}

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


    void getTimespec( inout timespec t, Interval adjust )
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
            // NOTE: When clock_gettime is not defined, the wait routines seem
            //       to actually use a timeval rather than a timespec, even if
            //       they are declared to take a timespec.  So treat nanos as
            //       usecs if this is true.
            t.tv_nsec = cast(typeof(t.tv_nsec)) tv.tv_usec;
        }
    }


    void adjTimespec( inout timespec t, Interval i )
    {
        // NOTE: When clock_gettime is not defined, the wait routines seem to
        //       actually use a timeval rather than a timespec, even if they
        //       are declared to take a timespec.  So treat nanos as usecs if
        //       this is true.
        static if( is( typeof( clock_gettime ) ) )
            const TS_NANOS_TO_SECS = 1_000_000_000;
        else
            const TS_NANOS_TO_SECS = 1_000_000;

        if( (cast(Interval) t.tv_sec.max) - i < cast(Interval) t.tv_sec )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = t.tv_nsec.max;
        }
        else
        {
            t.tv_sec  += cast(typeof(t.tv_sec)) i;
            t.tv_nsec += cast(typeof(t.tv_sec))( (i % 1.0) * TS_NANOS_TO_SECS );
        }
    }
}

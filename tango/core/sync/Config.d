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


    void setTimespec( inout timespec t, Interval i )
    {
        if( i > t.tv_sec.max )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = t.tv_nsec.max;
        }
        else
        {
            t.tv_sec  = cast(typeof(t.tv_sec)) i;
            t.tv_nsec = cast(typeof(t.tv_sec))( ( i - t.tv_sec ) * 1_000_000_000 );
        }
    }


    Interval toInterval( inout timespec t )
    {
        return (cast(Interval) t.tv_sec) + (cast(Interval) t.tv_nsec) / 1_000_000_000;
    }


    Interval absTimeout( Interval period )
    {
        timespec t;

        clockc_gettime( CLOCK_REALTIME, &t );
        return toInterval( t ) + period;
    }
}

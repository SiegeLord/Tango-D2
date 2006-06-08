/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.core.System;

private import  tango.core.Epoch,
                tango.core.Interval;

/*******************************************************************************

*******************************************************************************/

version (Win32)
         extern (Windows) void Sleep (uint millisecs);

version (Posix)
         extern (C) void usleep(uint);


/*******************************************************************************

        Some system-specific functionality that doesn't belong anywhere 
        else. This needs some further thought and refinement.

*******************************************************************************/

struct System
{       
        /***********************************************************************
                
                Return the number of milliseconds since January 1st 1970

        ***********************************************************************/

        final static ulong getMillisecs ()
        {
                return Epoch.utcMilli;
        }

        /***********************************************************************
        
                Send this thread to sleep for a while. The time interval
                is measured in microseconds. Specifying a period value of
                Interval.max will cause the calling thread to sleep forever.

        ***********************************************************************/

        final static void sleep (Interval interval = Interval.max)
        {
                do {
                   version (Posix)
                            usleep (interval);

                   version (Win32)
                            Sleep (interval / Interval.milli);
                   } while (interval is Interval.max);
        }
}

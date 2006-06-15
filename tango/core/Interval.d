/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      

        author:         Kris

*******************************************************************************/

module tango.core.Interval;

/*******************************************************************************

        Time interval multipliers ~ all Tango intervals are based upon 
        microseconds. Note that recent D compilers support arithmetic
        applied upon Interval members to be passed as a fully-typed
        Interval argument; e.g.

        ---
        void sleep (Interval period);

        sleep (Inteval.second * 5);
        ---

        Intervals can currently extend up to a one-hour period. They're
        intended to represent short durations of time, such as when one
        waits for a socket response.

*******************************************************************************/

enum Interval : uint {
                     // min   = uint.min,       // implied via type
                     // max   = uint.max,       // implied via type

                     micro    = 1, 
                     milli    = 1000, 
                     second   = 1_000_000,
                     minute   = 60_000_000,

                     Microsec = micro, 
                     Millisec = milli, 
                     Second   = second, 
                     Minute   = minute
                     };


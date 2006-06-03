/*******************************************************************************

        @file Interval.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, March 2004      

        @author         Kris

*******************************************************************************/

module tango.core.Interval;

/*******************************************************************************

        Time interval multipliers ~ all Tango intervals are based upon 
        microseconds. Note that recent D compilers support arithmetic
        applied upon Interval members to be passed as an fully typed
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

                     Microsec = 1, 
                     Millisec = 1000, 
                     Second   = 1_000_000, 
                     Minute   = 60_000_000
                     };


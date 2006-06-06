/*******************************************************************************

        @file System.d
        
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

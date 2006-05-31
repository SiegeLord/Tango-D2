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

module tango.sys.System;

private import tango.sys.thread;     

private import tango.sys.OS,
               tango.sys.Epoch;

/*******************************************************************************

*******************************************************************************/

version (Win32)
         extern (Windows) VOID Sleep (DWORD millisecs);

version (Posix)
         extern (C) void usleep(uint);


/*******************************************************************************

        Some system-specific functionality that doesn't belong anywhere 
        else. This needs some further thought and refinement.

*******************************************************************************/

struct System
{       
        /***********************************************************************
                
                Time interval multipliers. All Mango intervals are based
                upon microseconds. This should get pulled out into a 
                distinct module

        ***********************************************************************/

        enum Interval : ulong {
                        min      = ulong.min,
                        max      = ulong.max,

                        micro    = 1, 
                        milli    = 1000, 
                        second   = 1_000_000,
                        minute   = 60_000_000,

                        Microsec = 1, 
                        Millisec = 1000, 
                        Second   = 1_000_000, 
                        Minute   = 60_000_000
                        };


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
                uint.max will cause the calling thread to sleep forever.

        ***********************************************************************/

        final static void sleep (uint interval = uint.max)
        {
                do {
                   version (Posix)
                            usleep (interval);

                   version (Win32)
                            Sleep (interval / 1000);
                   } while (interval == uint.max);
        }

        /***********************************************************************
              
                Create a thread for the given delegate, and optionally start 
                it up.
                  
        ***********************************************************************/

        version (Phobos)
                 typedef int delegate() ThreadDelegate;
              else
                 typedef void delegate() ThreadDelegate;

        final static Thread createThread (ThreadDelegate dg, bool start = false)
        {
                Thread t = new Thread (dg);
                if (start)
                    t.start ();
                return t;
        }
}

/*******************************************************************************

        @file Event.d

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

      
        @version        Initial version, May 2004
        @author         Kris
                        Anders F Bjorklund (Darwin patches)


*******************************************************************************/

module tango.log.Event;

version = UseEventFreeList;

private import  tango.os.OS;

private import  tango.log.Hierarchy;

private import  tango.log.model.ILevel;

version (Win32)
{
        extern(Windows) int QueryPerformanceCounter(ulong *count);
        extern(Windows) int QueryPerformanceFrequency(ulong *frequency);
}


/*******************************************************************************

        Contains all information about a logging event, and is passed around
        between methods once it has been determined that the invoking logger
        is enabled for output.

        Note that Event instances are maintained in a freelist rather than
        being allocated each time, and they include a scratchpad area for
        Layout formatters to use.

*******************************************************************************/

public class Event : ILevel
{
        // primary event attributes
        private char[]          msg,
                                name;
        private ulong           time;
        private Level           level;
        private Hierarchy       hierarchy;

        // timestamps
        private static ulong    epochTime;
        private static ulong    beginTime;

        // scratch buffer for constructing output strings
        struct  Scratch
                {
                uint            length;
                char[256]       content;
                }
        package Scratch         scratch;


        // logging-level names
        package static char[][] LevelNames = 
        [
                "TRACE ", "INFO ", "WARN ", "ERROR ", "FATAL ", "NONE "
        ];

        version (Win32)
        {
                private static uint frequency;
        }

        version (UseEventFreeList)
        {
                /***************************************************************

                        Instance variables for free-list support

                ***************************************************************/

                private Event           next;   
                private static Event    freelist;

                /***************************************************************

                        Allocate an Event from a list rather than 
                        creating a new one

                ***************************************************************/

                static final synchronized Event allocate ()
                {       
                        Event e;

                        if (freelist)
                           {
                           e = freelist;
                           freelist = e.next;
                           }
                        else
                           e = new Event ();                                
                        return e;
                }

                /***************************************************************

                        Return this Event to the free-list

                ***************************************************************/

                static final synchronized void deallocate (Event e)
                { 
                        e.next = freelist;
                        freelist = e;

                        version (EventReset)
                                 e.reset();
                }
        }

        /***********************************************************************
                
                Setup the timing information for later use. Note how much 
                effort it takes to get epoch time in Win32 ...

        ***********************************************************************/

        package static void initialize ()
        {
                version (Posix)       
                {
                        timeval tv;

                        if (gettimeofday (&tv, null))
                            throw new Exception ("high-resolution timer is not available");
                        
                        epochTime = 1000L * tv.tv_sec;
                        beginTime = epochTime + tv.tv_usec / 1000;
                }

                version (Win32)
                {
                        ulong           time;
                        ulong           freq;

                        if (! QueryPerformanceFrequency (&freq))
                              throw new Exception ("high-resolution timer is not available");
                               
                        frequency = cast(uint) (freq / 1000);
                        QueryPerformanceCounter (&time);
                        beginTime = time / frequency;

                        SYSTEMTIME      sTime;
                        FILETIME        fTime;

                        GetSystemTime (&sTime);
                        SystemTimeToFileTime (&sTime, &fTime);
                        
                        ulong time1 = (cast(ulong) fTime.dwHighDateTime) << 32 | 
                                                   fTime.dwLowDateTime;

                        // first second of 1970 ...
                        sTime.wYear = 1970;
                        sTime.wMonth = 1;
                        sTime.wDayOfWeek = 0;
                        sTime.wDay = 1;
                        sTime.wHour = 0;
                        sTime.wMinute = 0;
                        sTime.wSecond = 0;
                        sTime.wMilliseconds = 0;
                        SystemTimeToFileTime (&sTime, &fTime);

                        ulong time2 = (cast(ulong) fTime.dwHighDateTime) << 32 | 
                                                   fTime.dwLowDateTime;
                        
                        epochTime = (time1 - time2) / 10_000;
                }
        }

        /***********************************************************************
                
                Return the number of milliseconds since the executable
                was started.

        ***********************************************************************/

        final static ulong getRuntime ()
        {
                version (Posix)       
                {
                        timeval tv;

                        gettimeofday (&tv, null);
                        return ((cast(ulong) tv.tv_sec) * 1000 + tv.tv_usec / 1000) - beginTime;
                }

                version (Win32)
                {
                        ulong time;

                        QueryPerformanceCounter (&time);
                        return (time / frequency) - beginTime;
                }
        }

        /***********************************************************************
                
                Set the various attributes of this event.

        ***********************************************************************/

        final void set (Hierarchy hierarchy, Level level, char[] msg, char[] name)
        {
                this.hierarchy = hierarchy;
                this.time = getRuntime ();
                this.level = level;
                this.name = name;
                this.msg = msg;
        }

        version (EventReset)
        {
                /***************************************************************

                        Reset this event

                ***************************************************************/

                final void reset ()
                {
                        time = 0;
                        msg = null;
                        name = null;
                        level = Level.None;
                }
        }

        /***********************************************************************
                
                Return the message attached to this event.

        ***********************************************************************/

        final override char[] toString ()
        {
                return msg;
        }

        /***********************************************************************
                
                Return the name of the logger which produced this event

        ***********************************************************************/

        final char[] getName ()
        {
                return name;
        }

        /***********************************************************************
                
                Return the scratch buffer for formatting. This is a thread
                safe place to format data within, without allocating any
                memory.

        ***********************************************************************/

        final char[] getContent ()
        {
                return scratch.content [0..scratch.length];
        }

        /***********************************************************************
                
                Return the logger level of this event.

        ***********************************************************************/

        final Level getLevel ()
        {
                return level;
        }

        /***********************************************************************
                
                Return the logger level name of this event.

        ***********************************************************************/

        final char[] getLevelName ()
        {
                return LevelNames[level];
        }

        /***********************************************************************
                
                Return the hierarchy where the event was produced from

        ***********************************************************************/

        final Hierarchy getHierarchy ()
        {
                return hierarchy;
        }

        /***********************************************************************
                
                Return the time this event was produced, relative to the 
                start of this executable

        ***********************************************************************/

        final ulong getTime ()
        {
                return time;
        }

        /***********************************************************************
               
                Return the time this event was produced, relative to 
                Jan 1st 1970

        ***********************************************************************/

        final ulong getEpochTime ()
        {
                return time + epochTime;
        }

        /***********************************************************************

                Append some content to the scratch buffer. This is limited
                to the size of said buffer, and will not expand further.

        ***********************************************************************/

        final Event append (char[] x)
        {
                uint addition = x.length;
                uint newLength = scratch.length + x.length;

                if (newLength < scratch.content.length)
                   {
                   scratch.content [scratch.length..newLength] = x[0..addition];
                   scratch.length = newLength;
                   }
                return this;
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: May 2005
        
        author:         Kris

*******************************************************************************/

module tango.core.Epoch;

/*******************************************************************************

        Haul in additional O/S specific imports

*******************************************************************************/

private import tango.sys.Common;

version (Posix)
{
        extern (C) int mktime (tm *);
        extern (C) tm *gmtime (int *);
}


/******************************************************************************

        Represents UTC time relative to Jan 1st 1970, and converts between
        the native time format (a long integer) and a set of fields. The
        native time is accurate to the millisecond level.

        See http://en.wikipedia.org/wiki/Unix_time for details on UTC time.

******************************************************************************/

abstract class Epoch
{
        private static ulong beginTime;

        const ulong InvalidEpoch = -1;

        /***********************************************************************
                     
                A set of fields representing date/time components. This is 
                used to abstract differences between Win32 & Posix platforms.
                                           
        ***********************************************************************/

        struct Fields
        {
                int     year,           // fully defined year ~ e.g. 2005
                        month,          // 1 through 12
                        day,            // 1 through 31
                        hour,           // 0 through 23
                        min,            // 0 through 59
                        sec,            // 0 through 59
                        ms,             // 0 through 999
                        dow;            // 0 through 6; sunday == 0


                /**************************************************************

                **************************************************************/

                private static char[][] Days = 
                [
                        "Sunday",
                        "Monday",
                        "Tuesday",
                        "Wednesday",
                        "Thursday",
                        "Friday",
                        "Saturday",
                ];

                /**************************************************************

                **************************************************************/

                private static char[][] Months = 
                [
                        "null",
                        "January",
                        "February",
                        "March",
                        "April",
                        "May",
                        "June",
                        "July",
                        "August",
                        "September",
                        "October",
                        "November",
                        "December",
                ];

                /**************************************************************

                        Set the date-related values

                        year  : fully defined year ~ e.g. 2005
                        month : 1 through 12
                        day   : 1 through 31
                        dow   : 0 through 6; sunday=0 (typically set by O/S)

                **************************************************************/

                void setDate (int year, int month, int day, int dow = 0)
                {
                        this.year = year;
                        this.month = month;
                        this.day = day;
                        this.dow = dow;
                }

                /**************************************************************

                        Set the time-related values 

                        hour : 0 through 23
                        min  : 0 through 59
                        sec  : 0 through 59
                        ms   : 0 through 999

                **************************************************************/

                void setTime (int hour, int min, int sec, int ms = 0)
                {
                        this.hour = hour;
                        this.min = min;
                        this.sec = sec;
                        this.ms = ms;
                }

                /**************************************************************

                        Retrieve English name for the Day of Week

                **************************************************************/

                char[] toDowName ()
                {
                        return Days[dow];
                }

                /**************************************************************

                        Retrieve English name for the month

                **************************************************************/

                char[] toMonthName ()
                {
                        return Months[month];
                }

                /***************************************************************

                        Win32 implementation

                ***************************************************************/

                version (Win32)
                {
                        /*******************************************************

                                Convert fields to UTC time, and return 
                                milliseconds since epoch

                        *******************************************************/

                        ulong getUtcTime ()
                        {
                                SYSTEMTIME sTime;
                                FILETIME   fTime;

                                sTime.wYear = cast(ushort) year;
                                sTime.wMonth = cast(ushort) month;
                                sTime.wDayOfWeek = 0;
                                sTime.wDay = cast(ushort) day;
                                sTime.wHour = cast(ushort) hour;
                                sTime.wMinute = cast(ushort) min;
                                sTime.wSecond = cast(ushort) sec;
                                sTime.wMilliseconds = cast(ushort) ms;

                                SystemTimeToFileTime (&sTime, &fTime);

                                return fromFileTime (&fTime);
                        }

                        /*******************************************************

                                Set fields to represent the provided epoch 
                                time
                                
                        *******************************************************/

                        void setUtcTime (ulong time)
                        {
                                SYSTEMTIME sTime;
                                FILETIME   fTime;

                                toFileTime (&fTime, time);
                                FileTimeToSystemTime (&fTime, &sTime);

                                year = sTime.wYear;
                                month = sTime.wMonth;
                                day = sTime.wDay;
                                hour = sTime.wHour;
                                min = sTime.wMinute;
                                sec = sTime.wSecond;
                                ms = sTime.wMilliseconds;
                                dow = sTime.wDayOfWeek;
                        }

                        /*******************************************************

                                Set fields to represent a localized version
                                of the provided epoch time

                        *******************************************************/

                        void setLocalTime (ulong time)
                        {
                                FILETIME fTime,
                                         local;

                                toFileTime (&fTime, time);
                                FileTimeToLocalFileTime (&fTime, &local);
                                setUtcTime (fromFileTime (&local));
                        }
                }


                /***************************************************************

                        Posix implementation

                ***************************************************************/

                version (Posix)
                {
                        /*******************************************************

                                Convert fields to UTC time, and return 
                                milliseconds since epoch

                        *******************************************************/

                        ulong getUtcTime ()
                        {
                                tm t;

                                t.tm_year = year - 1900;
                                t.tm_mon = month - 1;
                                t.tm_mday = day;
                                t.tm_hour = hour;
                                t.tm_min = min;
                                t.tm_sec = sec;
                                return 1000L * cast(ulong) mktime(&t) + ms;
                        }

                        /*******************************************************

                                Set fields to represent the provided epoch 
                                time


                        *******************************************************/

                        void setUtcTime (ulong time)
                        {
                                ms = time % 1000;                                
                                int utc = time / 1000;

                                synchronized (Epoch.classinfo)
                                             {
                                             tm* t = gmtime (&utc);
                                             assert (t);

                                             year = t.tm_year + 1900;
                                             month = t.tm_mon + 1;
                                             day = t.tm_mday;
                                             hour = t.tm_hour;
                                             min = t.tm_min;
                                             sec = t.tm_sec;
                                             dow = t.tm_wday;                        
                                             }
                        }

                        /*******************************************************

                                Set fields to represent a localized version
                                of the provided epoch time 

                        *******************************************************/

                        void setLocalTime (ulong time)
                        {
                                ms = time % 1000;                                
                                int utc = time / 1000;

                                synchronized (Epoch.classinfo)
                                             {
                                             tm* t = localtime (&utc);
                                             year = t.tm_year + 1900;
                                             month = t.tm_mon + 1;
                                             day = t.tm_mday;
                                             hour = t.tm_hour;
                                             min = t.tm_min;
                                             sec = t.tm_sec;
                                             dow = t.tm_wday;                        
                                             }
                        }
                }
        }


        /***********************************************************************
                
                        Utc time this executable started 

        ***********************************************************************/

        final static ulong startTime ()
        {
                return beginTime;
        }

        /***********************************************************************
                
                Throw an exception 

        ***********************************************************************/

        static void exception (char[] msg)
        {
                throw new Exception (msg);
        }

        
        /***********************************************************************
                        
                Basic functions for epoch time

        ***********************************************************************/

        version (Win32)
        {
                private static ulong epochOffset;

                /***************************************************************
                
                        Construct an offset representing epoch time

                ***************************************************************/

                static this ()
                {
                        SYSTEMTIME sTime;
                        FILETIME   fTime;

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

                        epochOffset = (cast(ulong) fTime.dwHighDateTime) << 32 | 
                                                   fTime.dwLowDateTime;
                        beginTime = utcMilli();
                }

                /***************************************************************
                
                        Return the current time as UTC milliseconds since 
                        the epoch

                ***************************************************************/

                static ulong utcMilli ()
                {
                        return utcMicro / 1000;
                }

                /***************************************************************
                
                        Return the current time as UTC milliseconds since 
                        the epoch

                ***************************************************************/

                static ulong utcMicro ()
                {
                        FILETIME fTime;

                        GetSystemTimeAsFileTime (&fTime);
                        ulong tmp = (cast(ulong) fTime.dwHighDateTime) << 32 | 
                                                 fTime.dwLowDateTime;

                        // convert to nanoseconds
                        return (tmp - epochOffset) / 10;
                }

                /***************************************************************
                
                        Return the timezone minutes relative to GMT

                ***************************************************************/

                static int tzMinutes ()
                {
                        TIME_ZONE_INFORMATION tz;

                        int ret = GetTimeZoneInformation (&tz);
                        return -tz.Bias;
                }

                /***************************************************************
                
                        Convert filetime to epoch time
                         
                ***************************************************************/

                private static ulong fromFileTime (FILETIME* ft)
                {
                        ulong tmp = (cast(ulong) ft.dwHighDateTime) << 32 | 
                                                 ft.dwLowDateTime;

                        // convert to milliseconds
                        return (tmp - epochOffset) / 10_000;
                }

                /***************************************************************
                
                        convert epoch time to file time

                ***************************************************************/

                private static void toFileTime (FILETIME* ft, ulong ms)
                {
                        ms = ms * 10_000 + epochOffset;

                        ft.dwHighDateTime = cast(uint) (ms >> 32); 
                        ft.dwLowDateTime  = cast(uint) (ms & 0xFFFFFFFF);
                }
        }


        /***********************************************************************
                        
        ***********************************************************************/

        version (Posix)
        {
                // these are exposed via tango.stdc.time
                //extern (C) int timezone;
                //extern (C) int daylight;

                /***************************************************************
                
                        set start time

                ***************************************************************/

                static this()
                {
                        beginTime = utcMilli();
                }

                /***************************************************************
                
                        Return the current time as UTC milliseconds since 
                        the epoch. 

                ***************************************************************/

                static ulong utcMilli ()
                {
                        return utcMicro / 1000;
                }

                /***************************************************************
                
                        Return the current time as UTC microseconds since 
                        the epoch. 

                ***************************************************************/

                static ulong utcMicro ()
                {
                        timeval tv;

                        if (gettimeofday (&tv, null))
                            exception ("Epoch.utcMicro :: linux timer is not available");

                        return 1_000_000L * cast(ulong) tv.tv_sec + tv.tv_usec;
                }

                /***************************************************************
                
                        Return the timezone minutes relative to GMT

                ***************************************************************/

                static int tzMinutes ()
                {
                        return -timezone / 60;
                }
        }
}

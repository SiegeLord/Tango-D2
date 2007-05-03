/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Feb 2007: Initial release
        
        author:         Kris

        Common types used by Tango

*******************************************************************************/

module tango.core.Type;

/******************************************************************************

        Represents UTC time relative to Jan 1st, 0 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. These Time values are the foundation of most 
        time & date functionality in Tango.

******************************************************************************/

public enum Time : long 
{
        TicksPerMillisecond = 10000,
        TicksPerSecond = TicksPerMillisecond * 1000,
        TicksPerMinute = TicksPerSecond * 60,
        TicksPerHour = TicksPerMinute * 60,
        TicksPerDay = TicksPerHour * 24,
        
        MillisPerSecond = 1000,
        MillisPerMinute = MillisPerSecond * 60,
        MillisPerHour = MillisPerMinute * 60,
        MillisPerDay = MillisPerHour * 24,
        
        DaysPerYear = 365,
        DaysPer4Years = DaysPerYear * 4 + 1,
        DaysPer100Years = DaysPer4Years * 25 - 1,
        DaysPer400Years = DaysPer100Years * 4 + 1,
        
        DaysTo1601 = DaysPer400Years * 4,
        DaysTo10000 = DaysPer400Years * 25 - 366,
        
        TicksTo1601 = DaysTo1601 * TicksPerDay,
        TicksTo1970 = 116444736000000000L + TicksTo1601,
}

/******************************************************************************

        Interval is another type of time period, used for measuring a
        much shorter duration; typically used for timeout periods and
        for high-resolution timers. These intervals are measured in
        units of 1 second and support fractions (0.001 = 1ms). 

******************************************************************************/

public alias float Interval;


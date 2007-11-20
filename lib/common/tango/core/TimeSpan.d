/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Feb 2007: Initial release
        
        author:         Steve Schveighoffer

        Common types used by Tango

*******************************************************************************/

module tango.core.TimeSpan;

struct TimeSpan
{
        long ticks;

        //
        // useful constants
        //
        public enum : long 
        {
                NanosecondsPerTick = 100,
                TicksPerMicrosecond = 1000 / NanosecondsPerTick,
                TicksPerMillisecond = 1000 * TicksPerMicrosecond,
                TicksPerSecond = 1000 * TicksPerMillisecond,
                TicksPerMinute = 60 * TicksPerSecond,
                TicksPerHour = 60 * TicksPerMinute,
                TicksPerDay = 24 * TicksPerHour,

                MillisPerSecond = 1000,
                MillisPerMinute = MillisPerSecond * 60,
                MillisPerHour = MillisPerMinute * 60,
                MillisPerDay = MillisPerHour * 24,

                DaysPerYear = 365,
                DaysPer4Years = DaysPerYear * 4 + 1,
                DaysPer100Years = DaysPer4Years * 25 - 1,
                DaysPer400Years = DaysPer100Years * 4 + 1,
        }

        static const TimeSpan microsecond = {TicksPerMicrosecond},
                              millisecond = {TicksPerMillisecond},
                              second = {TicksPerSecond},
                              minute = {TicksPerMinute},
                              hour = {TicksPerHour},
                              day = {TicksPerDay},
                              year = {DaysPerYear * TicksPerDay},
                              fourYears = {DaysPer4Years * TicksPerDay},
                              hundredYears = {DaysPer100Years * TicksPerDay},
                              fourHundredYears = {DaysPer400Years * TicksPerDay},

                              min = {long.min},
                              max = {long.max},
                              zero ={0};

        alias microsecond us;
        alias millisecond ms;

        //
        // common operators
        //
        bool opEquals(TimeSpan t)
        {
                return ticks is t.ticks;
        }

        int opCmp(TimeSpan t)
        {
                return cast(int)((ticks - t.ticks) >>> 32);
        }

        TimeSpan opAdd(TimeSpan t)
        {
                return TimeSpan(ticks + t.ticks);
        }

        TimeSpan opAddAssign(TimeSpan t)
        {
                ticks += t.ticks;
                return *this;
        }

        TimeSpan opSub(TimeSpan t)
        {
                return TimeSpan(ticks - t.ticks);
        }

        TimeSpan opSubAssign(TimeSpan t)
        {
                ticks -= t.ticks;
                return *this;
        }

        TimeSpan opMul(long v)
        {
                return TimeSpan(ticks * v);
        }

        TimeSpan opMulAssign(long v)
        {
                ticks *= v;
                return *this;
        }

        //
        // should not be used for scaling to certain units.
        //
        TimeSpan opDiv(long v)
        {
                return TimeSpan(ticks / v);
        }

        TimeSpan opDivAssign(long v)
        {
                ticks /= v;
                return *this;
        }

        long opDiv(TimeSpan t)
        {
                return ticks / t.ticks;
        }

        //
        // conversion routines.  Converts to the specific measure.  This
        // returns the full amount of time in the given measure.  For example,
        // if a timespan represents 1.5 seconds, milliseconds() returns 1500,
        // not 500.
        //
        long nanoseconds()
        {
                return ticks * NanosecondsPerTick;
        }

        long microseconds()
        {
                return ticks / us.ticks;
        }

        long milliseconds()
        {
                return ticks / ms.ticks;
        }

        long seconds()
        {
                return ticks / second.ticks;
        }

        long minutes()
        {
                return ticks / minute.ticks;
        }

        long hours()
        {
                return ticks / hour.ticks;
        }

        long days()
        {
                return ticks / day.ticks;
        }

        //
        //  Construction routines.  Build a timespan from common measurements
        //
        static TimeSpan nanoseconds(long value)
        {
                return TimeSpan(value / NanosecondsPerTick);
        }

        static TimeSpan microseconds(long value)
        {
                return TimeSpan(us.ticks * value);
        }

        static TimeSpan milliseconds(long value)
        {
                return TimeSpan(ms.ticks * value);
        }

        static TimeSpan seconds(long value)
        {
                return TimeSpan(value * second.ticks);
        }

        static TimeSpan minutes(long value)
        {
                return TimeSpan(minute.ticks * value);
        }

        static TimeSpan hours(long value)
        {
                return TimeSpan(hour.ticks * value);
        }

        static TimeSpan days(long value)
        {
                return TimeSpan(day.ticks * value);
        }

        static TimeSpan interval(double sec)
        {
                return TimeSpan(cast(long)(sec * second.ticks));
        }
}

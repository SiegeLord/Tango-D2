/**
 * copyright:  Copyright (c) 2007 Steven Schveighoffer . All rights reserved
 * license:        BSD style: $(LICENSE)
 * version:        Nov 2007: Initial release
 * author:         Steve Schveighoffer
 *
 * TimeSpan represents a length of time
 */

module tango.util.time.TimeSpan;

/**
 * This struct represents a length of time.  The underlying representation is
 * in units of 100ns.  This allows the length of time to span to roughly
 * +/- 10000 years.
 *
 * Notably missing from this is a representation of weeks, months and years.
 * This is because weeks, months, and years vary according to local calendars.
 * Use tango.util.time.* to deal with these concepts.
 *
 * Note: nobody should change this struct without really good reason as it is
 * required to be a part of some interfaces.  It should be treated as a
 * builtin type.
 *
 * Example:
 * -------------------
 *
 * DateTime start = DateTime.now;
 * Thread.sleep(TimeSpan.seconds(10));
 * Stdout.format("slept for {} ms",
 *    (start - * DateTime.now).milliseconds).newline;
 * -------------------
 * See_Also: tango.core.Thread, tango.util.time.DateTime
 */
struct TimeSpan
{
        /**
         * The internal representation.  This is the only member of the struct
         * that is part of the instance.
         */
        long ticks;

        //
        // useful constants.  Shouldn't be used in normal code, use the
        // static TimeSpan members below instead.  i.e. instead of
        // TimeSpan.TicksPerSecond, use TimeSpan.second.ticks
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

        /**
         * Useful constant TimeSpans.  Provides a TimeSpan that represents the
         * measurement of the same name.
         */
        static const TimeSpan microsecond = {TicksPerMicrosecond},
                              millisecond = {TicksPerMillisecond},
                              second = {TicksPerSecond},
                              minute = {TicksPerMinute},
                              hour = {TicksPerHour},
                              day = {TicksPerDay};

        //
        // these shouldn't be used in normal code, but are here for
        // convenience for other code to use.
        //
        static const TimeSpan year = {DaysPerYear * TicksPerDay},
                              fourYears = {DaysPer4Years * TicksPerDay},
                              hundredYears = {DaysPer100Years * TicksPerDay},
                              fourHundredYears = {DaysPer400Years * TicksPerDay};

        /**
         * Minimum TimeSpan
         */
        static const TimeSpan min  = {long.min};

        /**
         * Maximum TimeSpan
         */
        static const TimeSpan max  = {long.max};

        /**
         * Zero TimeSpan.  Useful for comparisons.
         */
        static const TimeSpan zero = {0};

        /**
         * Alias for microsecond
         */
        alias microsecond us;
        /**
         * Alias for millisecond
         */
        alias millisecond ms;

        /**
         * Determines whether two TimeSpan values are equal
         */
        bool opEquals(TimeSpan t)
        {
                return ticks is t.ticks;
        }

        /**
         * Compares this object against another TimeSpan value.
         */
        int opCmp(TimeSpan t)
        {
                return cast(int)((ticks - t.ticks) >>> 32);
        }

        /**
         * Add the TimeSpan given to this TimeSpan returning a new TimeSpan.
         *
         * Params: t = A TimeSpan value to add
         * Returns: A TimeSpan value that is the sum of this instance and t.
         */
        TimeSpan opAdd(TimeSpan t)
        {
                return TimeSpan(ticks + t.ticks);
        }

        /**
         * Add the specified TimeSpan to this TimeSpan, assigning the result
         * to this instance.
         *
         * Params: t = A TimeSpan value to add
         * Returns: a copy of this instance after adding t.
         */
        TimeSpan opAddAssign(TimeSpan t)
        {
                ticks += t.ticks;
                return *this;
        }

        /**
         * Subtract the specified TimeSpan from this TimeSpan.
         *
         * Params: t = A TimeSpan to subtract
         * Returns: A new timespan which is the difference between this
         * instance and t
         */
        TimeSpan opSub(TimeSpan t)
        {
                return TimeSpan(ticks - t.ticks);
        }

        /**
         *
         * Subtract the specified TimeSpan from this TimeSpan and assign the
         * value to this TimeSpan.
         *
         * Params: t = A TimeSpan to subtract
         * Returns: A copy of this instance after subtracting t.
         */
        TimeSpan opSubAssign(TimeSpan t)
        {
                ticks -= t.ticks;
                return *this;
        }

        /**
         * Scale the TimeSpan by the specified amount.  This should not be
         * used to convert to a different unit.  Use the unit accessors
         * instead.  This should only be used as a scaling mechanism.  For
         * example, if you have a timeout and you want to sleep for twice the
         * timeout, you would use timeout * 2.
         *
         * Params: v = A multiplier to use for scaling this time span.
         * Returns: A new TimeSpan that is scaled by v
         */
        TimeSpan opMul(long v)
        {
                return TimeSpan(ticks * v);
        }

        /**
         * Scales this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for scaling
         * Returns: A copy of this instance after scaling
         */
        TimeSpan opMulAssign(long v)
        {
                ticks *= v;
                return *this;
        }

        /**
         * Divide the TimeSpan by the specified amount.  This should not be
         * used to convert to a different unit.  Use the unit accessors
         * instead.  This should only be used as a scaling mechanism.  For
         * example, if you have a timeout and you want to sleep for half the
         * timeout, you would use timeout / 2.
         *
         *
         * Params: v = A divisor to use for scaling this time span.
         * Returns: A new TimeSpan that is divided by v
         */
        TimeSpan opDiv(long v)
        {
                return TimeSpan(ticks / v);
        }

        /**
         * Divides this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for dividing
         * Returns: A copy of this instance after dividing
         */
        TimeSpan opDivAssign(long v)
        {
                ticks /= v;
                return *this;
        }

        /**
         * Perform integer division with the given time span.
         *
         * Params: t = A divisor used for dividing
         * Returns: The result of integer division between this instance and
         * t.
         */
        long opDiv(TimeSpan t)
        {
                return ticks / t.ticks;
        }

        /**
         * Convert to nanoseconds
         *
         * Note: this may incur loss of data because nanoseconds cannot
         * represent the range of data a TimeSpan can represent.
         *
         * Returns: The number of nanoseconds that this TimeSpan represents.
         */
        long nanoseconds()
        {
                return ticks * NanosecondsPerTick;
        }

        /**
         * Convert to microseconds
         *
         * Returns: The number of microseconds that this TimeSpan represents.
         */
        long microseconds()
        {
                return ticks / us.ticks;
        }

        /**
         * Convert to milliseconds
         *
         * Returns: The number of milliseconds that this TimeSpan represents.
         */
        long milliseconds()
        {
                return ticks / ms.ticks;
        }

        /**
         * Convert to seconds
         *
         * Returns: The number of seconds that this TimeSpan represents.
         */
        long seconds()
        {
                return ticks / second.ticks;
        }

        /**
         * Convert to minutes
         *
         * Returns: The number of minutes that this TimeSpan represents.
         */
        long minutes()
        {
                return ticks / minute.ticks;
        }

        /**
         * Convert to hours
         *
         * Returns: The number of hours that this TimeSpan represents.
         */
        long hours()
        {
                return ticks / hour.ticks;
        }

        /**
         * Convert to days
         *
         * Returns: The number of days that this TimeSpan represents.
         */
        long days()
        {
                return ticks / day.ticks;
        }

        /**
         * Convert to a floating point interval representing seconds.
         *
         * Note: This may cause a loss of precision as a double cannot exactly
         * represent some fractional values.
         *
         * Returns: An interval representing the seconds and fractional
         * seconds that this TimeSpan represents.
         */
        double interval()
        {
                return cast(double)ticks * TicksPerSecond;
        }

        /**
         * Construct a TimeSpan from the given number of nanoseconds
         *
         * Note: This may cause a loss of data since a TimeSpan's resolution
         * is in 100ns increments.
         *
         * Params: value = The number of nanoseconds.
         * Returns: A TimeSpan representing the given number of nanoseconds.
         */
        static TimeSpan nanoseconds(long value)
        {
                return TimeSpan(value / NanosecondsPerTick);
        }

        /**
         * Construct a TimeSpan from the given number of microseconds
         *
         * Params: value = The number of microseconds.
         * Returns: A TimeSpan representing the given number of microseconds.
         */
        static TimeSpan microseconds(long value)
        {
                return TimeSpan(us.ticks * value);
        }

        /**
         * Construct a TimeSpan from the given number of milliseconds
         *
         * Params: value = The number of milliseconds.
         * Returns: A TimeSpan representing the given number of milliseconds.
         */
        static TimeSpan milliseconds(long value)
        {
                return TimeSpan(ms.ticks * value);
        }

        /**
         * Construct a TimeSpan from the given number of seconds
         *
         * Params: value = The number of seconds.
         * Returns: A TimeSpan representing the given number of seconds.
         */
        static TimeSpan seconds(long value)
        {
                return TimeSpan(value * second.ticks);
        }

        /**
         * Construct a TimeSpan from the given number of minutes
         *
         * Params: value = The number of minutes.
         * Returns: A TimeSpan representing the given number of minutes.
         */
        static TimeSpan minutes(long value)
        {
                return TimeSpan(minute.ticks * value);
        }

        /**
         * Construct a TimeSpan from the given number of hours
         *
         * Params: value = The number of hours.
         * Returns: A TimeSpan representing the given number of hours.
         */
        static TimeSpan hours(long value)
        {
                return TimeSpan(hour.ticks * value);
        }

        /**
         * Construct a TimeSpan from the given number of days
         *
         * Params: value = The number of days.
         * Returns: A TimeSpan representing the given number of days.
         */
        static TimeSpan days(long value)
        {
                return TimeSpan(day.ticks * value);
        }

        /**
         * Construct a TimeSpan from the given interval.  The interval
         * represents seconds as a double.  This allows both whole and
         * fractional seconds to be passed in.
         *
         * Note: The result cause loss of data due to a TimeSpan not being
         * able to represent all values a double can represent.  In addition,
         * the result may not exactly represent the given input due to
         * floating point error.
         *
         * Params: value = The interval to convert in seconds.
         * Returns: A TimeSpan representing the given interval.
         */
        static TimeSpan interval(double sec)
        {
                return TimeSpan(cast(long)(sec * second.ticks));
        }

}

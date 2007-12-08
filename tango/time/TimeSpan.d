/**
 * copyright:  Copyright (c) 2007 Steven Schveighoffer . All rights reserved
 * license:        BSD style: $(LICENSE)
 * version:        Nov 2007: Initial release
 * author:         Steve Schveighoffer
 *
 * TimeSpan represents a length of time
 */

module tango.time.TimeSpan;

/**
 * This struct represents a length of time.  The underlying representation is
 * in units of 100ns.  This allows the length of time to span to roughly
 * +/- 10000 years.
 *
 * Notably missing from this is a representation of weeks, months and years.
 * This is because weeks, months, and years vary according to local calendars.
 * Use tango.time.chrono.* to deal with these concepts.
 *
 * Note: nobody should change this struct without really good reason as it is
 * required to be a part of some interfaces.  It should be treated as a
 * builtin type.
 *
 * Example:
 * -------------------
 *
 * Time start = Clock.now;
 * Thread.sleep(TimeSpan.millis(150).interval);
 * Stdout.format("slept for {} ms",
 *    (start - Clock.now).millis).newline;
 * -------------------
 * See_Also: tango.core.Thread, tango.time.Time, tango.time.Clock
 */
struct TimeSpan
{
        // this is the only member of the struct.
        package long ticks_;

        // useful constants.  Shouldn't be used in normal code, use the
        // static TimeSpan members below instead.  i.e. instead of
        // TimeSpan.TicksPerSecond, use TimeSpan.second.ticks
        //
        enum : long 
        {
                /// basic tick values
                NanosecondsPerTick  = 100,
                TicksPerMicrosecond = 1000 / NanosecondsPerTick,
                TicksPerMillisecond = 1000 * TicksPerMicrosecond,
                TicksPerSecond      = 1000 * TicksPerMillisecond,
                TicksPerMinute      = 60 * TicksPerSecond,
                TicksPerHour        = 60 * TicksPerMinute,
                TicksPerDay         = 24 * TicksPerHour,

                // millisecond counts
                MillisPerSecond     = 1000,
                MillisPerMinute     = MillisPerSecond * 60,
                MillisPerHour       = MillisPerMinute * 60,
                MillisPerDay        = MillisPerHour * 24,

                /// day counts
                DaysPerYear         = 365,
                DaysPer4Years       = DaysPerYear * 4 + 1,
                DaysPer100Years     = DaysPer4Years * 25 - 1,
                DaysPer400Years     = DaysPer100Years * 4 + 1,

                // epoch counts
                Epoch1601           = DaysPer400Years * 4 * TicksPerDay,
                Epoch1970           = Epoch1601 + TicksPerSecond * 11644473600L,
        }
/+
        enum Tick : long 
        {
                Micro  = TicksPerMicrosecond,     
                Milli  = TicksPerMillisecond,
                Second = TicksPerSecond,
                Minute = TicksPerMinute,
                Hour   = TicksPerHour,
                Day    = TicksPerDay
        }

        enum Milli : long 
        {
                Second = 1000,
                Minute = Second * 60,
                Hour   = Minute * 60,
                Day    = Hour * 24
        }

        enum Day : long 
        {
                Year    = 365,
                Year4   = Year * 4 + 1,
                Year100 = Year4 * 25 - 1,
                Year400 = Year100 * 4 + 1
        }

        /**
         * Useful constant TimeSpans.  Provides a TimeSpan that represents the
         * measurement of the same name.
         */

        // NOTE: const is not manifest-constant, so the use of these makes
        // for less efficient codegen. I've removed them for now
        static const TimeSpan microsecond = {TicksPerMicrosecond},
                              millisecond = {TicksPerMillisecond},
                              second      = {TicksPerSecond},
                              minute      = {TicksPerMinute},
                              hour        = {TicksPerHour},
                              day         = {TicksPerDay};

        //
        // these shouldn't be used in normal code, but are here for
        // convenience for other code to use.
        //
        static const TimeSpan year = {DaysPerYear * TicksPerDay},
                              fourYears = {DaysPer4Years * TicksPerDay},
                              hundredYears = {DaysPer100Years * TicksPerDay},
                              fourHundredYears = {DaysPer400Years * TicksPerDay};

+/

        /**
         * Minimum TimeSpan
         */
        static const TimeSpan min = {long.min};

        /**
         * Maximum TimeSpan
         */
        static const TimeSpan max = {long.max};

        /**
         * Zero TimeSpan.  Useful for comparisons.
         */
        static const TimeSpan zero = {0};

        /**
         * Get the number of ticks that this timespan represents.
         */
        long ticks()
        {
                return ticks_;
        }

        /**
         * Determines whether two TimeSpan values are equal
         */
        bool opEquals(TimeSpan t)
        {
                return ticks_ is t.ticks_;
        }

        /**
         * Compares this object against another TimeSpan value.
         */
        int opCmp(TimeSpan t)
        {
                if (ticks_ < t.ticks_)
                    return -1;

                if (ticks_ > t.ticks_)
                    return 1;

                return 0;
        }

        /**
         * Add the TimeSpan given to this TimeSpan returning a new TimeSpan.
         *
         * Params: t = A TimeSpan value to add
         * Returns: A TimeSpan value that is the sum of this instance and t.
         */
        TimeSpan opAdd(TimeSpan t)
        {
                return TimeSpan(ticks_ + t.ticks_);
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
                ticks_ += t.ticks_;
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
                return TimeSpan(ticks_ - t.ticks_);
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
                ticks_ -= t.ticks_;
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
                return TimeSpan(ticks_ * v);
        }

        /**
         * Scales this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for scaling
         * Returns: A copy of this instance after scaling
         */
        TimeSpan opMulAssign(long v)
        {
                ticks_ *= v;
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
                return TimeSpan(ticks_ / v);
        }

        /**
         * Divides this TimeSpan and assigns the result to this instance.
         *
         * Params: v = A multipler to use for dividing
         * Returns: A copy of this instance after dividing
         */
        TimeSpan opDivAssign(long v)
        {
                ticks_ /= v;
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
                return ticks_ / t.ticks;
        }

        /**
         * Negate a time span
         *
         * Returns: The negative equivalent to this time span
         */
        TimeSpan opNeg()
        {
                return TimeSpan(-ticks_);
        }

        /**
         * Convert to nanoseconds
         *
         * Note: this may incur loss of data because nanoseconds cannot
         * represent the range of data a TimeSpan can represent.
         *
         * Returns: The number of nanoseconds that this TimeSpan represents.
         */
        long nanos()
        {
                return ticks_ * NanosecondsPerTick;
        }

        /**
         * Convert to microseconds
         *
         * Returns: The number of microseconds that this TimeSpan represents.
         */
        long micros()
        {
                return ticks_ / TicksPerMicrosecond;
        }

        /**
         * Convert to milliseconds
         *
         * Returns: The number of milliseconds that this TimeSpan represents.
         */
        long millis()
        {
                return ticks_ / TicksPerMillisecond;
        }

        /**
         * Convert to seconds
         *
         * Returns: The number of seconds that this TimeSpan represents.
         */
        long seconds()
        {
                return ticks_ / TicksPerSecond;
        }

        /**
         * Convert to minutes
         *
         * Returns: The number of minutes that this TimeSpan represents.
         */
        long minutes()
        {
                return ticks_ / TicksPerMinute;
        }

        /**
         * Convert to hours
         *
         * Returns: The number of hours that this TimeSpan represents.
         */
        long hours()
        {
                return ticks_ / TicksPerHour;
        }

        /**
         * Convert to days
         *
         * Returns: The number of days that this TimeSpan represents.
         */
        long days()
        {
                return ticks_ / TicksPerDay;
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
                return (cast(double) ticks_) / TicksPerSecond;
        }

        /**
         * Convert to TimeOfDay
         *
         * Returns: the TimeOfDay this TimeSpan represents.
         */
        TimeOfDay time()
        {
                return TimeOfDay(ticks_);
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
        static TimeSpan nanos(long value)
        {
                return TimeSpan(value / NanosecondsPerTick);
        }

        /**
         * Construct a TimeSpan from the given number of microseconds
         *
         * Params: value = The number of microseconds.
         * Returns: A TimeSpan representing the given number of microseconds.
         */
        static TimeSpan micros(long value)
        {
                return TimeSpan(TicksPerMicrosecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of milliseconds
         *
         * Params: value = The number of milliseconds.
         * Returns: A TimeSpan representing the given number of milliseconds.
         */
        static TimeSpan millis(long value)
        {
                return TimeSpan(TicksPerMillisecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of seconds
         *
         * Params: value = The number of seconds.
         * Returns: A TimeSpan representing the given number of seconds.
         */
        static TimeSpan seconds(long value)
        {
                return TimeSpan(TicksPerSecond * value);
        }

        /**
         * Construct a TimeSpan from the given number of minutes
         *
         * Params: value = The number of minutes.
         * Returns: A TimeSpan representing the given number of minutes.
         */
        static TimeSpan minutes(long value)
        {
                return TimeSpan(TicksPerMinute * value);
        }

        /**
         * Construct a TimeSpan from the given number of hours
         *
         * Params: value = The number of hours.
         * Returns: A TimeSpan representing the given number of hours.
         */
        static TimeSpan hours(long value)
        {
                return TimeSpan(TicksPerHour * value);
        }

        /**
         * Construct a TimeSpan from the given number of days
         *
         * Params: value = The number of days.
         * Returns: A TimeSpan representing the given number of days.
         */
        static TimeSpan days(long value)
        {
                return TimeSpan(TicksPerDay * value);
        }

        /**
         * Construct a TimeSpan from the given interval.  The interval
         * represents seconds as a double.  This allows both whole and
         * fractional seconds to be passed in.
         *
         * Params: value = The interval to convert in seconds.
         * Returns: A TimeSpan representing the given interval.
         */
        static TimeSpan interval(double sec)
        {
                return TimeSpan(cast(long)(sec * TicksPerSecond + .1));
        }
}



/******************************************************************************

        Represents a time of day. This is different from TimeSpan in that 
        each component is represented within the limits of everyday time, 
        rather than from the start of time. Effectively, the TimeOfDay
        epoch is the first second of each day.

        This is handy for dealing strictly with a 24-hour clock instead of
        potentially thousands of years. For example:
        ---
        auto time = Clock.now.time;
        assert (time.millis < 1000);
        assert (time.seconds < 60);
        assert (time.minutes < 60);
        assert (time.hours < 24);
        ---

        You can create a TimeOfDay from an existing Time or TimeSpan instance
        via the respective time() method. To convert back to a TimeSpan, use
        the span() method

******************************************************************************/

struct TimeOfDay 
{
        private long ticks;

        /**********************************************************************

                $(I Property.) Retrieves the equivalent TimeSpan.

                Returns: A TimeSpan representing this TimeOfDay.

        **********************************************************************/

        TimeSpan span () 
        {
                return TimeSpan (ticks);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _hour component of the time.

                Returns: The _hour.

        **********************************************************************/

        int hours () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerHour) % 24);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _minute component of the time.

                Returns: The _minute.

        **********************************************************************/

        int minutes () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerMinute) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _second component of the time.

                Returns: The _second.

        **********************************************************************/

        int seconds () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerSecond) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _millisecond component of the 
                time.

                Returns: The _milliseconds.

        **********************************************************************/

        int millis () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerMillisecond) % 1000);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _microsecond component of the 
                time.

                Returns: The _microseconds.

        **********************************************************************/

        int micros () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerMicrosecond) % 1000);
        }
}


debug (UnitTest)
{
        unittest
        {
                assert(TimeSpan.zero > TimeSpan.min);
                assert(TimeSpan.max  > TimeSpan.zero);
                assert(TimeSpan.max  > TimeSpan.min);
                assert(TimeSpan.zero >= TimeSpan.zero);
                assert(TimeSpan.zero <= TimeSpan.zero);
                assert(TimeSpan.max >= TimeSpan.max);
                assert(TimeSpan.max <= TimeSpan.max);
                assert(TimeSpan.min >= TimeSpan.min);
                assert(TimeSpan.min <= TimeSpan.min);

                assert (TimeSpan.micros(999).micros is 999);
                assert (TimeSpan.micros(1999).micros is 1999);
                assert (TimeSpan.seconds(50).seconds is 50);
                assert (TimeSpan.seconds(5000).seconds is 5000);
                assert (TimeSpan.minutes(50).minutes is 50);
                assert (TimeSpan.minutes(5000).minutes is 5000);
                assert (TimeSpan.hours(23).hours is 23);
                assert (TimeSpan.hours(5000).hours is 5000);
                assert (TimeSpan.days(6).days is 6);
                assert (TimeSpan.days(5000).days is 5000);

                assert (TimeSpan.micros(999).time.micros is 999);
                assert (TimeSpan.micros(1999).time.micros is 999);
                assert (TimeSpan.seconds(50).time.seconds is 50);
                assert (TimeSpan.seconds(5000).time.seconds is 5000 % 60);
                assert (TimeSpan.minutes(50).time.minutes is 50);
                assert (TimeSpan.minutes(5000).time.minutes is 5000 % 60);
                assert (TimeSpan.hours(23).time.hours is 23);
                assert (TimeSpan.hours(5000).time.hours is 5000 % 24);
        }
}


debug (TimeSpan)
{
        import tango.time.Clock;

        void main()
        {
                auto time = Clock.now.time;
                assert (time.seconds < 60);

                auto t = TimeSpan(1);
                auto h = t.hours;
                auto m = t.time.minutes;
        }
}

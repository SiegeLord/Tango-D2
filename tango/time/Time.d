/******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        mid 2005: Initial release
                        Apr 2007: heavily reshaped
                        Dec 2007: moved to tango.time

        author:         Chapman, Kris, scheivguy

******************************************************************************/

module tango.time.Time;

public import tango.time.TimeSpan;

/******************************************************************************

        Represents a point in time.

        Remarks: Time represents dates and times between 12:00:00 
        midnight on January 1, 10000 BC and 11:59:59 PM on December 31, 
        9999 AD.

        Time values are measured in 100-nanosecond intervals, or ticks. 
        A date value is the number of ticks that have elapsed since 
        12:00:00 midnight on January 1, 0001 AD in the Gregorian 
        calendar.
        
        Negative Time values are offsets from that same reference point, 
        but backwards in history.  Time values are not specific to any 
        calendar, but for an example, the beginning of December 31, 1 BC 
        in the Gregorian calendar is Time.epoch - TimeSpan.days(1).

******************************************************************************/

struct Time 
{
        private long ticks_;

        private enum : long
        {
                maximum = (TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1,
                minimum = -((TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1),
        }

        /// Represents the smallest and largest Time value.
        static const Time min       = {minimum},
                          max       = {maximum},
                          epoch     = {0},
                          epoch1601 = {TimeSpan.Epoch1601},
                          epoch1970 = {TimeSpan.Epoch1970};

        /**********************************************************************

                $(I Property.) Retrieves the number of ticks for this Time

                Returns: A long represented by the time of this 
                         instance.

        **********************************************************************/

        long ticks ()
        {
                return ticks_;
        }

        /**********************************************************************

                Determines whether two Time values are equal.

                Params:  value = A Time _value.
                Returns: true if both instances are equal; otherwise, false

        **********************************************************************/

        int opEquals (Time t) 
        {
                return ticks_ is t.ticks_;
        }

        /**********************************************************************

                Compares two Time values.

        **********************************************************************/

        int opCmp (Time t) 
        {
                if (ticks_ < t.ticks_)
                    return -1;

                if (ticks_ > t.ticks_)
                    return 1;

                return 0;
        }

        /**********************************************************************

                Adds the specified time span to the time, returning a new
                time.
                
                Params:  t = A TimeSpan value.
                Returns: A Time that is the sum of this instance and t.

        **********************************************************************/

        Time opAdd (TimeSpan t) 
        {
                return Time (ticks_ + t.ticks_);
        }

        /**********************************************************************

                Adds the specified time span to the time, assigning 
                the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t added to the 
                         time.

        **********************************************************************/

        Time opAddAssign (TimeSpan t) 
        {
                ticks_ += t.ticks_;
                return *this;
        }

        /**********************************************************************

                Subtracts the specified time span from the time, 
                returning a new time.

                Params:  t = A TimeSpan value.
                Returns: A Time whose value is the value of this instance 
                         minus the value of t.

        **********************************************************************/

        Time opSub (TimeSpan t) 
        {
                return Time (ticks_ - t.ticks_);
        }

        /**********************************************************************

                Returns a time span which represents the difference in time
                between this and the given Time.

                Params:  t = A Time value.
                Returns: A TimeSpan which represents the difference between
                         this and t.

        **********************************************************************/

        TimeSpan opSub (Time t)
        {
                return TimeSpan(ticks_ - t.ticks_);
        }

        /**********************************************************************

                Subtracts the specified time span from the time, 
                assigning the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t subtracted 
                         from the time.

        **********************************************************************/

        Time opSubAssign (TimeSpan t) 
        {
                ticks_ -= t.ticks_;
                return *this;
        }

        /**********************************************************************

                $(I Property.) Retrieves the date component.

                Returns: A new Time instance with the same date as 
                         this instance, but with the time trucated.

        **********************************************************************/

        Time date () 
        {
                return *this - TimeOfDay.modulo24(ticks_);
        }

        /**********************************************************************

                $(I Property.) Retrieves the time of day.

                Returns: A TimeOfDay representing the fraction of the day 
                         elapsed since midnight.

        **********************************************************************/

        TimeOfDay time () 
        {
                return TimeOfDay (ticks_);
        }

        /**********************************************************************

                $(I Property.) Retrieves the equivalent TimeSpan.

                Returns: A TimeSpan representing this Time.

        **********************************************************************/

        TimeSpan span () 
        {
                return TimeSpan (ticks_);
        }
}



/*******************************************************************************

*******************************************************************************/

debug (Time)
{
        import tango.io.Stdout;

        Time foo() 
        {
                auto d = Time(10);
                auto e = TimeSpan(20);

                return d + e;
        }

        void main()
        {
                auto c = foo();
                auto h = c.time.minutes;
                Stdout (c.ticks).newline;
        }
}




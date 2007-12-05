/******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        mid 2005: Initial release
                        Apr 2007: heavily reshaped

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.Time;

public  import  tango.util.time.TimeSpan;

// TODO: remove these when clock-like functionality is removed from Time
private import  tango.util.time.Clock,
                tango.util.time.WallClock;

/******************************************************************************

        Represents a point in time.

        Remarks: Time represents dates and times between 12:00:00 
        midnight on January 1, 10000 BC and 11:59:59 PM on December 31, 
        9999 AD.

        Time values are measured in 100-nanosecond intervals, or ticks. 
        A date value is the number of ticks that have elapsed since 
        12:00:00 midnight on January 1, 0001 AD in the Gregorian 
        calendar.
        
        Negative Time values are offsets from that same reference point, but
        backwards in history.  Time values are not specific to any calendar,
        but for an example, the beginning of December 31, 1 B.C. in the
        Gregorian calendar is Time.epoch - TimeSpan.day.


******************************************************************************/

struct Time 
{
        public long ticks;

        // TODO: remove this when deprecated functions are removed
        private package enum 
        {
                Year,
                Month,
                Day,
                DayOfYear
        }

        // TODO: remove this when deprecated functions are removed
        /**
         * Deprecated: use Calendar.DayOfWeek instead
         */
        public enum DayOfWeek 
        {
                Sunday,
                Monday,
                Tuesday,
                Wednesday,
                Thursday,
                Friday,
                Saturday
        }

        /// Represents the smallest and largest Time value.
        public static const Time    epoch = {0},
                                        max = {(TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1},
                                        min = {-((TimeSpan.DaysPer400Years * 25 - 366) * TimeSpan.TicksPerDay - 1)},
                                        epoch1601 = {TimeSpan.DaysPer400Years * 4 * TimeSpan.TicksPerDay},
                                        epoch1970 = {TimeSpan.DaysPer400Years * 4 * TimeSpan.TicksPerDay + TimeSpan.TicksPerSecond * 11644473600L};

        // TODO: remove this when deprecated functions are removed
        private static final int[] DaysToMonthCommon = 
        [
                0, 
                31, 
                59, 
                90, 
                120, 
                151, 
                181, 
                212, 
                243, 
                273, 
                304, 
                334, 
                365
        ];

        // TODO: remove this when deprecated fucntions are removed
        private static final int[] DaysToMonthLeap = 
        [
                0, 
                31, 
                60, 
                91, 
                121, 
                152, 
                182, 
                213, 
                244, 
                274, 
                305, 
                335, 
                366
        ];

        /**********************************************************************

                $(I Constructor.) Initializes a new instance of the 
                Time struct to the specified number of _ticks.         
                
                Params: ticks = A time expressed in units of 
                100 nanoseconds.

        **********************************************************************/

        static Time opCall (long ticks) 
        {
                Time d;
                d.ticks = ticks;
                return d;
        }

        /**********************************************************************
                Deprecated: use an appropriate calendar class instead.

        **********************************************************************/

        deprecated static Time opCall (int year, int month, int day) 
        {
                return opCall (getDateTicks (year, month, day));
        }

        /**********************************************************************
                Deprecated: use WallClock.now.date instead

                $(I Property.) Retrieves the current date.

                Returns: A Time instance set to today's date.

        **********************************************************************/

        deprecated static Time today () 
        {
                return now.date;
        }

        /**********************************************************************
                Deprecated: use WallClock.now instead.

                $(I Property.) Retrieves a Time instance set to the 
                current time in local time.

                Returns: A Time whose value is the current local date 
                         and time.

        **********************************************************************/
        
        deprecated static Time now () 
        {
                return  WallClock.now;
        }

        /**********************************************************************
                Deprecated: use Clock.now instead.

                $(I Property.) Retrieves a Time instance set to the 
                current time in UTC time.

                Returns: A Time whose value is the current UTC date 
                         and time.

        **********************************************************************/

        deprecated static Time utc () 
        {
                return Clock.now;
        }

        /**********************************************************************

                Determines whether two Time values are equal.

                Params:  value = A Time _value.
                Returns: true if both instances are equal; otherwise, false

        **********************************************************************/

        int opEquals (Time t) 
        {
                return ticks is t.ticks;
        }

        /**********************************************************************

                Compares two Time values.

        **********************************************************************/

        int opCmp (Time t) 
        {
                if(ticks < t.ticks)
                        return -1;
                if(ticks > t.ticks)
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
                return Time (ticks + t.ticks);
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
                ticks += t.ticks;
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
                return Time (ticks - t.ticks);
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
                return TimeSpan(ticks - t.ticks);
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
                ticks -= t.ticks;
                return *this;
        }

        /**********************************************************************

                Adds the specified number of ticks to the _value of this 
                instance.
                
                Deprecated: use x + TimeSpan(value) instead.

                Params:  value = The number of ticks to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the time in value.

        **********************************************************************/

        deprecated Time addTicks (long value) 
        {
                return Time (ticks + value);
        }

        /**********************************************************************
                Adds the specified number of hours to the _value of this 
                instance.

                Deprecated: use x + TimeSpan.hours(value) instead.

                Params:  value = The number of hours to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of hours in 
                         value.

        **********************************************************************/

        deprecated Time addHours (int value) 
        {
                return *this + TimeSpan.hours(value);
        }

        /**********************************************************************

                Adds the specified number of minutes to the _value of this 
                instance.

                Deprecated: use x + TimeSpan.minutes(value);

                Params:  value = The number of minutes to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of minutes in 
                         value.

        **********************************************************************/

        deprecated Time addMinutes (int value) 
        {
                return *this + TimeSpan.minutes(value);
        }

        /**********************************************************************

                Adds the specified number of seconds to the _value of this 
                instance.

                Deprecated: use x + TimeSpan.seconds(value) instead.

                Params:  value = The number of seconds to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of seconds in 
                         value.

        **********************************************************************/

        deprecated Time addSeconds (int value) 
        {
                return *this + TimeSpan.seconds(value);
        }

        /**********************************************************************

                Adds the specified number of milliseconds to the _value of 
                this instance.

                Deprecated: use x + TimeSpan.milliseconds(value) instead.

                Params:  value = The number of milliseconds to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of milliseconds 
                         in value.

        **********************************************************************/

        deprecated Time addMilliseconds (long value) 
        {
                return *this + TimeSpan.milliseconds(value);
        }

        /**********************************************************************

                Adds the specified number of days to the _value of this 
                instance.

                Deprecated: use x + TimeSpan.days(value) instead.

                Params:  value = The number of days to add.
                Returns: A Time whose value is the sum of the date 
                         and time of this instance and the number of days 
                         in value.

        **********************************************************************/

        deprecated Time addDays (int value) 
        {
                return *this + TimeSpan.days(value);
        }

        /**********************************************************************
                Deprecated: this is a Calendar function.  Currently there are
                    no functions to do this in Calendar, but there will be

                Adds the specified number of months to the _value of this 
                instance.

                Params:  value = The number of months to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of months in 
                         value.

        **********************************************************************/

        deprecated Time addMonths (int value) 
        {
                int year = this.year;
                int month = this.month;
                int day = this.day;
                int n = month - 1 + value;

                if (n >= 0) 
                   {
                   month = n % 12 + 1;
                   year = year + n / 12;
                   }
                else 
                   {
                   month = 12 + (n + 1) % 12;
                   year = year + (n - 11) / 12;
                   }
                int maxDays = daysInMonth (year, month);
                if (day > maxDays)
                    day = maxDays;

                return Time (getDateTicks(year, month, day) + (ticks % TimeSpan.day.ticks));
        }

        /**********************************************************************
                Deprecated: this is a Calendar function.

                Adds the specified number of years to the _value of this 
                instance.

                Params:  value = The number of years to add.
                Returns: A Time whose value is the sum of the date 
                         and time of this instance and the number of years 
                         in value.

        **********************************************************************/

        deprecated Time addYears (int value) 
        {
                return addMonths (value * 12);
        }

        /**********************************************************************
                Deprecated: use Calendar.year(Time) instead.

                $(I Property.) Retrieves the _year component of the date.

                Returns: The _year.

        **********************************************************************/

        deprecated int year () 
        {
                return extractPart (ticks, Year);
        }

        /**********************************************************************
                Deprecated: use Calendar.month(Time) instead.

                $(I Property.) Retrieves the _month component of the date.

                Returns: The _month.

        **********************************************************************/

        deprecated int month () 
        {
                return extractPart (ticks, Month);
        }

        /**********************************************************************
                Deprecated: use Calendar.day(Time) instead.

                $(I Property.) Retrieves the _day component of the date.

                Returns: The _day.

        **********************************************************************/

        deprecated int day () 
        {
                return extractPart (ticks, Day);
        }

        /**********************************************************************
                Deprecated: use Calendar.dayOfYear(Time) instead.

                $(I Property.) Retrieves the day of the year.

                Returns: The day of the year.

        **********************************************************************/

        deprecated int dayOfYear () 
        {
                return extractPart (ticks, DayOfYear);
        }

        /**********************************************************************
                Deprecated: use Calendar.dayOfWeek(Time) instead.

                $(I Property.) Retrieves the day of the week.

                Returns: A DayOfWeek value indicating the day of the week.

        **********************************************************************/

        deprecated int dayOfWeek () 
        {
                return cast(int) ((ticks / TimeSpan.day.ticks + 1) % 7);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _hour component of the date.

                Returns: The _hour.

        **********************************************************************/

        int hour () 
        {
                return cast(int) ((ticks / TimeSpan.hour.ticks) % 24);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _minute component of the date.

                Returns: The _minute.

        **********************************************************************/

        int minute () 
        {
                return cast(int) ((ticks / TimeSpan.minute.ticks) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _second component of the date.

                Returns: The _second.

        **********************************************************************/

        int second () 
        {
                return cast(int) ((ticks / TimeSpan.second.ticks) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _millisecond component of the 
                date.

                Returns: The _millisecond.

        **********************************************************************/

        int millisecond () 
        {
                return cast(int) ((ticks / TimeSpan.ms.ticks) % 1000);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _microsecond component of the 
                date.

                Returns: The _microsecond.

        **********************************************************************/

        int microsecond () 
        {
                return cast(int) ((ticks / TimeSpan.us.ticks) % 1000);
        }

        /**********************************************************************

                $(I Property.) Retrieves the date component.

                Returns: A new Time instance with the same date as 
                         this instance.

        **********************************************************************/

        Time date () 
        {
                return *this - timeOfDay;
        }

        /**********************************************************************

                $(I Property.) Retrieves the time of day.

                Returns: A Time representing the fraction of the day elapsed since midnight.

        **********************************************************************/

        TimeSpan timeOfDay () 
        {
                return TimeSpan (ticks % TimeSpan.day.ticks);
        }

        /**********************************************************************

                $(I Property.) Retrieves the number of ticks for this Time

                Deprecated: access ticks directly

                Returns: A long represented by the time of this 
                         instance.

        **********************************************************************/

        deprecated long time () 
        {
                return ticks;
        }

        /**********************************************************************
                Deprecated: use Calendar.daysInMonth instead.

                Returns the number of _days in the specified _month.

                Params:
                  year = The _year.
                  month = The _month.
                Returns: The number of _days in the specified _month.

        **********************************************************************/

        deprecated static int daysInMonth (int year, int month) 
        {
                int[] monthDays = isLeapYear(year) ? DaysToMonthLeap 
                                                   : DaysToMonthCommon;
                return monthDays[month] - monthDays[month - 1];
        }

        /**********************************************************************
                Deprecated: use Calendar.isLeapYear instead.

                Returns a value indicating whether the specified _year is 
                a leap _year.

                Params:  year = The _year.
                Returns: true if year is a leap _year; otherwise, false.

        **********************************************************************/

        deprecated static bool isLeapYear (int year) 
        {
                return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
        }

        /**********************************************************************

        **********************************************************************/

        deprecated private static long getDateTicks (int year, int month, int day) 
        {
                int[] monthDays = isLeapYear(year) ? DaysToMonthLeap 
                                                   : DaysToMonthCommon;
                --year;
                return (year * 365 + year / 4 - year / 100 + year / 400 + 
                        monthDays[month - 1] + day - 1) * TimeSpan.day.ticks;
        }

        /**********************************************************************

        **********************************************************************/

        deprecated private static void splitDate (long ticks, out int year, out int month, out int day, out int dayOfYear) 
        {
                int numDays = cast(int) (ticks / TimeSpan.day.ticks);
                int whole400Years = numDays / cast(int) TimeSpan.DaysPer400Years;
                numDays -= whole400Years * cast(int) TimeSpan.DaysPer400Years;
                int whole100Years = numDays / cast(int) TimeSpan.DaysPer100Years;
                if (whole100Years == 4)
                    whole100Years = 3;

                numDays -= whole100Years * cast(int) TimeSpan.DaysPer100Years;
                int whole4Years = numDays / cast(int) TimeSpan.DaysPer4Years;
                numDays -= whole4Years * cast(int) TimeSpan.DaysPer4Years;
                int wholeYears = numDays / cast(int) TimeSpan.DaysPerYear;
                if (wholeYears == 4)
                    wholeYears = 3;

                year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
                numDays -= wholeYears * TimeSpan.DaysPerYear;
                dayOfYear = numDays + 1;

                int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DaysToMonthLeap : DaysToMonthCommon;
                month = numDays >> 5 + 1;
                while (numDays >= monthDays[month])
                       month++;

                day = numDays - monthDays[month - 1] + 1;
        }

        /**********************************************************************

        **********************************************************************/

        deprecated private static int extractPart (long ticks, int part) 
        {
                int year, month, day, dayOfYear;

                splitDate (ticks, year, month, day, dayOfYear);

                if (part is Year)
                    return year;

                if (part is Month)
                    return month;

                if (part is DayOfYear)
                    return dayOfYear;

                return day;
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
                Stdout (c.time).newline;
        }
}




/******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        mid 2005: Initial release
                        Apr 2007: heavily reshaped

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.DateTime;

private import  tango.util.time.Clock,
                tango.util.time.WallClock;

/******************************************************************************

        Represents time expressed as a date and time of day.

        Remarks: DateTime represents dates and times between 12:00:00 
        midnight on January 1, 0001 AD and 11:59:59 PM on December 31, 
        9999 AD.

        Time values are measured in 100-nanosecond intervals, or ticks. 
        A date value is the number of ticks that have elapsed since 
        12:00:00 midnight on January 1, 0001 AD in the Gregorian 
        calendar.

******************************************************************************/

struct DateTime 
{
        public long ticks;

        private package enum 
        {
                Year,
                Month,
                Day,
                DayOfYear
        }

        public enum DayOfWeek 
        {
                Sunday,    /// Indicates _Sunday.
                Monday,    /// Indicates _Monday.
                Tuesday,   /// Indicates _Tuesday.
                Wednesday, /// Indicates _Wednesday.
                Thursday,  /// Indicates _Thursday.
                Friday,    /// Indicates _Friday.
                Saturday   /// Indicates _Saturday.
        }

        /// Represents the smallest and largest DateTime value.
        public static final DateTime    min = {0},
                                        max = {Time.DaysTo10000 * Time.TicksPerDay - 1};

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
                DateTime struct to the specified number of _ticks.         
                
                Params: ticks = A date and time expressed in units of 
                100 nanoseconds.

        **********************************************************************/

        static DateTime opCall (long ticks) 
        {
                DateTime d;
                d.ticks = ticks;
                return d;
        }

        /**********************************************************************

                $(I Constructor.) Initializes a new instance of the 
                DateTime struct to the specified Time.

                Params: time = A Tango time expressed in units of 100 
                nanoseconds.

        **********************************************************************/

        static DateTime opCall (Time time) 
        {
                return opCall (cast(long) time);
        }

        /**********************************************************************

        **********************************************************************/

        static DateTime opCall (int year, int month, int day) 
        {
                return opCall (getDateTicks (year, month, day));
        }

        /**********************************************************************

                $(I Property.) Retrieves the current date.

                Returns: A DateTime instance set to today's date.

        **********************************************************************/

        static DateTime today () 
        {
                return now.date;
        }

        /**********************************************************************

                $(I Property.) Retrieves a DateTime instance set to the 
                current date and time in local time.

                Returns: A DateTime whose value is the current local date 
                         and time.

        **********************************************************************/

        static DateTime now () 
        {
                return DateTime (WallClock.now);
        }

        /**********************************************************************

                $(I Property.) Retrieves a DateTime instance set to the 
                current date and time in UTC time.

                Returns: A DateTime whose value is the current UTC date 
                         and time.

        **********************************************************************/

        static DateTime utc () 
        {
                return DateTime (Clock.now);
        }

        /**********************************************************************

                Determines whether two DateTime values are equal.

                Params:  value = A DateTime _value.
                Returns: true if both instances are equal; otherwise, false

        **********************************************************************/

        bool opEquals (DateTime t) 
        {
                return ticks is t.ticks;
        }

        /**********************************************************************

                Compares two DateTime values.

        **********************************************************************/

        int opCmp (DateTime t) 
        {
                if (ticks < t.ticks)
                    return -1;
                else 
                   if (ticks > t.ticks)
                       return 1;
                return 0;
        }

        /**********************************************************************

                Adds the specified time span to the date and time, 
                returning a new date and time.
                
                Params:  t = A DateTime value.
                Returns: A DateTime that is the sum of this instance and t.

        **********************************************************************/

        DateTime opAdd (DateTime t) 
        {
                return DateTime (ticks + t.ticks);
        }

        /**********************************************************************

                Adds the specified time span to the date and time, assigning 
                the result to this instance.

                Params:  t = A DateTime value.
                Returns: The current DateTime instance, with t added to the 
                         date and time.

        **********************************************************************/

        DateTime opAddAssign (DateTime t) 
        {
                ticks += t.ticks;
                return *this;
        }

        /**********************************************************************

                Subtracts the specified time span from the date and time, 
                returning a new date and time.

                Params:  t = A DateTime value.
                Returns: A DateTime whose value is the value of this instance 
                         minus the value of t.

        **********************************************************************/

        DateTime opSub (DateTime t) 
        {
                return DateTime (ticks - t.ticks);
        }

        /**********************************************************************

                Subtracts the specified time span from the date and time, 
                assigning the result to this instance.

                Params:  t = A DateTime value.
                Returns: The current DateTime instance, with t subtracted 
                         from the date and time.

        **********************************************************************/

        DateTime opSubAssign (DateTime t) 
        {
                ticks -= t.ticks;
                return *this;
        }

        /**********************************************************************

                Adds the specified number of ticks to the _value of this 
                instance.

                Params:  value = The number of ticks to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the time in value.

        **********************************************************************/

        DateTime addTicks (long value) 
        {
                return DateTime (ticks + value);
        }

        /**********************************************************************
                Adds the specified number of hours to the _value of this 
                instance.

                Params:  value = The number of hours to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the number of hours in 
                         value.

        **********************************************************************/

        DateTime addHours (int value) 
        {
                return addMilliseconds (value * Time.MillisPerHour);
        }

        /**********************************************************************

                Adds the specified number of minutes to the _value of this 
                instance.

                Params:  value = The number of minutes to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the number of minutes in 
                         value.

        **********************************************************************/

        DateTime addMinutes (int value) 
        {
                return addMilliseconds (value * Time.MillisPerMinute);
        }

        /**********************************************************************

                Adds the specified number of seconds to the _value of this 
                instance.

                Params:  value = The number of seconds to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the number of seconds in 
                         value.

        **********************************************************************/

        DateTime addSeconds (int value) 
        {
                return addMilliseconds (value * Time.MillisPerSecond);
        }

        /**********************************************************************

                Adds the specified number of milliseconds to the _value of 
                this instance.

                Params:  value = The number of milliseconds to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the number of milliseconds 
                         in value.

        **********************************************************************/

        DateTime addMilliseconds (long value) 
        {
                return addTicks (value * Time.TicksPerMillisecond);
        }

        /**********************************************************************

                Adds the specified number of days to the _value of this 
                instance.

                Params:  value = The number of days to add.
                Returns: A DateTime whose value is the sum of the date 
                         and time of this instance and the number of days 
                         in value.

        **********************************************************************/

        DateTime addDays (int value) 
        {
                return addMilliseconds (value * Time.MillisPerDay);
        }

        /**********************************************************************

                Adds the specified number of months to the _value of this 
                instance.

                Params:  value = The number of months to add.
                Returns: A DateTime whose value is the sum of the date and 
                         time of this instance and the number of months in 
                         value.

        **********************************************************************/

        DateTime addMonths (int value) 
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

                return DateTime (getDateTicks(year, month, day) + (ticks % Time.TicksPerDay));
        }

        /**********************************************************************

                Adds the specified number of years to the _value of this 
                instance.

                Params:  value = The number of years to add.
                Returns: A DateTime whose value is the sum of the date 
                         and time of this instance and the number of years 
                         in value.

        **********************************************************************/

        DateTime addYears (int value) 
        {
                return addMonths (value * 12);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _year component of the date.

                Returns: The _year.

        **********************************************************************/

        int year () 
        {
                return extractPart (ticks, Year);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _month component of the date.

                Returns: The _month.

        **********************************************************************/

        int month () 
        {
                return extractPart (ticks, Month);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _day component of the date.

                Returns: The _day.

        **********************************************************************/

        int day () 
        {
                return extractPart (ticks, Day);
        }

        /**********************************************************************

                $(I Property.) Retrieves the day of the year.

                Returns: The day of the year.

        **********************************************************************/

        int dayOfYear () 
        {
                return extractPart (ticks, DayOfYear);
        }

        /**********************************************************************

                $(I Property.) Retrieves the day of the week.

                Returns: A DayOfWeek value indicating the day of the week.

        **********************************************************************/

        DayOfWeek dayOfWeek () 
        {
                return cast(DayOfWeek) ((ticks / Time.TicksPerDay + 1) % 7);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _hour component of the date.

                Returns: The _hour.

        **********************************************************************/

        int hour () 
        {
                return cast(int) ((ticks / Time.TicksPerHour) % 24);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _minute component of the date.

                Returns: The _minute.

        **********************************************************************/

        int minute () 
        {
                return cast(int) ((ticks / Time.TicksPerMinute) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _second component of the date.

                Returns: The _second.

        **********************************************************************/

        int second () 
        {
                return cast(int) ((ticks / Time.TicksPerSecond) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _millisecond component of the 
                date.

                Returns: The _millisecond.

        **********************************************************************/

        int millisecond () 
        {
                return cast(int) ((ticks / Time.TicksPerMillisecond) % 1000);
        }

        /**********************************************************************

                $(I Property.) Retrieves the date component.

                Returns: A new DateTime instance with the same date as 
                         this instance.

        **********************************************************************/

        DateTime date () 
        {
                auto ticks = this.ticks;
                return DateTime (ticks - ticks % Time.TicksPerDay);
        }

        /**********************************************************************

                $(I Property.) Retrieves the time of day.

                Returns: A DateTime representing the fraction of the day elapsed since midnight.

        **********************************************************************/

        DateTime timeOfDay () 
        {
                return DateTime (ticks % Time.TicksPerDay);
        }

        /**********************************************************************

                $(I Property.) Retrieves a Time value representing the 
                date and time of this instance.

                Returns: A Time represented by the date and time of this 
                         instance.

        **********************************************************************/

        Time time () 
        {
                return cast(Time) ticks;
        }

        /**********************************************************************

                Returns the number of _days in the specified _month.

                Params:
                  year = The _year.
                  month = The _month.
                Returns: The number of _days in the specified _month.

        **********************************************************************/

        static int daysInMonth (int year, int month) 
        {
                int[] monthDays = isLeapYear(year) ? DaysToMonthLeap 
                                                   : DaysToMonthCommon;
                return monthDays[month] - monthDays[month - 1];
        }

        /**********************************************************************

                Returns a value indicating whether the specified _year is 
                a leap _year.

                Params:  year = The _year.
                Returns: true if year is a leap _year; otherwise, false.

        **********************************************************************/

        static bool isLeapYear (int year) 
        {
                return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
        }

        /**********************************************************************

        **********************************************************************/

        private static long getDateTicks (int year, int month, int day) 
        {
                int[] monthDays = isLeapYear(year) ? DaysToMonthLeap 
                                                   : DaysToMonthCommon;
                --year;
                return (year * 365 + year / 4 - year / 100 + year / 400 + 
                        monthDays[month - 1] + day - 1) * Time.TicksPerDay;
        }

        /**********************************************************************

        **********************************************************************/

        private static void splitDate (long ticks, out int year, out int month, out int day, out int dayOfYear) 
        {
                int numDays = cast(int) (ticks / Time.TicksPerDay);
                int whole400Years = numDays / cast(int) Time.DaysPer400Years;
                numDays -= whole400Years * cast(int) Time.DaysPer400Years;
                int whole100Years = numDays / cast(int) Time.DaysPer100Years;
                if (whole100Years == 4)
                    whole100Years = 3;

                numDays -= whole100Years * cast(int) Time.DaysPer100Years;
                int whole4Years = numDays / cast(int) Time.DaysPer4Years;
                numDays -= whole4Years * cast(int) Time.DaysPer4Years;
                int wholeYears = numDays / cast(int) Time.DaysPerYear;
                if (wholeYears == 4)
                    wholeYears = 3;

                year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
                numDays -= wholeYears * Time.DaysPerYear;
                dayOfYear = numDays + 1;

                int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DaysToMonthLeap : DaysToMonthCommon;
                month = numDays >> 5 + 1;
                while (numDays >= monthDays[month])
                       month++;

                day = numDays - monthDays[month - 1] + 1;
        }

        /**********************************************************************

        **********************************************************************/

        private static int extractPart (long ticks, int part) 
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

debug (DateTime)
{
        import tango.io.Stdout;

        DateTime foo() 
        {
                auto d = DateTime(10);
                auto e = DateTime(20);

                return d + e;
        }

        void main()
        {
                auto c = foo();
                Stdout (c.time).newline;
        }
}




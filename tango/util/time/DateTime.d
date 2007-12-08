/**
 * copyright: Copyright (c) 2005 Steven Schveighoffer. All rights reserved
 * license:   BSD style: $(LICENSE)
 * version:   Dec 2007: Initial release
 * author:    schveiguy
 */

module tango.util.time.DateTime;


public  import  tango.time.TimeSpan;

private import  tango.time.Clock,
                tango.time.WallClock;

private import  tango.time.chrono.Calendar,
                tango.time.chrono.DefaultCalendar;

/******************************************************************************

        Represents time expressed as a date and time of day.

        Remarks: This can represent dates and times as defined by a given
        calendar.  The only limitation of DateTime is the representation of
        years, which is currently an integer.

        The smallest resolution supported by DateTime is the nanosecond.

        NOTE: do not use this class yet, it's not cooked :)  Use Time instead
        (tango.util.time.Time) which is the same as what DateTime used to be.

******************************************************************************/

pragma(msg, "Don't use DateTime module yet, use Time instead");

void getTimeOfDay(TimeSpan t, out int hour, out int minute, out int second, out int millis, out int micros)
{
        auto time = t.time;

        hour = time.hours;
        minute = time.minutes;
        second = time.seconds;
        millis = time.millis;
        micros = time.micros;
}

void getTimeOfDay(TimeSpan t, out int hour, out int minute, out int second, out int millis)
{
    int u;
    getTimeOfDay(t, hour, minute, second, millis, u);
}

void getTimeOfDay(TimeSpan t, out int hour, out int minute, out int second)
{
    int m, u;
    getTimeOfDay(t, hour, minute, second, m, u);
}

class DateTime 
{
    private int year;
    private int day;
    private int month;
    private TimeSpan timeOfDay;
    private Calendar calendar;
    private Calendar.DayOfWeek dow;

    // create a new instance with the default calendar
    this(Time t)
    {
        this(t, DefaultCalendar);
    }

    this(Time t, Calendar cal)
    in
    {
        assert(cal !is null);
    }
    body
    {
        this.calendar = cal;
        // TODO fill in other elements using calendar
    }

    static DateTime now () 
    {
        return new DateTime(Clock.now);
    }

    static DateTime localTime () 
    {
        return new DateTime(WallClock.now);
    }

    /+
    /**********************************************************************

                Determines whether two Time values are equal.

                Params:  value = A Time _value.
                Returns: true if both instances are equal; otherwise, false

        **********************************************************************/

        int opEquals (DateTime t) 
        {
            return 0;
        }

        /**********************************************************************

                Compares two Time values.

        **********************************************************************/

        int opCmp (Time t) 
        {
            return -1;
        }

        /**********************************************************************

                Adds the specified time span to the date and time, 
                returning a new date and time.
                
                Params:  t = A TimeSpan value.
                Returns: A Time that is the sum of this instance and t.

        **********************************************************************/

        DateTime opAdd (TimeSpan t) 
        {
            return null;
        }

        /**********************************************************************

                Adds the specified time span to the date and time, assigning 
                the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t added to the 
                         date and time.

        **********************************************************************/

        DateTime opAddAssign (TimeSpan t) 
        {
            return null;
        }

        /**********************************************************************

                Subtracts the specified time span from the date and time, 
                returning a new date and time.

                Params:  t = A TimeSpan value.
                Returns: A Time whose value is the value of this instance 
                         minus the value of t.

        **********************************************************************/

        DateTime opSub (TimeSpan t) 
        {
            return null;
        }

        /**********************************************************************

                Returns a time span which represents the difference in time
                between this and the given Time.

                Params:  t = A Time value.
                Returns: A TimeSpan which represents the difference between
                         this and t.

        **********************************************************************/

        TimeSpan opSub (DateTime t)
        {
                return TimeSpan(ticks - t.ticks);
        }

        /**********************************************************************

                Subtracts the specified time span from the date and time, 
                assigning the result to this instance.

                Params:  t = A TimeSpan value.
                Returns: The current Time instance, with t subtracted 
                         from the date and time.

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

        deprecated Time addMillis (long value) 
        {
                return *this + TimeSpan.millis(value);
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

                Adds the specified number of months to the _value of this 
                instance.

                Params:  value = The number of months to add.
                Returns: A Time whose value is the sum of the date and 
                         time of this instance and the number of months in 
                         value.

        **********************************************************************/

        Time addMonths (int value) 
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

                return Time (getDateTicks(year, month, day) + (ticks % TimeSpan.TicksPerDay));
        }

        /**********************************************************************

                Adds the specified number of years to the _value of this 
                instance.

                Params:  value = The number of years to add.
                Returns: A Time whose value is the sum of the date 
                         and time of this instance and the number of years 
                         in value.

        **********************************************************************/

        Time addYears (int value) 
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
                return cast(DayOfWeek) ((ticks / TimeSpan.TicksPerDay + 1) % 7);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _hour component of the date.

                Returns: The _hour.

        **********************************************************************/

        int hour () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerHour) % 24);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _minute component of the date.

                Returns: The _minute.

        **********************************************************************/

        int minute () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerMinute) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _second component of the date.

                Returns: The _second.

        **********************************************************************/

        int second () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerSecond) % 60);
        }

        /**********************************************************************

                $(I Property.) Retrieves the _millisecond component of the 
                date.

                Returns: The _millisecond.

        **********************************************************************/

        int millis () 
        {
                return cast(int) ((ticks / TimeSpan.TicksPerMillisecond) % 1000);
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

        TimeOfDay time () 
        {
                return TimeOfDay (ticks);
        }

        /**********************************************************************

                $(I Property.) Retrieves the number of ticks for this Time

                Deprecated: access ticks directly

                Returns: A long represented by the date and time of this 
                         instance.

        **********************************************************************/

        deprecated long time () 
        {
                return ticks;
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
                        monthDays[month - 1] + day - 1) * TimeSpan.TicksPerDay;
        }

        /**********************************************************************

        **********************************************************************/

        private static void splitDate (long ticks, out int year, out int month, out int day, out int dayOfYear) 
        {
                int numDays = cast(int) (ticks / TimeSpan.TickPerDay);
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
        +/
}

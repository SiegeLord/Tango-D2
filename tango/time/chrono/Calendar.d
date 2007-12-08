/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.Calendar;

private import tango.core.Exception;

public  import tango.time.Time;



/**
 * $(ANCHOR _Calendar)
 * Represents time in week, month and year divisions.
 * Remarks: Calendar is the abstract base class for the following Calendar implementations: 
 *   $(LINK2 #GregorianCalendar, GregorianCalendar), $(LINK2 #HebrewCalendar, HebrewCalendar), $(LINK2 #HijriCalendar, HijriCalendar),
 *   $(LINK2 #JapaneseCalendar, JapaneseCalendar), $(LINK2 #KoreanCalendar, KoreanCalendar), $(LINK2 #TaiwanCalendar, TaiwanCalendar) and
 *   $(LINK2 #ThaiBuddhistCalendar, ThaiBuddhistCalendar).
 */
public abstract class Calendar 
{
        /**
        * Indicates the current era of the calendar.
        */
        package enum {CURRENT_ERA = 0};

        // Corresponds to Win32 calendar IDs
        package enum 
        {
                GREGORIAN = 1,
                GREGORIAN_US = 2,
                JAPAN = 3,
                TAIWAN = 4,
                KOREA = 5,
                HIJRI = 6,
                THAI = 7,
                HEBREW = 8,
                GREGORIAN_ME_FRENCH = 9,
                GREGORIAN_ARABIC = 10,
                GREGORIAN_XLIT_ENGLISH = 11,
                GREGORIAN_XLIT_FRENCH = 12
        }

        package enum WeekRule 
        {
                FirstDay,         /// Indicates that the first week of the year is the first week containing the first day of the year.
                FirstFullWeek,    /// Indicates that the first week of the year is the first full week following the first day of the year.
                FirstFourDayWeek  /// Indicates that the first week of the year is the first week containing at least four days.
        }

        package enum DatePart
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

        /**
        * Returns a Time value set to the specified date and time in the current era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   day = An integer representing the _day.
        *   hour = An integer representing the _hour.
        *   minute = An integer representing the _minute.
        *   second = An integer representing the _second.
        *   millisecond = An integer representing the _millisecond.
        * Returns: The Time set to the specified date and time.
        */
        Time getTime (int year, int month, int day, int hour, int minute, int second, int millisecond) 
        {
                return getTime (year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
        }

        /**
        * When overridden, returns a Time value set to the specified date and time in the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   day = An integer representing the _day.
        *   hour = An integer representing the _hour.
        *   minute = An integer representing the _minute.
        *   second = An integer representing the _second.
        *   millisecond = An integer representing the _millisecond.
        *   era = An integer representing the _era.
        * Returns: A Time set to the specified date and time.
        */
        abstract Time getTime (int year, int month, int day, int hour, int minute, int second, int millisecond, int era);

        /**
        * When overridden, returns the day of the week in the specified Time.
        * Params: time = A Time value.
        * Returns: A DayOfWeek value representing the day of the week of time.
        */
        abstract DayOfWeek getDayOfWeek (Time time);

        /**
        * When overridden, returns the day of the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the month of time.
        */
        abstract int getDayOfMonth (Time time);

        /**
        * When overridden, returns the day of the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the year of time.
        */
        abstract int getDayOfYear (Time time);

        /**
        * When overridden, returns the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the month in time.
        */
        abstract int getMonth (Time time);

        /**
        * When overridden, returns the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the year in time.
        */
        abstract int getYear (Time time);

        /**
        * When overridden, returns the era in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the ear in time.
        */
        abstract int getEra (Time time);

        /**
        * Returns the number of days in the specified _year and _month of the current era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        * Returns: The number of days in the specified _year and _month of the current era.
        */
        int getDaysInMonth (int year, int month) 
        {
                return getDaysInMonth (year, month, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of days in the specified _year and _month of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year and _month of the specified _era.
        */
        abstract int getDaysInMonth (int year, int month, int era);

        /**
        * Returns the number of days in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of days in the specified _year in the current era.
        */
        int getDaysInYear (int year) 
        {
                return getDaysInYear (year, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of days in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of days in the specified _year in the specified _era.
        */
        abstract int getDaysInYear (int year, int era);

        /**
        * Returns the number of months in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of months in the specified _year in the current era.
        */
        int getMonthsInYear (int year) 
        {
                return getMonthsInYear (year, CURRENT_ERA);
        }

        /**
        * When overridden, returns the number of months in the specified _year of the specified _era.
        * Params:
        *   year = An integer representing the _year.
        *   era = An integer representing the _era.
        * Returns: The number of months in the specified _year in the specified _era.
        */
        abstract int getMonthsInYear (int year, int era);

        /**
        * Returns the week of the year that includes the specified Time.
        * Params:
        *   time = A Time value.
        *   rule = A WeekRule value defining a calendar week.
        *   firstDayOfWeek = A DayOfWeek value representing the first day of the week.
        * Returns: An integer representing the week of the year that includes the date in time.
        */
        int getWeekOfYear (Time time, WeekRule rule, DayOfWeek firstDayOfWeek) 
        {
                int year = getYear (time);
                int jan1 = cast(int) getDayOfWeek (getTime (year, 1, 1, 0, 0, 0, 0));

                switch (rule) 
                       {
                       case WeekRule.FirstDay:
                            int n = jan1 - cast(int) firstDayOfWeek;
                            if (n < 0)
                                n += 7;
                            return (getDayOfYear (time) + n - 1) / 7 + 1;

                       case WeekRule.FirstFullWeek:
                       case WeekRule.FirstFourDayWeek:
                            int fullDays = (rule is WeekRule.FirstFullWeek) ? 7 : 4;
                            int n = cast(int) firstDayOfWeek - jan1;
                            if (n != 0) 
                               {
                               if (n < 0)
                                   n += 7;
                               else 
                                  if (n >= fullDays)
                                      n -= 7;
                               }

                            int day = getDayOfYear (time) - n;
                            if (day > 0)
                                return (day - 1) / 7 + 1;
                            year = getYear(time) - 1;
                            int month = getMonthsInYear (year);
                            day = getDaysInMonth (year, month);
                            return getWeekOfYear(getTime(year, month, day, 0, 0, 0, 0), rule, firstDayOfWeek);

                       default:
                            break;
                       }
                throw new IllegalArgumentException("Value was out of range.");
        }

        /**
        * Indicates whether the specified _year in the current era is a leap _year.
        * Params: year = An integer representing the _year.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        bool isLeapYear(int year) 
        {
                return isLeapYear(year, CURRENT_ERA);
        }

        /**
        * When overridden, indicates whether the specified _year in the specified _era is a leap _year.
        * Params: year = An integer representing the _year.
        * Params: era = An integer representing the _era.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        abstract bool isLeapYear(int year, int era);

        /**
        * $(I Property.) When overridden, retrieves the list of eras in the current calendar.
        * Returns: An integer array representing the eras in the current calendar.
        */
        abstract int[] eras();

        /**
        * $(I Property.) Retrieves the identifier associated with the current calendar.
        * Returns: An integer representing the identifier of the current calendar.
        */
        int id() 
        {
                return -1;
        }

        /**
         * Get the components of a Time structure using the rules of the
         * calendar.  This is useful if you want more than one of the given
         * components.  Note that this doesn't handle the time of day, as that
         * is calculated directly from the Time struct.
         *
         * The default implemenation is to call all the other accessors
         * directly, a derived class may override if it has a more efficient
         * method.
         */
        void split(Time time, out int year, out int month, out int dayOfMonth, out int dayOfYear, out DayOfWeek dayOfWeek, out int era)
        {
            year = getYear(time);
            month = getMonth(time);
            dayOfMonth = getDayOfMonth(time);
            dayOfYear = getDayOfYear(time);
            dayOfWeek = getDayOfWeek(time);
            era = getEra(time);
        }

        package static long getTimeTicks (int hour, int minute, int second) 
        {
                return (TimeSpan.hours(hour) + TimeSpan.minutes(minute) + TimeSpan.seconds(second)).ticks;
        }
}

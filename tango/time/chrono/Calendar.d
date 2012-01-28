/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.Calendar;

public  import tango.time.Time;

private import tango.core.Exception;



/**
 * $(ANCHOR _Calendar)
 * Represents time in week, month and year divisions.
 * Remarks: Calendar is the abstract base class for the following Calendar implementations: 
 *   $(LINK2 #Gregorian, Gregorian), $(LINK2 #Hebrew, Hebrew), $(LINK2 #Hijri, Hijri),
 *   $(LINK2 #Japanese, Japanese), $(LINK2 #Korean, Korean), $(LINK2 #Taiwan, Taiwan) and
 *   $(LINK2 #ThaiBuddhist, ThaiBuddhist).
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
         * Get the components of a Time structure using the rules of the
         * calendar.  This is useful if you want more than one of the given
         * components.  Note that this doesn't handle the time of day, as that
         * is calculated directly from the Time struct.
         *
         * The default implemenation is to call all the other accessors
         * directly, a derived class may override if it has a more efficient
         * method.
         */
        const Date toDate (const(Time) time)
        {
                Date d;
                split (time, d.year, d.month, d.day, d.doy, d.dow, d.era);
                return d;
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
        const void split (const(Time) time, ref uint year, ref uint month, ref uint day, ref uint doy, ref uint dow, ref uint era)
        {
            year = getYear(time);
            month = getMonth(time);
            day = getDayOfMonth(time);
            doy = getDayOfYear(time);
            dow = getDayOfWeek(time);
            era = getEra(time);
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
        const Time toTime (uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond=0) 
        {
                return toTime (year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
        }

        /**
        * Returns a Time value for the given Date, in the current era 
        * Params:
        *   date = a representation of the Date
        * Returns: The Time set to the specified date.
        */
        const Time toTime (const(Date) d) 
        {
                return toTime (d.year, d.month, d.day, 0, 0, 0, 0, d.era);
        }

        /**
        * Returns a Time value for the given DateTime, in the current era 
        * Params:
        *   dt = a representation of the date and time
        * Returns: The Time set to the specified date and time.
        */
        const Time toTime (const(DateTime) dt) 
        {
                return toTime (dt.date, dt.time);
        }

        /**
        * Returns a Time value for the given Date and TimeOfDay, in the current era 
        * Params:
        *   d = a representation of the date 
        *   t = a representation of the day time 
        * Returns: The Time set to the specified date and time.
        */
        const Time toTime (const(Date) d, const(TimeOfDay) t) 
        {
                return toTime (d.year, d.month, d.day, t.hours, t.minutes, t.seconds, t.millis, d.era);
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
        abstract const Time toTime (uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond, uint era);

        /**
        * When overridden, returns the day of the week in the specified Time.
        * Params: time = A Time value.
        * Returns: A DayOfWeek value representing the day of the week of time.
        */
        abstract const DayOfWeek getDayOfWeek (const(Time) time);

        /**
        * When overridden, returns the day of the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the month of time.
        */
        abstract const uint getDayOfMonth (const(Time) time);

        /**
        * When overridden, returns the day of the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the day of the year of time.
        */
        abstract const uint getDayOfYear (const(Time) time);

        /**
        * When overridden, returns the month in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the month in time.
        */
        abstract const uint getMonth (const(Time) time);

        /**
        * When overridden, returns the year in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the year in time.
        */
        abstract const uint getYear (const(Time) time);

        /**
        * When overridden, returns the era in the specified Time.
        * Params: time = A Time value.
        * Returns: An integer representing the ear in time.
        */
        abstract const uint getEra (const(Time) time);

        /**
        * Returns the number of days in the specified _year and _month of the current era.
        * Params:
        *   year = An integer representing the _year.
        *   month = An integer representing the _month.
        * Returns: The number of days in the specified _year and _month of the current era.
        */
        const uint getDaysInMonth (uint year, uint month) 
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
        abstract const uint getDaysInMonth (uint year, uint month, uint era);

        /**
        * Returns the number of days in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of days in the specified _year in the current era.
        */
        const uint getDaysInYear (uint year) 
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
        abstract const uint getDaysInYear (uint year, uint era);

        /**
        * Returns the number of months in the specified _year of the current era.
        * Params: year = An integer representing the _year.
        * Returns: The number of months in the specified _year in the current era.
        */
        const uint getMonthsInYear (uint year) 
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
        abstract const uint getMonthsInYear (uint year, uint era);

        /**
        * Returns the week of the year that includes the specified Time.
        * Params:
        *   time = A Time value.
        *   rule = A WeekRule value defining a calendar week.
        *   firstDayOfWeek = A DayOfWeek value representing the first day of the week.
        * Returns: An integer representing the week of the year that includes the date in time.
        */
        const uint getWeekOfYear (const(Time) time, WeekRule rule, DayOfWeek firstDayOfWeek) 
        {
                auto year = getYear (time);
                auto jan1 = cast(int) getDayOfWeek (toTime (year, 1, 1, 0, 0, 0, 0));

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
                            return getWeekOfYear(toTime(year, month, day, 0, 0, 0, 0), rule, firstDayOfWeek);

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
        const bool isLeapYear(uint year) 
        {
                return isLeapYear(year, CURRENT_ERA);
        }

        /**
        * When overridden, indicates whether the specified _year in the specified _era is a leap _year.
        * Params: year = An integer representing the _year.
        * Params: era = An integer representing the _era.
        * Returns: true is the specified _year is a leap _year; otherwise, false.
        */
        abstract const bool isLeapYear(uint year, uint era);

        /**
        * $(I Property.) When overridden, retrieves the list of eras in the current calendar.
        * Returns: An integer array representing the eras in the current calendar.
        */
        @property abstract const uint[] eras();

        /**
        * $(I Property.) Retrieves the identifier associated with the current calendar.
        * Returns: An integer representing the identifier of the current calendar.
        */
        @property const uint id() 
        {
                return -1;
        }

        /**
         * Returns a new Time with the specified number of months added.  If
         * the months are negative, the months are subtracted.
         *
         * If the target month does not support the day component of the input
         * time, then an error will be thrown, unless truncateDay is set to
         * true.  If truncateDay is set to true, then the day is reduced to
         * the maximum day of that month.
         *
         * For example, adding one month to 1/31/2000 with truncateDay set to
         * true results in 2/28/2000.
         *
         * The default implementation uses information provided by the
         * calendar to calculate the correct time to add.  Derived classes may
         * override if there is a more optimized method.
         *
         * Note that the generic method does not take into account crossing
         * era boundaries.  Derived classes may support this.
         *
         * Params: t = A time to add the months to
         * Params: nMonths = The number of months to add.  This can be
         * negative.
         * Params: truncateDay = Round the day down to the maximum day of the
         * target month if necessary.
         *
         * Returns: A Time that represents the provided time with the number
         * of months added.
         */
        const Time addMonths(const(Time) t, int nMonths, bool truncateDay = false)
        {
                uint era = getEra(t);
                uint year = getYear(t);
                uint month = getMonth(t);

                //
                // Assume we go back to day 1 of the current year, taking
                // into account that offset using the nMonths and nDays
                // offsets.
                //
                nMonths += month - 1;
                int origDom = cast(int)getDayOfMonth(t);
                long nDays = origDom - cast(int)getDayOfYear(t);
                if(nMonths > 0)
                {
                        //
                        // Adding, add all the years until the year we want to
                        // be in.
                        //
                        auto miy = getMonthsInYear(year, era);
                        while(nMonths >= miy)
                        {
                                //
                                // skip a whole year
                                //
                                nDays += getDaysInYear(year, era);
                                nMonths -= miy;
                                year++;

                                //
                                // update miy
                                //
                                miy = getMonthsInYear(year, era);
                        }
                }
                else if(nMonths < 0)
                {
                        //
                        // subtracting months
                        //
                        while(nMonths < 0)
                        {
                                auto miy = getMonthsInYear(--year, era);
                                nDays -= getDaysInYear(year, era);
                                nMonths += miy;
                        }
                }

                //
                // we now are offset to the resulting year.
                // Add the rest of the months to get to the day we want.
                //
                int newDom = cast(int)getDaysInMonth(year, nMonths + 1, era);
                if(origDom > newDom)
                {
                    //
                    // error, the resulting day of month is out of range.  See
                    // if we should truncate
                    //
                    if(truncateDay)
                        nDays -= newDom - origDom;
                    else
                        throw new IllegalArgumentException("days out of range");

                }
                for(int m = 0; m < nMonths; m++)
                        nDays += getDaysInMonth(year, m + 1, era);
                return t + TimeSpan.fromDays(nDays);
        }

        /**
         * Add the specified number of years to the given Time.
         *
         * The generic algorithm uses information provided by the abstract
         * methods.  Derived classes may re-implement this in order to
         * optimize the algorithm
         *
         * Note that the generic algorithm does not take into account crossing
         * era boundaries.  Derived classes may support this.
         *
         * Params: t = A time to add the years to
         * Params: nYears = The number of years to add.  This can be negative.
         *
         * Returns: A Time that represents the provided time with the number
         * of years added.
         */
        const Time addYears(const(Time) t, int nYears)
        {
                auto date = toDate(t);
                auto tod = t.ticks % TimeSpan.TicksPerDay;
                if(tod < 0)
                        tod += TimeSpan.TicksPerDay;
                date.year += nYears;
                return toTime(date) + TimeSpan(tod);
        }

        package static long getTimeTicks (uint hour, uint minute, uint second) 
        {
                return (TimeSpan.fromHours(hour) + TimeSpan.fromMinutes(minute) + TimeSpan.fromSeconds(second)).ticks;
        }
}

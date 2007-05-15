/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: May 2005

        author:         Kris

*******************************************************************************/

module tango.util.time.Date;

/*******************************************************************************

        Date exposes the underlying OS support for splitting date fields
        to and from a set of discrete attributes. For example, to set all
        fields to the current UTC time:
        ---
        auto date = Clock.toDate;
        ---

        Note that Date does not provide general conversion to and from
        textual representations, since that requires support for locales
        and wide characters. However, it does support basic short English
        names that are used in a variety of text representations.

        Attributes exposed include year, month, day, hour, minute, second,
        millisecond, and day of week. Methods include setting time & date 
        values.

        See TimeStamp.d for an example of a simple derivation, and see
        "http://en.wikipedia.org/wiki/Unix_time" for details on UTC time

*******************************************************************************/

struct Date
{
        public int      year,           /// fully defined year ~ e.g. 2005
                        month,          /// 1 through 12
                        day,            /// 1 through 31
                        hour,           /// 0 through 23
                        min,            /// 0 through 59
                        sec,            /// 0 through 59
                        ms,             /// 0 through 999
                        dow;            /// 0 through 6 where sunday is 0

        /// list of english day names
        private static char[][] Days =
        [
                        "Sun",
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
        ];

        /// list of english month names
        private static char[][] Months =
        [
                        "Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec",
        ];

        /**********************************************************************

                Get the english short month name

        **********************************************************************/

        char[] asMonth ()
        {
                assert (month > 0);
                return Months [month-1];
        }

        /**********************************************************************

                Get the english short day name

        **********************************************************************/

        char[] asDay ()
        {
                return Days [dow];
        }

        /**********************************************************************

                Set the date-related values

                year  : fully defined year ~ e.g. 2005
                month : 1 through 12
                day   : 1 through 31
                dow   : 0 through 6; sunday=0 (typically set by O/S)

        **********************************************************************/

        void setDate (int year, int month, int day, int dow = 0)
        {
                this.year = year;
                this.month = month;
                this.day = day;
                this.dow = dow;
        }

        /**********************************************************************

                Set the time-related values

                hour : 0 through 23
                min  : 0 through 59
                sec  : 0 through 59
                ms   : 0 through 999

        **********************************************************************/

        void setTime (int hour, int min, int sec, int ms = 0)
        {
                this.hour = hour;
                this.min = min;
                this.sec = sec;
                this.ms = ms;
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: May 2005      
      
        author:         Kris

*******************************************************************************/

module tango.text.convert.Rfc1123;

private import tango.core.Epoch;

private import tango.text.convert.Format;

extern (C) int memcmp (char *, char *, uint);


/******************************************************************************

        Converts between native and text representations of HTTP time
        values. Internally, time is represented as UTC with an epoch 
        fixed at Jan 1st 1970. The text representation is formatted in
        accordance with RFC 1123, and the parser will accept one of 
        RFC 1123, RFC 850, or asctime formats.

        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html for
        further detail.

******************************************************************************/

class Rfc1123 : Epoch
{
        /**********************************************************************

                RFC 1123 formatted time

                Converts to the format "Sun, 06 Nov 1994 08:49:37 GMT", and
                returns a populated slice of the provided buffer; with zero
                length if the date was invalid.

                Note that RFC 1123 format is always in absolute GMT time.

                A 40-element buffer is sufficient for the longest string.

        **********************************************************************/

        final static char[] format (char[] output, ulong time)
        {
                // ignore invalid time values
                if (time == InvalidEpoch)
                    return "";

                // convert time to field values
                Fields fields;
                fields.setUtcTime (time);

                // format fields according to RFC 1123
                return Formatter.sprint (output,
                                         "{0,3}, {1:d2} {2,3} {3:d4} {4:d2}:{5:d2}:{6:d2} GMT",
                                         fields.toDowName,
                                         fields.day,
                                         fields.toMonthName,
                                         fields.year,
                                         fields.hour, 
                                         fields.min,
                                         fields.sec
                                        );
        }

        /**********************************************************************
              
              Parse provided input and return a UTC epoch time. A return 
              value of InvalidEpoch indicated a parse-failure.
              
              An option is provided to return the count of characters
              parsed ~ a zero value here also indicates invalid input.

        **********************************************************************/

        static ulong parse (char[] date, uint* ate = null)
        {
                int     len;
                ulong   value;

                if ((len = rfc1123 (date, value)) > 0 || 
                    (len = rfc850  (date, value)) > 0 || 
                    (len = asctime (date, value)) > 0)
                   {
                   if (ate)
                       *ate = len;
                   return value;
                   }
                return InvalidEpoch;
        }


        /**********************************************************************
              
                RFC 822, updated by RFC 1123

                "Sun, 06 Nov 1994 08:49:37 GMT"
                  
        **********************************************************************/

        private static int rfc1123 (char[] src, inout ulong value)
        {
                Fields fields;
                char* p = src.ptr;

                bool date (inout char* p)
                {
                        return cast(bool)
                                ((fields.day = parseInt(p)) > 0    &&
                                 *p++ == ' '                       &&
                                (fields.month = parseMonth(p)) > 0 &&
                                 *p++ == ' '                       &&
                                (fields.year = parseInt(p)) > 0);
                }

                if (parseShortDay(p) >= 0 &&
                    *p++ == ','           &&
                    *p++ == ' '           &&
                    date (p)              &&
                    *p++ == ' '           &&
                    time (fields, p)      &&
                    *p++ == ' '           &&
                    p[0..3] == "GMT")
                    {
                    value = fields.getUtcTime;
                    return (p+3) - src.ptr;
                    }

                return 0;
        }

        /**********************************************************************
              
                RFC 850, obsoleted by RFC 1036

                "Sunday, 06-Nov-94 08:49:37 GMT"

        **********************************************************************/

        private static int rfc850 (char[] src, inout ulong value)
        {
                Fields fields;
                char* p = src.ptr;

                bool date (inout char* p)
                {
                        return cast(bool)
                                ((fields.day = parseInt(p)) > 0    &&
                                 *p++ == '-'                       &&
                                (fields.month = parseMonth(p)) > 0 &&
                                 *p++ == '-'                       &&
                                (fields.year = parseInt(p)) > 0);
                }

                if (parseFullDay(p) >= 0 &&
                    *p++ == ','          &&
                    *p++ == ' '          &&
                    date (p)             &&
                    *p++ == ' '          &&
                    time (fields, p)     &&
                    *p++ == ' '          &&
                    p[0..3] == "GMT")
                    {
                    if (fields.year <= 70)
                        fields.year += 2000;
                    else
                       if (fields.year <= 99)
                           fields.year += 1900;

                    value = fields.getUtcTime;
                    return (p+3) - src.ptr;
                    }

                return 0;
        }

        /**********************************************************************
              
                ANSI C's asctime() format

                "Sun Nov  6 08:49:37 1994"

        **********************************************************************/

        private static int asctime (char[] src, inout ulong value)
        {
                Fields fields;
                char* p = src.ptr;

                bool date (inout char* p)
                {
                        return cast(bool)
                                ((fields.month = parseMonth(p)) > 0 &&
                                 *p++ == ' '                        &&
                                ((fields.day = parseInt(p)) > 0     ||
                                (*p++ == ' '                        &&
                                (fields.day = parseInt(p)) > 0)));
                }

                if (parseShortDay(p) >= 0 &&
                    *p++ == ' '           &&
                    date (p)              &&
                    *p++ == ' '           &&
                    time (fields, p)      &&
                    *p++ == ' '           &&
                    (fields.year = parseInt (p)) > 0)
                    {
                    value = fields.getUtcTime;
                    return p - src.ptr;
                    }

                return 0;
        }

        /**********************************************************************
              
                Parse a time field

        **********************************************************************/

        private static bool time (inout Fields fields, inout char* p)
        {
                return cast(bool) 
                       ((fields.hour = parseInt(p)) > 0 &&
                         *p++ == ':'                    &&
                        (fields.min = parseInt(p)) > 0  &&
                         *p++ == ':'                    &&
                        (fields.sec = parseInt(p)) > 0);
        }

        /**********************************************************************
              
                Match a month from the input

        **********************************************************************/

        private static int parseMonth (inout char* p)
        {
                int month;

                switch (p[0..3])
                       {
                       case "Jan":
                            month = 1;
                            break; 
                       case "Feb":
                            month = 2;
                            break; 
                       case "Mar":
                            month = 3;
                            break; 
                       case "Apr":
                            month = 4;
                            break; 
                       case "May":
                            month = 5;
                            break; 
                       case "Jun":
                            month = 6;
                            break; 
                       case "Jul":
                            month = 7;
                            break; 
                       case "Aug":
                            month = 8;
                            break; 
                       case "Sep":
                            month = 9;
                            break; 
                       case "Oct":
                            month = 10;
                            break; 
                       case "Nov":
                            month = 11;
                            break; 
                       case "Dec":
                            month = 12;
                            break; 
                       default:
                            return month;
                       }

                p += 3;
                return month;
        }

        /**********************************************************************
              
                Match a day from the input

        **********************************************************************/

        private static int parseShortDay (inout char* p)
        {
                int day;

                switch (p[0..3])
                       {
                       case "Sun":
                            day = 0;
                            break;
                       case "Mon":
                            day = 1;
                            break; 
                       case "Tue":
                            day = 2;
                            break; 
                       case "Wed":
                            day = 3;
                            break; 
                       case "Thu":
                            day = 4;
                            break; 
                       case "Fri":
                            day = 5;
                            break; 
                       case "Sat":
                            day = 6;
                            break; 
                       default:
                            return -1;
                       }

                p += 3;
                return day;
        }

        /**********************************************************************
              
                Match a day from the input

        **********************************************************************/

        private static int parseFullDay (inout char* p)
        {
                foreach (int i, char[] day; Fields.Days)
                         if (memcmp (day, p, day.length) == 0)
                            {
                            p += day.length;
                            return i;
                            }
                return -1;
        }


        /**********************************************************************
              
                Extract an integer from the input

        **********************************************************************/

        private static int parseInt (inout char* p)
        {
                int value;

                while (*p >= '0' && *p <= '9')
                       value = value * 10 + *p++ - '0';
                return value;
        }
}

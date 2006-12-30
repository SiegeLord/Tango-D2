/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: May 2005      
      
        author:         Kris

*******************************************************************************/

module tango.text.convert.Rfc1123;

private import tango.core.Epoch;

private import tango.text.convert.Integer;

/******************************************************************************

        Converts between native and text representations of HTTP time
        values. Internally, time is represented as UTC with an epoch 
        fixed at Jan 1st 1970. The text representation is formatted in
        accordance with RFC 1123, and the parser will accept one of 
        RFC 1123, RFC 850, or asctime formats.

        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html for
        further detail.

******************************************************************************/

struct Rfc1123
{
        public alias Epoch.InvalidEpoch InvalidEpoch;
        
        /**********************************************************************

                RFC1123 formatted time

                Converts to the format "Sun, 06 Nov 1994 08:49:37 GMT", and
                returns a populated slice of the provided buffer. Note that
                RFC1123 format is always in absolute GMT time, and a thirty-
                element buffer is sufficient for the produced output

                Throws an exception where the supplied time is invalid

        **********************************************************************/

        final static char[] format (char[] output, ulong time)
        {
                Epoch.Fields    fields;
                char[4]         tmp = void;
                char*           p = output.ptr;

                assert (output.length >= 29);

                if (time is InvalidEpoch)
                    Epoch.exception ("Rfc1123.format :: invalid epoch argument");

                // convert time to field values
                fields.setUtcTime (time);

                // build output string; less expensive than using Format
                p = append (p, fields.toDowName[0..3]);
                p = append (p, ", ");
                p = append (p, Integer.format (tmp[0..2], fields.day, Integer.Format.Unsigned, Integer.Flags.Zero));
                p = append (p, " ");
                p = append (p, fields.toMonthName[0..3]);
                p = append (p, " ");
                p = append (p, Integer.format (tmp[0..4], fields.year, Integer.Format.Unsigned, Integer.Flags.Zero));
                p = append (p, " ");
                p = append (p, Integer.format (tmp[0..2], fields.hour, Integer.Format.Unsigned, Integer.Flags.Zero));
                p = append (p, ":");
                p = append (p, Integer.format (tmp[0..2], fields.min, Integer.Format.Unsigned, Integer.Flags.Zero));
                p = append (p, ":");
                p = append (p, Integer.format (tmp[0..2], fields.sec, Integer.Format.Unsigned, Integer.Flags.Zero));
                p = append (p, " GMT");
                
                return output [0 .. p - output.ptr];
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
                Epoch.Fields    fields;
                char*           p = src.ptr;

                bool date (inout char* p)
                {
                        return ((fields.day = parseInt(p)) > 0     &&
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
                Epoch.Fields    fields;
                char*           p = src.ptr;

                bool date (inout char* p)
                {
                        return ((fields.day = parseInt(p)) > 0     &&
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
                Epoch.Fields    fields;
                char*           p = src.ptr;

                bool date (inout char* p)
                {
                        return ((fields.month = parseMonth(p)) > 0  &&
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

        private static bool time (inout Epoch.Fields fields, inout char* p)
        {
                return ((fields.hour = parseInt(p)) > 0 &&
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
                foreach (int i, char[] day; Epoch.Fields.Days)
                         if (day == p[0..day.length])
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

        /**********************************************************************
              
                Append text to an array. We use this as a featherweight
                alternative to tango.text.convert.Format

        **********************************************************************/

        private static char* append (char* p, char[] s)
        {
                p[0..s.length] = s[];
                return p + s.length;
        }
}


debug (UnitTest)
{
        unittest
        {
                char[30] tmp;
                char[] test = "Sun, 06 Nov 1994 08:49:37 GMT";
                
                auto time = Rfc1123.parse (test);
                auto text = Rfc1123.format (tmp, time);
                assert (text == test);
        }
}

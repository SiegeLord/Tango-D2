/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.convert.DateTime;

private import  tango.time.WallClock;

private import  tango.core.Exception;

private import  tango.time.chrono.Calendar,
                tango.time.chrono.Gregorian;

private import  Integer = tango.text.convert.Integer;

/******************************************************************************

******************************************************************************/

char[] format (char[] output, Time dateTime, char[] fmt)
{
        return format (output, dateTime, fmt, EngUS);
}

/******************************************************************************

******************************************************************************/

private char[] format (char[] output, Time dateTime, char[] format, ref DateTimeLocale dtl)
{
        /**********************************************************************

        **********************************************************************/

        char[] expandKnownFormat (char[] format)
        {
                char[] f;

                switch (format[0])
                       {
                       case 'd':
                            f = dtl.shortDatePattern;
                            break;
                       case 'D':
                            f = dtl.longDatePattern;
                            break;
                       case 'f':
                            f = dtl.longDatePattern ~ " " ~ dtl.shortTimePattern;
                            break;
                       case 'F':
                            f = dtl.fullDateTimePattern;
                            break;
                       case 'g':
                            f = dtl.generalShortTimePattern;
                            break;
                       case 'G':
                            f = dtl.generalLongTimePattern;
                            break;
                       case 'm':
                       case 'M':
                            f = dtl.monthDayPattern;
                            break;
                       case 'r':
                       case 'R':
                            f = dtl.rfc1123Pattern;
                            break;
                       case 's':
                            f = dtl.sortableDateTimePattern;
                            break;
                       case 'u':
                            f = dtl.universalSortableDateTimePattern;
                            break;
                       case 't':
                            f = dtl.shortTimePattern;
                            break;
                       case 'T':
                            f = dtl.longTimePattern;
                            break;
                       case 'y':
                       case 'Y':
                            f = dtl.yearMonthPattern;
                            break;
                       default:
                           throw new IllegalArgumentException("Invalid date format.");
                       }

                return f;
        }

        /**********************************************************************

        **********************************************************************/

        char[] formatCustom (ref Result result, Time dateTime, char[] format)
        {

                int parseRepeat(char[] format, int pos, char c)
                {
                        int n = pos + 1;
                        while (n < format.length && format[n] is c)
                               n++;
                        return n - pos;
                }

                char[] formatDayOfWeek(Calendar.DayOfWeek dayOfWeek, int rpt)
                {
                        if (rpt is 3)
                            return dtl.abbreviatedDayName(dayOfWeek);
                        return dtl.dayName(dayOfWeek);
                }

                char[] formatMonth(int month, int rpt)
                {
                        if (rpt is 3)
                            return dtl.abbreviatedMonthName(month);
                        return dtl.monthName(month);
                }

                char[] formatInt (char[] tmp, int v, int minimum)
                {
                        auto num = Integer.format (tmp, v, "u");
                        if ((minimum -= num.length) > 0)
                           {
                           auto p = tmp.ptr + tmp.length - num.length;
                           while (minimum--)
                                  *--p = '0';
                           num = tmp [p-tmp.ptr .. $];
                           }
                        return num;
                }

                int parseQuote(char[] format, int pos, out char[] result)
                {
                        int start = pos;
                        char chQuote = format[pos++];
                        bool found;
                        while (pos < format.length)
                              {
                              char c = format[pos++];
                              if (c is chQuote)
                                 {
                                 found = true;
                                 break;
                                 }
                              else
                                 if (c is '\\')
                                    { // escaped
                                    if (pos < format.length)
                                        result ~= format[pos++];
                                    }
                                 else
                                    result ~= c;
                              }
                        return pos - start;
                }


                auto calendar = dtl.calendar;
                auto justTime = true;
                int index, len;
                char[10] tmp;

                if (format[0] is '%')
                    {
                    // specifiers for both standard format strings and custom ones
                    const char[] commonSpecs = "dmMsty";
                    foreach (c; commonSpecs)
                             if (format[1] is c)
                                {
                                index += 1;
                                break;
                                }
                    }

                while (index < format.length)
                      {
                      char c = format[index];
                      auto time = dateTime.time;

                      switch (c)
                             {
                             case 'd':  // day
                                  len = parseRepeat(format, index, c);
                                  if (len <= 2)
                                     {
                                     int day = calendar.getDayOfMonth(dateTime);
                                     result ~= formatInt (tmp, day, len);
                                     }
                                  else
                                     result ~= formatDayOfWeek(calendar.getDayOfWeek(dateTime), len);
                                  justTime = false;
                                  break;

                             case 'M':  // month
                                  len = parseRepeat(format, index, c);
                                  int month = calendar.getMonth(dateTime);
                                  if (len <= 2)
                                      result ~= formatInt (tmp, month, len);
                                  else
                                     result ~= formatMonth(month, len);
                                  justTime = false;
                                  break;
                             case 'y':  // year
                                  len = parseRepeat(format, index, c);
                                  int year = calendar.getYear(dateTime);
                                  // Two-digit years for Japanese
                                  if (calendar.id is Calendar.JAPAN)
                                      result ~= formatInt (tmp, year, 2);
                                  else
                                     {
                                     if (len <= 2)
                                         result ~= formatInt (tmp, year % 100, len);
                                     else
                                        result ~= formatInt (tmp, year, len);
                                     }
                                  justTime = false;
                                  break;
                             case 'h':  // hour (12-hour clock)
                                  len = parseRepeat(format, index, c);
                                  int hour = time.hours % 12;
                                  if (hour is 0)
                                      hour = 12;
                                  result ~= formatInt (tmp, hour, len);
                                  break;
                             case 'H':  // hour (24-hour clock)
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.hours, len);
                                  break;
                             case 'm':  // minute
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.minutes, len);
                                  break;
                             case 's':  // second
                                  len = parseRepeat(format, index, c);
                                  result ~= formatInt (tmp, time.seconds, len);
                                  break;
                             case 't':  // AM/PM
                                  len = parseRepeat(format, index, c);
                                  if (len is 1)
                                     {
                                     if (time.hours < 12)
                                        {
                                        if (dtl.amDesignator.length != 0)
                                            result ~= dtl.amDesignator[0];
                                        }
                                     else
                                        {
                                        if (dtl.pmDesignator.length != 0)
                                            result ~= dtl.pmDesignator[0];
                                        }
                                     }
                                  else
                                     result ~= (time.hours < 12) ? dtl.amDesignator : dtl.pmDesignator;
                                  break;
                             case 'z':  // timezone offset
                                  len = parseRepeat(format, index, c);
                                  auto minutes = cast(int) (WallClock.zone.minutes);
                                  if (minutes < 0)
                                      minutes = -minutes, result ~= '-';
                                  else
                                     result ~= '+';
                                  int hours = minutes / 60;
                                  minutes %= 60;

                                  if (len is 1)
                                      result ~= formatInt (tmp, hours, 1);
                                  else
                                     if (len is 2)
                                         result ~= formatInt (tmp, hours, 2);
                                     else
                                        {
                                        result ~= formatInt (tmp, hours, 2);
                                        result ~= ':';
                                        result ~= formatInt (tmp, minutes, 2);
                                        }
                                  break;
                             case ':':  // time separator
                                  len = 1;
                                  result ~= dtl.timeSeparator;
                                  break;
                             case '/':  // date separator
                                  len = 1;
                                  result ~= dtl.dateSeparator;
                                  break;
                             case '\"':  // string literal
                             case '\'':  // char literal
                                  char[] quote;
                                  len = parseQuote(format, index, quote);
                                  result ~= quote;
                                  break;
                             default:
                                 len = 1;
                                 result ~= c;
                                 break;
                             }
                      index += len;
                      }
                return result.get;
        }


        if (format.length is 0)
            format = "G"; // Default to general format.

        if (format.length is 1) // It might be one of our shortcuts.
            format = expandKnownFormat (format);

        auto result = Result (output);
        return formatCustom (result, dateTime, format);
}


/******************************************************************************

******************************************************************************/

private struct Result
{
        private uint    index;
        private char[]  target_;

        /**********************************************************************

        **********************************************************************/

        private static Result opCall (char[] target)
        {
                Result result;

                result.target_ = target;
                return result;
        }

        /**********************************************************************

        **********************************************************************/

        private void opCatAssign (char[] rhs)
        {
                auto end = index + rhs.length;
                assert (end < target_.length);

                target_[index .. end] = rhs;
                index = end;
        }

        /**********************************************************************

        **********************************************************************/

        private void opCatAssign (char rhs)
        {
                assert (index < target_.length);
                target_[index++] = rhs;
        }

        /**********************************************************************

        **********************************************************************/

        private char[] get ()
        {
                return target_[0 .. index];
        }
}

/******************************************************************************

******************************************************************************/

private struct DateTimeLocale
{       
        static char[]   rfc1123Pattern = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
        static char[]   sortableDateTimePattern = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
        static char[]   universalSortableDateTimePattern = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'";

        Calendar        calendar;
        char[]          shortDatePattern,
                        shortTimePattern,
                        longDatePattern,
                        longTimePattern,
                        fullDateTimePattern,
                        generalShortTimePattern,
                        generalLongTimePattern,
                        monthDayPattern,
                        yearMonthPattern;
        char[]          amDesignator,
                        pmDesignator;
        char[]          timeSeparator,
                        dateSeparator;
        char[][]        dayNames,
                        monthNames,
                        abbreviatedDayNames,
                        abbreviatedMonthNames;

        char[] abbreviatedDayName (Calendar.DayOfWeek dayOfWeek)
        {
                return abbreviatedDayNames [cast(int) dayOfWeek];
        }

        char[] dayName (Calendar.DayOfWeek dayOfWeek)
        {
                return dayNames [cast(int) dayOfWeek];
        }
                       
        char[] abbreviatedMonthName (int month)
        {
                assert (month > 0 && month < 13);
                return abbreviatedMonthNames [month - 1];
        }

        char[] monthName (int month)
        {
                assert (month > 0 && month < 13);
                return monthNames [month - 1];
        }
}

/******************************************************************************

******************************************************************************/

private DateTimeLocale EngUS = 
{
        shortDatePattern                : "M/d/yyyy",
        shortTimePattern                : "h:mm tt",       
        longDatePattern                 : "dddd, MMMM d, yyyy",
        longTimePattern                 : "h:mm:ss tt",        
        fullDateTimePattern             : "dddd, MMMM d, yyyy h:mm:ss tt",
        generalShortTimePattern         : "M/d/yyyy h:mm tt",
        generalLongTimePattern          : "M/d/yyyy h:mm:ss tt",
        monthDayPattern                 : "MMMM d",
        yearMonthPattern                : "MMMM, yyyy",
        amDesignator                    : "AM",
        pmDesignator                    : "PM",
        timeSeparator                   : ":",
        dateSeparator                   : "/",
        dayNames                        : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        monthNames                      : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October" "November", "December"],
        abbreviatedDayNames             : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],    
        abbreviatedMonthNames           : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct" "Nov", "Dec"],
};

/******************************************************************************

******************************************************************************/

static this()
{       
        EngUS.calendar = Gregorian.generic;
}



/******************************************************************************

******************************************************************************/

debug (DateFormat)
{
        import tango.io.Stdout;

        void main()
        {
                char[100] tmp;

                Stdout.formatln ("d: {}", format (tmp, WallClock.now, "d"));
                Stdout.formatln ("D: {}", format (tmp, WallClock.now, "D"));
                Stdout.formatln ("f: {}", format (tmp, WallClock.now, "f"));
                Stdout.formatln ("F: {}", format (tmp, WallClock.now, "F"));
                Stdout.formatln ("g: {}", format (tmp, WallClock.now, "g"));
                Stdout.formatln ("G: {}", format (tmp, WallClock.now, "G"));
                Stdout.formatln ("m: {}", format (tmp, WallClock.now, "m"));
                Stdout.formatln ("r: {}", format (tmp, WallClock.now, "r"));
                Stdout.formatln ("s: {}", format (tmp, WallClock.now, "s"));
                Stdout.formatln ("t: {}", format (tmp, WallClock.now, "t"));
                Stdout.formatln ("T: {}", format (tmp, WallClock.now, "T"));
                Stdout.formatln ("y: {}", format (tmp, WallClock.now, "y"));
                Stdout.formatln ("u: {}", format (tmp, WallClock.now, "u"));
        }
}

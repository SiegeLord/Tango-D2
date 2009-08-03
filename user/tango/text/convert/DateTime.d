/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2005: initial release
                        Mar 2009: extracted from locale, and 
                                  converted to a struct

        author:         John Chapman, Kris

        Support for formatting date/time values, in a locale-specific
        manner. See DateTimeLocale.format() for a description on how 
        formatting is performed (below).

******************************************************************************/

module tango.text.convert.DateTime;

private import  tango.core.Exception;

private import  tango.time.WallClock;

private import  tango.time.chrono.Calendar,
                tango.time.chrono.Gregorian;

private import  Integer = tango.text.convert.Integer;

/******************************************************************************

        Windows specifics
                
******************************************************************************/

version (Windows)
{
        private import tango.sys.win32.UserGdi;

        enum {LOCALE_SYEARMONTH = 0x00001006};
}

/******************************************************************************

        The default DateTimeLocale instance
                
******************************************************************************/

public DateTimeLocale DateTimeDefault;

static this()
{       
        DateTimeDefault = DateTimeLocale.create;
}

/******************************************************************************

        How to format locale-specific date/time output

******************************************************************************/

struct DateTimeLocale
{       
        static char[]   rfc1123Pattern = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
        static char[]   sortableDateTimePattern = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
        static char[]   universalSortableDateTimePattern = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'";

        Calendar        assignedCalendar;

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

        /**********************************************************************

                Format the given Time value into the provided output, 
                using the specified layout. The layout can be a generic
                variant or a custom one, where generics are indicated
                via a single character:
                ---
                "t" = 7:04
                "T" = 7:04:02 PM 
                "d" = 3/30/2009
                "D" = Monday, March 30, 2009
                "f" = Monday, March 30, 2009 7:04 PM
                "F" = Monday, March 30, 2009 7:04:02 PM
                "g" = 3/30/2009 7:04 PM
                "G" = 3/30/2009 7:04:02 PM
                "y"
                "Y" = March, 2009
                "r"
                "R" = Mon, 30 Mar 2009 19:04:02 GMT
                "s" = 2009-03-30T19:04:02
                "u" = 2009-03-30 19:04:02Z
                ---
        
                For the US locale, these generic layouts are expanded in the 
                following manner:
                ---
                "t" = "h:mm" 
                "T" = "h:mm:ss tt"
                "d" = "M/d/yyyy"  
                "D" = "dddd, MMMM d, yyyy" 
                "f" = "dddd, MMMM d, yyyy h:mm tt"
                "F" = "dddd, MMMM d, yyyy h:mm:ss tt"
                "g" = "M/d/yyyy h:mm tt"
                "G" = "M/d/yyyy h:mm:ss tt"
                "y"
                "Y" = "MMMM, yyyy"        
                "r"
                "R" = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'"
                "s" = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"      
                "u" = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'"   
                ---

                Custom layouts are constructed using a combination of the 
                character codes indicated on the right, above. For example, 
                a layout of "dddd, dd MMM yyyy HH':'mm':'ss zzzz" will emit 
                something like this:
                ---
                Monday, 30 Mar 2009 19:04:02 -08:00
                ---

                Using these format indicators with Layout (Stdout etc) is
                straightforward. Formatting integers, for example, is done
                like so:
                ---
                Stdout.formatln ("{:u}", 5);
                Stdout.formatln ("{:b}", 5);
                Stdout.formatln ("{:x}", 5);
                ---

                Formatting date/time values is similar, where the format
                indicators are provided after the colon:
                ---
                Stdout.formatln ("{:t}", Clock.now);
                Stdout.formatln ("{:D}", Clock.now);
                Stdout.formatln ("{:dddd, dd MMMM yyyy HH:mm}", Clock.now);
                ---

        **********************************************************************/

        char[] format (char[] output, Time dateTime, char[] layout)
        {
                // default to general format
                if (layout.length is 0)
                    layout = "G"; 

                // might be one of our shortcuts
                if (layout.length is 1) 
                    layout = expandKnownFormat (layout);
                
                auto res=Result(output);
                return formatCustom (res, dateTime, layout);
        }

        /**********************************************************************

                Return a generic English/US instance

        **********************************************************************/

        static DateTimeLocale* generic ()
        {
                return &EngUS;
        }

        /**********************************************************************

                Return the assigned Calendar instance, using Gregorian
                as the default

        **********************************************************************/

        Calendar calendar ()
        {
                if (assignedCalendar is null)
                    assignedCalendar = Gregorian.generic;
                return assignedCalendar;
        }

        /**********************************************************************

                Return a short day name 

        **********************************************************************/

        char[] abbreviatedDayName (Calendar.DayOfWeek dayOfWeek)
        {
                return abbreviatedDayNames [cast(int) dayOfWeek];
        }

        /**********************************************************************

                Return a long day name

        **********************************************************************/

        char[] dayName (Calendar.DayOfWeek dayOfWeek)
        {
                return dayNames [cast(int) dayOfWeek];
        }
                       
        /**********************************************************************

                Return a short month name

        **********************************************************************/

        char[] abbreviatedMonthName (int month)
        {
                assert (month > 0 && month < 13);
                return abbreviatedMonthNames [month - 1];
        }

        /**********************************************************************

                Return a long month name

        **********************************************************************/

        char[] monthName (int month)
        {
                assert (month > 0 && month < 13);
                return monthNames [month - 1];
        }

version (Windows)
{
        /**********************************************************************

                create and populate an instance via O/S configuration
                for the current user

        **********************************************************************/

        static DateTimeLocale create ()
        {       
                static char[] toString (char[] dst, LCID id, LCTYPE type)
                {
                        wchar[256] wide = void;

                        auto len = GetLocaleInfoW (id, type, null, 0);
                        if (len && len < wide.length)
                           {
                           GetLocaleInfoW (id, type, wide.ptr, wide.length);
                           len = WideCharToMultiByte (CP_UTF8, 0, wide.ptr, len-1,
                                                      cast(PCHAR)dst.ptr, dst.length, 
                                                      null, null);
                           return dst [0..len].dup;
                           }
                        throw new Exception ("DateTime :: GetLocaleInfo failed");
                }

                DateTimeLocale dt;
                char[256] tmp = void;
                auto lcid = LOCALE_USER_DEFAULT;

                for (auto i=LOCALE_SDAYNAME1; i <= LOCALE_SDAYNAME7; ++i)
                     dt.dayNames ~= toString (tmp, lcid, i);

                for (auto i=LOCALE_SABBREVDAYNAME1; i <= LOCALE_SABBREVDAYNAME7; ++i)
                     dt.abbreviatedDayNames ~= toString (tmp, lcid, i);

                for (auto i=LOCALE_SMONTHNAME1; i <= LOCALE_SMONTHNAME12; ++i)
                     dt.monthNames ~= toString (tmp, lcid, i);

                for (auto i=LOCALE_SABBREVMONTHNAME1; i <= LOCALE_SABBREVMONTHNAME12; ++i)
                     dt.abbreviatedMonthNames ~= toString (tmp, lcid, i);

                dt.dateSeparator    = toString (tmp, lcid, LOCALE_SDATE);
                dt.timeSeparator    = toString (tmp, lcid, LOCALE_STIME);
                dt.amDesignator     = toString (tmp, lcid, LOCALE_S1159);
                dt.pmDesignator     = toString (tmp, lcid, LOCALE_S2359);
                dt.longDatePattern  = toString (tmp, lcid, LOCALE_SLONGDATE);
                dt.shortDatePattern = toString (tmp, lcid, LOCALE_SSHORTDATE);
                dt.yearMonthPattern = toString (tmp, lcid, LOCALE_SYEARMONTH);
                dt.longTimePattern  = toString (tmp, lcid, LOCALE_STIMEFORMAT);
                         
                // synthesize a short time
                auto s = dt.shortTimePattern = dt.longTimePattern;
                for (auto i=s.length; i--;)
                     if (s[i] is dt.timeSeparator[0])
                        {
                        dt.shortTimePattern = s[0..i];
                        break;
                        }

                dt.fullDateTimePattern = dt.longDatePattern ~ " " ~ 
                                         dt.longTimePattern;
                dt.generalLongTimePattern = dt.shortDatePattern ~ " " ~ 
                                            dt.longTimePattern;
                dt.generalShortTimePattern = dt.shortDatePattern ~ " " ~ 
                                             dt.shortTimePattern;
                return dt;
        }
}
else
{
        /**********************************************************************

                
        **********************************************************************/

        static DateTimeLocale create ()
        {
                return EngUS;
        }
}
        /**********************************************************************

        **********************************************************************/

        private char[] expandKnownFormat (char[] format)
        {
                char[] f;

                switch (format[0])
                       {
                       case 'd':
                            f = shortDatePattern;
                            break;
                       case 'D':
                            f = longDatePattern;
                            break;
                       case 'f':
                            f = longDatePattern ~ " " ~ shortTimePattern;
                            break;
                       case 'F':
                            f = fullDateTimePattern;
                            break;
                       case 'g':
                            f = generalShortTimePattern;
                            break;
                       case 'G':
                            f = generalLongTimePattern;
                            break;
                       case 'r':
                       case 'R':
                            f = rfc1123Pattern;
                            break;
                       case 's':
                            f = sortableDateTimePattern;
                            break;
                       case 'u':
                            f = universalSortableDateTimePattern;
                            break;
                       case 't':
                            f = shortTimePattern;
                            break;
                       case 'T':
                            f = longTimePattern;
                            break;
                       case 'y':
                       case 'Y':
                            f = yearMonthPattern;
                            break;
                       default:
                           return ("'{invalid time format}'");
                       }
                return f;
        }

        /**********************************************************************

        **********************************************************************/

        private char[] formatCustom (ref Result result, Time dateTime, char[] format)
        {
                uint            len,
                                doy,
                                dow,
                                era;        
                uint            day,
                                year,
                                month;
                int             index;
                char[10]        tmp = void;
                auto            time = dateTime.time;

                // extract date components
                calendar.split (dateTime, year, month, day, doy, dow, era);

                // sweep format specifiers ...
                while (index < format.length)
                      {
                      char c = format[index];
                      
                      switch (c)
                             {
                             // day
                             case 'd':  
                                  len = parseRepeat (format, index, c);
                                  if (len <= 2)
                                      result ~= formatInt (tmp, day, len);
                                  else
                                     result ~= formatDayOfWeek (cast(Calendar.DayOfWeek) dow, len);
                                  break;

                             // month
                             case 'M':  
                                  len = parseRepeat (format, index, c);
                                  if (len <= 2)
                                      result ~= formatInt (tmp, month, len);
                                  else
                                     result ~= formatMonth (month, len);
                                  break;

                             // year
                             case 'y':  
                                  len = parseRepeat (format, index, c);

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
                                  break;

                             // hour (12-hour clock)
                             case 'h':  
                                  len = parseRepeat (format, index, c);
                                  int hour = time.hours % 12;
                                  if (hour is 0)
                                      hour = 12;
                                  result ~= formatInt (tmp, hour, len);
                                  break;

                             // hour (24-hour clock)
                             case 'H':  
                                  len = parseRepeat (format, index, c);
                                  result ~= formatInt (tmp, time.hours, len);
                                  break;

                             // minute
                             case 'm':  
                                  len = parseRepeat (format, index, c);
                                  result ~= formatInt (tmp, time.minutes, len);
                                  break;

                             // second
                             case 's':  
                                  len = parseRepeat (format, index, c);
                                  result ~= formatInt (tmp, time.seconds, len);
                                  break;

                             // AM/PM
                             case 't':  
                                  len = parseRepeat (format, index, c);
                                  if (len is 1)
                                     {
                                     if (time.hours < 12)
                                        {
                                        if (amDesignator.length != 0)
                                            result ~= amDesignator[0];
                                        }
                                     else
                                        {
                                        if (pmDesignator.length != 0)
                                            result ~= pmDesignator[0];
                                        }
                                     }
                                  else
                                     result ~= (time.hours < 12) ? amDesignator : pmDesignator;
                                  break;

                             // timezone offset
                             case 'z':  
                                  len = parseRepeat (format, index, c);
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
                                        result ~= formatInt (tmp, minutes, 2);
                                        }
                                  break;

                             // time separator
                             case ':':  
                                  len = 1;
                                  result ~= timeSeparator;
                                  break;

                             // date separator
                             case '/':  
                                  len = 1;
                                  result ~= dateSeparator;
                                  break;

                             // string literal
                             case '\"':  
                             case '\'':  
                                  len = parseQuote (result, format, index);
                                  break;

                             // other
                             default:
                                 len = 1;
                                 result ~= c;
                                 break;
                             }
                      index += len;
                      }
                return result.get;
        }

        /**********************************************************************

        **********************************************************************/

        private char[] formatMonth (int month, int rpt)
        {
                if (rpt is 3)
                    return abbreviatedMonthName (month);
                return monthName (month);
        }

        /**********************************************************************

        **********************************************************************/

        private char[] formatDayOfWeek (Calendar.DayOfWeek dayOfWeek, int rpt)
        {
                if (rpt is 3)
                    return abbreviatedDayName (dayOfWeek);
                return dayName (dayOfWeek);
        }

        /**********************************************************************

        **********************************************************************/

        private static int parseRepeat(char[] format, int pos, char c)
        {
                int n = pos + 1;
                while (n < format.length && format[n] is c)
                       n++;
                return n - pos;
        }

        /**********************************************************************

        **********************************************************************/

        private static char[] formatInt (char[] tmp, int v, int minimum)
        {
                auto num = Integer.itoa (tmp, v);
                if ((minimum -= num.length) > 0)
                   {
                   auto p = tmp.ptr + tmp.length - num.length;
                   while (minimum--)
                          *--p = '0';
                   num = tmp [p-tmp.ptr .. $];
                   }
                return num;
        }

        /**********************************************************************

        **********************************************************************/

        private static int parseQuote (ref Result result, char[] format, int pos)
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
}

/******************************************************************************
        
        An english/usa locale

        TODO: need to make this integrate with the content within 
        text.locale.Data, or populate from the O/S instead

******************************************************************************/

private DateTimeLocale EngUS = 
{
        shortDatePattern                : "M/d/yyyy",
        shortTimePattern                : "h:mm",       
        longDatePattern                 : "dddd, MMMM d, yyyy",
        longTimePattern                 : "h:mm:ss tt",        
        fullDateTimePattern             : "dddd, MMMM d, yyyy h:mm:ss tt",
        generalShortTimePattern         : "M/d/yyyy h:mm",
        generalLongTimePattern          : "M/d/yyyy h:mm:ss tt",
        monthDayPattern                 : "MMMM d",
        yearMonthPattern                : "MMMM, yyyy",
        amDesignator                    : "AM",
        pmDesignator                    : "PM",
        timeSeparator                   : ":",
        dateSeparator                   : "/",
        dayNames                        : ["Sunday", "Monday", "Tuesday", "Wednesday", 
                                           "Thursday", "Friday", "Saturday"],
        monthNames                      : ["January", "February", "March", "April", 
                                           "May", "June", "July", "August", "September", 
                                           "October" "November", "December"],
        abbreviatedDayNames             : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],    
        abbreviatedMonthNames           : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                           "Jul", "Aug", "Sep", "Oct" "Nov", "Dec"],
};


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

debug (DateTime)
{
        import tango.io.Stdout;

        void main()
        {
                char[100] tmp;
                auto time = WallClock.now;
                auto locale = DateTimeLocale.create;

                Stdout.formatln ("d: {}", locale.format (tmp, time, "d"));
                Stdout.formatln ("D: {}", locale.format (tmp, time, "D"));
                Stdout.formatln ("f: {}", locale.format (tmp, time, "f"));
                Stdout.formatln ("F: {}", locale.format (tmp, time, "F"));
                Stdout.formatln ("g: {}", locale.format (tmp, time, "g"));
                Stdout.formatln ("G: {}", locale.format (tmp, time, "G"));
                Stdout.formatln ("r: {}", locale.format (tmp, time, "r"));
                Stdout.formatln ("s: {}", locale.format (tmp, time, "s"));
                Stdout.formatln ("t: {}", locale.format (tmp, time, "t"));
                Stdout.formatln ("T: {}", locale.format (tmp, time, "T"));
                Stdout.formatln ("y: {}", locale.format (tmp, time, "y"));
                Stdout.formatln ("u: {}", locale.format (tmp, time, "u"));
                Stdout.formatln ("@: {}", locale.format (tmp, time, "@"));
                Stdout.formatln ("{}", locale.generic.format (tmp, time, "ddd, dd MMM yyyy HH':'mm':'ss zzzz"));
        }
}

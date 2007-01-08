/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: May 2005      
      
        author:         Kris

        Converts between native and text representations of HTTP time
        values. Internally, time is represented as UTC with an epoch 
        fixed at Jan 1st 1970. The text representation is formatted in
        accordance with RFC 1123, and the parser will accept one of 
        RFC 1123, RFC 850, or asctime formats.

        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html for
        further detail.

        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import TimeStamp = tango.text.convert.TimeStamp;

        auto t = TimeStamp.parse ("Sun, 06 Nov 1994 08:49:37 GMT");
        ---
        
*******************************************************************************/

module tango.text.convert.TimeStamp;

private import tango.core.Epoch;

private import Integer = tango.text.convert.Integer;

public alias Epoch.InvalidEpoch InvalidEpoch;

/******************************************************************************

        RFC1123 formatted time

        Converts to the format "Sun, 06 Nov 1994 08:49:37 GMT", and
        returns a populated slice of the provided buffer. Note that
        RFC1123 format is always in absolute GMT time, and a thirty-
        element buffer is sufficient for the produced output

        Throws an exception where the supplied time is invalid

******************************************************************************/

T[] format(T) (T[] output, ulong time)
{
        assert (output.length >= 29);

        Epoch.Fields    fields;
        T[4]            tmp = void;
        T*              p = output.ptr;

        // these arrays also reside in Epoch, but need to be templated here
        static T[][] Days = 
        [
                "Sun",
                "Mon",
                "Tue",
                "Wed",
                "Thu",
                "Fri",
                "Sat",
        ];

        // ditto
        static T[][] Months = 
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

        static T[] Comma = ", ",
                   Space = " ",
                   Colon = ":",
                   Gmt   = " GMT";

        if (time is InvalidEpoch)
            throw new Exception ("Rfc1123.format :: invalid epoch argument");

        // convert time to field values
        fields.asUtcTime (time);

        // build output string manually; much less expensive than binding Format
        p = append (p, Days[fields.dow]);
        p = append (p, Comma);
        p = append (p, Integer.format (tmp[0..2], cast(long) fields.day, Integer.Format.Unsigned, Integer.Flags.Zero));
        p = append (p, Space);
        p = append (p, Months[fields.month-1]);
        p = append (p, Space);
        p = append (p, Integer.format (tmp[0..4], cast(long) fields.year, Integer.Format.Unsigned, Integer.Flags.Zero));
        p = append (p, Space);
        p = append (p, Integer.format (tmp[0..2], cast(long) fields.hour, Integer.Format.Unsigned, Integer.Flags.Zero));
        p = append (p, Colon);
        p = append (p, Integer.format (tmp[0..2], cast(long) fields.min, Integer.Format.Unsigned, Integer.Flags.Zero));
        p = append (p, Colon);
        p = append (p, Integer.format (tmp[0..2], cast(long) fields.sec, Integer.Format.Unsigned, Integer.Flags.Zero));
        p = append (p, Gmt);

        return output [0 .. p - output.ptr];
}


/******************************************************************************

      Parse provided input and return a UTC epoch time. A return 
      value of InvalidEpoch indicated a parse-failure.

      An option is provided to return the count of characters
      parsed - an unchanged value here also indicates invalid
      input.

******************************************************************************/

ulong parse(T) (T[] date, uint* ate = null)
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


/******************************************************************************

        RFC 822, updated by RFC 1123 :: "Sun, 06 Nov 1994 08:49:37 GMT"

        Returns the number of elements consumed by the parse

******************************************************************************/

int rfc1123(T) (T[] src, inout ulong value)
{
        Epoch.Fields    fields;
        T*              p = src.ptr;

        bool date (inout T* p)
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
            value = fields.toUtcTime;
            return (p+3) - src.ptr;
            }

        return 0;
}


/******************************************************************************

        RFC 850, obsoleted by RFC 1036 :: "Sunday, 06-Nov-94 08:49:37 GMT"

        Returns the number of elements consumed by the parse

******************************************************************************/

int rfc850(T) (T[] src, inout ulong value)
{
        Epoch.Fields    fields;
        T*              p = src.ptr;

        bool date (inout T* p)
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

            value = fields.toUtcTime;
            return (p+3) - src.ptr;
            }

        return 0;
}


/******************************************************************************

        ANSI C's asctime() format :: "Sun Nov  6 08:49:37 1994"

        Returns the number of elements consumed by the parse

******************************************************************************/

int asctime(T) (T[] src, inout ulong value)
{
        Epoch.Fields    fields;
        T*              p = src.ptr;

        bool date (inout T* p)
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
            value = fields.toUtcTime;
            return p - src.ptr;
            }

        return 0;
}

/******************************************************************************

        Parse a time field

******************************************************************************/

private bool time(T) (inout Epoch.Fields fields, inout T* p)
{
        return ((fields.hour = parseInt(p)) > 0 &&
                 *p++ == ':'                    &&
                (fields.min = parseInt(p)) > 0  &&
                 *p++ == ':'                    &&
                (fields.sec = parseInt(p)) > 0);
}


/******************************************************************************

        Match a month from the input

******************************************************************************/

private int parseMonth(T) (inout T* p)
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


/******************************************************************************

        Match a day from the input

******************************************************************************/

private int parseShortDay(T) (inout T* p)
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


/******************************************************************************

        Match a day from the input. Sunday is 0

******************************************************************************/

private int parseFullDay(T) (inout T* p)
{
        static T[][] days =
        [
        "Sunday", 
        "Monday", 
        "Tuesday", 
        "Wednesday", 
        "Thursday", 
        "Friday", 
        "Saturday", 
        ];

        foreach (i, day; days)
                 if (day == p[0..day.length])
                    {
                    p += day.length;
                    return i;
                    }
        return -1;
}


/******************************************************************************

        Extract an integer from the input

******************************************************************************/

private static int parseInt(T) (inout T* p)
{
        int value;

        while (*p >= '0' && *p <= '9')
               value = value * 10 + *p++ - '0';
        return value;
}


/******************************************************************************

        Append text to an array. We use this as a featherweight
        alternative to tango.text.convert.Format

******************************************************************************/

private static T* append(T) (T* p, T[] s)
{
        p[0..s.length] = s[];
        return p + s.length;
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
        unittest
        {
                wchar[30] tmp;
                wchar[] test = "Sun, 06 Nov 1994 08:49:37 GMT";
                
                auto time = parse (test);
                auto text = format (tmp, time);
                assert (text == test);
        }
}

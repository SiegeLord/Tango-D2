/*******************************************************************************

        @file localtime.d
        
*******************************************************************************/

private import  tango.io.Stdout;

private import  tango.util.time.Utc,
                tango.util.time.Date;

/******************************************************************************

        Example code to format a local time in the following format:
        "Wed Dec 31 16:00:00 GMT-0800 1969"

******************************************************************************/

void main ()
{
        Date date;

        // set current local time
        date.set (Utc.local);

        // get GMT difference in minutes
        auto tz = cast(int) Utc.zone / 60;
        char sign = '+';
        if (tz < 0)
            tz = -tz, sign = '-';

        // format date
        Stdout.formatln ("{0}, {1} {2:d2} {3:d2}:{4:d2}:{5:d2} GMT{6}{7:d2}:{8:d2} {9}",
                          date.asDay,
                          date.asMonth,
                          date.day,
                          date.hour, 
                          date.min,
                          date.sec,
                          sign,
                          tz / 60,
                          tz % 60,
                          date.year
                         );
}

/*******************************************************************************

        @file localtime.d
        
*******************************************************************************/

private import tango.io.Stdout;

private import tango.core.Epoch;

/******************************************************************************

        Example code to format a local time in the following format:
        "Wed Dec 31 16:00:00 GMT-0800 1969"

******************************************************************************/

void main ()
{
        Epoch.Fields fields;

        // get current time and convert to local
        fields.asLocalTime (Epoch.utcMilli);

        // get GMT difference
        int tz = Epoch.tzMinutes;
        char sign = '+';
        if (tz < 0)
            tz = -tz, sign = '-';

        // format fields
        Stdout.format ("{0}, {1} {2:d2} {3:d2}:{4:d2}:{5:d2} GMT{6}{7:d2}{8:d2} {9}",
                        fields.toDowName,
                        fields.toMonthName,
                        fields.day,
                        fields.hour, 
                        fields.min,
                        fields.sec,
                        sign,
                        tz / 60,
                        tz % 60,
                        fields.year
                        ).newline;
}

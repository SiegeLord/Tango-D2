/*******************************************************************************

        @file localtime.d
        
*******************************************************************************/

private import tango.io.Print;

private import tango.core.Epoch;

/******************************************************************************

        Example code to format a local time in the following format:
        "Wed Dec 31 16:00:00 GMT-0800 1969"

******************************************************************************/

void main ()
{
        Epoch.Fields fields;

        // get current time and convert to local
        fields.setLocalTime (Epoch.utcMilli);

        // get GMT difference
        int tz = Epoch.tzMinutes;
        char sign = '+';
        if (tz < 0)
            tz = -tz, sign = '-';

        // format fields
        Println ("%.3s %.3s %02d %02d:%02d:%02d GMT%c%02d%02d %d",
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
                 );
}

/**
 * Default calendar.  Use this module to have a system-wide calendar.  By
 * default, the calendar instance is set to GregorianCalendar.  To change it,
 * simply assign it.
 */

module tango.time.chrono.DefaultCalendar;

private import tango.time.chrono.Calendar,
               tango.time.chrono.Gregorian;

public static Calendar DefaultCalendar;

static this()
{
        DefaultCalendar = GregorianCalendar.getDefaultInstance();
}

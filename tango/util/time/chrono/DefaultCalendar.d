/**
 * Default calendar.  Use this module to have a system-wide calendar.  By
 * default, the calendar instance is set to GregorianCalendar.  To change it,
 * simply assign it.
 */

module tango.util.time.chrono.DefaultCalendar;

private import tango.util.time.chrono.Calendar,
               tango.util.time.chrono.Gregorian;

public static Calendar DefaultCalendar;

static this()
{
        DefaultCalendar = GregorianCalendar.getDefaultInstance();
}

/**
 * Default calendar.  Use this module to have a system-wide calendar.
 */

module tango.time.chrono.DefaultCalendar;

private import tango.time.chrono.Calendar,
               tango.time.chrono.Gregorian;

/**
 * System-wide default calendar instance.  By default, the calendar instance
 * is set to GregorianCalendar.  To change it, simply assign it.
 */
public static Calendar DefaultCalendar;

static this()
{
        DefaultCalendar = GregorianCalendar.generic;
}

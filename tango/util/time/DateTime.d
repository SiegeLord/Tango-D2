/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.util.time.DateTime;

private import tango.util.time.Utc;

/**
*/
public enum DayOfWeek {
  Sunday,    /// Indicates _Sunday.
  Monday,    /// Indicates _Monday.
  Tuesday,   /// Indicates _Tuesday.
  Wednesday, /// Indicates _Wednesday.
  Thursday,  /// Indicates _Thursday.
  Friday,    /// Indicates _Friday.
  Saturday   /// Indicates _Saturday.
}

/**
*/
public enum CalendarWeekRule {
  FirstDay,         /// Indicates that the first week of the year is the first week containing the first day of the year.
  FirstFullWeek,    /// Indicates that the first week of the year is the first full week following the first day of the year.
  FirstFourDayWeek  /// Indicates that the first week of the year is the first week containing at least four days.
}

/**
*/
public enum GregorianCalendarTypes {
  Localized = 1,               /// Refers to the localized version of the Gregorian calendar.
  USEnglish = 2,               /// Refers to the US English version of the Gregorian calendar.
  MiddleEastFrench = 9,        /// Refers to the Middle East French version of the Gregorian calendar.
  Arabic = 10,                 /// Refers to the _Arabic version of the Gregorian calendar.
  TransliteratedEnglish = 11,  /// Refers to the transliterated English version of the Gregorian calendar.
  TransliteratedFrench = 12    /// Refers to the transliterated French version of the Gregorian calendar.
}

package enum DatePart {
  YEAR,
  MONTH,
  DAY,
  DAY_OF_YEAR
}


package const int[] DAYS_TO_MONTH_COMMON = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 ];
package const int[] DAYS_TO_MONTH_LEAP = [ 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 ];

package enum : ulong 
        {
        TICKS_PER_MILLISECOND = 10000,
        TICKS_PER_SECOND = TICKS_PER_MILLISECOND * 1000,
        TICKS_PER_MINUTE = TICKS_PER_SECOND * 60,
        TICKS_PER_HOUR = TICKS_PER_MINUTE * 60,
        TICKS_PER_DAY = TICKS_PER_HOUR * 24,
        }

package enum : int
        {
        MILLIS_PER_SECOND = 1000,
        MILLIS_PER_MINUTE = MILLIS_PER_SECOND * 60,
        MILLIS_PER_HOUR = MILLIS_PER_MINUTE * 60,
        MILLIS_PER_DAY = MILLIS_PER_HOUR * 24,
        DAYS_PER_YEAR = 365,
        DAYS_PER_4_YEARS = DAYS_PER_YEAR * 4 + 1,
        DAYS_PER_100_YEARS = DAYS_PER_4_YEARS * 25 - 1,
        DAYS_PER_400_YEARS = DAYS_PER_100_YEARS * 4 + 1,
        DAYS_TO_1601 = DAYS_PER_400_YEARS * 4,
        DAYS_TO_10000 = DAYS_PER_400_YEARS * 25 - 366,
        }

/**
 * $(ANCHOR _DateTime)
 * Represents time expressed as a date and time of day.
 * Remarks: DateTime respresents dates and times between 12:00:00 midnight on January 1, 0001 AD and 11:59:59 PM on 
 * December 31, 9999 AD.
 *
 * Time values are measured in 100-nanosecond intervals, or ticks. A date value is the number of ticks that have elapsed since 
 * 12:00:00 midnight on January 1, 0001 AD in the $(LINK2 #GregorianCalendar, GregorianCalendar) calendar.
 */
public struct DateTime {

  package enum Kind : ulong 
  {
    UNKNOWN = 0x0000000000000000,
    UTC = 0x4000000000000000,
    LOCAL = 0x8000000000000000
  }

  private enum : ulong 
          {
          MIN_TICKS = 0,
          MAX_TICKS = DAYS_TO_10000 * TICKS_PER_DAY - 1,
          TICKS_MASK = 0x3FFFFFFFFFFFFFFF,
          KIND_MASK = 0xC000000000000000,
          }

  private const int KIND_SHIFT = 62;

  private ulong data_;

  /**
   * Represents the smallest DateTime value.
   */
  public static const DateTime min;
  /**
   * Represents the largest DateTime value.
   */
  public static const DateTime max;

  static this() {
    min = DateTime(MIN_TICKS);
    max = DateTime(MAX_TICKS);
  }

  /**
   * $(I Constructor.) Initializes a new instance of the DateTime struct to the specified Time.
   * Params: time = A Tango time expressed in units of 100 nanoseconds.
   */
  public static DateTime opCall(Time time) {
    DateTime d;
    d.data_ = cast(ulong) time;
    return d;
  }

  /**
   * $(I Constructor.) Initializes a new instance of the DateTime struct to the specified number of _ticks.
   * Params: ticks = A date and time expressed in units of 100 nanoseconds.
   */
  public static DateTime opCall(ulong ticks) {
    DateTime d;
    d.data_ = ticks;
    return d;
  }

  /**
   * $(I Constructor.) Initializes a new instance of the DateTime struct to the specified _year, _month, _day and _calendar.
   * Params:
   *   year = The _year.
   *   month = The _month.
   *   day = The _day.
   *   calendar = The Calendar that applies to this instance.
   */
  public static DateTime opCall(int year, int month, int day, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day);
    else
      d.data_ = calendar.getDateTime(year, month, day, 0, 0, 0, 0).ticks;
    return d;
  }

  /**
   * $(I Constructor.) Initializes a new instance of the DateTime struct to the specified _year, _month, _day, _hour, _minute, _second and _calendar.
   * Params:
   *   year = The _year.
   *   month = The _month.
   *   day = The _day.
   *   hour = The _hours.
   *   minute = The _minutes.
   *   second = The _seconds.
   *   calendar = The Calendar that applies to this instance.
   */
  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second);
    else
      d.data_ = calendar.getDateTime(year, month, day, hour, minute, second, 0).ticks;
    return d;
  }

  /**
   * $(I Constructor.) Initializes a new instance of the DateTime struct to the specified _year, _month, _day, _hour, _minute, _second, _millisecond and _calendar.
   * Params:
   *   year = The _year.
   *   month = The _month.
   *   day = The _day.
   *   hour = The _hours.
   *   minute = The _minutes.
   *   second = The _seconds.
   *   millisecond = The _milliseconds.
   *   calendar = The Calendar that applies to this instance.
   */
  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second, int millisecond, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND);
    else
      d.data_ = calendar.getDateTime(year, month, day, hour, minute, second, millisecond).ticks;
    return d;
  }

  /**
   * Compares two DateTime values.
   */
  public int opCmp(DateTime value) {
    if (ticks < value.ticks)
      return -1;
    else if (ticks > value.ticks)
      return 1;
    return 0;
  }

  /**
   * Determines whether two DateTime values are equal.
   * Params: value = A DateTime _value.
   * Returns: true if both instances are equal; otherwise, false;
   */
  public bool opEquals(DateTime value) {
    return ticks == value.ticks;
  }

  /**
   * Adds the specified time span to the date and time, returning a new date and time.
   * Params: t = A TimeSpan value.
   * Returns: A DateTime that is the sum of this instance and t.
   */
  public DateTime opAdd(TimeSpan t) {
    return DateTime(ticks + t.ticks);
  }

  /**
   * Adds the specified time span to the date and time, assigning the result to this instance.
   * Params: t = A TimeSpan value.
   * Returns: The current DateTime instance, with t added to the date and time.
   */
  public DateTime opAddAssign(TimeSpan t) {
    return data_ = (ticks + t.ticks) | kind, *this;
  }

  /**
   * Subtracts the specified time span from the date and time, returning a new date and time.
   * Params: t = A TimeSpan value.
   * Returns: A DateTime whose value is the value of this instance minus the value of t.
   */
  public DateTime opSub(TimeSpan t) {
    return DateTime(ticks - t.ticks);
  }

  /**
   * Subtracts the specified time span from the date and time, assigning the result to this instance.
   * Params: t = A TimeSpan value.
   * Returns: The current DateTime instance, with t subtracted from the date and time.
   */
  public DateTime opSubAssign(TimeSpan t) {
    return data_ = (ticks - t.ticks) | kind, *this;
  }

  /**
   * Adds the specified number of ticks to the _value of this instance.
   * Params: value = The number of ticks to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the time in value.
   */
  public DateTime addTicks(ulong value) {
    return DateTime((ticks + value) | kind);
  }

  /**
   * Adds the specified number of hours to the _value of this instance.
   * Params: value = The number of hours to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of hours in value.
   */
  public DateTime addHours(int value) {
    return addMilliseconds(value * MILLIS_PER_HOUR);
  }

  /**
   * Adds the specified number of minutes to the _value of this instance.
   * Params: value = The number of minutes to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of minutes in value.
   */
  public DateTime addMinutes(int value) {
    return addMilliseconds(value * MILLIS_PER_MINUTE);
  }

  /**
   * Adds the specified number of seconds to the _value of this instance.
   * Params: value = The number of seconds to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of seconds in value.
   */
  public DateTime addSeconds(int value) {
    return addMilliseconds(value * MILLIS_PER_SECOND);
  }

  /**
   * Adds the specified number of milliseconds to the _value of this instance.
   * Params: value = The number of milliseconds to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of milliseconds in value.
   */
  public DateTime addMilliseconds(double value) {
    return addTicks(cast(ulong)(cast(long)(value + ((value >= 0) ? 0.5 : -0.5))) * TICKS_PER_MILLISECOND);
  }

  /**
   * Adds the specified number of days to the _value of this instance.
   * Params: value = The number of days to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of days in value.
   */
  public DateTime addDays(int value) {
    return addMilliseconds(value * MILLIS_PER_DAY);
  }

  /**
   * Adds the specified number of months to the _value of this instance.
   * Params: value = The number of months to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of months in value.
   */
  public DateTime addMonths(int value) {
    int year = this.year;
    int month = this.month;
    int day = this.day;
    int n = month - 1 + value;
    if (n >= 0) {
      month = n % 12 + 1;
      year = year + n / 12;
    }
    else {
      month = 12 + (n + 1) % 12;
      year = year + (n - 11) / 12;
    }
    int maxDays = daysInMonth(year, month);
    if (day > maxDays)
      day = maxDays;
    return DateTime((getDateTicks(year, month, day) + (ticks % TICKS_PER_DAY)) | kind);
  }

  /**
   * Adds the specified number of years to the _value of this instance.
   * Params: value = The number of years to add.
   * Returns: A DateTime whose value is the sum of the date and time of this instance and the number of years in value.
   */
  public DateTime addYears(int value) {
    return addMonths(value * 12);
  }

  /**
   * Returns the number of _days in the specified _month.
   * Params:
   *   year = The _year.
   *   month = The _month.
   * Returns: The number of _days in the specified _month.
   */
  public static int daysInMonth(int year, int month) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  /**
   * Returns a value indicating whether the specified _year is a leap _year.
   * Param: year = The _year.
   * Returns: true if year is a leap _year; otherwise, false.
   */
  public static bool isLeapYear(int year) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

version (Full)
{
  /**
   * Determines whether this instance is within the Daylight Saving Time range for the current time zone.
   * Returns: true if the value of this instance is within the Daylight Saving Time for the current time zone; otherwise, false.
   */
  public bool isDaylightSavingTime() {
    return TimeZone.current.isDaylightSavingTime(*this);
  }

  /**
   * Converts the value of this instance to local time.
   * Returns: A DateTime whose value is the local time equivalent to the value of the current instance.
   */
  public DateTime toLocalTime() {
    //return TimeZone.current.getLocalTime(*this);
  }

  /**
   * Converts the value of this instance to UTC time.
   * Returns: A DateTime whose value is the UTC equivalent to the value of the current instance.
   */
  public DateTime toUniversalTime() {
    //return TimeZone.current.getUniversalTime(*this);
    if (this.kind == Kind.UTC)
        return *this;
    return DateTime(Utc.toLocal(cast(Time)ticks) | DateTime.Kind.UTC);
  }
}
  
  /**
   * Converts the value of this instance to its equivalent string representation using the specified culture-specific formatting information.
   * Params: formatService = An IFormatService that provides culture-specific formatting information.
   * Returns: A string representation of the value of this instance as specified by formatService.
   * Remarks: The value of the DateTime instance is formatted using the "G" format specifier.
   *
   * See $(LINK2 datetimeformat.html, DateTime Formatting) for more information about date and time formatting.
   */
version (Full)
{
  public char[] toUtf8(char[] output, IFormatService formatService = null) {
    return toUtf8 (output, null, formatService);
  }

}
  /**
   * Converts the value of this instance to its equivalent string representation using the specified _format and culture-specific formatting information.
   * Params: 
   *   format = A _format string.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   * Returns: A string representation of the value of this instance as specified by format and formatService.
   * Remarks: See $(LINK2 datetimeformat.html, DateTime Formatting) for more information about date and time formatting.
   * Examples:
   * ---
   * import tango.io.Print, tango.text.locale.Core;
   *
   * void main() {
   *   Culture culture = Culture.current;
   *   DateTime now = DateTime.now;
   *
   *   Println("Current date and time: %s", now.toUtf8());
   *   Println();
   *
   *   // Format the current date and time in a number of ways.
   *   Println("Culture: %s", culture.englishName);
   *   Println();
   *
   *   Println("Short date:              %s", now.toUtf8("d"));
   *   Println("Long date:               %s", now.toUtf8("D"));
   *   Println("Short time:              %s", now.toUtf8("t"));
   *   Println("Long time:               %s", now.toUtf8("T"));
   *   Println("General date short time: %s", now.toUtf8("g"));
   *   Println("General date long time:  %s", now.toUtf8("G"));
   *   Println("Month:                   %s", now.toUtf8("M"));
   *   Println("RFC1123:                 %s", now.toUtf8("R"));
   *   Println("Sortable:                %s", now.toUtf8("s"));
   *   Println("Year:                    %s", now.toUtf8("Y"));
   *   Println();
   *
   *   // Display the same values using a different culture.
   *   culture = Culture.getCulture("fr-FR");
   *   Println("Culture: %s", culture.englishName);
   *   Println();
   *
   *   Println("Short date:              %s", now.toUtf8("d", culture));
   *   Println("Long date:               %s", now.toUtf8("D", culture));
   *   Println("Short time:              %s", now.toUtf8("t", culture));
   *   Println("Long time:               %s", now.toUtf8("T", culture));
   *   Println("General date short time: %s", now.toUtf8("g", culture));
   *   Println("General date long time:  %s", now.toUtf8("G", culture));
   *   Println("Month:                   %s", now.toUtf8("M", culture));
   *   Println("RFC1123:                 %s", now.toUtf8("R", culture));
   *   Println("Sortable:                %s", now.toUtf8("s", culture));
   *   Println("Year:                    %s", now.toUtf8("Y", culture));
   *   Println();
   * }
   *
   * // Produces the following output:
   * // Current date and time: 26/05/2006 10:04:57 AM
   * //
   * // Culture: English (United Kingdom)
   * //
   * // Short date:              26/05/2006
   * // Long date:               26 May 2006
   * // Short time:              10:04
   * // Long time:               10:04:57 AM
   * // General date short time: 26/05/2006 10:04
   * // General date long time:  26/05/2006 10:04:57 AM
   * // Month:                   26 May
   * // RFC1123:                 Fri, 26 May 2006 10:04:57 GMT
   * // Sortable:                2006-05-26T10:04:57
   * // Year:                    May 2006
   * //
   * // Culture: French (France)
   * //
   * // Short date:              26/05/2006
   * // Long date:               vendredi 26 mai 2006
   * // Short time:              10:04
   * // Long time:               10:04:57
   * // General date short time: 26/05/2006 10:04
   * // General date long time:  26/05/2006 10:04:57
   * // Month:                   26 mai
   * // RFC1123:                 ven., 26 mai 2006 10:04:57 GMT
   * // Sortable:                2006-05-26T10:04:57
   * // Year:                    mai 2006
   * ---
   */
version (Full)
{
  public char[] toUtf8(char[] output, char[] format, IFormatService formatService = null) {
    return formatDateTime(output, *this, format, DateTimeFormat.getInstance(formatService));
  }
}
  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent using the specified culture-specific formatting information.
   * Params:
   *   s = A string representing the date and time to convert.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   * Returns: A DateTime equivalent to the date and time contained in s as specified by formatService.
   * Remarks: The s parameter is parsed using the formatting information in the current $(LINK2 #DateTimeFormat, DateTimeFormat) instance.
   * Examples:
   * ---
   * import tango.io.Print, tango.text.locale.Core;
   *
   * void main() {
   *   // Date is May 26, 2006
   *   char[] ukDateValue = "26/05/2006 9:15:10";
   *   char[] usDateValue = "05/26/2006 9:15:10";
   *
   *   Culture.current = Culture.getCulture("en-GB");
   *   DateTime ukDate = DateTime.parse(ukDateValue);
   *   Println("UK date: %s", ukDate.toUtf8());

   *   Culture.current = Culture.getCulture("en-US");
   *   DateTime usDate = DateTime.parse(usDateValue);
   *   Println("US date: %s", usDate.toUtf8());
   * }
   *
   * // Produces the following output:
   * // UK date: 26/05/2006 9:15:10 AM
   * // US date: 5/26/2006 9:15:10 AM
   * ---
   */
version (Full)
{
  public static DateTime parse(char[] s, IFormatService formatService = null) {
    DateTime result = parseDateTime(s, DateTimeFormat.getInstance(formatService));
    return result;
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalent using the specified culture-specific formatting information.
   * The _format of the string representation must exactly match the specified format.
   * Params:
   *   s = A string representing the date and time to convert.
   *   format = The expected _format of s.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   * Returns: A DateTime equivalent to the date and time contained in s as specified by format and formatService.
   */
  public static DateTime parseExact(char[] s, char[] format, IFormatService formatService = null) {
    DateTime result = parseDateTimeExact(s, format, DateTimeFormat.getInstance(formatService));
    return result;
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalant.
   * Params:
   *   s = A string representing the date and time to convert.
   *   result = On return, contains the DateTime value equivalent to the date and time in s if the conversion was successful.
   * Returns: true if s is converted successfully; otherwise, false.
   */
  public static bool tryParse(char[] s, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.current, result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalant using the specified culture-specific formatting information.
   * Params:
   *   s = A string representing the date and time to convert.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   *   result = On return, contains the DateTime value equivalent to the date and time in s if the conversion was successful.
   * Returns: true if s is converted successfully; otherwise, false.
   */
  public static bool tryParse(char[] s, IFormatService formatService, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.getInstance(formatService), result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalant using the specified culture-specific formatting information.
   * The _format of the string representation must exactly match the specified format.
   * Params:
   *   s = A string representing the date and time to convert.
   *   format = The expected _format of s.
   *   result = On return, contains the DateTime value equivalent to the date and time in s if the conversion was successful.
   * Returns: true if s is converted successfully; otherwise, false.
   */
  public static bool tryParseExact(char[] s, char[] format, out DateTime result) {
    return tryParseDateTimeExact(s, format, DateTimeFormat.current, result);
  }

  /**
   * Converts the specified string representation of a date and time to its DateTime equivalant using the specified culture-specific formatting information.
   * The _format of the string representation must exactly match the specified format.
   * Params:
   *   s = A string representing the date and time to convert.
   *   format = The expected _format of s.
   *   formatService = An IFormatService that provides culture-specific formatting information.
   *   result = On return, contains the DateTime value equivalent to the date and time in s if the conversion was successful.
   * Returns: true if s is converted successfully; otherwise, false.
   */
  public static bool tryParseExact(char[] s, char[] format, IFormatService formatService, out DateTime result) {
    return tryParseDateTimeExact(s, format, DateTimeFormat.getInstance(formatService), result);
  }

  }

  /**
   * $(I Property.) Retrieves the _year component of the date.
   * Returns: The _year.
   */
  public int year() {
    return extractPart(ticks, DatePart.YEAR);
  }

  /**
   * $(I Property.) Retrieves the _month component of the date.
   * Returns: The _month.
   */
  public int month() {
    return extractPart(ticks, DatePart.MONTH);
  }

  /**
   * $(I Property.) Retrieves the _day component of the date.
   * Returns: The _day.
   */
  public int day() {
    return extractPart(ticks, DatePart.DAY);
  }

  /**
   * $(I Property.) Retrieves the day of the year.
   * Returns: The day of the year.
   */
  public int dayOfYear() {
    return extractPart(ticks, DatePart.DAY_OF_YEAR);
  }

  /**
   * $(I Property.) Retrieves the day of the week.
   * Returns: A DayOfWeek value indicating the day of the week.
   */
  public DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)((ticks / TICKS_PER_DAY + 1) % 7);
  }

  /**
   * $(I Property.) Retrieves the _hour component of the date.
   * Returns: The _hour.
   */
  public int hour() {
    return cast(int)((ticks / TICKS_PER_HOUR) % 24);
  }

  /**
   * $(I Property.) Retrieves the _minute component of the date.
   * Returns: The _minute.
   */
  public int minute() {
    return cast(int)((ticks / TICKS_PER_MINUTE) % 60);
  }

  /**
   * $(I Property.) Retrieves the _second component of the date.
   * Returns: The _second.
   */
  public int second() {
    return cast(int)((ticks / TICKS_PER_SECOND) % 60);
  }

  /**
   * $(I Property.) Retrieves the _millisecond component of the date.
   * Returns: The _millisecond.
   */
  public int millisecond() {
    return cast(int)((ticks / TICKS_PER_MILLISECOND) % 1000);
  }

  /**
   * $(I Property.) Retrieves the date component.
   * Returns: A new DateTime instance with the same date as this instance.
   */
  public DateTime date() {
    ulong ticks = this.ticks;
    return DateTime((ticks - ticks % TICKS_PER_DAY) | kind);
  }

  /**
   * $(I Property.) Retrieves the current date.
   * Returns: A DateTime instance set to today's date.
   */
  public static DateTime today() {
    // return now.date;
    // The above code causes DMD to complain about lvalues in toLocalTime, so we need a temporary here.
    DateTime d = now;
    return d.date;
  }

  /**
   * $(I Property.) Retrieves the time of day.
   * Returns: A TimeSpan representing the fraction of the day elapsed since midnight.
   */
  public TimeSpan timeOfDay() {
    return TimeSpan(ticks % TICKS_PER_DAY);
  }

  /**
   * $(I Property.) Retrieves the number of ticks representing the date and time of this instance.
   * Returns: The number of ticks representing the date and time of this instance.
   */
  public ulong ticks() {
    return data_ & TICKS_MASK;
  }

  /**
   * $(I Property.) Retrieves a Time value representing the date and time of this instance.
   * Returns: A Time represented by the date and time of this instance.
   */
  public Time time() {
    return cast(Time) ticks;
  }

  /**
   * $(I Property.) Retrieves a DateTime instance set to the current date and time in local time.
   * Returns: A DateTime whose value is the current local date and time.
   * Examples:
   * The following example displays the current time in local and UTC time.
   * ---
   * import tango.io.Print, tango.text.locale.Core;
   *
   * void main() {
   *   // Get the current local time.
   *   DateTime localTime = DateTime.now;
   *
   *   // Convert the current local time to UTC time.
   *   DateTime utcTime = localTime.toUniversalTime();
   *
   *   // Display the local and UTC time using a custom pattern.
   *   char[] pattern = "d/M/yyyy hh:mm:ss tt";
   *   Println("Local time: %s", localTime.toUtf8(pattern));
   *   Println("UTC time:   %s", utcTime.toUtf8(pattern));
   * }
   *
   * // Produces the following output:
   * // Local time: 26/5/2006 9:15:00 AM
   * // UTC time:   26/5/2006 8:15:00 AM
   * ---
   */

  public static DateTime now() {
    // return utcNow.toLocalTime();
    // The above code causes DMD to complain about lvalues in toLocalTime, so we need a temporary here.
    //DateTime d = utcNow.toLocalTime();
    //return d;
    auto ticks = Utc.local();
    return DateTime (cast(ulong) ticks | Kind.LOCAL);
  }

  /**
   * $(I Property.) Retrieves a DateTime instance set to the current date and time in UTC time.
   * Returns: A DateTime whose value is the current UTC date and time.
   */
  public static DateTime utcNow() {
    auto ticks = Utc.now();
    return DateTime (cast(ulong) ticks | Kind.UTC);
  }

  package ulong kind() {
    return data_ & KIND_MASK;
  }

  private static ulong getDateTicks(int year, int month, int day) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    year--;
    return (year * 365 + year / 4 - year / 100 + year / 400 + monthDays[month - 1] + day - 1) * TICKS_PER_DAY;
  }

  private static ulong getTimeTicks(int hour, int minute, int second) {
    return (cast(ulong)hour * 3600 + cast(ulong)minute * 60 + cast(ulong)second) * TICKS_PER_SECOND;
  }

}

/**
 * $(ANCHOR _TimeSpan)
 * Represents a time interval.
 */
public struct TimeSpan {

  private ulong ticks_;
  private bool  backward_;

  /**
   * Represents the minimum value.
   */
  public static const TimeSpan min;
  /**
   * Represents the maximum value.
   */
  public static const TimeSpan max;

  static this() {
    min = TimeSpan(ulong.min);
    max = TimeSpan(ulong.max);
  }

  /**
   * $(I Constructor.) Initializes a new TimeSpan to the specified number of _ticks.
   * Params: ticks = A time interval in units of 100 nanoseconds.
   */
  public static TimeSpan opCall(ulong ticks) {
    TimeSpan t;
    t.ticks_ = ticks;
    return t;
  }

  /**
   * $(I Constructor.) Initializes a new TimeSpan to the specified number of _hours, _minutes and _seconds.
   * Params:
   *   hours = The number of _hours.
   *   minutes = The number of _minutes.
   *   seconds = The number of _seconds.
   */
  public static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan t;
    t.ticks_ = getTicks(hours, minutes, seconds);
    return t;
  }

  /**
   * $(I Constructor.) Initializes a new TimeSpan to the specified number of _hours, _minutes, _seconds and _milliseconds.
   * Params:
   *   hours = The number of _hours.
   *   minutes = The number of _minutes.
   *   seconds = The number of _seconds.
   *   milliseconds = The number of _milliseconds.
   */
  public static TimeSpan opCall(int hours, int minutes, int seconds, int milliseconds) {
    TimeSpan t;
    t.ticks_ = getTicks(hours, minutes, seconds) + (milliseconds * TICKS_PER_MILLISECOND);
    return t;
  }

  /**
   * Adds two TimeSpan instances.
   * Params: t = A TimeSpan.
   * Returns: A TimeSpan whose value is the sum of the value of this instance and the value of t.
   */
  public TimeSpan opAdd(TimeSpan t) {
    return TimeSpan(ticks_ + t.ticks_);
  }

  /**
   * Adds two TimeSpan instances and assigns the result to this instance.
   * Params: t = A TimeSpan.
   * Returns: This instance, modified by adding value of t.
   */
  public TimeSpan opAddAssign(TimeSpan t) {
    ticks_ += t.ticks_;
    return *this;
  }

  /**
   * Subtracts the specified TimeSpan from this instance.
   * Params: t = A TimeSpan.
   * Returns: A TimeSpan whose value is the result of the value of this instance minus the value of t.
   */
  public TimeSpan opSub(TimeSpan t) {
    return TimeSpan(ticks_ - t.ticks_);
  }

  /**
   * Subtracts the specified TimeSpan and assigns the result to this instance.
   * Params: t = A TimeSpan.
   * Returns: This instance, modified by subtracting the value of t.
   */
  public TimeSpan opSubAssign(TimeSpan t) {
    ticks_ -= t.ticks_;
    return *this;
  }

  /**
   */
  public void invert() {
     backward_ = !backward_;
     ticks_ = -ticks_;
  }

  /**
   */
  public bool backward() {
     return backward_;
  }

  /**
   * Returns a TimeSpan whose value is the negated value of this instance.
   * Returns: The same value as this instance with the opposite sign.
   */
  public TimeSpan negate() {
    return TimeSpan(-ticks_);
  }

  /**
   * $(I Property.) Retrieves the number of _ticks representing the value of this instance.
   * Returns: The number of _ticks in this instance.
   */
  public ulong ticks() {
    return ticks_;
  }

  /**
   * $(I Property.) Retrieves the number of _hours represented by this instance.
   * Returns: The number of _hours in this instance.
   */
  public int hours() {
    return cast(int)((ticks_ / TICKS_PER_HOUR) % 24);
  }

  /**
   * $(I Property.) Retrieves the number of _minutes represented by this instance.
   * Returns: The number of _minutes in this instance.
   */
  public int minutes() {
    return cast(int)((ticks_ / TICKS_PER_MINUTE) % 60);
  }

  /**
   * $(I Property.) Retrieves the number of _seconds represented by this instance.
   * Returns: The number of _seconds in this instance.
   */
  public int seconds() {
    return cast(int)((ticks_ / TICKS_PER_SECOND) % 60);
  }

  /**
   * $(I Property.) Retrieves the number of _milliseconds represented by this instance.
   * Returns: The number of _milliseconds in this instance.
   */
  public int milliseconds() {
    return cast(int)((ticks_ / TICKS_PER_MILLISECOND) % 1000);
  }

  /**
   * $(I Property.) Retrieves the number of _days represented by this instance.
   * Returns: The number of _days in this instance.
   */
  public int days() {
    return cast(int)(ticks_ / TICKS_PER_DAY);
  }

  package static ulong getTicks(int hour, int minute, int second) {
    return (cast(ulong)hour * 3600 + cast(ulong)minute * 60 + cast(ulong)second) * TICKS_PER_SECOND;
  }

}



 
// Used by cloneObject.
extern (C) private Object _d_newclass(ClassInfo info);

// Creates a shallow copy of an object.
Object cloneObject(Object obj) 
{
  if (obj is null)
    return null;

  ClassInfo ci = obj.classinfo;
  size_t start = Object.classinfo.init.length;
  size_t end = ci.init.length;

  Object clone = _d_newclass(ci);
  (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
  return clone;
}



/**
 * $(ANCHOR _Calendar)
 * Represents time in week, month and year divisions.
 * Remarks: Calendar is the abstract base class for the following Calendar implementations: 
 *   $(LINK2 #GregorianCalendar, GregorianCalendar), $(LINK2 #HebrewCalendar, HebrewCalendar), $(LINK2 #HijriCalendar, HijriCalendar),
 *   $(LINK2 #JapaneseCalendar, JapaneseCalendar), $(LINK2 #KoreanCalendar, KoreanCalendar), $(LINK2 #TaiwanCalendar, TaiwanCalendar) and
 *   $(LINK2 #ThaiBuddhistCalendar, ThaiBuddhistCalendar).
 */
public abstract class Calendar {

  /**
   * Indicates the current era of the calendar.
   */
  public const int CURRENT_ERA = 0;

  package bool isReadOnly_;

  /**
   * Initiate with the provided ReadOnly state
   */
  public this(bool readOnly=false) 
  {
        isReadOnly_ = readOnly;
  }

  /**
   * Creates a copy of the current instance.
   * Returns: A new Object that is a copy of the current instance.
   */
  public Object clone() {
    Calendar other = cast(Calendar)cloneObject(this);
    other.isReadOnly_ = false;
    return other;
  }

  /**
   * Returns a DateTime value set to the specified date and time in the current era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   day = An integer representing the _day.
   *   hour = An integer representing the _hour.
   *   minute = An integer representing the _minute.
   *   second = An integer representing the _second.
   *   millisecond = An integer representing the _millisecond.
   * Returns: The DateTime set to the specified date and time.
   */
  public DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    return getDateTime(year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
  }

  /**
   * When overridden, returns a DateTime value set to the specified date and time in the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   day = An integer representing the _day.
   *   hour = An integer representing the _hour.
   *   minute = An integer representing the _minute.
   *   second = An integer representing the _second.
   *   millisecond = An integer representing the _millisecond.
   *   era = An integer representing the _era.
   * Returns: A DateTime set to the specified date and time.
   */
  public abstract DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era);

  /**
   * When overridden, returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public abstract DayOfWeek getDayOfWeek(DateTime time);

  /**
   * When overridden, returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public abstract int getDayOfMonth(DateTime time);

  /**
   * When overridden, returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public abstract int getDayOfYear(DateTime time);

  /**
   * When overridden, returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public abstract int getMonth(DateTime time);

  /**
   * When overridden, returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public abstract int getYear(DateTime time);

  /**
   * When overridden, returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public abstract int getEra(DateTime time);

  /**
   * Returns the number of days in the specified _year and _month of the current era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   * Returns: The number of days in the specified _year and _month of the current era.
   */
  public int getDaysInMonth(int year, int month) {
    return getDaysInMonth(year, month, CURRENT_ERA);
  }

  /**
   * When overridden, returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public abstract int getDaysInMonth(int year, int month, int era);

  /**
   * Returns the number of days in the specified _year of the current era.
   * Params: year = An integer representing the _year.
   * Returns: The number of days in the specified _year in the current era.
   */
  public int getDaysInYear(int year) {
    return getDaysInYear(year, CURRENT_ERA);
  }

  /**
   * When overridden, returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public abstract int getDaysInYear(int year, int era);

  /**
   * Returns the number of months in the specified _year of the current era.
   * Params: year = An integer representing the _year.
   * Returns: The number of months in the specified _year in the current era.
   */
  public int getMonthsInYear(int year) {
    return getMonthsInYear(year, CURRENT_ERA);
  }

  /**
   * When overridden, returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public abstract int getMonthsInYear(int year, int era);

  /**
   * Returns the week of the year that includes the specified DateTime.
   * Params:
   *   time = A DateTime value.
   *   rule = A CalendarWeekRule value defining a calendar week.
   *   firstDayOfWeek = A DayOfWeek value representing the first day of the week.
   * Returns: An integer representing the week of the year that includes the date in time.
   */
  public int getWeekOfYear(DateTime time, CalendarWeekRule rule, DayOfWeek firstDayOfWeek) {
    int year = getYear(time);
    int jan1 = cast(int)getDayOfWeek(getDateTime(year, 1, 1, 0, 0, 0, 0));

    switch (rule) {
      case CalendarWeekRule.FirstDay:
        int n = jan1 - cast(int)firstDayOfWeek;
        if (n < 0)
          n += 7;
        return (getDayOfYear(time) + n - 1) / 7 + 1;
      case CalendarWeekRule.FirstFullWeek:
      case CalendarWeekRule.FirstFourDayWeek:
        int fullDays = (rule == CalendarWeekRule.FirstFullWeek) ? 7 : 4;
        int n = cast(int)firstDayOfWeek - jan1;
        if (n != 0) {
          if (n < 0)
            n += 7;
          else if (n >= fullDays)
            n -= 7;
        }
        int day = getDayOfYear(time) - n;
        if (day > 0)
          return (day - 1) / 7 + 1;
        year = getYear(time) - 1;
        int month = getMonthsInYear(year);
        day = getDaysInMonth(year, month);
        return getWeekOfYear(getDateTime(year, month, day, 0, 0, 0, 0), rule, firstDayOfWeek);
      default:
        break;
    }
    // To satisfy -w
    throw new Exception("Value was out of range.");
  }

  /**
   * Indicates whether the specified _year in the current era is a leap _year.
   * Params: year = An integer representing the _year.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public bool isLeapYear(int year) {
    return isLeapYear(year, CURRENT_ERA);
  }

  /**
   * When overridden, indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public abstract bool isLeapYear(int year, int era);

  /**
   * $(I Property.) When overridden, retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public abstract int[] eras();

  /**
   * $(I Property.) Retreives a value indicating whether the instance is read-only.
   * Returns: true if the instance is read-only; otherwise, false.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * $(I Property.) Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public int id() {
    return -1;
  }

 // Corresponds to Win32 calendar IDs
  package enum {
    GREGORIAN = 1,
    GREGORIAN_US = 2,
    JAPAN = 3,
    TAIWAN = 4,
    KOREA = 5,
    HIJRI = 6,
    THAI = 7,
    HEBREW = 8,
    GREGORIAN_ME_FRENCH = 9,
    GREGORIAN_ARABIC = 10,
    GREGORIAN_XLIT_ENGLISH = 11,
    GREGORIAN_XLIT_FRENCH = 12
  }

}



package void splitDate(ulong ticks, out int year, out int month, out int day, out int dayOfYear) 
{
  int numDays = cast(int)(ticks / TICKS_PER_DAY);
  int whole400Years = numDays / DAYS_PER_400_YEARS;
  numDays -= whole400Years * DAYS_PER_400_YEARS;
  int whole100Years = numDays / DAYS_PER_100_YEARS;
  if (whole100Years == 4)
    whole100Years = 3;
  numDays -= whole100Years * DAYS_PER_100_YEARS;
  int whole4Years = numDays / DAYS_PER_4_YEARS;
  numDays -= whole4Years * DAYS_PER_4_YEARS;
  int wholeYears = numDays / DAYS_PER_YEAR;
  if (wholeYears == 4)
    wholeYears = 3;
  year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
  numDays -= wholeYears * DAYS_PER_YEAR;
  dayOfYear = numDays + 1;
  int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
  month = numDays >> 5 + 1;
  while (numDays >= monthDays[month])
    month++;
  day = numDays - monthDays[month - 1] + 1;
}

package int extractPart(ulong ticks, DatePart part) 
{
  int year, month, day, dayOfYear;
  splitDate(ticks, year, month, day, dayOfYear);
  if (part == DatePart.YEAR)
    return year;
  else if (part == DatePart.MONTH)
    return month;
  else if (part == DatePart.DAY_OF_YEAR)
    return dayOfYear;
  return day;
}




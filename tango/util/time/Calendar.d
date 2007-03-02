/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.util.time.Calendar;

private import tango.util.time.DateTime;


// Initializes an array.
private template arrayOf(T) {
  private T[] arrayOf(T[] params ...) {
    return params.dup;
  }
}

package struct EraRange {

  private static EraRange[][int] eraRanges;
  private static int[int] currentEras;
  private static bool initialized_;

  package int era;
  package ulong ticks;
  package int yearOffset;
  package int minEraYear;
  package int maxEraYear;

  private static void initialize() {
    if (!initialized_) {
      eraRanges[Calendar.JAPAN] ~= EraRange(4, DateTime(1989, 1, 8).ticks, 1988, 1, GregorianCalendar.MAX_YEAR);
      eraRanges[Calendar.JAPAN] ~= EraRange(3, DateTime(1926, 12, 25).ticks, 1925, 1, 1989);
      eraRanges[Calendar.JAPAN] ~= EraRange(2, DateTime(1912, 7, 30).ticks, 1911, 1, 1926);
      eraRanges[Calendar.JAPAN] ~= EraRange(1, DateTime(1868, 9, 8).ticks, 1867, 1, 1912);
      eraRanges[Calendar.TAIWAN] ~= EraRange(1, DateTime(1912, 1, 1).ticks, 1911, 1, GregorianCalendar.MAX_YEAR);
      eraRanges[Calendar.KOREA] ~= EraRange(1, DateTime(1, 1, 1).ticks, -2333, 2334, GregorianCalendar.MAX_YEAR);
      eraRanges[Calendar.THAI] ~= EraRange(1, DateTime(1, 1, 1).ticks, -543, 544, GregorianCalendar.MAX_YEAR);
      currentEras[Calendar.JAPAN] = 4;
      currentEras[Calendar.TAIWAN] = 1;
      currentEras[Calendar.KOREA] = 1;
      currentEras[Calendar.THAI] = 1;
      initialized_ = true;
    }
  }

  package static EraRange[] getEraRanges(int calID) {
    if (!initialized_)
      initialize();
    return eraRanges[calID];
  }

  package static int getCurrentEra(int calID) {
    if (!initialized_)
      initialize();
    return currentEras[calID];
  }

  private static EraRange opCall(int era, ulong ticks, int yearOffset, int minEraYear, int prevEraYear) {
    EraRange eraRange;
    eraRange.era = era;
    eraRange.ticks = ticks;
    eraRange.yearOffset = yearOffset;
    eraRange.minEraYear = minEraYear;
    eraRange.maxEraYear = prevEraYear - yearOffset;
    return eraRange;
  }

}



// Calendars
// Apart from GreogrianCalendar, these are pretty much untested.


/**
 * $(ANCHOR _GregorianCalendar)
 * Represents the Gregorian calendar.
*/
public class GregorianCalendar : Calendar {

  /**
   * Represents the current era.
   */
  public const int AD_ERA = 1;

  private const int MAX_YEAR = 9999;

  private static Calendar defaultInstance_;
  private GregorianCalendarTypes type_;

  /**
   * Initializes an instance of the GregorianCalendar class using the specified GregorianCalendarTypes value. If no value is 
   * specified, the default is GregorianCalendarTypes.Localized.
   */
  public this(bool readOnly=false, GregorianCalendarTypes type = GregorianCalendarTypes.Localized) {
    super (readOnly);
    type_ = type;
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return DateTime(year, month, day, hour, minute, second, millisecond);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)((time.ticks / TICKS_PER_DAY + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY_OF_YEAR);
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.MONTH);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return extractPart(time.ticks, DatePart.YEAR);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return AD_ERA;
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    int[] monthDays = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return isLeapYear(year, era) ? 366 : 365;
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return 12;
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  /**
   * $(I Property.) Retrieves the GregorianCalendarTypes value indicating the language version of the GregorianCalendar.
   * Returns: The GregorianCalendarTypes value indicating the language version of the GregorianCalendar.
   */
  public GregorianCalendarTypes calendarType() {
    return type_;
  }
  /**
   * $(I Property.) Assigns the GregorianCalendarTypes _value indicating the language version of the GregorianCalendar.
   * Params: value = The GregorianCalendarTypes _value indicating the language version of the GregorianCalendar.
   */
  public void calendarType(GregorianCalendarTypes value) {
    checkReadOnly();
    type_ = value;
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return arrayOf!(int)(AD_ERA);
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return cast(int)type_;
  }

  public static Calendar getDefaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar(false);
    return defaultInstance_;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new Exception("Calendar instance is read-only.");
  }
}




private class GregorianBasedCalendar : Calendar {

  private EraRange[] eraRanges_;
  private int maxYear_, minYear_;
  private int currentEra_ = -1;

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    year = getGregorianYear(year, era);
    return DateTime(year, month, day, hour, minute, second, millisecond);
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)((time.ticks / TICKS_PER_DAY + 1) % 7);
  }

  public override int getDayOfMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY);
  }

  public override int getDayOfYear(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY_OF_YEAR);
  }

  public override int getMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.MONTH);
  }

  public override int getYear(DateTime time) {
    ulong ticks = time.ticks;
    int year = extractPart(time.ticks, DatePart.YEAR);
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return year - eraRange.yearOffset;
    }
    throw new Exception("Value was out of range.");
  }

  public override int getEra(DateTime time) {
    ulong ticks = time.ticks;
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return eraRange.era;
    }
    throw new Exception("Value was out of range.");
  }

  public override int getDaysInMonth(int year, int month, int era) {
    int[] monthDays = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  public override int getDaysInYear(int year, int era) {
    return isLeapYear(year, era) ? 366 : 365;
  }

  public override int getMonthsInYear(int year, int era) {
    return 12;
  }

  public override bool isLeapYear(int year, int era) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  public override int[] eras() {
    int[] result;
    foreach (EraRange eraRange; eraRanges_)
      result ~= eraRange.era;
    return result;
  }

  protected this(bool readOnly = false) 
  {
    eraRanges_ = EraRange.getEraRanges(id);
    maxYear_ = eraRanges_[0].maxEraYear;
    minYear_ = eraRanges_[0].minEraYear;
    super (readOnly);
  }

  private int getGregorianYear(int year, int era) {
    if (era == 0)
      era = currentEra;
    foreach (EraRange eraRange; eraRanges_) {
      if (era == eraRange.era) {
        if (year >= eraRange.minEraYear && year <= eraRange.maxEraYear)
          return eraRange.yearOffset + year;
        throw new Exception("Value was out of range.");
      }
    }
    throw new Exception("Era value was not valid.");
  }

  protected int currentEra() {
    if (currentEra_ == -1)
      currentEra_ = EraRange.getCurrentEra(id);
    return currentEra_;
  }
}




/**
 * $(ANCHOR _JapaneseCalendar)
 * Represents the Japanese calendar.
 */
public class JapaneseCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  /**
   * Initializes an instance of the JapaneseCalendar class.
   */
  public this(bool readOnly=false) 
  {
    cal_ = new GregorianBasedCalendar;
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return cal_.eras;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.JAPAN;
  }

}




/**
 * $(ANCHOR _TaiwanCalendar)
 * Represents the Taiwan calendar.
 */
public class TaiwanCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  /**
   * Initializes a new instance of the TaiwanCalendar class.
   */
  public this(bool readOnly=false) 
  {
    cal_ = new GregorianBasedCalendar;
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return cal_.eras;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.TAIWAN;
  }

}




/** 
 * $(ANCHOR _KoreanCalendar)
 * Represents the Korean calendar.
 */
public class KoreanCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  /**
   * Initializes a new instance of the KoreanCalendar class.
   */
  public this(bool readOnly=false) 
  {
    cal_ = new GregorianBasedCalendar;
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return cal_.eras;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.KOREA;
  }

}




/**
 * $(ANCHOR _HijriCalendar)
 * Represents the Hijri calendar.
 */
public class HijriCalendar : Calendar {

  private static const int[] DAYS_TO_MONTH = [ 0, 30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325, 355 ];

  /**
   * Represents the current era.
   */
  public const int HIJRI_ERA = 1;

  public this(bool readOnly=false) 
  {
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return DateTime((daysSinceJan1(year, month, day) - 1) * TICKS_PER_DAY + TimeSpan.getTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND));
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)(cast(int)(time.ticks / TICKS_PER_DAY + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return extractPart(time.ticks, DatePart.DAY_OF_YEAR);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.MONTH);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return extractPart(time.ticks, DatePart.YEAR);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return HIJRI_ERA;
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    if (month == 12)
      return isLeapYear(year, CURRENT_ERA) ? 30 : 29;
    return (month % 2 == 1) ? 30 : 29;
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return isLeapYear(year, era) ? 355 : 354;
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return 12;
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return (14 + 11 * year) % 30 < 11;
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return arrayOf!(int)(HIJRI_ERA);
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.HIJRI;
  }

  private long daysToYear(int year) {
    int cycle = ((year - 1) / 30) * 30;
    int remaining = year - cycle - 1;
    long days = ((cycle * 10631L) / 30L) + 227013L;
    while (remaining > 0) {
      days += 354 + (isLeapYear(remaining, CURRENT_ERA) ? 1 : 0);
      remaining--;
    }
    return days;
  }

  private long daysSinceJan1(int year, int month, int day) {
    return cast(long)(daysToYear(year) + DAYS_TO_MONTH[month - 1] + day);
  }

  private int extractPart(ulong ticks, DatePart part) {
    long days = cast(long)(ticks / TICKS_PER_DAY + 1);
    int year = cast(int)(((days - 227013) * 30) / 10631) + 1;
    long daysUpToYear = daysToYear(year);
    long daysInYear = getDaysInYear(year, CURRENT_ERA);
    if (days < daysUpToYear) {
      daysUpToYear -= daysInYear;
      year--;
    }
    else if (days == daysUpToYear) {
      year--;
      daysUpToYear -= getDaysInYear(year, CURRENT_ERA);
    }
    else if (days > daysUpToYear + daysInYear) {
      daysUpToYear += daysInYear;
      year++;
    }

    if (part == DatePart.YEAR)
      return year;

    days -= daysUpToYear;
    if (part == DatePart.DAY_OF_YEAR)
      return cast(int)days;

    int month = 1;
    while (month <= 12 && days > DAYS_TO_MONTH[month - 1])
      month++;
    month--;
    if (part == DatePart.MONTH)
      return month;

    return cast(int)(days - DAYS_TO_MONTH[month - 1]);
  }

}




/**
 * $(ANCHOR _ThaiBuddhistCalendar)
 * Represents the Thai Buddhist calendar.
 */
public class ThaiBuddhistCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  /**
   * Initializes a new instance of the ThaiBuddhistCalendar class.
   */
  public this(bool readOnly=false) 
  {
    cal_ = new GregorianBasedCalendar;
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return cal_.eras;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.THAI;
  }

}




/**
 * $(ANCHOR _HebrewCalendar)
 * Represents the Hebrew calendar.
 */
public class HebrewCalendar : Calendar {

  private const int[14][7] MONTHDAYS = [
    // month                                                    // year type
    [ 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ], 
    [ 0, 30, 29, 29, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 1
    [ 0, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 2
    [ 0, 30, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 3
    [ 0, 30, 29, 29, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 4
    [ 0, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 5
    [ 0, 30, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ]   // 6
  ];

  private const int YEAROF1AD = 3760;
  private const int DAYS_TO_1AD = cast(int)(YEAROF1AD * 365.2735);

  private const int PARTS_PER_HOUR = 1080;
  private const int PARTS_PER_DAY = 24 * PARTS_PER_HOUR;
  private const int DAYS_PER_MONTH = 29;
  private const int DAYS_PER_MONTH_FRACTION = 12 * PARTS_PER_HOUR + 793;
  private const int PARTS_PER_MONTH = DAYS_PER_MONTH * PARTS_PER_DAY + DAYS_PER_MONTH_FRACTION;
  private const int FIRST_NEW_MOON = 11 * PARTS_PER_HOUR + 204;

  private int minYear_ = YEAROF1AD + 1583;
  private int maxYear_ = YEAROF1AD + 2240;

  /**
   * Represents the current era.
   */
  public const int HEBREW_ERA = 1;

  public this(bool readOnly=false) 
  {
    super (readOnly);
  }

  /**
   * Overridden. Returns a DateTime value set to the specified date and time in the specified _era.
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
  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    checkYear(year, era);
    return getGregorianDateTime(year, month, day, hour, minute, second, millisecond);
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)cast(int)((time.ticks / TICKS_PER_DAY + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    int year = getYear(time);
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DAYS_TO_1AD;
    int day = cast(int)(time.ticks / TICKS_PER_DAY) - days;
    int n;
    while (n < 12 && day >= MONTHDAYS[yearType][n + 1]) {
      day -= MONTHDAYS[yearType][n + 1];
      n++;
    }
    return day + 1;
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    int year = getYear(time);
    int days = getStartOfYear(year) - DAYS_TO_1AD;
    return (cast(int)(time.ticks / TICKS_PER_DAY) - days) + 1;
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    int year = getYear(time);
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DAYS_TO_1AD;
    int day = cast(int)(time.ticks / TICKS_PER_DAY) - days;
    int n;
    while (n < 12 && day >= MONTHDAYS[yearType][n + 1]) {
      day -= MONTHDAYS[yearType][n + 1];
      n++;
    }
    return n + 1;
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    int day = cast(int)(time.ticks / TICKS_PER_DAY) + DAYS_TO_1AD;
    int low = minYear_, high = maxYear_;
    // Perform a binary search.
    while (low <= high) {
      int mid = low + (high - low) / 2;
      int startDay = getStartOfYear(mid);
      if (day < startDay)
        high = mid - 1;
      else if (day >= startDay && day < getStartOfYear(mid + 1))
        return mid;
      else
        low = mid + 1;
    }
    return low;
  }

  /**
   * Overridden. Returns the era in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the ear in time.
   */
  public override int getEra(DateTime time) {
    return HEBREW_ERA;
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override int getDaysInMonth(int year, int month, int era) {
    checkYear(year, era);
    return MONTHDAYS[getYearType(year)][month];
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override int getDaysInYear(int year, int era) {
    return getStartOfYear(year + 1) - getStartOfYear(year);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override int getMonthsInYear(int year, int era) {
    return isLeapYear(year, era) ? 13 : 12;
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(int year, int era) {
    checkYear(year, era);
    // true if year % 19 == 0, 3, 6, 8, 11, 14, 17
    return ((7 * year + 1) % 19) < 7;
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override int[] eras() {
    return arrayOf!(int)(HEBREW_ERA);
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return Calendar.HEBREW;
  }

  private void checkYear(int year, int era) {
    if ((era != CURRENT_ERA && era != HEBREW_ERA) || (year > maxYear_ || year < minYear_))
      throw new Exception("Value was out of range.");
  }

  private int getYearType(int year) {
    int yearLength = getStartOfYear(year + 1) - getStartOfYear(year);
    if (yearLength > 380)
      yearLength -= 30;
    switch (yearLength) {
      case 353:
        // "deficient"
        return 0;
      case 383:
        // "deficient" leap
        return 4;
      case 354:
        // "normal"
        return 1;
      case 384:
        // "normal" leap
        return 5;
      case 355:
        // "complete"
        return 2;
      case 385:
        // "complete" leap
        return 6;
      default:
        break;
    }
    // Satisfies -w
    throw new Exception("Value was not valid.");
  }

  private int getStartOfYear(int year) {
    int months = (235 * year - 234) / 19;
    int fraction = months * DAYS_PER_MONTH_FRACTION + FIRST_NEW_MOON;
    int day = months * 29 + (fraction / PARTS_PER_DAY);
    fraction %= PARTS_PER_DAY;

    int dayOfWeek = day % 7;
    if (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6) {
      day++;
      dayOfWeek = day % 7;
    }
    if (dayOfWeek == 1 && fraction > 15 * PARTS_PER_HOUR + 204 && !isLeapYear(year, CURRENT_ERA))
      day += 2;
    else if (dayOfWeek == 0 && fraction > 21 * PARTS_PER_HOUR + 589 && isLeapYear(year, CURRENT_ERA))
      day++;
    return day;
  }

  private DateTime getGregorianDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DAYS_TO_1AD + day - 1;
    for (int i = 1; i <= month; i++)
      days += MONTHDAYS[yearType][i - 1];
    return DateTime((days * TICKS_PER_DAY) + TimeSpan.getTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND));
  }

}


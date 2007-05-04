/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.chrono.Hijri;

private import tango.util.time.chrono.Calendar;


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
    return DateTime((daysSinceJan1(year, month, day) - 1) * Time.TicksPerDay + getTimeTicks(hour, minute, second) + (millisecond * Time.TicksPerMillisecond));
  }

  /**
   * Overridden. Returns the day of the week in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DateTime.DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DateTime.DayOfWeek) (cast(int) (time.ticks / Time.TicksPerDay + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.Day);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getDayOfYear(DateTime time) {
    return extractPart(time.ticks, DatePart.DayOfYear);
  }

  /**
   * Overridden. Returns the day of the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the year of time.
   */
  public override int getMonth(DateTime time) {
    return extractPart(time.ticks, DatePart.Month);
  }

  /**
   * Overridden. Returns the year in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the year in time.
   */
  public override int getYear(DateTime time) {
    return extractPart(time.ticks, DatePart.Year);
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
    int[] tmp = [HIJRI_ERA];
    return tmp.dup;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return HIJRI;
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

  private int extractPart(long ticks, DatePart part) {
    long days = (ticks / Time.TicksPerDay + 1);
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

    if (part == DatePart.Year)
      return year;

    days -= daysUpToYear;
    if (part == DatePart.DayOfYear)
      return cast(int)days;

    int month = 1;
    while (month <= 12 && days > DAYS_TO_MONTH[month - 1])
      month++;
    month--;
    if (part == DatePart.Month)
      return month;

    return cast(int)(days - DAYS_TO_MONTH[month - 1]);
  }

}


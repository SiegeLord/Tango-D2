/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.chrono.Hebrew;

private import tango.util.time.chrono.Calendar;



/**
 * $(ANCHOR _HebrewCalendar)
 * Represents the Hebrew calendar.
 */
public class HebrewCalendar : Calendar {

  private const int[14][7] MonthDays = [
    // month                                                    // year type
    [ 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ], 
    [ 0, 30, 29, 29, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 1
    [ 0, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 2
    [ 0, 30, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 0 ],   // 3
    [ 0, 30, 29, 29, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 4
    [ 0, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 5
    [ 0, 30, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ]   // 6
  ];

  private const int YearOfOneAD = 3760;
  private const int DaysToOneAD = cast(int)(YearOfOneAD * 365.2735);

  private const int PartsPerHour = 1080;
  private const int PartsPerDay = 24 * PartsPerHour;
  private const int DaysPerMonth = 29;
  private const int DaysPerMonthFraction = 12 * PartsPerHour + 793;
  private const int PartsPerMonth = DaysPerMonth * PartsPerDay + DaysPerMonthFraction;
  private const int FirstNewMoon = 11 * PartsPerHour + 204;

  private int minYear_ = YearOfOneAD + 1583;
  private int maxYear_ = YearOfOneAD + 2240;

  /**
   * Represents the current era.
   */
  public const int HEBREW_ERA = 1;

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
  public override DateTime.DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DateTime.DayOfWeek) cast(int) ((time.ticks / Time.TicksPerDay + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the day of the month of time.
   */
  public override int getDayOfMonth(DateTime time) {
    int year = getYear(time);
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DaysToOneAD;
    int day = cast(int)(time.ticks / Time.TicksPerDay) - days;
    int n;
    while (n < 12 && day >= MonthDays[yearType][n + 1]) {
      day -= MonthDays[yearType][n + 1];
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
    int days = getStartOfYear(year) - DaysToOneAD;
    return (cast(int)(time.ticks / Time.TicksPerDay) - days) + 1;
  }

  /**
   * Overridden. Returns the month in the specified DateTime.
   * Params: time = A DateTime value.
   * Returns: An integer representing the month in time.
   */
  public override int getMonth(DateTime time) {
    int year = getYear(time);
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DaysToOneAD;
    int day = cast(int)(time.ticks / Time.TicksPerDay) - days;
    int n;
    while (n < 12 && day >= MonthDays[yearType][n + 1]) {
      day -= MonthDays[yearType][n + 1];
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
    int day = cast(int)(time.ticks / Time.TicksPerDay) + DaysToOneAD;
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
    return MonthDays[getYearType(year)][month];
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
        int[] tmp = [HEBREW_ERA];
        return tmp.dup;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return HEBREW;
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
    int fraction = months * DaysPerMonthFraction + FirstNewMoon;
    int day = months * 29 + (fraction / PartsPerDay);
    fraction %= PartsPerDay;

    int dayOfWeek = day % 7;
    if (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6) {
      day++;
      dayOfWeek = day % 7;
    }
    if (dayOfWeek == 1 && fraction > 15 * PartsPerHour + 204 && !isLeapYear(year, CURRENT_ERA))
      day += 2;
    else if (dayOfWeek == 0 && fraction > 21 * PartsPerHour + 589 && isLeapYear(year, CURRENT_ERA))
      day++;
    return day;
  }

  private DateTime getGregorianDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    int yearType = getYearType(year);
    int days = getStartOfYear(year) - DaysToOneAD + day - 1;
    for (int i = 1; i <= month; i++)
      days += MonthDays[yearType][i - 1];
    return DateTime((days * Time.TicksPerDay) + getTimeTicks(hour, minute, second) + (millisecond * Time.TicksPerMillisecond));
  }

}


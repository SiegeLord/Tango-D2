/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.util.time.TimeZone;

private import tango.util.time.DateTime;
private import tango.util.time.Calendar;


version (Windows)
  private import tango.text.locale.Win32;
else version (Posix)
  private import tango.text.locale.Posix;



/**
 * $(ANCHOR _DaylightSavingTime)
 * Represents a period of daylight-saving time.
 */
public class DaylightSavingTime {

  private DateTime start_;
  private DateTime end_;
  private TimeSpan change_;

  /**
   * Initializes a new instance of the DaylightSavingTime class.
   * Params:
   *   start = The DateTime representing the date and time when the daylight-saving period starts.
   *   end = The DateTime representing the date and time when the daylight-saving period ends.
   *   change = The TimeSpan representing the difference between the standard time and daylight-saving time.
   */
  public this(DateTime start, DateTime end, TimeSpan change) {
    start_ = start;
    end_ = end;
    change_ = change;
  }

  /**
   * $(I Property.) Retrieves the DateTime representing the date and time when the daylight-saving period starts.
   * Returns: The DateTime representing the date and time when the daylight-saving period starts.
   */
  public DateTime start() {
    return start_;
  }

  /**
   * $(I Property.) Retrieves the DateTime representing the date and time when the daylight-saving period ends.
   * Returns: The DateTime representing the date and time when the daylight-saving period ends.
   */
  public DateTime end() {
    return end_;
  }

  /**
   * $(I Property.) Retrieves the TimeSpan representing the difference between the standard time and daylight-saving time.
   * Returns: The TimeSpan representing the difference between the standard time and daylight-saving time.
   */
  public TimeSpan change() {
    return change_;
  }

}

/**
 * $(ANCHOR _TimeZone);
 * Represents the current time zone.
 */
public class TimeZone {

  private static TimeZone current_;
  private static DaylightSavingTime[int] changesCache_;
  private short[] changesData_;
  private ulong ticksOffset_;

  /**
   * Returns the daylight-saving period for the specified _year.
   * Params: year = The _year to which the daylight-saving period applies.
   * Returns: A DaylightSavingTime instance containing the start and end for daylight saving in year.
   */
  public DaylightSavingTime getDaylightChanges(int year) {
      
     DateTime getSunday(int year, int month, int day, int sunday, int hour, int minute, int second, int millisecond) {
        DateTime result;
        if (sunday > 4) {
          result = DateTime(year, month, GregorianCalendar.getDefaultInstance().getDaysInMonth(year, month), hour, minute, second, millisecond);
          int change = cast(int)result.dayOfWeek - day;
          if (change < 0)
            change += 7;
          if (change > 0)
            result = result.addDays(-change);
        }
        else {
         result = DateTime(year, month, 1, hour, minute, second, millisecond);
         int change = day - cast(int)result.dayOfWeek;
         if (change < 0)
           change += 7;
         change += 7 * (sunday - 1);
         if (change > 0)
           result = result.addDays(change);
        }
        return result;
     }
  
     if (!(year in changesCache_)) {
       if (changesData_ == null)
         changesCache_[year] = new DaylightSavingTime(DateTime.min, DateTime.max, TimeSpan.init);
       else
         changesCache_[year] = new DaylightSavingTime(getSunday(year, changesData_[1], changesData_[2], changesData_[3], changesData_[4], changesData_[5], changesData_[6], changesData_[7]), getSunday(year, changesData_[9], changesData_[10], changesData_[11], changesData_[12], changesData_[13], changesData_[14], changesData_[15]), TimeSpan(changesData_[16] * TICKS_PER_MINUTE));
     }
     return changesCache_[year];
   }

  /**
   * Returns the local _time representing the specified UTC _time.
   * Params: time = A UTC _time.
   * Returns: A DateTime whose value is the local _time corresponding to time.
   */
  public DateTime getLocalTime(DateTime time) {
    if (time.kind == DateTime.Kind.LOCAL)
      return time;
    TimeSpan offset = TimeSpan(ticksOffset_);
    DaylightSavingTime dst = getDaylightChanges(time.year);
    if (dst.change.ticks != 0) {
      DateTime start = dst.start - offset;
      DateTime end = dst.end - offset - dst.change;
      bool isDst = (start > end) ? (time < end || time >= start) : (time >= start && time < end);
      if (isDst)
        offset += dst.change;
    }
    return DateTime((time.ticks + offset.ticks) | DateTime.Kind.LOCAL);
  }

  /**
   * Returns the UTC _time representing the specified locale _time.
   * Params: time = A UTC time.
   * Returns: A DateTime whose value is the UTC time corresponding to time.
   */
  public DateTime getUniversalTime(DateTime time) {
    if (time.kind == DateTime.Kind.UTC)
      return time;
    return DateTime((time.ticks - getUtcOffset(time).ticks) | DateTime.Kind.UTC);
  }

  /**
   * Returns the UTC _time offset for the specified local _time.
   * Params: time = The local _time.
   * Returns: The UTC offset from time.
   */
  public TimeSpan getUtcOffset(DateTime time) {
    long offset = cast(long) ticksOffset_;
    if (time.kind != DateTime.Kind.UTC) {
      DaylightSavingTime dst = getDaylightChanges(time.year);
      DateTime start = dst.start + dst.change;
      DateTime end = dst.end;
      bool isDst = (start > end) ? (time >= start || time < end) : (time >= start && time < end);
      if (isDst)
          offset += dst.change.ticks;
    }
    auto span = TimeSpan(cast(ulong) offset);
    if (offset < 0)
        span.invert;
    return span;
  }

  /**
   * Returns a value indicating whether the specified date and _time is within a daylight-saving period.
   * Params: time = A date and _time.
   * Returns: true if time is within a daylight-saving period; otherwise, false.
   */
  public bool isDaylightSavingTime(DateTime time) {
    return getUtcOffset(time) != TimeSpan.init;
  }

  /**
   * $(I Property.) Retrieves the _current time zone.
   * Returns: A TimeZone instance representing the _current time zone.
   */
  public static TimeZone current() {
    if (current_ is null)
      current_ = new TimeZone;
    return current_;
  }

  private this() {
    changesData_ = nativeMethods.getDaylightChanges();
    if (changesData_ != null)
       {
       ticksOffset_ = changesData_[17] * TICKS_PER_MINUTE;
       }
  }

}



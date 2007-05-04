/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.util.time.TimeZone;

private import tango.core.Type : Time;

private import tango.util.time.DateTime;

private import tango.util.time.chrono.Gregorian;



/**
 * $(ANCHOR _DaylightSavingTime)
 * Represents a period of daylight-saving time.
 */
public class DaylightSavingTime {

  private DateTime start_;
  private DateTime end_;
  private long change_;

  /**
   * Initializes a new instance of the DaylightSavingTime class.
   * Params:
   *   start = The DateTime representing the date and time when the daylight-saving period starts.
   *   end = The DateTime representing the date and time when the daylight-saving period ends.
   *   change = The TimeSpan representing the difference between the standard time and daylight-saving time.
   */
  public this(DateTime start, DateTime end, long change) {
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
  public long change() {
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
  private long ticksOffset_;

  /**
   * Returns the daylight-saving period for the specified _year.
   * Params: year = The _year to which the daylight-saving period applies.
   * Returns: A DaylightSavingTime instance containing the start and end for daylight saving in year.
   */
  public DaylightSavingTime getDaylightChanges(int year) {
      
     DateTime getSunday(int year, int month, int day, int sunday, int hour, int minute, int second, int millisecond) {
        DateTime result;
        auto c = GregorianCalendar.getDefaultInstance();

        if (sunday > 4) {
          result = c.getDateTime(year, month, c.getDaysInMonth(year, month), hour, minute, second, millisecond);
          int change = cast(int)result.dayOfWeek - day;
          if (change < 0)
            change += 7;
          if (change > 0)
            result = result.addDays(-change);
        }
        else {
         result = c.getDateTime(year, month, 1, hour, minute, second, millisecond);
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
         changesCache_[year] = new DaylightSavingTime(DateTime.min, DateTime.max, Time.init);
       else
         changesCache_[year] = new DaylightSavingTime(getSunday(year, changesData_[1], changesData_[2], changesData_[3], changesData_[4], changesData_[5], changesData_[6], changesData_[7]), getSunday(year, changesData_[9], changesData_[10], changesData_[11], changesData_[12], changesData_[13], changesData_[14], changesData_[15]), changesData_[16] * Time.TicksPerMinute);
     }
     return changesCache_[year];
   }

  /**
   * Returns the local _time representing the specified UTC _time.
   * Params: time = A UTC _time.
   * Returns: A DateTime whose value is the local _time corresponding to time.
   */
  public DateTime getLocalTime(DateTime time) {
    auto offset = ticksOffset_;
    auto dst = getDaylightChanges(time.year);
    if (dst.change != 0) {
      auto start = dst.start.addTicks(-offset);
      auto end = dst.end.addTicks(-(offset + dst.change));
      bool isDst = (start > end) ? (time < end || time >= start) : (time >= start && time < end);
      if (isDst)
        offset += dst.change;
    }
    return DateTime(time.ticks + offset);
  }

  /**
   * Returns the UTC _time representing the specified locale _time.
   * Params: time = A UTC time.
   * Returns: A DateTime whose value is the UTC time corresponding to time.
   */
  public DateTime getUniversalTime(DateTime time) {
    return DateTime(time.ticks - getUtcOffset(time));
  }

  /**
   * Returns the UTC _time offset for the specified local _time.
   * Params: time = The local _time.
   * Returns: The UTC offset from time.
   */
  public long getUtcOffset(DateTime time) {
    return ticksOffset_ + daylightSavingsTime(time);
  }

  /**
   * Returns a value indicating whether the specified date and _time is within a daylight-saving period.
   * Params: time = A date and _time.
   * Returns: true if time is within a daylight-saving period; otherwise, false.
   */
  public bool isDaylightSavingTime(DateTime time) {
        return daylightSavingsTime(time) != 0;
  }

  private long daylightSavingsTime(DateTime time) {
      auto dst = getDaylightChanges(time.year);
      if (dst.change)
         {
         auto start = dst.start.addTicks(dst.change);
         auto end = dst.end;
         if ((start > end) ? (time >= start || time < end) : (time >= start && time < end))
              return dst.change;
         }
      return 0;
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
    changesData_ = getDaylightInfo();
    if (changesData_ != null)
       {
       ticksOffset_ = changesData_[17] * Time.TicksPerMinute;
       }
  }

}


version (Win32)
{
private import tango.sys.Common;

short[] getDaylightInfo() {
  TIME_ZONE_INFORMATION tzi;
  GetTimeZoneInformation(&tzi);
  short[] data = new short[18];
  data[0] = cast(short)tzi.DaylightDate.wYear;
  data[1] = cast(short)tzi.DaylightDate.wMonth;
  data[2] = cast(short)tzi.DaylightDate.wDayOfWeek;
  data[3] = cast(short)tzi.DaylightDate.wDay;
  data[4] = cast(short)tzi.DaylightDate.wHour;
  data[5] = cast(short)tzi.DaylightDate.wMinute;
  data[6] = cast(short)tzi.DaylightDate.wSecond;
  data[7] = cast(short)tzi.DaylightDate.wMilliseconds;
  data[8] = cast(short)tzi.StandardDate.wYear;
  data[9] = cast(short)tzi.StandardDate.wMonth;
  data[10] = cast(short)tzi.StandardDate.wDayOfWeek;
  data[11] = cast(short)tzi.StandardDate.wDay;
  data[12] = cast(short)tzi.StandardDate.wHour;
  data[13] = cast(short)tzi.StandardDate.wMinute;
  data[14] = cast(short)tzi.StandardDate.wSecond;
  data[15] = cast(short)tzi.StandardDate.wMilliseconds;
  data[16] = cast(short)(tzi.DaylightBias * -1);
  data[17] = cast(short)(tzi.Bias * -1);
  return data;
}
}


version (Posix)
{
private import tango.sys.Common;

private import tango.io.File;
private import tango.io.protocol.EndianProtocol;
private import tango.io.protocol.Reader;
private import tango.io.Buffer;

short[] getDaylightInfo() {

    struct ttinfo
    {
        int     gmtoff;
        ubyte   isdst;
        ubyte   abbrind;
        
        void read(Reader r)
        {
            r.get(gmtoff).get(isdst).get(abbrind);
        }
    }

    char[] file;
    version(Linux)
    {
        file = cast(char[])(new File("/etc/timezone")).read();
    }
    else
    {
        file = "/etc/localtime";
    }

    auto r = new Reader(new EndianProtocol(new Buffer((new File(file)).read)));
    r.buffer.slice(20); // skipping first 20 bytes of file, they are not used
    
    
    int gmtcnt, stdcnt, leapcnt, timecnt, typecnt, charcnt;
    int[] times;
    ubyte[] indices;
    ttinfo[] infos;
    int tim, curTime = time(null);
    ubyte index;
    ttinfo info;
    short[] ret;
    short offSTD, offDST;
    tm timeStruct, curTimeStruct = *(localtime(&curTime));
    
    // read first 6 int values from file, needed for correct parsing. Some are not used here though
    r.get(gmtcnt).get(stdcnt).get(leapcnt).get(timecnt).get(typecnt).get(charcnt);
    
    // read transition times
    for(int i = 0; i < timecnt; i++)
    {
        r.get(tim);
        times ~= tim;
    }
    // read indices to an array of ttinfo structs
    for(int i = 0; i < timecnt; i++)
    {
        r.get(index);
        indices ~= index;
    }
    // read ttinfo structs
    for(int i = 0; i < typecnt; i++)
    {
        info.read(r);
        infos ~= info;
    }
    // look for transition times for current year, add them to the return array
    foreach(int i, int t; times)  // i - index, t - time
    {
        timeStruct = *(localtime(cast(int*)&t));
        if(timeStruct.tm_year == curTimeStruct.tm_year)
        {
            ret ~= cast(short) timeStruct.tm_year + 1900;
            ret ~= cast(short) timeStruct.tm_mon;
            ret ~= cast(short) timeStruct.tm_wday;
            ret ~= cast(short) timeStruct.tm_mday;
            ret ~= cast(short) timeStruct.tm_hour;
            ret ~= cast(short) timeStruct.tm_min;
            ret ~= cast(short) timeStruct.tm_sec;
            ret ~= cast(short) 0;                   // tm doesnt have data for miliseconds
            if(infos[indices[i]].isdst) offDST = cast(short) infos[indices[i]].gmtoff;
            else                        offSTD = cast(short) infos[indices[i]].gmtoff;
        }
    }
    
    ret ~= [offDST/60, offSTD/60];
    
    return ret;
}
}




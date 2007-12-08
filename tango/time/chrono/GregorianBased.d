/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.GregorianBased;

private import tango.core.Exception;

private import tango.time.Time;

private import tango.time.chrono.Gregorian;



private class GregorianBasedCalendar : GregorianCalendar {

  private EraRange[] eraRanges_;
  private int maxYear_, minYear_;
  private int currentEra_ = -1;

  this() 
  {
    eraRanges_ = EraRange.getEraRanges(id);
    maxYear_ = eraRanges_[0].maxEraYear;
    minYear_ = eraRanges_[0].minEraYear;
  }

  public override Time getTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    year = getGregorianYear(year, era);
    return super.getTime(year, month, day, hour, minute, second, millisecond, era);
  }
  public override int getYear(Time time) {
    auto ticks = time.ticks;
    auto year = extractPart(time.ticks, DatePart.Year);
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return year - eraRange.yearOffset;
    }
    throw new IllegalArgumentException("Value was out of range.");
  }

  public override int getEra(Time time) {
    auto ticks = time.ticks;
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return eraRange.era;
    }
    throw new IllegalArgumentException("Value was out of range.");
  }

  public override int[] eras() {
    int[] result;
    foreach (EraRange eraRange; eraRanges_)
      result ~= eraRange.era;
    return result;
  }

  private int getGregorianYear(int year, int era) {
    if (era == 0)
      era = currentEra;
    foreach (EraRange eraRange; eraRanges_) {
      if (era == eraRange.era) {
        if (year >= eraRange.minEraYear && year <= eraRange.maxEraYear)
          return eraRange.yearOffset + year;
        throw new IllegalArgumentException("Value was out of range.");
      }
    }
    throw new IllegalArgumentException("Era value was not valid.");
  }

  protected int currentEra() {
    if (currentEra_ == -1)
      currentEra_ = EraRange.getCurrentEra(id);
    return currentEra_;
  }
}



package struct EraRange {

  private static EraRange[][int] eraRanges;
  private static int[int] currentEras;
  private static bool initialized_;

  package int era;
  package long ticks;
  package int yearOffset;
  package int minEraYear;
  package int maxEraYear;

  private static void initialize() {
    if (!initialized_) {
      long getTicks(int year, int month, int day)
      {
        return GregorianCalendar.getDefaultInstance.getDateTicks(year, month, day);
      }
      eraRanges[GregorianCalendar.JAPAN] ~= EraRange(4, getTicks(1989, 1, 8), 1988, 1, GregorianCalendar.MAX_YEAR);
      eraRanges[GregorianCalendar.JAPAN] ~= EraRange(3, getTicks(1926, 12, 25), 1925, 1, 1989);
      eraRanges[GregorianCalendar.JAPAN] ~= EraRange(2, getTicks(1912, 7, 30), 1911, 1, 1926);
      eraRanges[GregorianCalendar.JAPAN] ~= EraRange(1, getTicks(1868, 9, 8), 1867, 1, 1912);
      eraRanges[GregorianCalendar.TAIWAN] ~= EraRange(1, getTicks(1912, 1, 1), 1911, 1, GregorianCalendar.MAX_YEAR);
      eraRanges[GregorianCalendar.KOREA] ~= EraRange(1, getTicks(1, 1, 1), -2333, 2334, GregorianCalendar.MAX_YEAR);
      eraRanges[GregorianCalendar.THAI] ~= EraRange(1, getTicks(1, 1, 1), -543, 544, GregorianCalendar.MAX_YEAR);
      currentEras[GregorianCalendar.JAPAN] = 4;
      currentEras[GregorianCalendar.TAIWAN] = 1;
      currentEras[GregorianCalendar.KOREA] = 1;
      currentEras[GregorianCalendar.THAI] = 1;
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

  private static EraRange opCall(int era, long ticks, int yearOffset, int minEraYear, int prevEraYear) {
    EraRange eraRange;
    eraRange.era = era;
    eraRange.ticks = ticks;
    eraRange.yearOffset = yearOffset;
    eraRange.minEraYear = minEraYear;
    eraRange.maxEraYear = prevEraYear - yearOffset;
    return eraRange;
  }

}


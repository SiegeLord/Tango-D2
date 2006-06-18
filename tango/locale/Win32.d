module tango.locale.Win32;

alias tango.locale.Win32 nativeMethods;

extern (Windows)
private {

  struct SYSTEMTIME {
    ushort wYear;
    ushort wMonth;
    ushort wDayOfWeek;
    ushort wDay;
    ushort wHour;
    ushort wMinute;
    ushort wSecond;
    ushort wMilliseconds;
  }

  struct TIME_ZONE_INFORMATION {
    int Bias;
    wchar[32] StandardName;
    SYSTEMTIME StandardDate;
    int StandardBias;
    wchar[32] DaylightName;
    SYSTEMTIME DaylightDate;
    int DaylightBias;
  }

  void GetSystemTimeAsFileTime(out ulong lpSystemTimeAsFileTime);
  uint GetTimeZoneInformation(out TIME_ZONE_INFORMATION lpTimeZoneInformation);
  uint GetUserDefaultLCID();
  uint GetThreadLocale();
  bool SetThreadLocale(uint Locale);
  int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
  int CompareStringW(uint Locale, uint dwCmpFlags, wchar* lpString1, int cchCount1, wchar* lpString2, int cchCount2);

}

int getUserCulture() {
  return GetUserDefaultLCID();
}

void setUserCulture(int lcid) {
  SetThreadLocale(lcid);
}

ulong getUtcTime() {
  ulong ticks;
  GetSystemTimeAsFileTime(ticks);
  return ticks;
}

short[] getDaylightChanges() {
  TIME_ZONE_INFORMATION tzi;
  GetTimeZoneInformation(tzi);
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

int compareString(int lcid, char[] stringA, uint offsetA, uint lengthA, char[] stringB, uint offsetB, uint lengthB, bool ignoreCase) {

  wchar[] toUnicode(char[] string, uint offset, uint length, out int translated) {
    char* chars = string.ptr + offset;
    int required = MultiByteToWideChar(0, 0, chars, length, null, 0);
    wchar[] result = new wchar[required];
    translated = MultiByteToWideChar(0, 0, chars, length, result, required);
    return result;
  }

  int sortId = (lcid >> 16) & 0xF;
  sortId = (sortId == 0) ? lcid : (lcid | (sortId << 16));

  int len1, len2;
  wchar[] string1 = toUnicode(stringA, offsetA, lengthA, len1);
  wchar[] string2 = toUnicode(stringB, offsetB, lengthB, len2);

  return CompareStringW(sortId, ignoreCase ? 0x1 : 0x0, string1, len1, string2, len2) - 2;
}
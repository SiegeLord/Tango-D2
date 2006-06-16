module tango.locale.linux;

version (Posix)
{
alias tango.locale.linux nativeMethods;

private import tango.locale.data;

extern (C)
private {

  struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
  }

  int time(int*);
  tm* gmtime(int*);

}

int getUserCulture() {
  char* env = getenv("LC_ALL");
  if (!env || *env == '\0') {
    env = getenv("LANG");
    if (!env || *env = '\0')
      return 0;
  }

  // getenv returns a string of the form <language>_<region>.
  // Therefore we need to replace underscores with hyphens.
  char* p = env;
  int len;
  while (*p) {
    if (*p == '_')
      *p = '-';
    *p++;
    len++;
  }

  char[] s = env[0 .. len];
  foreach (entry; CultureData.cultureDataTable) {
    if (compareString(entry.name, s) == 0)
      return entry.id;
  }
  return 0;
}

void setUserCulture(int lcid) {
  // putenv?
}

ulong getUtcTime() {
  int t;
  time(t);
  gmtime(t);
  return (cast(long)t * 10000000L) + 116444736000000000L;
}

short[] getDaylightChanges() {
  return null;
}

int compareString(int lcid, char[] stringA, uint offsetA, uint lengthA, char[] stringB, uint offsetB, uint lengthB, bool ignoreCase) {
  return 0;
}
}

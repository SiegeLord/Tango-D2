module tango.text.locale.Linux;

version (Posix)
{
alias tango.text.locale.Linux nativeMethods;

private import tango.text.locale.Data;
private import tango.stdc.stdlib;
private import tango.stdc.posix.time;

int getUserCulture() {
  char* env = getenv("LC_ALL");
  if (!env || *env == '\0') {
    env = getenv("LANG");
    if (!env || *env == '\0')
      return 0;
  }

  // getenv returns a string of the form <language>_<region>.
  // Therefore we need to replace underscores with hyphens.
  char* p = env;
  int len;
  while (*p) {
    if (*p == '.'){
      break;
    }
    if (*p == '_'){
      *p = '-';
    }
    p++;
    len++;
  }

  char[] s = env[0 .. len];
  foreach (entry; CultureData.cultureDataTable) {
    // todo: there is also a local compareString defined. Is it correct that here 
    // we use tango.text.locale.Data, which matches the signature?
    if (tango.text.locale.Data.compareString(entry.name, s) == 0)
	// todo: here was entry.id returned, which does not exist. Is lcid correct?
      return entry.lcid;
  }
  return 0;
}

void setUserCulture(int lcid) {
  // putenv?
}

ulong getUtcTime() {
   int t;
   time(&t);
   gmtime(&t);
   return cast(ulong)((cast(long)t * 10000000L) + 116444736000000000L);
}

short[] getDaylightChanges() {
  return null;
}

int compareString(int lcid, char[] stringA, uint offsetA, uint lengthA, char[] stringB, uint offsetB, uint lengthB, bool ignoreCase) {
  return 0;
}
}

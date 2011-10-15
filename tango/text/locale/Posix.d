/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.locale.Posix;

private import  tango.core.Exception;

private import  tango.text.locale.Data,
                tango.text.convert.Utf;

private import  core.sys.posix.stdlib,
                core.stdc.locale,
                core.stdc.ctype,
                core.stdc.string;

int getUserCulture()
{
  char* env = getenv("LC_ALL");
  if (!env || *env == '\0') {
    env = getenv("LANG");
  }

  // getenv returns a string of the form <language>_<region>.
  // Therefore we need to replace underscores with hyphens.
  char[] s;
  if (env){
      s = fromStringz(env).dup;
      foreach (ref c; s)
               if (c == '.')
                   break;
               else
                  if (c == '_')
                      c = '-';
  } else {
      /* Bad dup */
      s="en-US".dup;
  }
  foreach (entry; CultureData.cultureDataTable) {
    // todo: there is also a local compareString defined. Is it correct that here 
    // we use tango.text.locale.Data, which matches the signature?
    if (tango.text.locale.Data.compareString(entry.name, s) == 0)
      return entry.lcid;
  }
  
  foreach (entry; CultureData.cultureDataTable) {
    // todo: there is also a local compareString defined. Is it correct that here 
    // we use tango.text.locale.Data, which matches the signature?
    if (tango.text.locale.Data.compareString(entry.name, "en-US") == 0)
      return entry.lcid;
  }
  return 0;
}

void setUserCulture(int lcid)
{
  char[] name;
  try {
    name = CultureData.getDataFromCultureID(lcid).name ~ ".utf-8";
  }
  catch(Exception e) {
    return;
  }
  
  for(int i = 0; i < name.length; i++) {
    if(name[i] == '.') break;
    if(name[i] == '-') name[i] = '_';
  }
  
  putenv(("LANG=" ~ name).ptr);
  setlocale(LC_CTYPE, name.ptr);
  setlocale(LC_NUMERIC, name.ptr);
  setlocale(LC_TIME, name.ptr);
  setlocale(LC_COLLATE, name.ptr);
  setlocale(LC_MONETARY, name.ptr);

  version (GNU) {} else {
/*      setlocale(LC_MESSAGES, name.ptr); */
  }

  setlocale(LC_PAPER, name.ptr);
  setlocale(LC_NAME, name.ptr);
  setlocale(LC_ADDRESS, name.ptr);
  setlocale(LC_TELEPHONE, name.ptr);
  setlocale(LC_MEASUREMENT, name.ptr);
  setlocale(LC_IDENTIFICATION, name.ptr);
}

int compareString(int lcid, const(char)[] stringA, size_t offsetA, size_t lengthA, const(char)[] stringB, size_t offsetB, size_t lengthB, bool ignoreCase) {

  void strToLower(char[] string) {
    for(int i = 0; i < string.length; i++) {
      string[i] = cast(char)(tolower(cast(int)string[i]));
    }
  }

  char* tempCol = setlocale(LC_COLLATE, null), tempCType = setlocale(LC_CTYPE, null);
  const(char)[] locale;
  try {
    locale = CultureData.getDataFromCultureID(lcid).name ~ ".utf-8";
  }
  catch(Exception e) {
    return 0;
  }

  setlocale(LC_COLLATE, locale.ptr);
  setlocale(LC_CTYPE, locale.ptr);
  
  char[] s1 = stringA[offsetA..offsetA+lengthA] ~ "\0",
         s2 = stringB[offsetB..offsetB+lengthB] ~ "\0";
  if(ignoreCase) {
    strToLower(s1);
    strToLower(s2);
  }
  
  int ret = strcoll(s1.ptr, s2.ptr);
  
  setlocale(LC_COLLATE, tempCol);
  setlocale(LC_CTYPE, tempCType);
  
  return ret;
}

debug(UnitTest)
{
    unittest
    {
        int c = getUserCulture();
        assert(compareString(c, "Alphabet", 0, 8, "Alphabet", 0, 8, false) == 0);
        assert(compareString(c, "Alphabet", 0, 8, "alphabet", 0, 8, true) == 0);
        assert(compareString(c, "Alphabet", 0, 8, "alphabet", 0, 8, false) != 0);
        assert(compareString(c, "lphabet", 0, 7, "alphabet", 0, 8, true) != 0);
        assert(compareString(c, "Alphabet", 0, 8, "lphabet", 0, 7, true) != 0);
        assert(compareString(c, "Alphabet", 0, 7, "ZAlphabet", 1, 7, false) == 0);
    }
}

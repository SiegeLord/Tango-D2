module tango.locale.core;

private import tango.locale.constants,
  tango.locale.data,
  tango.locale.format,
  tango.locale.parse;

version (Windows)
  private import tango.locale.win32;
else version (linux)
  private import tango.locale.linux;

// Used by cloneObject.
extern (C) 
private Object _d_newclass(ClassInfo info);

// Creates a shallow copy of an object.
private Object cloneObject(Object obj) {
  if (obj is null)
    return null;

  ClassInfo ci = obj.classinfo;
  size_t start = Object.classinfo.init.length;
  size_t end = ci.init.length;

  Object clone = _d_newclass(ci);
  (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
  return clone;
}

// Initializes an array.
template arrayOf(T) {
  private T[] arrayOf(T[] params ...) {
    return params.dup;
  }
}

/// Retrieves an object to control formatting.
public interface IFormatService {

  /**
    Retrieves an object that supports formatting for the specified _type.
    Returns: The current instance if type is the same _type as the current instance; otherwise, null.
    Params: type = An object that specifies the _type of formatting to retrieve.
  **/
  Object getFormat(TypeInfo type);

}

/// Provides information about a culture, such as its name, calendar and date formatting.
public class Culture : IFormatService {

  private const int LCID_INVARIANT = 0x007F;

  private static Culture[char[]] namedCultures;
  private static Culture[int] idCultures;
  private static Culture[char[]] ietfCultures;

  private static Culture currentCulture_;
  private static Culture userDefaultCulture_; // The user's default culture (GetUserDefaultLCID).
  private static Culture invariantCulture_; // The invariant culture is associated with the English language.
  private Calendar calendar_;
  private Culture parent_;
  private CultureData* cultureData_;
  private bool isReadOnly_;
  private NumberFormat numberFormat_;
  private DateTimeFormat dateTimeFormat_;

  static this() {
    invariantCulture_ = new Culture(LCID_INVARIANT);
    invariantCulture_.isReadOnly_ = true;

    userDefaultCulture_ = new Culture(nativeMethods.getUserCulture());
    if (userDefaultCulture_ is null)
      // Fallback
      userDefaultCulture_ = invariantCulture;
    else
      userDefaultCulture_.isReadOnly_ = true;
  }

  static ~this() {
    namedCultures = null;
    idCultures = null;
    ietfCultures = null;
  }

  public this(char[] cultureName) {
    cultureData_ = CultureData.getDataFromCultureName(cultureName);
  }

  public this(int cultureID) {
    cultureData_ = CultureData.getDataFromCultureID(cultureID);
  }

  public Object getFormat(TypeInfo type) {
    if (type is typeid(NumberFormat))
      return numberFormat;
    else if (type is typeid(DateTimeFormat))
      return dateTimeFormat;
    return null;
  }

  public Object clone() {
    Culture culture = cast(Culture)cloneObject(this);
    if (!culture.isNeutral) {
      if (dateTimeFormat_ !is null)
        culture.dateTimeFormat_ = cast(DateTimeFormat)dateTimeFormat_.clone();
      if (numberFormat_ !is null)
        culture.numberFormat_ = cast(NumberFormat)numberFormat_.clone();
    }
    if (calendar_ !is null)
      culture.calendar_ = cast(Calendar)calendar_.clone();
    return culture;
  }

  public static Culture getCulture(int cultureID) {
    Culture culture = getCultureInternal(cultureID, null);
    if (culture is null)
      throw new Exception("Culture is not supported.");
    return culture;
  }

  /**
    Returns a read-only instance of a culture using the specified culture name.
    Params: cultureName = The name of the culture.
    Returns: A read-only culture instance.
  **/
  public static Culture getCulture(char[] cultureName) {
    if (cultureName == null)
      throw new Exception("Value cannot be null.");
    Culture culture = getCultureInternal(0, cultureName);
    if (culture is null)
      throw new Exception("Culture name " ~ cultureName ~ " is not supported.");
    return culture;
  }

  public static Culture getCultureFromIetfLanguageTag(char[] name) {
    if (name == null)
      throw new Exception("Value cannot be null.");
    Culture culture = getCultureInternal(-1, name);
    if (culture is null)
      throw new Exception("Culture IETF name " ~ name ~ " is not a known IETF name.");
    return culture;
  }

  private static Culture getCultureInternal(int cultureID, char[] name) {
    // If cultureID is - 1, name is an IETF name; if it's 0, name is a culture name; otherwise, it's a valid LCID.

    // Look up tables first.
    if (cultureID == 0) {
      if (Culture* culture = name in namedCultures)
        return *culture;
    }
    else if (cultureID > 0) {
      if (Culture* culture = cultureID in idCultures)
        return *culture;
    }
    else if (cultureID == -1) {
      if (Culture* culture = name in ietfCultures)
        return *culture;
    }

    // Nothing found, create a new instance.
    Culture culture;

    try {
      if (cultureID == -1) {
        name = CultureData.getCultureNameFromIetfName(name);
        if (name == null)
          return null;
      }
      else if (cultureID == 0)
        culture = new Culture(name);
      else if (userDefaultCulture_ !is null && userDefaultCulture_.id == cultureID) {
        culture = userDefaultCulture_;
      }
      else
        culture = new Culture(cultureID);
    }
    catch (Exception) {
      return null;
    }

    culture.isReadOnly_ = true;

    // Now cache the new instance in all tables.
    ietfCultures[culture.ietfLanguageTag] = culture;
    namedCultures[culture.name] = culture;
    idCultures[culture.id] = culture;

    return culture;
  }

  public static Culture[] getCultures(CultureTypes types) {
    bool includeSpecific = (types & CultureTypes.Specific) != 0;
    bool includeNeutral = (types & CultureTypes.Neutral) != 0;

    int[] cultures;
    for (int i = 0; i < CultureData.cultureDataTable.length; i++) {
      if ((CultureData.cultureDataTable[i].isNeutral && includeNeutral) || (!CultureData.cultureDataTable[i].isNeutral && includeSpecific))
        cultures ~= CultureData.cultureDataTable[i].lcid;
    }
    cultures.sort;

    Culture[] result = new Culture[cultures.length];
    foreach (int i, int cultureID; cultures)
      result[i] = new Culture(cultureID);
    return result;
  }

  public override char[] toString() {
    return cultureData_.name;
  }

  public override int opEquals(Object obj) {
    if (obj is this)
      return true;
    Culture other = cast(Culture)obj;
    if (other is null)
      return false;
    return other.name == name; // This needs to be changed so it's culturally aware.
  }

  public static Culture current() {
    if (currentCulture_ !is null)
      return currentCulture_;

    if (userDefaultCulture_ !is null) {
      // If the user has changed their locale settings since last we checked, invalidate our data.
      if (userDefaultCulture_.id != nativeMethods.getUserCulture())
        userDefaultCulture_ = null;
    }
    if (userDefaultCulture_ is null) {
      userDefaultCulture_ = new Culture(nativeMethods.getUserCulture());
      if (userDefaultCulture_ is null)
        userDefaultCulture_ = invariantCulture;
      else
        userDefaultCulture_.isReadOnly_ = true;
    }

    return userDefaultCulture_;
  }
  public static void current(Culture value) {
    checkNeutral(value);
    nativeMethods.setUserCulture(value.id);
    currentCulture_ = value;
  }

  public static Culture invariantCulture() {
    return invariantCulture_;
  }

  public int id() {
    return cultureData_.lcid;
  }

  public char[] name() {
    return cultureData_.name;
  }

  public char[] englishName() {
    return cultureData_.englishName;
  }

  public char[] nativeName() {
    return cultureData_.nativeName;
  }

  public char[] twoLetterLanguageName() {
    return cultureData_.isoLangName;
  }

  public char[] threeLetterLanguageName() {
    return cultureData_.isoLangName2;
  }

  public final char[] ietfLanguageTag() {
    return cultureData_.ietfTag;
  }

  public Culture parent() {
    if (parent_ is null) {
      try {
        int parentCulture = cultureData_.parent;
        if (parentCulture == LCID_INVARIANT)
          parent_ = invariantCulture;
        else
          parent_ = new Culture(parentCulture);
      }
      catch {
        parent_ = invariantCulture;
      }
    }
    return parent_;
  }

  public bool isNeutral() {
    return cultureData_.isNeutral;
  }

  public final bool isReadOnly() {
    return isReadOnly_;
  }

  public Calendar calendar() {
    if (calendar_ is null) {
      calendar_ = getCalendarInstance(cultureData_.calendarType);
      calendar_.isReadOnly_ = isReadOnly_;
    }
    return calendar_;
  }

  public Calendar[] optionalCalendars() {
    Calendar[] cals = new Calendar[cultureData_.optionalCalendars.length];
    foreach (int i, int calID; cultureData_.optionalCalendars)
      cals[i] = getCalendarInstance(calID);
    return cals;
  }

  /**
    Retrieves a NumberFormat defining the culturally appropriate format for displaying numbers and currency.
    Returns: A NumberFormat defining the culturally appropriate format for displaying numbers and currency.
  **/
  public NumberFormat numberFormat() {
    checkNeutral(this);
    if (numberFormat_ is null) {
      numberFormat_ = new NumberFormat(cultureData_);
      numberFormat_.isReadOnly_ = isReadOnly_;
    }
    return numberFormat_;
  }
  public void numberFormat(NumberFormat value) {
    checkReadOnly();
    numberFormat_ = value;
  }

  public DateTimeFormat dateTimeFormat() {
    checkNeutral(this);
    if (dateTimeFormat_ is null) {
      dateTimeFormat_ = new DateTimeFormat(cultureData_, calendar);
      dateTimeFormat_.isReadOnly_ = isReadOnly_;
    }
    return dateTimeFormat_;
  }
  public void dateTimeFormat(DateTimeFormat value) {
    checkReadOnly();
    dateTimeFormat_ = value;
  }

  private static void checkNeutral(Culture culture) {
    if (culture.isNeutral)
      throw new Exception("Culture '" ~ culture.name ~ "' is a neutral culture. It cannot be used in formatting and therefore cannot be set as the current culture.");
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new Exception("Instance is read-only.");
  }

  private static Calendar getCalendarInstance(int calendarType) {
    switch (calendarType) {
      case Calendar.JAPAN:
        return new JapaneseCalendar;
      case Calendar.TAIWAN:
        return new TaiwaneseCalendar;
      case Calendar.KOREA:
        return new KoreanCalendar;
      case Calendar.HIJRI:
        return new HijriCalendar;
      case Calendar.HEBREW:
        return new HebrewCalendar;
      case Calendar.GREGORIAN_US:
      case Calendar.GREGORIAN_ME_FRENCH:
      case Calendar.GREGORIAN_ARABIC:
      case Calendar.GREGORIAN_XLIT_ENGLISH:
      case Calendar.GREGORIAN_XLIT_FRENCH:
        return new GregorianCalendar(cast(GregorianCalendarTypes)calendarType);
      default:
        break;
    }
    return new GregorianCalendar;
  }

}

public class Region {

  private CultureData* cultureData_;
  private static Region currentRegion_;
  private char[] name_;

  public this(int cultureID) {
    cultureData_ = CultureData.getDataFromCultureID(cultureID);
    if (cultureData_.isNeutral)
      throw new Exception("Cannot use a neutral culture to create a region.");
    name_ = cultureData_.regionName;
  }

  public this(char[] name) {
    cultureData_ = CultureData.getDataFromRegionName(name);
    name_ = name;
    if (cultureData_.isNeutral)
      throw new Exception("The region name " ~ name ~ " corresponds to a neutral culture and cannot be used to create a region.");
  }

  package this(CultureData* cultureData) {
    cultureData_ = cultureData;
    name_ = cultureData.regionName;
  }

  public static Region current() {
    if (currentRegion_ is null)
      currentRegion_ = new Region(Culture.current.cultureData_);
    return currentRegion_;
  }

  public int geoID() {
    return cultureData_.geoId;
  }

  public char[] name() {
    return name_;
  }

  public char[] englishName() {
    return cultureData_.englishCountry;
  }

  public char[] nativeName() {
    return cultureData_.nativeCountry;
  }

  public char[] twoLetterRegionName() {
    return cultureData_.regionName;
  }

  public char[] threeLetterRegionName() {
    return cultureData_.isoRegionName;
  }

  public char[] currencySymbol() {
    return cultureData_.currency;
  }

  public char[] isoCurrencySymbol() {
    return cultureData_.intlSymbol;
  }

  public char[] currencyEnglishName() {
    return cultureData_.englishCurrency;
  }

  public char[] currencyNativeName() {
    return cultureData_.nativeCurrency;
  }

  public bool isMetric() {
    return cultureData_.isMetric;
  }

  public override char[] toString() {
    return name_;
  }

}

public class NumberFormat : IFormatService {

  package bool isReadOnly_;
  private static NumberFormat invariantFormat_;

  private int numberDecimalDigits_;
  private int numberNegativePattern_;
  private int currencyDecimalDigits_;
  private int currencyNegativePattern_;
  private int currencyPositivePattern_;
  private int[] numberGroupSizes_;
  private int[] currencyGroupSizes_;
  private char[] numberGroupSeparator_;
  private char[] numberDecimalSeparator_;
  private char[] currencyGroupSeparator_;
  private char[] currencyDecimalSeparator_;
  private char[] currencySymbol_;
  private char[] negativeSign_;
  private char[] positiveSign_;
  private char[] nanSymbol_;
  private char[] negativeInfinitySymbol_;
  private char[] positiveInfinitySymbol_;
  private char[][] nativeDigits_;

  public this() {
    this(null);
  }

  package this(CultureData* cultureData) {
    // Initialize invariant data.
    numberDecimalDigits_ = 2;
    numberNegativePattern_ = 1;
    currencyDecimalDigits_ = 2;
    numberGroupSizes_ = arrayOf!(int)(3);
    currencyGroupSizes_ = arrayOf!(int)(3);
    numberGroupSeparator_ = ",";
    numberDecimalSeparator_ = ".";
    currencyGroupSeparator_ = ",";
    currencyDecimalSeparator_ = ".";
    currencySymbol_ = "\u00A4";
    negativeSign_ = "-";
    positiveSign_ = "+";
    nanSymbol_ = "NaN";
    negativeInfinitySymbol_ = "-Infinity";
    positiveInfinitySymbol_ = "Infinity";
    nativeDigits_ = arrayOf!(char[])("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");

    if (cultureData !is null && cultureData.lcid != Culture.LCID_INVARIANT) {
      // Initialize culture-specific data.
      numberDecimalDigits_ = cultureData.digits;
      numberNegativePattern_ = cultureData.negativeNumber;
      currencyDecimalDigits_ = cultureData.currencyDigits;
      currencyNegativePattern_ = cultureData.negativeCurrency;
      currencyPositivePattern_ = cultureData.positiveCurrency;
      numberGroupSizes_ = cultureData.grouping;
      currencyGroupSizes_ = cultureData.monetaryGrouping;
      numberGroupSeparator_ = cultureData.thousand;
      numberDecimalSeparator_ = cultureData.decimal;
      currencyGroupSeparator_ = cultureData.monetaryThousand;
      currencyDecimalSeparator_ = cultureData.monetaryDecimal;
      currencySymbol_ = cultureData.currency;
      negativeSign_ = cultureData.negativeSign;
      positiveSign_ = cultureData.positiveSign;
      nanSymbol_ = cultureData.nan;
      negativeInfinitySymbol_ = cultureData.negInfinity;
      positiveInfinitySymbol_ = cultureData.posInfinity;
      nativeDigits_ = cultureData.nativeDigits;
    }
  }

  public Object getFormat(TypeInfo type) {
    return (type is typeid(NumberFormat)) ? this : null;
  }

  public Object clone() {
    NumberFormat copy = cast(NumberFormat)cloneObject(this);
    copy.isReadOnly_ = false;
    return copy;
  }

  public static NumberFormat getInstance(IFormatService formatService) {
    Culture culture = cast(Culture)formatService;
    if (culture !is null) {
      if (culture.numberFormat_ !is null)
        return culture.numberFormat_;
      return culture.numberFormat;
    }
    if (NumberFormat numberFormat = cast(NumberFormat)formatService)
      return numberFormat;
    if (formatService !is null) {
      if (NumberFormat numberFormat = cast(NumberFormat)(formatService.getFormat(typeid(NumberFormat))))
        return numberFormat;
    }
    return current;
  }

  public static NumberFormat current() {
    return Culture.current.numberFormat;
  }

  public static NumberFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new NumberFormat;
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  public final bool isReadOnly() {
    return isReadOnly_;
  }

  public final int numberDecimalDigits() {
    return numberDecimalDigits_;
  }
  public final void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  public final int numberNegativePattern() {
    return numberNegativePattern_;
  }
  public final void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  public final int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }
  public final void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  public final int currencyNegativePattern() {
    return currencyNegativePattern_;
  }
  public final void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  public final int currencyPositivePattern() {
    return currencyPositivePattern_;
  }
  public final void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  public final int[] numberGroupSizes() {
    return numberGroupSizes_;
  }
  public final void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  public final int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }
  public final void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  public final char[] numberGroupSeparator() {
    return numberGroupSeparator_;
  }
  public final void numberGroupSeparator(char[] value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  public final char[] numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }
  public final void numberDecimalSeparator(char[] value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  public final char[] currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }
  public final void currencyGroupSeparator(char[] value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  public final char[] currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }
  public final void currencyDecimalSeparator(char[] value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  public final char[] currencySymbol() {
    return currencySymbol_;
  }
  public final void currencySymbol(char[] value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  public final char[] negativeSign() {
    return negativeSign_;
  }
  public final void negativeSign(char[] value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  public final char[] positiveSign() {
    return positiveSign_;
  }
  public final void positiveSign(char[] value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  public final char[] nanSymbol() {
    return nanSymbol_;
  }
  public final void nanSymbol(char[] value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  public final char[] negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }
  public final void negativeInfinitySymbol(char[] value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  public final char[] positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }
  public final void positiveInfinitySymbol(char[] value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  public final char[][] nativeDigits() {
    return nativeDigits_;
  }
  public final void nativeDigits(char[][] value) {
    checkReadOnly();
    nativeDigits_ = value;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new Exception("NumberFormat instance is read-only.");
  }

}

public class DateTimeFormat : IFormatService {

  private const char[] rfc1123Pattern_ = "ddd, dd MMMM yyyy HH':'mm':'ss 'GMT'";
  private const char[] sortableDateTimePattern_ = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private const char[] universalSortableDateTimePattern_ = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'";

  package bool isReadOnly_;
  private static DateTimeFormat invariantFormat_;
  private CultureData* cultureData_;

  private Calendar calendar_;
  private int[] optionalCalendars_;
  private int firstDayOfWeek_ = -1;
  private int calendarWeekRule_ = -1;
  private char[] dateSeparator_;
  private char[] timeSeparator_;
  private char[] amDesignator_;
  private char[] pmDesignator_;
  private char[] shortDatePattern_;
  private char[] shortTimePattern_;
  private char[] longDatePattern_;
  private char[] longTimePattern_;
  private char[] monthDayPattern_;
  private char[] yearMonthPattern_;
  private char[][] abbreviatedDayNames_;
  private char[][] dayNames_;
  private char[][] abbreviatedMonthNames_;
  private char[][] monthNames_;

  private char[] fullDateTimePattern_;
  private char[] generalShortTimePattern_;
  private char[] generalLongTimePattern_;

  private char[][] shortTimePatterns_;
  private char[][] shortDatePatterns_;
  private char[][] longTimePatterns_;
  private char[][] longDatePatterns_;
  private char[][] yearMonthPatterns_;

  public this() {
    // This ctor is used by invariantFormat so we can't set the calendar property.
    cultureData_ = Culture.invariantCulture.cultureData_;
    calendar_ = GregorianCalendar.getDefaultInstance();
    initialize();
  }

  package this(CultureData* cultureData, Calendar calendar) {
    cultureData_ = cultureData;
    this.calendar = calendar;
  }

  public Object getFormat(TypeInfo type) {
    return (type is typeid(DateTimeFormat)) ? this : null;
  }

  public Object clone() {
    DateTimeFormat other = cast(DateTimeFormat)cloneObject(this);
    other.calendar_ = cast(Calendar)calendar.clone();
    other.isReadOnly_ = false;
    return other;
  }

  public final char[][] getAllDateTimePatterns() {
    char[][] result;
    foreach (char format; allStandardFormats)
      result ~= getAllDateTimePatterns(format);
    return result;
  }

  package char[][] shortTimePatterns() {
    if (shortTimePatterns_ == null)
      shortTimePatterns_ = cultureData_.shortTimes;
    return shortTimePatterns_.dup;
  }

  package char[][] shortDatePatterns() {
    if (shortDatePatterns_ == null)
      shortDatePatterns_ = cultureData_.shortDates;
    return shortDatePatterns_.dup;
  }

  package char[][] longTimePatterns() {
    if (longTimePatterns_ == null)
      longTimePatterns_ = cultureData_.longTimes;
    return longTimePatterns_.dup;
  }

  package char[][] longDatePatterns() {
    if (longDatePatterns_ == null)
      longDatePatterns_ = cultureData_.longDates;
    return longDatePatterns_.dup;
  }

  package char[][] yearMonthPatterns() {
    if (yearMonthPatterns_ == null)
      yearMonthPatterns_ = cultureData_.yearMonths;
    return yearMonthPatterns_;
  }

  public final char[][] getAllDateTimePatterns(char format) {

    char[][] combinePatterns(char[][] patterns1, char[][] patterns2) {
      char[][] result = new char[][patterns1.length * patterns2.length];
      for (int i = 0; i < patterns1.length; i++) {
        for (int j = 0; j < patterns2.length; j++)
          result[i * patterns2.length + j] = patterns1[i] ~ " " ~ patterns2[j];
      }
      return result;
    }

    // format must be one of allStandardFormats.
    char[][] result;
    switch (format) {
      case 'd':
        result ~= shortDatePatterns;
        break;
      case 'D':
        result ~= longDatePatterns;
        break;
      case 'f':
        result ~= combinePatterns(longDatePatterns, shortTimePatterns);
        break;
      case 'F':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'g':
        result ~= combinePatterns(shortDatePatterns, shortTimePatterns);
        break;
      case 'G':
        result ~= combinePatterns(shortDatePatterns, longTimePatterns);
        break;
      case 'm':
      case 'M':
        result ~= monthDayPattern;
        break;
      case 'r':
      case 'R':
        result ~= rfc1123Pattern_;
        break;
      case 's':
        result ~= sortableDateTimePattern_;
        break;
      case 't':
        result ~= shortTimePatterns;
        break;
      case 'T':
        result ~= longTimePatterns;
      case 'u':
        result ~= universalSortableDateTimePattern_;
        break;
      case 'U':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'y':
      case 'Y':
        result ~= yearMonthPatterns;
        break;
      default:
        throw new Exception("The specified format was not valid.");
    }
    return result;
  }

  public final char[] getAbbreviatedDayName(DayOfWeek dayOfWeek) {
    return abbreviatedDayNames[cast(int)dayOfWeek];
  }

  public final char[] getDayName(DayOfWeek dayOfWeek) {
    return dayNames[cast(int)dayOfWeek];
  }

  public final char[] getAbbreviatedMonthName(int month) {
    return abbreviatedMonthNames[month - 1];
  }

  public final char[] getMonthName(int month) {
    return monthNames[month - 1];
  }

  public static DateTimeFormat getInstance(IFormatService formatService) {
    Culture culture = cast(Culture)formatService;
    if (culture !is null) {
      if (culture.dateTimeFormat_ !is null)
        return culture.dateTimeFormat_;
      return culture.dateTimeFormat;
    }
    if (DateTimeFormat dateTimeFormat = cast(DateTimeFormat)formatService)
      return dateTimeFormat;
    if (formatService !is null) {
      if (DateTimeFormat dateTimeFormat = cast(DateTimeFormat)(formatService.getFormat(typeid(DateTimeFormat))))
        return dateTimeFormat;
    }
    return current;
  }

  public static DateTimeFormat current() {
    return Culture.current.dateTimeFormat;
  }

  public static DateTimeFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new DateTimeFormat;
      invariantFormat_.calendar.isReadOnly_ = true;
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  public final bool isReadOnly() {
    return isReadOnly_;
  }

  public final Calendar calendar() {
    assert(calendar_ !is null);
    return calendar_;
  }
  public final void calendar(Calendar value) {
    checkReadOnly();
    if (value !is calendar_) {
      for (int i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.id) {
          if (calendar_ !is null) {
            // Clear current properties.
            shortDatePattern_ = null;
            longDatePattern_ = null;
            shortTimePattern_ = null;
            yearMonthPattern_ = null;
            monthDayPattern_ = null;
            generalShortTimePattern_ = null;
            generalLongTimePattern_ = null;
            fullDateTimePattern_ = null;
            shortDatePatterns_ = null;
            longDatePatterns_ = null;
            yearMonthPatterns_ = null;
            abbreviatedDayNames_ = null;
            abbreviatedMonthNames_ = null;
            dayNames_ = null;
            monthNames_ = null;
          }
          calendar_ = value;
          initialize();
          return;
        }
      }
      throw new Exception("Not a valid calendar for the culture.");
    }
  }

  public final DayOfWeek firstDayOfWeek() {
    return cast(DayOfWeek)firstDayOfWeek_;
  }
  public final void firstDayOfWeek(DayOfWeek value) {
    checkReadOnly();
    firstDayOfWeek_ = value;
  }

  public final CalendarWeekRule calendarWeekRule() {
    return cast(CalendarWeekRule)calendarWeekRule_;
  }
  public final void calendarWeekRule(CalendarWeekRule value) {
    checkReadOnly();
    calendarWeekRule_ = value;
  }

  public final char[] nativeCalendarName() {
    return cultureData_.nativeCalName;
  }

  public final char[] dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = cultureData_.date;
    return dateSeparator_;
  }
  public final void dateSeparator(char[] value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  public final char[] timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = cultureData_.time;
    return timeSeparator_;
  }
  public final void timeSeparator(char[] value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  public final char[] amDesignator() {
    assert(amDesignator_ != null);
    return amDesignator_;
  }
  public final void amDesignator(char[] value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  public final char[] pmDesignator() {
    assert(pmDesignator_ != null);
    return pmDesignator_;
  }
  public final void pmDesignator(char[] value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  public final char[] shortDatePattern() {
    assert(shortDatePattern_ != null);
    return shortDatePattern_;
  }
  public final void shortDatePattern(char[] value) {
    checkReadOnly();
    if (shortDatePatterns_ != null)
      shortDatePatterns_[0] = value;
    shortDatePattern_ = value;
    generalLongTimePattern_ = null;
    generalShortTimePattern_ = null;
  }

  public final char[] shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = cultureData_.shortTime;
    return shortTimePattern_;
  }
  public final void shortTimePattern(char[] value) {
    checkReadOnly();
    shortTimePattern_ = value;
    generalShortTimePattern_ = null;
  }

  public final char[] longDatePattern() {
    assert(longDatePattern_ != null);
    return longDatePattern_;
  }
  public final void longDatePattern(char[] value) {
    checkReadOnly();
    if (longDatePatterns_ != null)
      longDatePatterns_[0] = value;
    longDatePattern_ = value;
    fullDateTimePattern_ = null;
  }

  public final char[] longTimePattern() {
    assert(longTimePattern_ != null);
    return longTimePattern_;
  }
  public final void longTimePattern(char[] value) {
    checkReadOnly();
    longTimePattern_ = value;
    fullDateTimePattern_ = null;
  }

  public final char[] monthDayPattern() {
    if (monthDayPattern_ == null)
      monthDayPattern_ = cultureData_.monthDay;
    return monthDayPattern_;
  }
  public final void monthDayPattern(char[] value) {
    checkReadOnly();
    monthDayPattern_ = value;
  }

  public final char[] yearMonthPattern() {
    assert(yearMonthPattern_ != null);
    return yearMonthPattern_;
  }
  public final void yearMonthPattern(char[] value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  public final char[][] abbreviatedDayNames() {
    if (abbreviatedDayNames_ == null)
      abbreviatedDayNames_ = cultureData_.abbrevDayNames;
    return abbreviatedDayNames_.dup;
  }
  public final void abbreviatedDayNames(char[][] value) {
    checkReadOnly();
    abbreviatedDayNames_ = value;
  }

  public final char[][] dayNames() {
    if (dayNames_ == null)
      dayNames_ = cultureData_.dayNames;
    return dayNames_.dup;
  }
  public final void dayNames(char[][] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  public final char[][] abbreviatedMonthNames() {
    if (abbreviatedMonthNames_ == null)
      abbreviatedMonthNames_ = cultureData_.abbrevMonthNames;
    return abbreviatedMonthNames_.dup;
  }
  public final void abbreviatedMonthNames(char[][] value) {
    checkReadOnly();
    abbreviatedMonthNames_ = value;
  }

  public final char[][] monthNames() {
    if (monthNames_ == null)
      monthNames_ = cultureData_.monthNames;
    return monthNames_.dup;
  }
  public final void monthNames(char[][] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  public final char[] fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern;
    return fullDateTimePattern_;
  }
  public final void fullDateTimePattern(char[] value) {
    checkReadOnly();
    fullDateTimePattern_ = value;
  }

  public final char[] rfc1123Pattern() {
    return rfc1123Pattern_;
  }

  public final char[] sortableDateTimePattern() {
    return sortableDateTimePattern_;
  }

  public final char[] universalSortableDateTimePattern() {
    return universalSortableDateTimePattern_;
  }

  package char[] generalShortTimePattern() {
    if (generalShortTimePattern_ == null)
      generalShortTimePattern_ = shortDatePattern ~ " " ~ shortTimePattern;
    return generalShortTimePattern_;
  }

  package char[] generalLongTimePattern() {
    if (generalLongTimePattern_ == null)
      generalLongTimePattern_ = shortDatePattern ~ " " ~ longTimePattern;
    return generalLongTimePattern_;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      throw new Exception("DateTimeFormat instance is read-only.");
  }

  private void initialize() {
    if (longTimePattern_ == null)
      longTimePattern_ = cultureData_.longTime;
    if (shortDatePattern_ == null)
      shortDatePattern_ = cultureData_.shortDate;
    if (longDatePattern_ == null)
      longDatePattern_ = cultureData_.longDate;
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = cultureData_.yearMonth;
    if (amDesignator_ == null)
      amDesignator_ = cultureData_.am;
    if (pmDesignator_ == null)
      pmDesignator_ = cultureData_.pm;
    if (firstDayOfWeek_ == -1)
      firstDayOfWeek_ = cultureData_.firstDayOfWeek;
    if (calendarWeekRule_ == -1)
      calendarWeekRule_ = cultureData_.firstDayOfYear;
  }

  private int[] optionalCalendars() {
    if (optionalCalendars_ is null)
      optionalCalendars_ = cultureData_.optionalCalendars;
    return optionalCalendars_;
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

public abstract class Calendar {

  public const int CURRENT_ERA = 0;

  private int currentEra_ = -1;
  package bool isReadOnly_;

  public Object clone() {
    Calendar other = cast(Calendar)cloneObject(this);
    other.isReadOnly_ = false;
    return other;
  }

  public DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    return getDateTime(year, month, day, hour, minute, second, millisecond, CURRENT_ERA);
  }

  public abstract DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era);

  public abstract DayOfWeek getDayOfWeek(DateTime time);

  public abstract int getDayOfMonth(DateTime time);

  public abstract int getDayOfYear(DateTime time);

  public abstract int getMonth(DateTime time);

  public abstract int getYear(DateTime time);

  public abstract int getEra(DateTime time);

  public int getDaysInMonth(int year, int month) {
    return getDaysInMonth(year, month, CURRENT_ERA);
  }

  public abstract int getDaysInMonth(int year, int month, int era);

  public int getDaysInYear(int year) {
    return getDaysInYear(year, CURRENT_ERA);
  }

  public abstract int getDaysInYear(int year, int era);

  public int getMonthsInYear(int year) {
    return getMonthsInYear(year, CURRENT_ERA);
  }

  public abstract int getMonthsInYear(int year, int era);

  public int getWeekOfYear(DateTime time, CalendarWeekRule rule, DayOfWeek firstDayOfWeek) {
    int year = getYear(time);
    int jan1 = cast(int)getDayOfWeek(getDateTime(year, 1, 1, 0, 0, 0, 0));

    switch (rule) {
      case CalendarWeekRule.FirstDay:
        int n = jan1 - cast(int)firstDayOfWeek;
        if (n < 0)
          n += 7;
        return (getDayOfYear(time) + n - 1) / 7 + 1;
      case CalendarWeekRule.FirstFullWeek:
      case CalendarWeekRule.FirstFourDayWeek:
        int fullDays = (rule == CalendarWeekRule.FirstFullWeek) ? 7 : 4;
        int n = cast(int)firstDayOfWeek - jan1;
        if (n != 0) {
          if (n < 0)
            n += 7;
          else if (n >= fullDays)
            n -= 7;
        }
        int day = getDayOfYear(time) - n;
        if (day > 0)
          return (day - 1) / 7 + 1;
        year = getYear(time) - 1;
        int month = getMonthsInYear(year);
        day = getDaysInMonth(year, month);
        return getWeekOfYear(getDateTime(year, month, day, 0, 0, 0, 0), rule, firstDayOfWeek);
      default:
        break;
    }
    // To satisfy -w
    throw new Exception("Value was out of range.");
  }

  public bool isLeapYear(int year) {
    return isLeapYear(year, CURRENT_ERA);
  }

  public abstract bool isLeapYear(int year, int era);

  public abstract int[] eras();

  public final bool isReadOnly() {
    return isReadOnly_;
  }

  public int id() {
    return -1;
  }

  protected int currentEra() {
    if (currentEra_ == -1)
      currentEra_ = EraRange.getCurrentEra(id);
    return currentEra_;
  }

  // Corresponds to Win32 calendar IDs
  package enum {
    GREGORIAN = 1,
    GREGORIAN_US = 2,
    JAPAN = 3,
    TAIWAN = 4,
    KOREA = 5,
    HIJRI = 6,
    THAI = 7,
    HEBREW = 8,
    GREGORIAN_ME_FRENCH = 9,
    GREGORIAN_ARABIC = 10,
    GREGORIAN_XLIT_ENGLISH = 11,
    GREGORIAN_XLIT_FRENCH = 12
  }

}

public class GregorianCalendar : Calendar {

  public const int AD_ERA = 1;

  private const int MAX_YEAR = 9999;

  private static Calendar defaultInstance_;
  private GregorianCalendarTypes type_;

  public this(GregorianCalendarTypes type = GregorianCalendarTypes.Localized) {
    type_ = type;
  }

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
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
    return extractPart(time.ticks, DatePart.YEAR);
  }

  public override int getEra(DateTime time) {
    return AD_ERA;
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

  public GregorianCalendarTypes calendarType() {
    return type_;
  }
  public void calendarType(GregorianCalendarTypes value) {
    checkReadOnly();
    type_ = value;
  }

  public override int[] eras() {
    return arrayOf!(int)(AD_ERA);
  }

  public override int id() {
    return cast(int)type_;
  }

  package static Calendar getDefaultInstance() {
    if (defaultInstance_ is null)
      defaultInstance_ = new GregorianCalendar;
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

  protected this() {
    eraRanges_ = EraRange.getEraRanges(id);
    maxYear_ = eraRanges_[0].maxEraYear;
    minYear_ = eraRanges_[0].minEraYear;
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

}

public class JapaneseCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  public this() {
    cal_ = new GregorianBasedCalendar;
  }

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  public override int[] eras() {
    return cal_.eras;
  }

  public override int id() {
    return Calendar.JAPAN;
  }

}

public class TaiwaneseCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  public this() {
    cal_ = new GregorianBasedCalendar;
  }

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  public override int[] eras() {
    return cal_.eras;
  }

  public override int id() {
    return Calendar.TAIWAN;
  }

}

public class KoreanCalendar : Calendar {

  private GregorianBasedCalendar cal_;

  public this() {
    cal_ = new GregorianBasedCalendar;
  }

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return cal_.getDateTime(year, month, day, hour, minute, second, millisecond, era);
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cal_.getDayOfWeek(time);
  }

  public override int getDayOfMonth(DateTime time) {
    return cal_.getDayOfMonth(time);
  }

  public override int getDayOfYear(DateTime time) {
    return cal_.getDayOfYear(time);
  }

  public override int getMonth(DateTime time) {
    return cal_.getMonth(time);
  }

  public override int getYear(DateTime time) {
    return cal_.getYear(time);
  }

  public override int getEra(DateTime time) {
    return cal_.getEra(time);
  }

  public override int getDaysInMonth(int year, int month, int era) {
    return cal_.getDaysInMonth(year, month, era);
  }

  public override int getDaysInYear(int year, int era) {
    return cal_.getDaysInYear(year, era);
  }

  public override int getMonthsInYear(int year, int era) {
    return cal_.getMonthsInYear(year, era);
  }

  public override bool isLeapYear(int year, int era) {
    return cal_.isLeapYear(year, era);
  }

  public override int[] eras() {
    return cal_.eras;
  }

  public override int id() {
    return Calendar.KOREA;
  }

}

public class HijriCalendar : Calendar {

  private static const int[] DAYS_TO_MONTH = [ 0, 30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325, 355 ];

  public const int HIJRI_ERA = 1;

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    return DateTime((daysSinceJan1(year, month, day) - 1) * TICKS_PER_DAY + TimeSpan.getTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND));
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)(cast(int)(time.ticks / TICKS_PER_DAY + 1) % 7);
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
    return extractPart(time.ticks, DatePart.YEAR);
  }

  public override int getEra(DateTime time) {
    return HIJRI_ERA;
  }

  public override int getDaysInMonth(int year, int month, int era) {
    if (month == 12)
      return isLeapYear(year, CURRENT_ERA) ? 30 : 29;
    return (month % 2 == 1) ? 30 : 29;
  }

  public override int getDaysInYear(int year, int era) {
    return isLeapYear(year, era) ? 355 : 354;
  }

  public override int getMonthsInYear(int year, int era) {
    return 12;
  }

  public override bool isLeapYear(int year, int era) {
    return (14 + 11 * year) % 30 < 11;
  }

  public override int[] eras() {
    return arrayOf!(int)(HIJRI_ERA);
  }

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

  public const int HEBREW_ERA = 1;

  public override DateTime getDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era) {
    checkYear(year, era);
    return getGregorianDateTime(year, month, day, hour, minute, second, millisecond);
  }

  public override DayOfWeek getDayOfWeek(DateTime time) {
    return cast(DayOfWeek)cast(int)((time.ticks / TICKS_PER_DAY + 1) % 7);
  }

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

  public override int getDayOfYear(DateTime time) {
    int year = getYear(time);
    int days = getStartOfYear(year) - DAYS_TO_1AD;
    return (cast(int)(time.ticks / TICKS_PER_DAY) - days) + 1;
  }

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

  public override int getEra(DateTime time) {
    return HEBREW_ERA;
  }

  public override int getDaysInMonth(int year, int month, int era) {
    checkYear(year, era);
    return MONTHDAYS[getYearType(year)][month];
  }

  public override int getDaysInYear(int year, int era) {
    return getStartOfYear(year + 1) - getStartOfYear(year);
  }

  public override int getMonthsInYear(int year, int era) {
    return isLeapYear(year, era) ? 13 : 12;
  }

  public override bool isLeapYear(int year, int era) {
    checkYear(year, era);
    // true if year % 19 == 0, 3, 6, 8, 11, 14, 17
    return ((7 * year + 1) % 19) < 7;
  }

  public override int[] eras() {
    return arrayOf!(int)(HEBREW_ERA);
  }

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

package const int[] DAYS_TO_MONTH_COMMON = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 ];
package const int[] DAYS_TO_MONTH_LEAP = [ 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 ];

package const ulong TICKS_PER_MILLISECOND = 10000;
package const ulong TICKS_PER_SECOND = TICKS_PER_MILLISECOND * 1000;
package const ulong TICKS_PER_MINUTE = TICKS_PER_SECOND * 60;
package const ulong TICKS_PER_HOUR = TICKS_PER_MINUTE * 60;
package const ulong TICKS_PER_DAY = TICKS_PER_HOUR * 24;

package const int MILLIS_PER_SECOND = 1000;
package const int MILLIS_PER_MINUTE = MILLIS_PER_SECOND * 60;
package const int MILLIS_PER_HOUR = MILLIS_PER_MINUTE * 60;
package const int MILLIS_PER_DAY = MILLIS_PER_HOUR * 24;

package const int DAYS_PER_YEAR = 365;
package const int DAYS_PER_4_YEARS = DAYS_PER_YEAR * 4 + 1;
package const int DAYS_PER_100_YEARS = DAYS_PER_4_YEARS * 25 - 1;
package const int DAYS_PER_400_YEARS = DAYS_PER_100_YEARS * 4 + 1;

package const int DAYS_TO_1601 = DAYS_PER_400_YEARS * 4;
package const int DAYS_TO_10000 = DAYS_PER_400_YEARS * 25 - 366;

package void splitDate(ulong ticks, out int year, out int month, out int day, out int dayOfYear) {
  int numDays = cast(int)(ticks / TICKS_PER_DAY);
  int whole400Years = numDays / DAYS_PER_400_YEARS;
  numDays -= whole400Years * DAYS_PER_400_YEARS;
  int whole100Years = numDays / DAYS_PER_100_YEARS;
  if (whole100Years == 4)
    whole100Years = 3;
  numDays -= whole100Years * DAYS_PER_100_YEARS;
  int whole4Years = numDays / DAYS_PER_4_YEARS;
  numDays -= whole4Years * DAYS_PER_4_YEARS;
  int wholeYears = numDays / DAYS_PER_YEAR;
  if (wholeYears == 4)
    wholeYears = 3;
  year = whole400Years * 400 + whole100Years * 100 + whole4Years * 4 + wholeYears + 1;
  numDays -= wholeYears * DAYS_PER_YEAR;
  dayOfYear = numDays + 1;
  int[] monthDays = (wholeYears == 3 && (whole4Years != 24 || whole100Years == 3)) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
  month = numDays >> 5 + 1;
  while (numDays >= monthDays[month])
    month++;
  day = numDays - monthDays[month - 1] + 1;
}

package int extractPart(ulong ticks, DatePart part) {
  int year, month, day, dayOfYear;
  splitDate(ticks, year, month, day, dayOfYear);
  if (part == DatePart.YEAR)
    return year;
  else if (part == DatePart.MONTH)
    return month;
  else if (part == DatePart.DAY_OF_YEAR)
    return dayOfYear;
  return day;
}

public struct DateTime {

  package enum Kind : ulong {
    UNKNOWN = 0x0000000000000000,
    UTC = 0x4000000000000000,
    LOCAL = 0x8000000000000000
  }

  private const ulong MIN_TICKS = 0;
  private const ulong MAX_TICKS = DAYS_TO_10000 * TICKS_PER_DAY - 1;

  private const ulong TICKS_MASK = 0x3FFFFFFFFFFFFFFF;
  private const ulong KIND_MASK = 0xC000000000000000;

  private const int KIND_SHIFT = 62;

  private ulong data_;

  public static DateTime min;
  public static DateTime max;

  static this() {
    min = DateTime(MIN_TICKS);
    max = DateTime(MAX_TICKS);
  }

  public static DateTime opCall(ulong data) {
    DateTime d;
    d.data_ = data;
    return d;
  }

  public static DateTime opCall(int year, int month, int day, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day);
    else
      d.data_ = calendar.getDateTime(year, month, day, 0, 0, 0, 0).ticks;
    return d;
  }

  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second);
    else
      d.data_ = calendar.getDateTime(year, month, day, hour, minute, second, 0).ticks;
    return d;
  }

  public static DateTime opCall(int year, int month, int day, int hour, int minute, int second, int millisecond, Calendar calendar = null) {
    DateTime d;
    if (calendar is null)
      d.data_ = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second) + (millisecond * TICKS_PER_MILLISECOND);
    else
      d.data_ = calendar.getDateTime(year, month, day, hour, minute, second, millisecond).ticks;
    return d;
  }

  public int opCmp(DateTime value) {
    if (ticks < value.ticks)
      return -1;
    else if (ticks > value.ticks)
      return 1;
    return 0;
  }

  public bool opEquals(DateTime value) {
    return ticks == value.ticks;
  }

  public DateTime opAdd(TimeSpan t) {
    return DateTime(ticks + t.ticks);
  }

  public DateTime opAddAssign(TimeSpan t) {
    return data_ = (ticks + t.ticks) | kind, *this;
  }

  public DateTime opSub(TimeSpan t) {
    return DateTime(ticks - t.ticks);
  }

  public DateTime opSubAssign(TimeSpan t) {
    return data_ = (ticks - t.ticks) | kind, *this;
  }

  public DateTime addTicks(ulong value) {
    return DateTime((ticks + value) | kind);
  }

  public DateTime addHours(int value) {
    return addMilliseconds(value * MILLIS_PER_HOUR);
  }

  public DateTime addMinutes(int value) {
    return addMilliseconds(value * MILLIS_PER_MINUTE);
  }

  public DateTime addSeconds(int value) {
    return addMilliseconds(value * MILLIS_PER_SECOND);
  }

  public DateTime addMilliseconds(double value) {
    return addTicks(cast(ulong)(value += (value > 0) ? 0.5 : -0.5) * TICKS_PER_MILLISECOND);
  }

  public DateTime addDays(int value) {
    return addMilliseconds(value * MILLIS_PER_DAY);
  }

  public DateTime addMonths(int value) {
    int year = this.year;
    int month = this.month;
    int day = this.day;
    int n = month - 1 + value;
    if (n >= 0) {
      month = n % 12 + 1;
      year = year + n / 12;
    }
    else {
      month = 12 + (n + 1) % 12;
      year = year + (n - 11) / 12;
    }
    int maxDays = daysInMonth(year, month);
    if (day > maxDays)
      day = maxDays;
    return DateTime((getDateTicks(year, month, day) + (ticks % TICKS_PER_DAY)) | kind);
  }

  public DateTime addYears(int value) {
    return addMonths(value * 12);
  }

  public static int daysInMonth(int year, int month) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    return monthDays[month] - monthDays[month - 1];
  }

  public static bool isLeapYear(int year) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
  }

  public bool isDaylightSavingTime() {
    return TimeZone.current.isDaylightSavingTime(*this);
  }

  public DateTime toLocalTime() {
    return TimeZone.current.getLocalTime(*this);
  }

  public DateTime toUniversalTime() {
    return TimeZone.current.getUniversalTime(*this);
  }
  
  public char[] toString(IFormatService formatService = null) {
    return formatDateTime(*this, null, DateTimeFormat.getInstance(formatService));
  }

  public char[] toString(char[] format, IFormatService formatService = null) {
    return formatDateTime(*this, format, DateTimeFormat.getInstance(formatService));
  }

  public static DateTime parse(char[] s, IFormatService formatService = null) {
    DateTime result = parseDateTime(s, DateTimeFormat.getInstance(formatService));
    return result;
  }

  public static DateTime parseExact(char[] s, char[] format, IFormatService formatService = null) {
    DateTime result = parseDateTimeExact(s, format, DateTimeFormat.getInstance(formatService));
    return result;
  }

  public static bool tryParse(char[] s, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.current, result);
  }

  public static bool tryParse(char[] s, IFormatService formatService, out DateTime result) {
    return tryParseDateTime(s, DateTimeFormat.getInstance(formatService), result);
  }

  public static bool tryParseExact(char[] s, char[] format, out DateTime result) {
    return tryParseDateTimeExact(s, format, DateTimeFormat.current, result);
  }

  public static bool tryParseExact(char[] s, char[] format, IFormatService formatService, out DateTime result) {
    return tryParseDateTimeExact(s, format, DateTimeFormat.getInstance(formatService), result);
  }

  public int year() {
    return extractPart(ticks, DatePart.YEAR);
  }

  public int month() {
    return extractPart(ticks, DatePart.MONTH);
  }

  public int day() {
    return extractPart(ticks, DatePart.DAY);
  }

  public int dayOfYear() {
    return extractPart(ticks, DatePart.DAY_OF_YEAR);
  }

  public DayOfWeek dayOfWeek() {
    return cast(DayOfWeek)((ticks / TICKS_PER_DAY + 1) % 7);
  }

  public int hour() {
    return cast(int)((ticks / TICKS_PER_HOUR) % 24);
  }

  public int minute() {
    return cast(int)((ticks / TICKS_PER_MINUTE) % 60);
  }

  public int second() {
    return cast(int)((ticks / TICKS_PER_SECOND) % 60);
  }

  public int millisecond() {
    return cast(int)((ticks / TICKS_PER_MILLISECOND) % 1000);
  }

  public DateTime date() {
    ulong ticks = this.ticks;
    return DateTime((ticks - ticks % TICKS_PER_DAY) | kind);
  }

  public static DateTime today() {
    // return now.date;
    // The above code causes DMD to complain about lvalues in toLocalTime, so we need a temporary here.
    DateTime d = now;
    return d.date;
  }

  public TimeSpan timeOfDay() {
    return TimeSpan(ticks % TICKS_PER_DAY);
  }

  public ulong ticks() {
    return data_ & TICKS_MASK;
  }

  public static DateTime now() {
    // return utcNow.toLocalTime();
    // The above code causes DMD to complain about lvalues in toLocalTime, so we need a temporary here.
    DateTime d = utcNow.toLocalTime();
    return d;
  }

  public static DateTime utcNow() {
    ulong ticks = nativeMethods.getUtcTime();
    return DateTime(cast(ulong)(ticks + (DAYS_TO_1601 * TICKS_PER_DAY)) | Kind.UTC);
  }

  package ulong kind() {
    return data_ & KIND_MASK;
  }

  private static ulong getDateTicks(int year, int month, int day) {
    int[] monthDays = isLeapYear(year) ? DAYS_TO_MONTH_LEAP : DAYS_TO_MONTH_COMMON;
    year--;
    return (year * 365 + year / 4 - year / 100 + year / 400 + monthDays[month - 1] + day - 1) * TICKS_PER_DAY;
  }

  private static ulong getTimeTicks(int hour, int minute, int second) {
    return (cast(ulong)hour * 3600 + cast(ulong)minute * 60 + cast(ulong)second) * TICKS_PER_SECOND;
  }

}

public struct TimeSpan {

  private ulong ticks_;

  public static const TimeSpan min;
  public static const TimeSpan max;

  static this() {
    min = TimeSpan(ulong.min);
    max = TimeSpan(ulong.max);
  }

  public static TimeSpan opCall(ulong ticks) {
    TimeSpan t;
    t.ticks_ = ticks;
    return t;
  }

  public static TimeSpan opCall(int hours, int minutes, int seconds) {
    TimeSpan t;
    t.ticks_ = getTicks(hours, minutes, seconds);
    return t;
  }

  public static TimeSpan opCall(int hours, int minutes, int seconds, int milliseconds) {
    TimeSpan t;
    t.ticks_ = getTicks(hours, minutes, seconds) + (milliseconds * TICKS_PER_MILLISECOND);
    return t;
  }

  public TimeSpan opAdd(TimeSpan t) {
    return TimeSpan(ticks_ + t.ticks_);
  }

  public TimeSpan opAddAssign(TimeSpan t) {
    ticks_ += t.ticks_;
    return *this;
  }

  public TimeSpan opSub(TimeSpan t) {
    return TimeSpan(ticks_ - t.ticks_);
  }

  public TimeSpan opSubAssign(TimeSpan t) {
    ticks_ -= t.ticks_;
    return *this;
  }

  public TimeSpan negate() {
    return TimeSpan(-ticks_);
  }

  public ulong ticks() {
    return ticks_;
  }

  public int hours() {
    return cast(int)((ticks_ / TICKS_PER_HOUR) % 24);
  }

  public int minutes() {
    return cast(int)((ticks_ / TICKS_PER_MINUTE) % 60);
  }

  public int seconds() {
    return cast(int)((ticks_ / TICKS_PER_SECOND) % 60);
  }

  public int milliseconds() {
    return cast(int)((ticks_ / TICKS_PER_MILLISECOND) % 1000);
  }

  public int days() {
    return cast(int)(ticks_ / TICKS_PER_DAY);
  }

  private static ulong getTicks(int hour, int minute, int second) {
    return (cast(ulong)hour * 3600 + cast(ulong)minute * 60 + cast(ulong)second) * TICKS_PER_SECOND;
  }

}

public class DaylightSavingTime {

  private DateTime start_;
  private DateTime end_;
  private TimeSpan change_;

  public this(DateTime start, DateTime end, TimeSpan change) {
    start_ = start;
    end_ = end;
    change_ = change;
  }

  public DateTime start() {
    return start_;
  }

  public DateTime end() {
    return end_;
  }

  public TimeSpan change() {
    return change_;
  }

}

public class TimeZone {

  private static TimeZone current_;
  private static DaylightSavingTime[int] changesCache_;
  private short[] changesData_;
  private ulong ticksOffset_;

  public DaylightSavingTime getDaylightChanges(int year) {
    if (!(year in changesCache_)) {
      if (changesData_ == null)
        changesCache_[year] = new DaylightSavingTime(DateTime.min, DateTime.max, TimeSpan.init);
      else
        changesCache_[year] = new DaylightSavingTime(DateTime(year, changesData_[1], changesData_[3], changesData_[4], changesData_[5], changesData_[6], changesData_[7]), DateTime(year, changesData_[9], changesData_[11], changesData_[12], changesData_[13], changesData_[14], changesData_[15]), TimeSpan(changesData_[16] * TICKS_PER_MINUTE));
    }
    return changesCache_[year];
  }

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

  public DateTime getUniversalTime(DateTime time) {
    if (time.kind == DateTime.Kind.UTC)
      return time;
    return DateTime((time.ticks - getUtcOffset(time).ticks) | DateTime.Kind.UTC);
  }

  public TimeSpan getUtcOffset(DateTime time) {
    TimeSpan offset;
    if (time.kind != DateTime.Kind.UTC) {
      DaylightSavingTime dst = getDaylightChanges(time.year);
      DateTime start = dst.start + dst.change;
      DateTime end = dst.end;
      bool isDst = (start > end) ? (time >= start || time < end) : (time >= start && time < end);
      if (isDst)
        offset = dst.change;
    }
    return TimeSpan(offset.ticks + ticksOffset_);
  }

  public bool isDaylightSavingTime(DateTime time) {
    return getUtcOffset(time) != TimeSpan.init;
  }

  public static TimeZone current() {
    if (current_ is null)
      current_ = new TimeZone;
    return current_;
  }

  private this() {
    changesData_ = nativeMethods.getDaylightChanges();
    if (changesData_ != null)
      ticksOffset_ = changesData_[17] * TICKS_PER_MINUTE;
  }

}
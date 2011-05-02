/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 */
module tango.stdc.posix.langinfo;

private import tango.stdc.locale;
private import tango.text.locale.Posix;


typedef int nl_item;

/*
  Return the current locale's value for ITEM.
  If ITEM is invalid, an empty string is returned.

  The string returned will not change until `setlocale' is called;
  it is usually in read-only memory and cannot be modified. 
*/
extern(C) char* nl_langinfo (nl_item __item);

enum : nl_item
{
        /* LC_TIME category: date and time formatting.  */

        /* Abbreviated days of the week. */
        ABDAY_1 = (((LC_TIME) << 16) | 0),  /* Sun */
        ABDAY_2,
        ABDAY_3,
        ABDAY_4,
        ABDAY_5,
        ABDAY_6,
        ABDAY_7,

        /* Long-named days of the week. */
        DAY_1,			/* Sunday */
        DAY_2,
        DAY_3,
        DAY_4,
        DAY_5,
        DAY_6,
        DAY_7,

        /* Abbreviated month names.  */
        ABMON_1,			/* Jan */
        ABMON_2,
        ABMON_3,
        ABMON_4,
        ABMON_5,
        ABMON_6,
        ABMON_7,
        ABMON_8,
        ABMON_9,
        ABMON_10,
        ABMON_11,
        ABMON_12,

        /* Long month names.  */
        MON_1,			/* January */
        MON_2,
        MON_3,
        MON_4,
        MON_5,
        MON_6,
        MON_7,
        MON_8,
        MON_9,
        MON_10,
        MON_11,
        MON_12,

        AM_STR,			/* Ante meridiem string.  */
        PM_STR,			/* Post meridiem string.  */

        D_T_FMT,			/* Date and time format for strftime.  */
        D_FMT,			/* Date format for strftime.  */
        T_FMT,			/* Time format for strftime.  */
        T_FMT_AMPM,			/* 12-hour time format for strftime.  */

        ERA,				/* Alternate era.  */
        ERA_YEAR,			/* Year in alternate era format.  */
        ERA_D_FMT,			/* Date in alternate era format.  */
        ALT_DIGITS,			/* Alternate symbols for digits.  */
        ERA_D_T_FMT,			/* Date and time in alternate era format.  */
        ERA_T_FMT,			/* Time in alternate era format.  */
}

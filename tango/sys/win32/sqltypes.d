/***********************************************************************\
*                              sqltypes.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
/* Conversion notes:
  It's assumed that ODBC >= 0x0300.
*/

module win32.sqltypes;
private import win32.wtypes; // for GUID

alias byte SCHAR;
alias int SDWORD;
alias short SWORD;
alias ULONG UDWORD;
alias USHORT UWORD;
alias int SLONG;
alias short SSHORT;
alias double SDOUBLE;
alias double LDOUBLE;
alias float SFLOAT;
alias PVOID PTR;
alias PVOID HENV;
alias PVOID HDBC;
alias PVOID HSTMT;
alias short RETCODE;
alias UCHAR SQLCHAR;
alias SCHAR SQLSCHAR;
alias SDWORD SQLINTEGER;
alias SWORD SQLSMALLINT;
// #ifndef __WIN64
alias UDWORD SQLUINTEGER;
// #endif
alias UWORD SQLUSMALLINT;
alias PVOID SQLPOINTER;

//static if (ODBCVER >= 0x0300) {
typedef void* SQLHANDLE;
alias SQLHANDLE SQLHENV;
alias SQLHANDLE SQLHDBC;
alias SQLHANDLE SQLHSTMT;
alias SQLHANDLE SQLHDESC;
/*
} else {
alias void* SQLHENV;
alias void* SQLHDBC;
alias void* SQLHSTMT;
}
*/
alias SQLSMALLINT SQLRETURN;
alias HWND SQLHWND;
alias ULONG BOOKMARK;

alias SQLINTEGER SQLLEN;
alias SQLINTEGER SQLROWOFFSET;
alias SQLUINTEGER SQLROWCOUNT;
alias SQLUINTEGER SQLULEN;
alias DWORD SQLTRANSID;
alias SQLUSMALLINT SQLSETPOSIROW;
alias wchar SQLWCHAR;

version(Unicode) {
	alias SQLWCHAR SQLTCHAR;
} else {
	alias SQLCHAR  SQLTCHAR;
}
//static if (ODBCVER >= 0x0300) {
alias ubyte   SQLDATE;
alias ubyte   SQLDECIMAL;
alias double  SQLDOUBLE;
alias double  SQLFLOAT;
alias ubyte   SQLNUMERIC;
alias float   SQLREAL;
alias ubyte   SQLTIME;
alias ubyte   SQLTIMESTAMP;
alias ubyte   SQLVARCHAR;
alias long   ODBCINT64;
alias long SQLBIGINT;
alias ulong SQLUBIGINT;
//}

struct DATE_STRUCT{
	SQLSMALLINT year;
	SQLUSMALLINT month;
	SQLUSMALLINT day;
}

struct TIME_STRUCT{
	SQLUSMALLINT hour;
	SQLUSMALLINT minute;
	SQLUSMALLINT second;
}

struct TIMESTAMP_STRUCT{
	SQLSMALLINT year;
	SQLUSMALLINT month;
	SQLUSMALLINT day;
	SQLUSMALLINT hour;
	SQLUSMALLINT minute;
	SQLUSMALLINT second;
	SQLUINTEGER fraction;
}

//static if (ODBCVER >= 0x0300) {
alias DATE_STRUCT SQL_DATE_STRUCT;
alias TIME_STRUCT SQL_TIME_STRUCT;
alias TIMESTAMP_STRUCT SQL_TIMESTAMP_STRUCT;
enum SQLINTERVAL {
	SQL_IS_YEAR = 1,
	SQL_IS_MONTH,
	SQL_IS_DAY,
	SQL_IS_HOUR,
	SQL_IS_MINUTE,
	SQL_IS_SECOND,
	SQL_IS_YEAR_TO_MONTH,
	SQL_IS_DAY_TO_HOUR,
	SQL_IS_DAY_TO_MINUTE,
	SQL_IS_DAY_TO_SECOND,
	SQL_IS_HOUR_TO_MINUTE,
	SQL_IS_HOUR_TO_SECOND,
	SQL_IS_MINUTE_TO_SECOND
}

struct SQL_YEAR_MONTH_STRUCT {
	SQLUINTEGER year;
	SQLUINTEGER month;
}

struct SQL_DAY_SECOND_STRUCT {
	SQLUINTEGER day;
	SQLUINTEGER	hour;
	SQLUINTEGER minute;
	SQLUINTEGER second;
	SQLUINTEGER fraction;
}

struct SQL_INTERVAL_STRUCT{
	SQLINTERVAL interval_type;
	SQLSMALLINT interval_sign;
	union intval{
		SQL_YEAR_MONTH_STRUCT year_month;
		SQL_DAY_SECOND_STRUCT day_second;
	}
}

const SQL_MAX_NUMERIC_LEN = 16;

struct SQL_NUMERIC_STRUCT{
	SQLCHAR precision;
	SQLSCHAR scale;
	SQLCHAR sign;
	SQLCHAR val[SQL_MAX_NUMERIC_LEN];
}
// } ODBCVER >= 0x0300
alias GUID SQLGUID;

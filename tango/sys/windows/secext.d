// Don't include this file directly, use tango.sys.windows.security instead.
module tango.sys.windows.secext;
private import tango.sys.windows.w32api;
private import tango.sys.windows.windef;
pragma(lib, "secur32.lib");

static assert (_WIN32_WINNT >= 0x0501,
  "SecExt is only available on WindowsXP and later");

enum EXTENDED_NAME_FORMAT {
	NameUnknown,
	NameFullyQualifiedDN,
	NameSamCompatible,
	NameDisplay,          // =  3
	NameUniqueId             =  6,
	NameCanonical,
	NameUserPrincipal,
	NameCanonicalEx,
	NameServicePrincipal, // = 10
	NameDnsDomain            = 12
}
alias EXTENDED_NAME_FORMAT* PEXTENDED_NAME_FORMAT;

extern (Windows) {
	BOOLEAN GetComputerObjectNameA(EXTENDED_NAME_FORMAT, LPSTR, PULONG);
	BOOLEAN GetComputerObjectNameW(EXTENDED_NAME_FORMAT, LPWSTR, PULONG);
	BOOLEAN GetUserNameExA(EXTENDED_NAME_FORMAT, LPSTR, PULONG);
	BOOLEAN GetUserNameExW(EXTENDED_NAME_FORMAT, LPWSTR, PULONG);
	BOOLEAN TranslateNameA(LPCSTR, EXTENDED_NAME_FORMAT,
	  EXTENDED_NAME_FORMAT, LPSTR, PULONG);
	BOOLEAN TranslateNameW(LPCWSTR, EXTENDED_NAME_FORMAT,
	  EXTENDED_NAME_FORMAT, LPWSTR, PULONG);
}

version (Unicode) {
	alias GetComputerObjectNameW GetComputerObjectName;
	alias GetUserNameExW GetUserNameEx;
	alias TranslateNameW TranslateName;
} else {
	alias GetComputerObjectNameA GetComputerObjectName;
	alias GetUserNameExA GetUserNameEx;
	alias TranslateNameA TranslateName;
}

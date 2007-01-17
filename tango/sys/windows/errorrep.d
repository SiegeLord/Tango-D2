/***********************************************************************\
*                               errorrep.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.errorrep;

private import win32.w32api, win32.windef;

static if (_WIN32_WINNT < 0x501) {
	pragma(msg,
"win32.errorrep is available only if version WindowsXP or Windows2003 is set");
	static assert (false);
}

enum EFaultRepRetVal {
	frrvOk,
	frrvOkManifest,
	frrvOkQueued,
	frrvErr,
	frrvErrNoDW,
	frrvErrTimeout,
	frrvLaunchDebugger,
	frrvOkHeadless // = 7
}

extern (Windows) {
	BOOL AddERExcludedApplicationA(LPCSTR);
	BOOL AddERExcludedApplicationW(LPCWSTR);
	EFaultRepRetVal ReportFault(LPEXCEPTION_POINTERS, DWORD);
}

version (Unicode) {
	alias AddERExcludedApplicationW AddERExcludedApplication;
} else {
	alias AddERExcludedApplicationA AddERExcludedApplication;
}

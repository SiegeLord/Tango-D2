/***********************************************************************\
*                                ntdll.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.ntdll;

// FIXME: check Windows version support

enum SHUTDOWN_ACTION {
	ShutdownNoReboot,
	ShutdownReboot,
	ShutdownPowerOff
}

extern (Windows) uint NtShutdownSystem(SHUTDOWN_ACTION Action);

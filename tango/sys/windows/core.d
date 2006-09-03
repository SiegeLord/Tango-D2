/***********************************************************************\
*                                core.d                                 *
*                                                                       *
*                    Helper module for the Windows API                  *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
/**
 The core Windows API functions.

 Importing this file is equivalent to the C code:
 ---
 #define WIN32_LEAN_AND_MEAN
 #include "windows.h"
 ---

*/
module tango.sys.windows.core;

public import tango.sys.windows.windef;
public import tango.sys.windows.winnt;
public import tango.sys.windows.wincon;
public import tango.sys.windows.winbase;
public import tango.sys.windows.wingdi;
public import tango.sys.windows.winuser;
public import tango.sys.windows.winnls;
public import tango.sys.windows.winver;
public import tango.sys.windows.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import tango.sys.windows.winsvc;
version (Windows2003) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsXP) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_WINNT_ONLY;
}

version (WIN32_WINNT_ONLY) {
	public import tango.sys.windows.winsvc;
}

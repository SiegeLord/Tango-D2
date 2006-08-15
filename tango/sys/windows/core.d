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

import tango.sys.windows.windef;
import tango.sys.windows.wincon;
import tango.sys.windows.winbase;
import tango.sys.windows.wingdi;
import tango.sys.windows.winuser;
import tango.sys.windows.winnls;
import tango.sys.windows.winver;
import tango.sys.windows.winnetwk;

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
	import tango.sys.windows.winsvc;
}

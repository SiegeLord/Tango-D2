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

module tango.os.win32.core;

private import tango.os.win32.w32api;
import tango.os.win32.windef;
import tango.os.win32.wincon;
import tango.os.win32.winbase;
import tango.os.win32.wingdi;
import tango.os.win32.winuser;
import tango.os.win32.winnls;
import tango.os.win32.winver;
import tango.os.win32.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import tango.os.win32.winsvc;
version (Windows2003) {
	version = WIN32_NT_ONLY;
} else version (WindowsXP) { 
	version = WIN32_NT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_NT_ONLY;
}
version (WIN32_NT_ONLY) {
	import tango.os.win32.winsvc;
}
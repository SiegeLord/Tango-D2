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

module tango.os.windows.core;

//version (build) { pragma(nolink); }


private import tango.os.windows.w32api;
import tango.os.windows.windef;
import tango.os.windows.wincon;
import tango.os.windows.winbase;
import tango.os.windows.wingdi;
import tango.os.windows.winuser;
import tango.os.windows.winnls;
import tango.os.windows.winver;
import tango.os.windows.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import tango.os.windows.winsvc;
version (Windows2003) {
	version = WIN32_NT_ONLY;
} else version (WindowsXP) { 
	version = WIN32_NT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_NT_ONLY;
}
version (WIN32_NT_ONLY) {
	import tango.os.windows.winsvc;
}
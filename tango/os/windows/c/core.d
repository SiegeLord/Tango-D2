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

module tango.os.windows.c.core;

//version (build) { pragma(nolink); }


private import tango.os.windows.c.w32api;
import tango.os.windows.c.windef;
import tango.os.windows.c.wincon;
import tango.os.windows.c.winbase;
import tango.os.windows.c.wingdi;
import tango.os.windows.c.winuser;
import tango.os.windows.c.winnls;
import tango.os.windows.c.winver;
import tango.os.windows.c.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import tango.os.windows.c.winsvc;
version (Windows2003) {
	version = WIN32_NT_ONLY;
} else version (WindowsXP) { 
	version = WIN32_NT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_NT_ONLY;
}
version (WIN32_NT_ONLY) {
	import tango.os.windows.c.winsvc;
}
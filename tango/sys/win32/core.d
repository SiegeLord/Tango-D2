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

module win32.core;

private import win32.w32api;
import win32.windef;
import win32.wincon;
import win32.winbase;
import win32.wingdi;
import win32.winuser;
import win32.winnls;
import win32.winver;
import win32.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import win32.winsvc;
version (Windows2003) {
	version = WIN32_NT_ONLY;
} else version (WindowsXP) { 
	version = WIN32_NT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_NT_ONLY;
}
version (WIN32_NT_ONLY) {
	import win32.winsvc;
}
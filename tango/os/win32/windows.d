/***********************************************************************\
*                               windows.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
/*
	windows.h - main header file for the Win32 API

	Written by Anders Norlander <anorland@hem2.passagen.se>

	This file is part of a free library for the Win32 API.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/
module tango.os.win32.windows;

import tango.os.win32.w32api;
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
	import tango.os.win32.winsvc;
} else version (WindowsXP) { 
	import tango.os.win32.winsvc;
} else version (WindowsNTonly) {
	import tango.os.win32.winsvc;
}

//#ifndef WIN32_LEAN_AND_MEAN
import tango.os.win32.cderr;
import tango.os.win32.dde;
import tango.os.win32.ddeml;
import tango.os.win32.dlgs;
import tango.os.win32.imm;
import tango.os.win32.lzexpand;
import tango.os.win32.mmsystem;
import tango.os.win32.nb30;
//import tango.os.win32.rpc;
import tango.os.win32.shellapi;
import tango.os.win32.winperf;
import tango.os.win32.commdlg;
import tango.os.win32.winspool;

// Select correct version of winsock.  Importing the incorrect
// module will cause a static assert to prevent problems later on.
version( Win32_Winsock2 )
	import tango.os.win32.winsock2;
else
	import tango.os.win32.winsock;

/+
#if (_WIN32_WINNT >= 0x0400)
#include <winsock2.h>
/*
 * MS likes to include mswsock.h here as well,
 * but that can cause undefined symbols if
 * winsock2.h is included before windows.h
 */
#else
#include <winsock.h>
#endif /*  (_WIN32_WINNT >= 0x0400) */
+/

import tango.os.win32.ole2;
// #endif /* WIN32_LEAN_AND_MEAN */

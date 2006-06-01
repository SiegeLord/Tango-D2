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
module win32.windows;

import win32.w32api;
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
	import win32.winsvc;
} else version (WindowsXP) { 
	import win32.winsvc;
} else version (WindowsNTonly) {
	import win32.winsvc;
}

//#ifndef WIN32_LEAN_AND_MEAN
import win32.cderr;
import win32.dde;
import win32.ddeml;
import win32.dlgs;
import win32.imm;
import win32.lzexpand;
import win32.mmsystem;
import win32.nb30;
//import win32.rpc;
import win32.shellapi;
import win32.winperf;
import win32.commdlg;
import win32.winspool;

// Select correct version of winsock.  Importing the incorrect
// module will cause a static assert to prevent problems later on.
version( Win32_Winsock2 )
	import win32.winsock2;
else
	import win32.winsock;

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

import win32.ole2;
// #endif /* WIN32_LEAN_AND_MEAN */

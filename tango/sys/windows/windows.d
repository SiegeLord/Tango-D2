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
module tango.sys.windows.windows;

import tango.sys.windows.w32api;
import tango.sys.windows.core;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import tango.sys.windows.winsvc;
version (Windows2003) {
	import tango.sys.windows.winsvc;
} else version (WindowsXP) {
	import tango.sys.windows.winsvc;
} else version (WindowsNTonly) {
	import tango.sys.windows.winsvc;
}

import tango.sys.windows.cderr;
import tango.sys.windows.dde;
import tango.sys.windows.ddeml;
import tango.sys.windows.dlgs;
import tango.sys.windows.imm;
import tango.sys.windows.lzexpand;
import tango.sys.windows.mmsystem;
import tango.sys.windows.nb30;
//import tango.sys.windows.rpc;
import tango.sys.windows.shellapi;
import tango.sys.windows.winperf;
import tango.sys.windows.commdlg;
import tango.sys.windows.winspool;

// Select correct version of winsock.  Importing the incorrect
// module will cause a static assert to prevent problems later on.
version (Win32_Winsock2)
	import tango.sys.windows.winsock2;
else
	import tango.sys.windows.winsock;

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

import tango.sys.windows.ole2;

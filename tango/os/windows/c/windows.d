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
module tango.os.windows.c.windows;

//version (build) { pragma(nolink); }


import tango.os.windows.c.w32api;
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
	import tango.os.windows.c.winsvc;
} else version (WindowsXP) { 
	import tango.os.windows.c.winsvc;
} else version (WindowsNTonly) {
	import tango.os.windows.c.winsvc;
}

//#ifndef WIN32_LEAN_AND_MEAN
import tango.os.windows.c.cderr;
import tango.os.windows.c.dde;
import tango.os.windows.c.ddeml;
import tango.os.windows.c.dlgs;
import tango.os.windows.c.imm;
import tango.os.windows.c.lzexpand;
import tango.os.windows.c.mmsystem;
import tango.os.windows.c.nb30;
//import tango.os.windows.c.rpc;
import tango.os.windows.c.shellapi;
import tango.os.windows.c.winperf;
import tango.os.windows.c.commdlg;
import tango.os.windows.c.winspool;

// Select correct version of winsock.  Importing the incorrect
// module will cause a static assert to prevent problems later on.
version( Win32_Winsock2 )
	import tango.os.windows.c.winsock2;
else
	import tango.os.windows.c.winsock;

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

import tango.os.windows.c.ole2;
// #endif /* WIN32_LEAN_AND_MEAN */

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
module tango.os.windows.windows;

//version (build) { pragma(nolink); }


import tango.os.windows.w32api;
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
	import tango.os.windows.winsvc;
} else version (WindowsXP) { 
	import tango.os.windows.winsvc;
} else version (WindowsNTonly) {
	import tango.os.windows.winsvc;
}

//#ifndef WIN32_LEAN_AND_MEAN
import tango.os.windows.cderr;
import tango.os.windows.dde;
import tango.os.windows.ddeml;
import tango.os.windows.dlgs;
import tango.os.windows.imm;
import tango.os.windows.lzexpand;
import tango.os.windows.mmsystem;
import tango.os.windows.nb30;
//import tango.os.windows.rpc;
import tango.os.windows.shellapi;
import tango.os.windows.winperf;
import tango.os.windows.commdlg;
import tango.os.windows.winspool;

// Select correct version of winsock.  Importing the incorrect
// module will cause a static assert to prevent problems later on.
version( Win32_Winsock2 )
	import tango.os.windows.winsock2;
else
	import tango.os.windows.winsock;

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

import tango.os.windows.ole2;
// #endif /* WIN32_LEAN_AND_MEAN */

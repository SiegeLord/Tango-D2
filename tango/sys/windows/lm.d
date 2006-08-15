/***********************************************************************\
*                                  lm.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.sys.windows.lm;

version (Windows2003) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsXP) {
	version = WIN32_WINNT_ONLY;
} else version(WindowsNTonly) {
	version = WIN32_WINNT_ONLY;
}

import tango.sys.windows.lmcons;
import tango.sys.windows.lmaccess;
import tango.sys.windows.lmalert;
import tango.sys.windows.lmat;
import tango.sys.windows.lmerr;
import tango.sys.windows.lmmsg;
import tango.sys.windows.lmshare;
import tango.sys.windows.lmapibuf;
import tango.sys.windows.lmremutl;
import tango.sys.windows.lmrepl;
import tango.sys.windows.lmuse;

version (WIN32_WINNT_ONLY) {
	import tango.sys.windows.lmwksta;
	import tango.sys.windows.lmserver;
}
import tango.sys.windows.lmstats;

// FIXME: Everything in these next files seems to be deprecated!
import tango.sys.windows.lmaudit;
import tango.sys.windows.lmchdev; // can't find many docs for functions from this file.
import tango.sys.windows.lmconfig;
import tango.sys.windows.lmerrlog;
import tango.sys.windows.lmsvc;
import tango.sys.windows.lmsname; // in MinGW, this was publicly included by lm.lmsvc

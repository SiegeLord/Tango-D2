/***********************************************************************\
*                                  lm.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.windows.lm;

version (Windows2003) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsXP) {
	version = WIN32_WINNT_ONLY;
} else version(WindowsNTonly) {
	version = WIN32_WINNT_ONLY;
}

import tango.os.windows.lmcons;
import tango.os.windows.lmaccess;
import tango.os.windows.lmalert;
import tango.os.windows.lmat;
import tango.os.windows.lmerr;
import tango.os.windows.lmmsg;
import tango.os.windows.lmshare;
import tango.os.windows.lmapibuf;
import tango.os.windows.lmremutl;
import tango.os.windows.lmrepl;
import tango.os.windows.lmuse;

version (WIN32_WINNT_ONLY) {
	import tango.os.windows.lmwksta;
	import tango.os.windows.lmserver;
}
import tango.os.windows.lmstats;

// FIXME: Everything in these next files seems to be deprecated!
import tango.os.windows.lmaudit;
import tango.os.windows.lmchdev; // can't find many docs for functions from this file.
import tango.os.windows.lmconfig;
import tango.os.windows.lmerrlog;
import tango.os.windows.lmsvc;
import tango.os.windows.lmsname; // in MinGW, this was publicly included by lm.lmsvc

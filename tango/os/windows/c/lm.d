/***********************************************************************\
*                                  lm.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/

module tango.os.windows.c.lm;

//version (build) { pragma(nolink); }


version (WindowsXP) {
 version = WIN32_WINNT_ONLY;
} else version(Windows2000) {
 version = WIN32_WINNT_ONLY;
} else version (Windows2003) {
 version = WIN32_WINNT_ONLY;
}

import tango.os.windows.c.lmcons;
import tango.os.windows.c.lmaccess;
import tango.os.windows.c.lmalert;
import tango.os.windows.c.lmat;
import tango.os.windows.c.lmerr;
import tango.os.windows.c.lmmsg;
import tango.os.windows.c.lmshare;
import tango.os.windows.c.lmapibuf;
import tango.os.windows.c.lmremutl;
import tango.os.windows.c.lmrepl;
import tango.os.windows.c.lmuse;

version (WIN32_WINNT_ONLY) {
import tango.os.windows.c.lmwksta;
import tango.os.windows.c.lmserver;
}
import tango.os.windows.c.lmstats;

// FIXME: Everything in these next files seems to be deprecated!
import tango.os.windows.c.lmaudit;
import tango.os.windows.c.lmchdev; // can't find many docs for functions from this file.
import tango.os.windows.c.lmconfig;
import tango.os.windows.c.lmerrlog;
import tango.os.windows.c.lmsvc;
import tango.os.windows.c.lmsname; // in MinGW, this was publicly included by lm.lmsvc

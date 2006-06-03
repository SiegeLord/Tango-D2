/***********************************************************************\
*                                  lm.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/

module tango.os.win32.lm;

version (WindowsXP) {
 version = WIN32_WINNT_ONLY;
} else version(Windows2000) {
 version = WIN32_WINNT_ONLY;
} else version (Windows2003) {
 version = WIN32_WINNT_ONLY;
}

import tango.os.win32.lmcons;
import tango.os.win32.lmaccess;
import tango.os.win32.lmalert;
import tango.os.win32.lmat;
import tango.os.win32.lmerr;
import tango.os.win32.lmmsg;
import tango.os.win32.lmshare;
import tango.os.win32.lmapibuf;
import tango.os.win32.lmremutl;
import tango.os.win32.lmrepl;
import tango.os.win32.lmuse;

version (WIN32_WINNT_ONLY) {
import tango.os.win32.lmwksta;
import tango.os.win32.lmserver;
}
import tango.os.win32.lmstats;

// FIXME: Everything in these next files seems to be deprecated!
import tango.os.win32.lmaudit;
import tango.os.win32.lmchdev; // can't find many docs for functions from this file.
import tango.os.win32.lmconfig;
import tango.os.win32.lmerrlog;
import tango.os.win32.lmsvc;
import tango.os.win32.lmsname; // in MinGW, this was publicly included by lm.lmsvc

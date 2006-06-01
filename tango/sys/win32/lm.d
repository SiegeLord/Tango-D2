/***********************************************************************\
*                                  lm.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/

module win32.lm;

version (WindowsXP) {
 version = WIN32_WINNT_ONLY;
} else version(Windows2000) {
 version = WIN32_WINNT_ONLY;
} else version (Windows2003) {
 version = WIN32_WINNT_ONLY;
}

import win32.lmcons;
import win32.lmaccess;
import win32.lmalert;
import win32.lmat;
import win32.lmerr;
import win32.lmmsg;
import win32.lmshare;
import win32.lmapibuf;
import win32.lmremutl;
import win32.lmrepl;
import win32.lmuse;

version (WIN32_WINNT_ONLY) {
import win32.lmwksta;
import win32.lmserver;
}
import win32.lmstats;

// FIXME: Everything in these next files seems to be deprecated!
import win32.lmaudit;
import win32.lmchdev; // can't find many docs for functions from this file.
import win32.lmconfig;
import win32.lmerrlog;
import win32.lmsvc;
import win32.lmsname; // in MinGW, this was publicly included by lm.lmsvc

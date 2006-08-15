/+// Used only for testing -- imports all windows headers.
module tango.sys.windows.all;

import tango.sys.windows.core;
import tango.sys.windows.windows;
import tango.sys.windows.commctrl;
import tango.sys.windows.setupapi;

import tango.sys.windows.dxerr8;
import tango.sys.windows.dxerr9;
import tango.sys.windows.oleacc;
import tango.sys.windows.aclui;
import tango.sys.windows.comcat;
import tango.sys.windows.cpl;
import tango.sys.windows.cplext;
import tango.sys.windows.custcntl;
import tango.sys.windows.d3d9;
import tango.sys.windows.oleacc;
import tango.sys.windows.ocidl;
import tango.sys.windows.olectl;
import tango.sys.windows.oledlg;

import tango.sys.windows.shldisp;
import tango.sys.windows.shlobj;
import tango.sys.windows.shlwapi;
import tango.sys.windows.regstr;
import tango.sys.windows.richole;
import tango.sys.windows.tmschema;
import tango.sys.windows.servprov;
import tango.sys.windows.exdisp;
import tango.sys.windows.exdispid;
import tango.sys.windows.idispids;
import tango.sys.windows.mshtml;

import tango.sys.windows.lm;
import tango.sys.windows.lmbrowsr;

import tango.sys.windows.sql;
import tango.sys.windows.sqlext;
import tango.sys.windows.sqlucode;

import tango.sys.windows.imagehlp;
import tango.sys.windows.intshcut;
import tango.sys.windows.iphlpapi;
import tango.sys.windows.isguids;

import tango.sys.windows.subauth;
import tango.sys.windows.ras;

import tango.sys.windows.mapi;
import tango.sys.windows.mciavi;
import tango.sys.windows.mcx;
import tango.sys.windows.mgmtapi;

import tango.sys.windows.msacm;
import tango.sys.windows.nspapi;
+/
import tango.sys.windows.nddeapi;
/+
version (Windows2003) {
	import tango.sys.windows.dhcpcsdk;
	import tango.sys.windows.errorrep;
	import tango.sys.windows.secext;
} else version (WindowsXP) {
	import tango.sys.windows.dhcpcsdk;
	import tango.sys.windows.errorrep;
	import tango.sys.windows.secext;
} else version (WindowsNTonly) {
	version (Windows2000) import tango.sys.windows.dhcpcsdk;
}
+/
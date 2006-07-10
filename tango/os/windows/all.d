/+// Used only for testing -- imports all windows headers.
module tango.os.windows.all;

import tango.os.windows.core;
import tango.os.windows.windows;
import tango.os.windows.commctrl;
import tango.os.windows.setupapi;

import tango.os.windows.dxerr8;
import tango.os.windows.dxerr9;
import tango.os.windows.oleacc;
import tango.os.windows.aclui;
import tango.os.windows.comcat;
import tango.os.windows.cpl;
import tango.os.windows.cplext;
import tango.os.windows.custcntl;
import tango.os.windows.d3d9;
import tango.os.windows.oleacc;
import tango.os.windows.ocidl;
import tango.os.windows.olectl;
import tango.os.windows.oledlg;

import tango.os.windows.shldisp;
import tango.os.windows.shlobj;
import tango.os.windows.shlwapi;
import tango.os.windows.regstr;
import tango.os.windows.richole;
import tango.os.windows.tmschema;
import tango.os.windows.servprov;
import tango.os.windows.exdisp;
import tango.os.windows.exdispid;
import tango.os.windows.idispids;
import tango.os.windows.mshtml;

import tango.os.windows.lm;
import tango.os.windows.lmbrowsr;

import tango.os.windows.sql;
import tango.os.windows.sqlext;
import tango.os.windows.sqlucode;

import tango.os.windows.imagehlp;
import tango.os.windows.intshcut;
import tango.os.windows.iphlpapi;
import tango.os.windows.isguids;

import tango.os.windows.subauth;
import tango.os.windows.ras;

import tango.os.windows.mapi;
import tango.os.windows.mciavi;
import tango.os.windows.mcx;
import tango.os.windows.mgmtapi;

import tango.os.windows.msacm;
import tango.os.windows.nspapi;
+/
import tango.os.windows.nddeapi;
/+
version (Windows2003) {
	import tango.os.windows.dhcpcsdk;
	import tango.os.windows.errorrep;
	import tango.os.windows.secext;
} else version (WindowsXP) {
	import tango.os.windows.dhcpcsdk;
	import tango.os.windows.errorrep;
	import tango.os.windows.secext;
} else version (WindowsNTonly) {
	version (Windows2000) import tango.os.windows.dhcpcsdk;
}
+/
/***********************************************************************\
*                               basetyps.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.win32.basetyps;
private import tango.os.win32.windef;

struct GUID {          // size is 16
align(1):
	DWORD Data1;
	WORD  Data2;
	WORD  Data3;
	BYTE  Data4[8];
}
alias GUID UUID, IID, CLSID, FMTID, uuid_t;
alias GUID* REFGUID, LPGUID, LPCLSID, REFCLSID, LPIID, REFIID, REFFMTID;

alias uint error_status_t, PROPID;

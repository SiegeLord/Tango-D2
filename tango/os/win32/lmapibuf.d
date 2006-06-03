/***********************************************************************\
*                              lmapibuf.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.win32.lmapibuf;
pragma(lib, "netapi32.lib");
private import tango.os.win32.windef;
private import tango.os.win32.lmcons;

extern (Windows) {
	NET_API_STATUS NetApiBufferAllocate(DWORD, PVOID*);
	NET_API_STATUS NetApiBufferFree(PVOID);
	NET_API_STATUS NetApiBufferReallocate(PVOID, DWORD, PVOID*);
	NET_API_STATUS NetApiBufferSize(PVOID, PDWORD);
	NET_API_STATUS NetapipBufferAllocate(DWORD, PVOID*);
}

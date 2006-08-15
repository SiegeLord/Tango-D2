/***********************************************************************\
*                              lmapibuf.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.sys.windows.lmapibuf;
pragma(lib, "netapi32.lib");
private import tango.sys.windows.windef;
private import tango.sys.windows.lmcons;

extern (Windows) {
	NET_API_STATUS NetApiBufferAllocate(DWORD, PVOID*);
	NET_API_STATUS NetApiBufferFree(PVOID);
	NET_API_STATUS NetApiBufferReallocate(PVOID, DWORD, PVOID*);
	NET_API_STATUS NetApiBufferSize(PVOID, PDWORD);
	NET_API_STATUS NetapipBufferAllocate(DWORD, PVOID*);
}

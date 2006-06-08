/***********************************************************************\
*                              servprov.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.windows.c.servprov;

version (build) { pragma(nolink); }

private import tango.os.windows.c.unknwn;
private import tango.os.windows.c.wtypes;

extern (C) {
	extern IID IID_IServiceProvider;
}

interface IServiceProvider : public IUnknown {
	HRESULT QueryService(REFGUID, REFIID, void**);
}

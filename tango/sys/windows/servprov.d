/***********************************************************************\
*                              servprov.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.sys.windows.servprov;
private import tango.sys.windows.unknwn;
private import tango.sys.windows.wtypes;

extern (C) {
	extern IID IID_IServiceProvider;
}

interface IServiceProvider : public IUnknown {
	HRESULT QueryService(REFGUID, REFIID, void**);
}

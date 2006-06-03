/***********************************************************************\
*                              servprov.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module tango.os.win32.servprov;
private import tango.os.win32.unknwn;
private import tango.os.win32.wtypes;

extern (C) {
	extern IID IID_IServiceProvider;
}

interface IServiceProvider : public IUnknown {
	HRESULT QueryService(REFGUID, REFIID, void**);
}

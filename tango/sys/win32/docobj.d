/***********************************************************************\
*                              docobj.d                                 *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.docobj;
private import win32.unknwn;
private import win32.wtypes;
private import win32.oleidl;
private import win32.objidl;
private import win32.oaidl;

// FIXME: remove inherited methods from interface definitions

const OLECMDERR_E_UNKNOWNGROUP = -2147221244;
const OLECMDERR_E_CANCELED     = -2147221245;
const OLECMDERR_E_NOHELP       = -2147221246;
const OLECMDERR_E_DISABLED     = -2147221247;
const OLECMDERR_E_NOTSUPPORTED = -2147221248;

enum OLECMDID {
	OLECMDID_OPEN = 1,
	OLECMDID_NEW = 2,
	OLECMDID_SAVE = 3,
	OLECMDID_SAVEAS = 4,
	OLECMDID_SAVECOPYAS = 5,
	OLECMDID_PRINT = 6,
	OLECMDID_PRINTPREVIEW = 7,
	OLECMDID_PAGESETUP = 8,
	OLECMDID_SPELL = 9,
	OLECMDID_PROPERTIES = 10,
	OLECMDID_CUT = 11,
	OLECMDID_COPY = 12,
	OLECMDID_PASTE = 13,
	OLECMDID_PASTESPECIAL = 14,
	OLECMDID_UNDO = 15,
	OLECMDID_REDO = 16,
	OLECMDID_SELECTALL = 17,
	OLECMDID_CLEARSELECTION = 18,
	OLECMDID_ZOOM = 19,
	OLECMDID_GETZOOMRANGE = 20,
	OLECMDID_UPDATECOMMANDS = 21,
	OLECMDID_REFRESH = 22,
	OLECMDID_STOP = 23,
	OLECMDID_HIDETOOLBARS = 24,
	OLECMDID_SETPROGRESSMAX = 25,
	OLECMDID_SETPROGRESSPOS = 26,
	OLECMDID_SETPROGRESSTEXT = 27,
	OLECMDID_SETTITLE = 28,
	OLECMDID_SETDOWNLOADSTATE = 29,
	OLECMDID_STOPDOWNLOAD = 30
}

enum OLECMDF {
	OLECMDF_SUPPORTED = 1,
	OLECMDF_ENABLED = 2,
	OLECMDF_LATCHED = 4,
	OLECMDF_NINCHED = 8
}

enum OLECMDEXECOPT {
	OLECMDEXECOPT_DODEFAULT = 0,
	OLECMDEXECOPT_PROMPTUSER = 1,
	OLECMDEXECOPT_DONTPROMPTUSER = 2,
	OLECMDEXECOPT_SHOWHELP = 3
}

struct OLECMDTEXT{
	DWORD cmdtextf;
	ULONG cwActual;
	ULONG cwBuf;
	wchar rgwz[1];
}

struct OLECMD{
	ULONG cmdID;
	DWORD cmdf;
}

alias IOleInPlaceSite* LPOLEINPLACESITE;
alias IEnumOleDocumentViews* LPENUMOLEDOCUMENTVIEWS;

extern (C) {
extern IID IID_IContinueCallback;
extern IID IID_IEnumOleDocumentViews;
extern IID IID_IPrint;
extern IID IID_IOleDocumentView;
extern IID IID_IOleDocument;
extern IID IID_IOleCommandTarget;
extern IID IID_IOleDocumentSite;
}

interface IOleDocumentView : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();

	HRESULT SetInPlaceSite(LPOLEINPLACESITE);
	HRESULT GetInPlaceSite(LPOLEINPLACESITE*);
	HRESULT GetDocument(IUnknown**);
	HRESULT SetRect(LPRECT);
	HRESULT GetRect(LPRECT);
	HRESULT SetRectComplex(LPRECT,LPRECT,LPRECT,LPRECT);
	HRESULT Show(BOOL);
	HRESULT UIActivate(BOOL);
	HRESULT Open();
	HRESULT Close(DWORD);
	HRESULT SaveViewState(IStream*);
	HRESULT ApplyViewState(IStream*);
	HRESULT Clone(LPOLEINPLACESITE,IOleDocumentView**);
}

interface IEnumOleDocumentViews : public IUnknown
{
	  HRESULT QueryInterface(REFIID,PVOID*);
	  ULONG AddRef();
	  ULONG Release();
	  HRESULT Next(ULONG,IOleDocumentView*,ULONG*);
	  HRESULT Skip(ULONG);
	  HRESULT Reset();
	  HRESULT Clone(IEnumOleDocumentViews**);
}

interface IOleDocument : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();

	HRESULT CreateView(LPOLEINPLACESITE,IStream*,DWORD,IOleDocumentView**);
	HRESULT GetDocMiscStatus(DWORD*);
	HRESULT EnumViews(LPENUMOLEDOCUMENTVIEWS*,IOleDocumentView**);
}

interface IOleCommandTarget : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();

	HRESULT QueryStatus( GUID*,ULONG,OLECMD*,OLECMDTEXT*);
	HRESULT Exec( GUID*,DWORD,DWORD,VARIANTARG*,VARIANTARG*);
}

interface IOleDocumentSite : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();

	HRESULT ActivateMe(IOleDocumentView*);
}

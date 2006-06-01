/***********************************************************************\
*                                ocidl.d                                *
*                                                                       *
*                       Windows API header module                       *
*                 Part of the Internet Development SDK                  *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.ocidl;

private import win32.ole2;
private import win32.wingdi; // for TEXTMETRICW
private import win32.winuser; // for LPMSG

interface IBindHost : public IUnknown {}
interface IServiceProvider {}

/+
// TODO:
//private import win32.servprov; // for IServiceProvider
// private import win32.urlmon; // for IBindHost. This is not included in MinGW.

// win32.urlmon should contain:
interface IBindHost : public IUnknown
{
	HRESULT CreateMoniker(LPOLESTR szName, IBindCtx* pBC, IMoniker** ppmk, DWORD);
	HRESULT MonikerBindToObject(IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, REFIID, void** );
	HRESULT MonikerBindToStorage(IMoniker* pMk, IBindCtx* pBC, IBindStatusCallback* pBSC, REFIID, void** );
}
+/

alias IErrorLog* LPERRORLOG;
alias IPropertyBag* LPPROPERTYBAG;
alias IPropertyBag2* LPPROPERTYBAG2;
alias IEnumConnections* LPENUMCONNECTIONS;
alias IConnectionPoint* LPCONNECTIONPOINT;
alias IEnumConnectionPoints* LPENUMCONNECTIONPOINTS;
alias IPropertyPageSite* LPPROPERTYPAGESITE;
alias IFont* LPFONT;
alias IFontDisp* LPFONTDISP;
alias IOleUndoManager* LPOLEUNDOMANAGER;


//[Yes] #ifndef OLE2ANSI
alias TEXTMETRICW TEXTMETRICOLE;
//} else {
//alias TEXTMETRIC TEXTMETRICOLE;
//}
alias TEXTMETRICOLE* LPTEXTMETRICOLE;

alias DWORD OLE_COLOR;
alias UINT OLE_HANDLE;
alias int OLE_XPOS_HIMETRIC;
alias int OLE_YPOS_HIMETRIC;
alias int OLE_XSIZE_HIMETRIC;
alias int OLE_YSIZE_HIMETRIC;

enum READYSTATE {
	READYSTATE_UNINITIALIZED = 0,
	READYSTATE_LOADING = 1,
	READYSTATE_LOADED = 2,
	READYSTATE_INTERACTIVE = 3,
	READYSTATE_COMPLETE = 4
}

enum PROPBAG2_TYPE {
	PROPBAG2_TYPE_UNDEFINED	= 0,
	PROPBAG2_TYPE_DATA = 1,
	PROPBAG2_TYPE_URL = 2,
	PROPBAG2_TYPE_OBJECT = 3,
	PROPBAG2_TYPE_STREAM = 4,
	PROPBAG2_TYPE_STORAGE = 5,
	PROPBAG2_TYPE_MONIKER = 6
}

struct PROPBAG2 {
	DWORD dwType;
	VARTYPE vt;
	CLIPFORMAT cfType;
	DWORD dwHint;
	LPOLESTR pstrName;
	CLSID clsid;
}

enum QACONTAINERFLAGS {
	QACONTAINER_SHOWHATCHING = 1,
	QACONTAINER_SHOWGRABHANDLES = 2,
	QACONTAINER_USERMODE = 4,
	QACONTAINER_DISPLAYASDEFAULT = 8,
	QACONTAINER_UIDEAD = 16,
	QACONTAINER_AUTOCLIP = 32,
	QACONTAINER_MESSAGEREFLECT = 64,
	QACONTAINER_SUPPORTSMNEMONICS = 128
}

struct QACONTAINER {
	ULONG cbSize;
	IOleClientSite* pClientSite;
	IAdviseSinkEx* pAdviseSink;
	IPropertyNotifySink* pPropertyNotifySink;
	IUnknown* pUnkEventSink;
	DWORD dwAmbientFlags;
	OLE_COLOR colorFore;
	OLE_COLOR colorBack;
	IFont* pFont;
	IOleUndoManager* pUndoMgr;
	DWORD dwAppearance;
	LONG lcid;
	HPALETTE hpal;
	IBindHost* pBindHost;
	IOleControlSite* pOleControlSite;
	IServiceProvider* pServiceProvider;
}

struct QACONTROL {
	ULONG cbSize;
	DWORD dwMiscStatus;
	DWORD dwViewStatus;
	DWORD dwEventCookie;
	DWORD dwPropNotifyCookie;
	DWORD dwPointerActivationPolicy;
}

struct POINTF {
	float x;
	float y;
}
alias POINTF* LPPOINTF;

struct CONTROLINFO {
	ULONG cb;
	HACCEL hAccel;
	USHORT cAccel;
	DWORD dwFlags;
}
alias CONTROLINFO* LPCONTROLINFO;

struct CONNECTDATA {
	LPUNKNOWN pUnk;
	DWORD dwCookie;
}
alias CONNECTDATA* LPCONNECTDATA;

struct LICINFO {
	int cbLicInfo;
	BOOL fRuntimeKeyAvail;
	BOOL fLicVerified;
}
alias LICINFO* LPLICINFO;

struct CAUUID {
	ULONG cElems;
	GUID* pElems;
}
alias CAUUID* LPCAUUID;

struct CALPOLESTR {
	ULONG cElems;
	LPOLESTR* pElems;
}
alias CALPOLESTR* LPCALPOLESTR;

struct CADWORD {
	ULONG cElems;
	DWORD* pElems;
}
alias CADWORD* LPCADWORD;

struct PROPPAGEINFO {
	ULONG cb;
	LPOLESTR pszTitle;
	SIZE size;
	LPOLESTR pszDocString;
	LPOLESTR pszHelpFile;
	DWORD dwHelpContext;
}
alias PROPPAGEINFO* LPPROPPAGEINFO;

extern (C)
{
	extern IID IID_IOleControl;
	extern IID IID_IOleControlSite;
	extern IID IID_ISimpleFrameSite;
	extern IID IID_IErrorLog;
	extern IID IID_IPropertyBag;
	extern IID IID_IPropertyBag2;
	extern IID IID_IPersistPropertyBag;
	extern IID IID_IPersistPropertyBag2;
	extern IID IID_IPersistStreamInit;
	extern IID IID_IPersistMemory;
	extern IID IID_IPropertyNotifySink;
	extern IID IID_IProvideClassInfo;
	extern IID IID_IProvideClassInfo2;
	extern IID IID_IConnectionPointContainer;
	extern IID IID_IEnumConnectionPoints;
	extern IID IID_IConnectionPoint;
	extern IID IID_IEnumConnections;
	extern IID IID_IClassFactory2;
	extern IID IID_ISpecifyPropertyPages;
	extern IID IID_IPerPropertyBrowsing;
	extern IID IID_IPropertyPageSite;
	extern IID IID_IPropertyPage;
	extern IID IID_IPropertyPage2;
	extern IID IID_IFont;
	extern IID IID_IFontDisp;
	extern IID IID_IPicture;
	extern IID IID_IPictureDisp;
	extern IID IID_IOleInPlaceSiteEx;
	extern IID IID_IObjectWithSite;
	extern IID IID_IOleInPlaceSiteWindowless;
	extern IID IID_IAdviseSinkEx;
	extern IID IID_IPointerInactive;
	extern IID IID_IOleUndoUnit;
	extern IID IID_IOleParentUndoUnit;
	extern IID IID_IEnumOleUndoUnits;
	extern IID IID_IOleUndoManager;
	extern IID IID_IQuickActivate;
}

interface IOleControl : public IUnknown {
	HRESULT GetControlInfo(LPCONTROLINFO);
	HRESULT OnMnemonic(LPMSG);
	HRESULT OnAmbientPropertyChange(DISPID);
	HRESULT FreezeEvents(BOOL);
}

interface IOleControlSite : public IUnknown {
	HRESULT OnControlInfoChanged();
	HRESULT LockInPlaceActive(BOOL);
	HRESULT GetExtendedControl(LPDISPATCH*);
	HRESULT TransformCoords(POINTL*, POINTF*, DWORD);
	HRESULT TranslateAccelerator(LPMSG, DWORD);
	HRESULT OnFocus(BOOL);
	HRESULT ShowPropertyFrame();
}

interface ISimpleFrameSite : public IUnknown {
	HRESULT PreMessageFilter(HWND, UINT, WPARAM, LPARAM, LRESULT*, PDWORD);
	HRESULT PostMessageFilter(HWND, UINT, WPARAM, LPARAM, LRESULT*, DWORD);
}

interface IErrorLog : public IUnknown {
	HRESULT AddError(LPCOLESTR, LPEXCEPINFO);
}

interface IPropertyBag : public IUnknown {
	HRESULT Read(LPCOLESTR, LPVARIANT, LPERRORLOG);
	HRESULT Write(LPCOLESTR, LPVARIANT);
}

interface IPropertyBag2 : public IUnknown {
	HRESULT Read(ULONG, PROPBAG2*, LPERRORLOG, VARIANT*, HRESULT*);
	HRESULT Write(ULONG, PROPBAG2*, VARIANT*);
	HRESULT CountProperties(ULONG*);
	HRESULT GetPropertyInfo(ULONG, ULONG, PROPBAG2*, ULONG*);
	HRESULT LoadObject(LPCOLESTR, DWORD, IUnknown*, LPERRORLOG);
}

interface IPersistPropertyBag : public IPersist {
	HRESULT InitNew();
	HRESULT Load(LPPROPERTYBAG, LPERRORLOG);
	HRESULT Save(LPPROPERTYBAG, BOOL, BOOL);
}

interface IPersistPropertyBag2 : public IPersist {
	HRESULT InitNew();
	HRESULT Load(LPPROPERTYBAG2, LPERRORLOG);
	HRESULT Save(LPPROPERTYBAG2, BOOL, BOOL);
	HRESULT IsDirty();
}

interface IPersistStreamInit : public IPersist {
	HRESULT IsDirty();
	HRESULT Load(LPSTREAM);
	HRESULT Save(LPSTREAM, BOOL);
	HRESULT GetSizeMax(PULARGE_INTEGER);
	HRESULT InitNew();
}

interface IPersistMemory : public IPersist {
	HRESULT IsDirty();
	HRESULT Load(PVOID, ULONG);
	HRESULT Save(PVOID, BOOL, ULONG);
	HRESULT GetSizeMax(PULONG);
	HRESULT InitNew();
}

interface IPropertyNotifySink : public IUnknown {
	HRESULT OnChanged(DISPID);
	HRESULT OnRequestEdit(DISPID);
}

interface IProvideClassInfo : public IUnknown {
	HRESULT GetClassInfo(LPTYPEINFO*);
}

interface IProvideClassInfo2 : public IProvideClassInfo {
	HRESULT GetGUID(DWORD, GUID*);
}

interface IConnectionPointContainer : public IUnknown {
	HRESULT EnumConnectionPoints(LPENUMCONNECTIONPOINTS*);
	HRESULT FindConnectionPoint(REFIID, LPCONNECTIONPOINT*);
}

interface IEnumConnectionPoints : public IUnknown {
	HRESULT Next(ULONG, LPCONNECTIONPOINT*, ULONG*);
	HRESULT Skip(ULONG);
	HRESULT Reset();
	HRESULT Clone(LPENUMCONNECTIONPOINTS*);
}

interface IConnectionPoint : public IUnknown {
	HRESULT GetConnectionInterface(IID*);
	HRESULT GetConnectionPointContainer(IConnectionPointContainer**);
	HRESULT Advise(LPUNKNOWN, PDWORD);
	HRESULT Unadvise(DWORD);
	HRESULT EnumConnections(LPENUMCONNECTIONS*);
}

interface IEnumConnections : public IUnknown {
	HRESULT Next(ULONG, LPCONNECTDATA, PULONG);
	HRESULT Skip(ULONG);
	HRESULT Reset();
	HRESULT Clone(LPENUMCONNECTIONS*);
}

interface IClassFactory2 : public IClassFactory {
	HRESULT GetLicInfo(LPLICINFO);
	HRESULT RequestLicKey(DWORD, BSTR*);
	HRESULT CreateInstanceLic(LPUNKNOWN, LPUNKNOWN, REFIID, BSTR, PVOID*);
}

interface ISpecifyPropertyPages : public IUnknown {
	HRESULT GetPages(CAUUID*);
}

interface IPerPropertyBrowsing : public IUnknown {
	HRESULT GetDisplayString(DISPID, BSTR*);
	HRESULT MapPropertyToPage(DISPID, LPCLSID);
	HRESULT GetPredefinedStrings(DISPID, CALPOLESTR*, CADWORD*);
	HRESULT GetPredefinedValue(DISPID, DWORD, VARIANT*);
}

interface IPropertyPageSite : public IUnknown {
	HRESULT OnStatusChange(DWORD);
	HRESULT GetLocaleID(LCID*);
	HRESULT GetPageContainer(LPUNKNOWN*);
	HRESULT TranslateAccelerator(LPMSG);
}

interface IPropertyPage : public IUnknown {
	HRESULT SetPageSite(LPPROPERTYPAGESITE);
	HRESULT Activate(HWND, LPCRECT, BOOL);
	HRESULT Deactivate();
	HRESULT GetPageInfo(LPPROPPAGEINFO);
	HRESULT SetObjects(ULONG, LPUNKNOWN*);
	HRESULT Show(UINT);
	HRESULT Move(LPCRECT);
	HRESULT IsPageDirty();
	HRESULT Apply();
	HRESULT Help(LPCOLESTR);
	HRESULT TranslateAccelerator(LPMSG);
}


interface IPropertyPage2 : public IPropertyPage
{ HRESULT EditProperty(DISPID);
}

interface IFont : public IUnknown {
	HRESULT get_Name(BSTR*);
	HRESULT put_Name(BSTR);
	HRESULT get_Size(CY*);
	HRESULT put_Size(CY);
	HRESULT get_Bold(BOOL*);
	HRESULT put_Bold(BOOL);
	HRESULT get_Italic(BOOL*);
	HRESULT put_Italic(BOOL);
	HRESULT get_Underline(BOOL*);
	HRESULT put_Underline(BOOL);
	HRESULT get_Strikethrough(BOOL*);
	HRESULT put_Strikethrough(BOOL);
	HRESULT get_Weight(short*);
	HRESULT put_Weight(short);
	HRESULT get_Charset(short*);
	HRESULT put_Charset(short);
	HRESULT get_hFont(HFONT*);
	HRESULT Clone(IFont**);
	HRESULT IsEqual(IFont*);
	HRESULT SetRatio(int, int);
	HRESULT QueryTextMetrics(LPTEXTMETRICOLE);
	HRESULT AddRefHfont(HFONT);
	HRESULT ReleaseHfont(HFONT);
	HRESULT SetHdc(HDC);
}

interface IFontDisp : public IDispatch {
}

interface IPicture : public IUnknown {
	HRESULT get_Handle(OLE_HANDLE*);
	HRESULT get_hPal(OLE_HANDLE*);
	HRESULT get_Type(short*);
	HRESULT get_Width(OLE_XSIZE_HIMETRIC*);
	HRESULT get_Height(OLE_YSIZE_HIMETRIC*);
	HRESULT Render(HDC, int, int, int, int, OLE_XPOS_HIMETRIC,
	  OLE_YPOS_HIMETRIC, OLE_XSIZE_HIMETRIC, OLE_YSIZE_HIMETRIC, LPCRECT);
	HRESULT set_hPal(OLE_HANDLE);
	HRESULT get_CurDC(HDC*);
	HRESULT SelectPicture(HDC, HDC*, OLE_HANDLE*);
	HRESULT get_KeepOriginalFormat(BOOL*);
	HRESULT put_KeepOriginalFormat(BOOL);
	HRESULT PictureChanged();
	HRESULT SaveAsFile(LPSTREAM, BOOL, LONG*);
	HRESULT get_Attributes(PDWORD);
}

interface IPictureDisp : public IDispatch {
}

interface IOleInPlaceSiteEx : public IOleInPlaceSite {
	HRESULT OnInPlaceActivateEx(BOOL*, DWORD);
	HRESULT OnInPlaceDeactivateEx(BOOL);
	HRESULT RequestUIActivate();
}

interface IObjectWithSite : public IUnknown {
	HRESULT SetSite(IUnknown*);
	HRESULT GetSite(REFIID, void**);
}

interface IOleInPlaceSiteWindowless : public IOleInPlaceSiteEx {
	HRESULT CanWindowlessActivate();
	HRESULT GetCapture();
	HRESULT SetCapture(BOOL);
	HRESULT GetFocus();
	HRESULT SetFocus(BOOL);
	HRESULT GetDC(LPCRECT, DWORD, HDC*);
	HRESULT ReleaseDC(HDC);
	HRESULT InvalidateRect(LPCRECT, BOOL);
	HRESULT InvalidateRgn(HRGN, BOOL);
	HRESULT ScrollRect(INT, INT, LPCRECT, LPCRECT);
	HRESULT AdjustRect(LPCRECT);
	HRESULT OnDefWindowMessage(UINT, WPARAM, LPARAM, LRESULT*);
}

interface IAdviseSinkEx : public IUnknown {
	void OnDataChange(FORMATETC*, STGMEDIUM*);
	void OnViewChange(DWORD, LONG);
	void OnRename(IMoniker*);
	void OnSave();
	void OnClose();
	HRESULT OnViewStatusChange(DWORD);
}

interface IPointerInactive : public IUnknown {
	HRESULT GetActivationPolicy(DWORD*);
	HRESULT OnInactiveMouseMove(LPCRECT, LONG, LONG, DWORD);
	HRESULT OnInactiveSetCursor(LPCRECT, LONG, LONG, DWORD, BOOL);
}

interface IOleUndoUnit : public IUnknown {
	HRESULT Do(LPOLEUNDOMANAGER);
	HRESULT GetDescription(BSTR*);
	HRESULT GetUnitType(CLSID*, LONG*);
	HRESULT OnNextAdd();
}

interface IOleParentUndoUnit : public IOleUndoUnit {
	HRESULT Open(IOleParentUndoUnit*);
	HRESULT Close(IOleParentUndoUnit*, BOOL);
	HRESULT Add(IOleUndoUnit*);
	HRESULT FindUnit(IOleUndoUnit*);
	HRESULT GetParentState(DWORD*);
}

interface IEnumOleUndoUnits : public IUnknown {
	HRESULT Next(ULONG, IOleUndoUnit**, ULONG*);
	HRESULT Skip(ULONG);
	HRESULT Reset();
	HRESULT Clone(IEnumOleUndoUnits**);
}

interface IOleUndoManager : public IUnknown {
	HRESULT Open(IOleParentUndoUnit*);
	HRESULT Close(IOleParentUndoUnit*, BOOL);
	HRESULT Add(IOleUndoUnit*);
	HRESULT GetOpenParentState(DWORD*);
	HRESULT DiscardFrom(IOleUndoUnit*);
	HRESULT UndoTo(IOleUndoUnit*);
	HRESULT RedoTo(IOleUndoUnit*);
	HRESULT EnumUndoable(IEnumOleUndoUnits**);
	HRESULT EnumRedoable(IEnumOleUndoUnits**);
	HRESULT GetLastUndoDescription(BSTR*);
	HRESULT GetLastRedoDescription(BSTR*);
	HRESULT Enable(BOOL);
}

interface IQuickActivate : public IUnknown {
	HRESULT QuickActivate(QACONTAINER*, QACONTROL*);
	HRESULT SetContentExtent(LPSIZEL);
	HRESULT GetContentExtent(LPSIZEL);
}

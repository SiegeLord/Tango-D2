/***********************************************************************\
*                                oleidl.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
// DAC: This is defined in ocidl !!
// what is it doing in here?
//alias IEnumOleUndoUnits* LPENUMOLEUNDOUNITS;

module win32.oleidl;

private import win32.unknwn;
private import win32.wtypes;
private import win32.objidl;
private import win32.winuser;
private import win32.wingdi; // for LPLOGPALETTE

const MK_ALT = 32;

alias IParseDisplayName* LPPARSEDISPLAYNAME;
alias IOleContainer* LPOLECONTAINER;
alias IOleClientSite* LPOLECLIENTSITE;
alias IOleObject* LPOLEOBJECT;
alias IDropTarget* LPDROPTARGET;
alias IDropSource* LPDROPSOURCE;
alias IEnumOLEVERB* LPENUMOLEVERB;
alias IOleWindow* LPOLEWINDOW;
alias IOleInPlaceUIWindow* LPOLEINPLACEUIWINDOW;
alias IOleInPlaceActiveObject* LPOLEINPLACEACTIVEOBJECT;
alias IOleInPlaceFrame* LPOLEINPLACEFRAME;
alias IOleAdviseHolder* LPOLEADVISEHOLDER;
alias IViewObject* LPVIEWOBJECT;
alias IViewObject2* LPVIEWOBJECT2;
alias IOleCache* LPOLECACHE;
alias IOleCache2* LPOLECACHE2;
alias IOleCacheControl* LPOLECACHECONTROL;

enum BINDSPEED {
	BINDSPEED_INDEFINITE = 1,
	BINDSPEED_MODERATE,
	BINDSPEED_IMMEDIATE
}

enum OLEWHICHMK {
	OLEWHICHMK_CONTAINER = 1,
	OLEWHICHMK_OBJREL,
	OLEWHICHMK_OBJFULL
}

enum OLEGETMONIKER {
	OLEGETMONIKER_ONLYIFTHERE = 1,
	OLEGETMONIKER_FORCEASSIGN,
	OLEGETMONIKER_UNASSIGN,
	OLEGETMONIKER_TEMPFORUSER
}

enum USERCLASSTYPE {
	USERCLASSTYPE_FULL = 1,
	USERCLASSTYPE_SHORT,
	USERCLASSTYPE_APPNAME
}

enum DROPEFFECT {
	DROPEFFECT_NONE   = 0,
	DROPEFFECT_COPY   = 1,
	DROPEFFECT_MOVE   = 2,
	DROPEFFECT_LINK   = 4,
	DROPEFFECT_SCROLL = 0x80000000
}

struct OLEMENUGROUPWIDTHS {
	LONG width[6];
}
alias OLEMENUGROUPWIDTHS* LPOLEMENUGROUPWIDTHS;

alias HGLOBAL HOLEMENU;

enum OLECLOSE {
	OLECLOSE_SAVEIFDIRTY,
	OLECLOSE_NOSAVE,
	OLECLOSE_PROMPTSAVE
}

struct OLEVERB {
	LONG lVerb;
	LPWSTR lpszVerbName;
	DWORD fuFlags;
	DWORD grfAttribs;
}
alias OLEVERB* LPOLEVERB;

alias RECT BORDERWIDTHS;
alias LPRECT LPBORDERWIDTHS;
alias LPCRECT LPCBORDERWIDTHS;

struct OLEINPLACEFRAMEINFO {
	UINT cb;
	BOOL fMDIApp;
	HWND hwndFrame;
	HACCEL haccel;
	UINT cAccelEntries;
}
alias OLEINPLACEFRAMEINFO* LPOLEINPLACEFRAMEINFO;

interface IEnumOLEVERB : public IUnknown
{
	  HRESULT Next(ULONG,OLEVERB*,ULONG*);
	  HRESULT Skip(ULONG);
	  HRESULT Reset();
	  HRESULT Clone(IEnumOLEVERB**);
}
alias IEnumOLEVERB IEnumOleVerb;

extern (C) {
	extern IID IID_IParseDisplayName;
	extern IID IID_IOleContainer;
	extern IID IID_IOleItemContainer;
	extern IID IID_IOleClientSite;
	extern IID IID_IOleObject;
	extern IID IID_IOleWindow;
	extern IID IID_IOleInPlaceUIWindow;
	extern IID IID_IOleInPlaceObject;
	extern IID IID_IOleInPlaceActiveObject;
	extern IID IID_IOleInPlaceFrame;
	extern IID IID_IOleInPlaceSite;
	extern IID IID_IOleAdviseHolder;
	extern IID IID_IDropSource;
	extern IID IID_IDropTarget;
	extern IID IID_IViewObject;
	extern IID IID_IViewObject2;
	extern IID IID_IOleCache;
	extern IID IID_IOleCache2;
	extern IID IID_IOleCacheControl;
}

interface IParseDisplayName : public IUnknown {
	HRESULT ParseDisplayName(IBindCtx*,LPOLESTR,ULONG*,IMoniker**);
}

interface IOleContainer : public IParseDisplayName {
	HRESULT EnumObjects(DWORD,IEnumUnknown**);
	HRESULT LockContainer(BOOL);
}

interface IOleItemContainer : public IOleContainer {
	HRESULT GetObject(LPOLESTR,DWORD,IBindCtx*,REFIID,void**);
	HRESULT GetObjectStorage(LPOLESTR,IBindCtx*,REFIID,void**);
	HRESULT IsRunning(LPOLESTR);
}

interface IOleClientSite : public IUnknown {
	HRESULT SaveObject();
	HRESULT GetMoniker(DWORD,DWORD,LPMONIKER*);
	HRESULT GetContainer(LPOLECONTAINER*);
	HRESULT ShowObject();
	HRESULT OnShowWindow(BOOL);
	HRESULT RequestNewObjectLayout();
}

interface IOleObject : public IUnknown {
	HRESULT SetClientSite(LPOLECLIENTSITE);
	HRESULT GetClientSite(LPOLECLIENTSITE*);
	HRESULT SetHostNames(LPCOLESTR,LPCOLESTR);
	HRESULT Close(DWORD);
	HRESULT SetMoniker(DWORD,LPMONIKER);
	HRESULT GetMoniker(DWORD,DWORD,LPMONIKER*);
	HRESULT InitFromData(LPDATAOBJECT,BOOL,DWORD);
	HRESULT GetClipboardData(DWORD,LPDATAOBJECT*);
	HRESULT DoVerb(LONG,LPMSG,LPOLECLIENTSITE,LONG,HWND,LPCRECT);
	HRESULT EnumVerbs(LPENUMOLEVERB*);
	HRESULT Update();
	HRESULT IsUpToDate();
	HRESULT GetUserClassID(LPCLSID);
	HRESULT GetUserType(DWORD,LPOLESTR*);
	HRESULT SetExtent(DWORD,SIZEL*);
	HRESULT GetExtent(DWORD,SIZEL*);
	HRESULT Advise(LPADVISESINK,PDWORD);
	HRESULT Unadvise(DWORD);
	HRESULT EnumAdvise(LPENUMSTATDATA*);
	HRESULT GetMiscStatus(DWORD,PDWORD);
	HRESULT SetColorScheme(LPLOGPALETTE);
}

interface IOleWindow : public IUnknown {
	HRESULT GetWindow(HWND*);
	HRESULT ContextSensitiveHelp(BOOL);
}

interface IOleInPlaceUIWindow : public IOleWindow {
	HRESULT GetBorder(LPRECT);
	HRESULT RequestBorderSpace(LPCBORDERWIDTHS);
	HRESULT SetBorderSpace(LPCBORDERWIDTHS);
	HRESULT SetActiveObject(LPOLEINPLACEACTIVEOBJECT,LPCOLESTR);
}

interface IOleInPlaceObject : public IOleWindow {
	HRESULT InPlaceDeactivate();
	HRESULT UIDeactivate();
	HRESULT SetObjectRects(LPCRECT,LPCRECT);
	HRESULT ReactivateAndUndo();
}


interface IOleInPlaceActiveObject : public IOleWindow {
	HRESULT TranslateAccelerator(LPMSG);
	HRESULT OnFrameWindowActivate(BOOL);
	HRESULT OnDocWindowActivate(BOOL);
	HRESULT ResizeBorder(LPCRECT,LPOLEINPLACEUIWINDOW,BOOL);
	HRESULT EnableModeless(BOOL);
}

interface IOleInPlaceFrame : public IOleInPlaceUIWindow {
	HRESULT InsertMenus(HMENU,LPOLEMENUGROUPWIDTHS);
	HRESULT SetMenu(HMENU,HOLEMENU,HWND);
	HRESULT RemoveMenus(HMENU);
	HRESULT SetStatusText(LPCOLESTR);
	HRESULT EnableModeless(BOOL);
	HRESULT TranslateAccelerator(LPMSG,WORD);
}

interface IOleInPlaceSite  : public IOleWindow {
	HRESULT CanInPlaceActivate();
	HRESULT OnInPlaceActivate();
	HRESULT OnUIActivate();
	HRESULT GetWindowContext(IOleInPlaceFrame**,IOleInPlaceUIWindow**,LPRECT,LPRECT,LPOLEINPLACEFRAMEINFO);
	HRESULT Scroll(SIZE);
	HRESULT OnUIDeactivate(BOOL);
	HRESULT OnInPlaceDeactivate();
	HRESULT DiscardUndoState();
	HRESULT DeactivateAndUndo();
	HRESULT OnPosRectChange(LPCRECT);
}

interface IOleAdviseHolder : public IUnknown {
	HRESULT Advise(LPADVISESINK,PDWORD);
	HRESULT Unadvise(DWORD);
	HRESULT EnumAdvise(LPENUMSTATDATA*);
	HRESULT SendOnRename(LPMONIKER);
	HRESULT SendOnSave();
	HRESULT SendOnClose();
}

interface IDropSource : public IUnknown {
	HRESULT QueryContinueDrag(BOOL,DWORD);
	HRESULT GiveFeedback(DWORD);
}

interface IDropTarget : public IUnknown {
	HRESULT DragEnter(LPDATAOBJECT,DWORD,POINTL,PDWORD);
	HRESULT DragOver(DWORD,POINTL,PDWORD);
	HRESULT DragLeave();
	HRESULT Drop(LPDATAOBJECT,DWORD,POINTL,PDWORD);
}

extern (Windows) {
	alias BOOL function(DWORD) __IView_pfncont;
}

interface IViewObject : public IUnknown {
	HRESULT Draw(DWORD,LONG,PVOID,DVTARGETDEVICE*,HDC,HDC,LPCRECTL,LPCRECTL,__IView_pfncont pfnContinue,DWORD);
	HRESULT GetColorSet(DWORD,LONG,PVOID,DVTARGETDEVICE*,HDC,LPLOGPALETTE*);
	HRESULT Freeze(DWORD,LONG,PVOID,PDWORD);
	HRESULT Unfreeze(DWORD);
	HRESULT SetAdvise(DWORD,DWORD,IAdviseSink*);
	HRESULT GetAdvise(PDWORD,PDWORD,IAdviseSink**);
}

interface IViewObject2 : public IViewObject {
	HRESULT GetExtent(DWORD,LONG,DVTARGETDEVICE*,LPSIZEL);
}

interface IOleCache : public IUnknown {
	HRESULT Cache(FORMATETC*,DWORD,DWORD*);
	HRESULT Uncache(DWORD);
	HRESULT EnumCache(IEnumSTATDATA**);
	HRESULT InitCache(LPDATAOBJECT);
	HRESULT SetData(FORMATETC*,STGMEDIUM*,BOOL);
}

interface IOleCache2 : public IOleCache {
	HRESULT UpdateCache(LPDATAOBJECT,DWORD,LPVOID);
	HRESULT DiscardCache(DWORD);
}

interface IOleCacheControl : public IUnknown {
	HRESULT OnRun(LPDATAOBJECT);
	HRESULT OnStop();
}

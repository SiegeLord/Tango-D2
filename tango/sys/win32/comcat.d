/***********************************************************************\
*                                comcat.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.comcat;

import win32.windows, win32.ole2;

alias IEnumGUID* LPENUMGUID;

interface IEnumGUID : IUnknown {
	HRESULT Next(ULONG, GUID*, ULONG*);
	HRESULT Skip(ULONG);
	HRESULT Reset();
	HRESULT Clone(LPENUMGUID*);
}

alias GUID CATID;
alias REFGUID REFCATID;
alias GUID_NULL CATID_NULL;
alias IsEqualGUID IsEqualCATID;

struct CATEGORYINFO {
	CATID        catid;
	LCID         lcid;
	OLECHAR[128] szDescription;
}
alias CATEGORYINFO* LPCATEGORYINFO;

extern (C) {
	const CATID
		CATID_Insertable,
		CATID_Control,
		CATID_Programmable,
		CATID_IsShortcut,
		CATID_NeverShowExt,
		CATID_DocObject,
		CATID_Printable,
		CATID_RequiresDataPathHost,
		CATID_PersistsToMoniker,
		CATID_PersistsToStorage,
		CATID_PersistsToStreamInit,
		CATID_PersistsToStream,
		CATID_PersistsToMemory,
		CATID_PersistsToFile,
		CATID_PersistsToPropertyBag,
		CATID_InternetAware,
		CATID_DesignTimeUIActivatableControl;

	const CLSID CLSID_StdComponentCategoriesMgr;

	const IID
		IID_IEnumGUID,
		IID_ICatInformation,
		IID_ICatRegister,
		IID_IEnumCATEGORYINFO;
}

alias IEnumGUID IEnumCATID;
alias LPENUMGUID LPENUMCATID;
alias IID_IEnumGUID IID_IEnumCATID;

alias IEnumGUID IEnumCLSID;
alias LPENUMGUID LPENUMCLSID;
alias IID_IEnumGUID IID_IEnumCLSID;

interface ICatInformation : IUnknown {
	HRESULT EnumCategories(LCID, LPENUMCATEGORYINFO*);
	HRESULT GetCategoryDesc(REFCATID, LCID, PWCHAR*);
	HRESULT EnumClassesOfCategories(ULONG, CATID*, ULONG, CATID*,
	  LPENUMCLSID*);
	HRESULT IsClassOfCategories(REFCLSID, ULONG, CATID*, ULONG, CATID*);
	HRESULT EnumImplCategoriesOfClass(REFCLSID, LPENUMCATID*);
	HRESULT EnumReqCategoriesOfClass(REFCLSID, LPENUMCATID*);
}
alias ICatInformation* LPCATINFORMATION;

interface ICatRegister : IUnknown {
	HRESULT RegisterCategories(ULONG, CATEGORYINFO*);
	HRESULT UnRegisterCategories(ULONG, CATID*);
	HRESULT RegisterClassImplCategories(REFCLSID, ULONG, CATID*);
	HRESULT UnRegisterClassImplCategories(REFCLSID, ULONG, CATID*);
	HRESULT RegisterClassReqCategories(REFCLSID, ULONG, CATID*);
	HRESULT UnRegisterClassReqCategories(REFCLSID, ULONG, CATID*);
}
alias ICatRegister* LPCATREGISTER;

interface IEnumCATEGORYINFO : IUnknown {
	HRESULT Next(ULONG, CATEGORYINFO*, ULONG*);
	HRESULT Skip(ULONG);
	HRESULT Reset();
	HRESULT Clone(LPENUMCATEGORYINFO*);
}
alias IEnumCATEGORYINFO* LPENUMCATEGORYINFO;

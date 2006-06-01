/***********************************************************************\
*                              shlguid.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.shlguid;

private import win32.basetyps;
private import win32.w32api;

// FIXME: clean up Windows version support

// I think this is just a helper macro for other win32 headers?
//MACRO #define DEFINE_SHLGUID(n,l,w1,w2) DEFINE_GUID(n,l,w1,w2,0xC0,0,0,0,0,0,0,0x46)

extern (C) {
	extern GUID CLSID_ShellDesktop;
	extern GUID CLSID_ShellLink;
	extern GUID FMTID_Intshcut;
	extern GUID FMTID_InternetSite;
	extern GUID CGID_Explorer;
	extern GUID CGID_ShellDocView;
	extern GUID CGID_ShellServiceObject;
	extern GUID IID_INewShortcutHookA;
	extern GUID IID_IShellBrowser;
	extern GUID IID_IShellView;
	extern GUID IID_IContextMenu;
	extern GUID IID_IColumnProvider;
	extern GUID IID_IQueryInfo;
	extern GUID IID_IShellIcon;
	extern GUID IID_IShellIconOverlayIdentifier;
	extern GUID IID_IShellFolder;
	extern GUID IID_IShellExtInit;
	extern GUID IID_IShellPropSheetExt;
	extern GUID IID_IPersistFolder;
	extern GUID IID_IExtractIconA;
	extern GUID IID_IShellLinkA;
	extern GUID IID_IShellCopyHookA;
	extern GUID IID_IFileViewerA;
	extern GUID IID_ICommDlgBrowser;
	extern GUID IID_IEnumIDList;
	extern GUID IID_IFileViewerSite;
	extern GUID IID_IContextMenu2;
	extern GUID IID_IShellExecuteHookA;
	extern GUID IID_IPropSheetPage;
	extern GUID IID_INewShortcutHookW;
	extern GUID IID_IFileViewerW;
	extern GUID IID_IShellLinkW;
	extern GUID IID_IExtractIconW;
	extern GUID IID_IShellExecuteHookW;
	extern GUID IID_IShellCopyHookW;
	extern GUID IID_IShellView2;
	extern GUID LIBID_SHDocVw;
	extern GUID IID_IShellExplorer;
	extern GUID DIID_DShellExplorerEvents;
	extern GUID CLSID_ShellExplorer;
	extern GUID IID_ISHItemOC;
	extern GUID DIID_DSHItemOCEvents;
	extern GUID CLSID_SHItemOC;
	extern GUID IID_DHyperLink;
	extern GUID IID_DIExplorer;
	extern GUID DIID_DExplorerEvents;
	extern GUID CLSID_InternetExplorer;
	extern GUID CLSID_StdHyperLink;
	extern GUID CLSID_FileTypes;
	extern GUID CLSID_InternetShortcut;
	extern GUID IID_IUniformResourceLocator;
	extern GUID CLSID_DragDropHelper;
	extern GUID IID_IDropTargetHelper;
	extern GUID IID_IDragSourceHelper;
	extern GUID CLSID_AutoComplete;
	extern GUID IID_IAutoComplete;
	extern GUID IID_IAutoComplete2;
	extern GUID CLSID_ACLMulti;
	extern GUID IID_IObjMgr;
	extern GUID CLSID_ACListISF;
	extern GUID IID_IACList;

	static if (_WIN32_IE >= 0x400 || _WIN32_WINNT >= 0x500) {
		extern GUID IID_IPersistFolder2;
	}

	static if (_WIN32_WINNT >= 0x0500) {
		extern GUID IID_IPersistFolder3;
		extern GUID IID_IShellFolder2;
		extern GUID IID_IFileSystemBindData;
	}
}

alias IID_IShellBrowser SID_SShellBrowser;

version(Unicode) {
	alias IID_IFileViewerW IID_IFileViewer;
	alias IID_IShellLinkW IID_IShellLink;
	alias IID_IExtractIconW IID_IExtractIcon;
	alias IID_IShellCopyHookW IID_IShellCopyHook;
	alias IID_IShellExecuteHookW IID_IShellExecuteHook;
	alias IID_INewShortcutHookW IID_INewShortcutHook;
} else {
	alias IID_IFileViewerA IID_IFileViewer;
	alias IID_IShellLinkA IID_IShellLink;
	alias IID_IExtractIconA IID_IExtractIcon;
	alias IID_IShellCopyHookA IID_IShellCopyHook;
	alias IID_IShellExecuteHookA IID_IShellExecuteHook;
	alias IID_INewShortcutHookA IID_INewShortcutHook;
}

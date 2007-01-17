/***********************************************************************\
*                               shlguid.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.shlguid;

private import win32.basetyps, win32.w32api;

// FIXME: clean up Windows version support

// I think this is just a helper macro for other win32 headers?
//MACRO #define DEFINE_SHLGUID(n,l,w1,w2) DEFINE_GUID(n,l,w1,w2,0xC0,0,0,0,0,0,0,0x46)

extern (C) {
	extern const GUID
		CLSID_ShellDesktop,
		CLSID_ShellLink,
		FMTID_Intshcut,
		FMTID_InternetSite,
		CGID_Explorer,
		CGID_ShellDocView,
		CGID_ShellServiceObject,
		IID_INewShortcutHookA,
		IID_IShellBrowser,
		IID_IShellView,
		IID_IContextMenu,
		IID_IColumnProvider,
		IID_IQueryInfo,
		IID_IShellIcon,
		IID_IShellIconOverlayIdentifier,
		IID_IShellFolder,
		IID_IShellExtInit,
		IID_IShellPropSheetExt,
		IID_IPersistFolder,
		IID_IExtractIconA,
		IID_IShellLinkA,
		IID_IShellCopyHookA,
		IID_IFileViewerA,
		IID_ICommDlgBrowser,
		IID_IEnumIDList,
		IID_IFileViewerSite,
		IID_IContextMenu2,
		IID_IShellExecuteHookA,
		IID_IPropSheetPage,
		IID_INewShortcutHookW,
		IID_IFileViewerW,
		IID_IShellLinkW,
		IID_IExtractIconW,
		IID_IShellExecuteHookW,
		IID_IShellCopyHookW,
		IID_IShellView2,
		LIBID_SHDocVw,
		IID_IShellExplorer,
		DIID_DShellExplorerEvents,
		CLSID_ShellExplorer,
		IID_ISHItemOC,
		DIID_DSHItemOCEvents,
		CLSID_SHItemOC,
		IID_DHyperLink,
		IID_DIExplorer,
		DIID_DExplorerEvents,
		CLSID_InternetExplorer,
		CLSID_StdHyperLink,
		CLSID_FileTypes,
		CLSID_InternetShortcut,
		IID_IUniformResourceLocator,
		CLSID_DragDropHelper,
		IID_IDropTargetHelper,
		IID_IDragSourceHelper,
		CLSID_AutoComplete,
		IID_IAutoComplete,
		IID_IAutoComplete2,
		CLSID_ACLMulti,
		IID_IObjMgr,
		CLSID_ACListISF,
		IID_IACList;

	static if (_WIN32_IE >= 0x400 || _WIN32_WINNT >= 0x500) {
		extern const GUID IID_IPersistFolder2;
	}

	static if (_WIN32_WINNT >= 0x0500) {
		extern const GUID
			IID_IPersistFolder3,
			IID_IShellFolder2,
			IID_IFileSystemBindData;
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

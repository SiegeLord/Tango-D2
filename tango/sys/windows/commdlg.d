/***********************************************************************\
*                               commdlg.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.commdlg;
pragma(lib, "comdlg32.lib");

private import win32.w32api;
import win32.windef, win32.winuser;
import win32.wingdi; // for LPLOGFONTA

const TCHAR []
	LBSELCHSTRING = "commdlg_LBSelChangedNotify",
	SHAREVISTRING = "commdlg_ShareViolation",
	FILEOKSTRING  = "commdlg_FileNameOK",
	COLOROKSTRING = "commdlg_ColorOK",
	SETRGBSTRING  = "commdlg_SetRGBColor",
	HELPMSGSTRING = "commdlg_help",
	FINDMSGSTRING = "commdlg_FindReplace";

const UINT
	CDN_FIRST          = -601, // also in commctrl.h
	CDN_LAST           = -699,
	CDN_INITDONE       = CDN_FIRST,
	CDN_SELCHANGE      = CDN_FIRST-1,
	CDN_FOLDERCHANGE   = CDN_FIRST-2,
	CDN_SHAREVIOLATION = CDN_FIRST-3,
	CDN_HELP           = CDN_FIRST-4,
	CDN_FILEOK         = CDN_FIRST-5,
	CDN_TYPECHANGE     = CDN_FIRST-6;

const CDM_FIRST           = WM_USER+100;
const CDM_LAST            = WM_USER+200;
const CDM_GETSPEC         = CDM_FIRST;
const CDM_GETFILEPATH     = CDM_FIRST+1;
const CDM_GETFOLDERPATH   = CDM_FIRST+2;
const CDM_GETFOLDERIDLIST = CDM_FIRST+3;
const CDM_SETCONTROLTEXT  = CDM_FIRST+4;
const CDM_HIDECONTROL     = CDM_FIRST+5;
const CDM_SETDEFEXT       = CDM_FIRST+6;

// flags for ChooseColor
enum : DWORD {
	CC_RGBINIT              = 1,
	CC_FULLOPEN             = 2,
	CC_PREVENTFULLOPEN      = 4,
	CC_SHOWHELP             = 8,
	CC_ENABLEHOOK           = 16,
	CC_ENABLETEMPLATE       = 32,
	CC_ENABLETEMPLATEHANDLE = 64,
	CC_SOLIDCOLOR           = 128,
	CC_ANYCOLOR             = 256
}

// flags for ChooseFont
enum : DWORD {
	CF_SCREENFONTS          = 1,
	CF_PRINTERFONTS         = 2,
	CF_BOTH                 = 3,
	CF_SHOWHELP             = 4,
	CF_ENABLEHOOK           = 8,
	CF_ENABLETEMPLATE       = 16,
	CF_ENABLETEMPLATEHANDLE = 32,
	CF_INITTOLOGFONTSTRUCT  = 64,
	CF_USESTYLE             = 128,
	CF_EFFECTS              = 256,
	CF_APPLY                = 512,
	CF_ANSIONLY             = 1024,
	CF_SCRIPTSONLY          = CF_ANSIONLY,
	CF_NOVECTORFONTS        = 2048,
	CF_NOOEMFONTS           = 2048,
	CF_NOSIMULATIONS        = 4096,
	CF_LIMITSIZE            = 8192,
	CF_FIXEDPITCHONLY       = 16384,
	CF_WYSIWYG              = 32768,
	CF_FORCEFONTEXIST       = 65536,
	CF_SCALABLEONLY         = 131072,
	CF_TTONLY               = 262144,
	CF_NOFACESEL            = 524288,
	CF_NOSTYLESEL           = 1048576,
	CF_NOSIZESEL            = 2097152,
	CF_SELECTSCRIPT         = 4194304,
	CF_NOSCRIPTSEL          = 8388608,
	CF_NOVERTFONTS          = 0x1000000
}

// Font type for ChooseFont
enum : WORD {
	BOLD_FONTTYPE      = 0x100,
	ITALIC_FONTTYPE    = 0x200,
	REGULAR_FONTTYPE   = 0x400,
	SCREEN_FONTTYPE    = 0x2000,
	PRINTER_FONTTYPE   = 0x4000,
	SIMULATED_FONTTYPE = 0x8000
}

const WM_CHOOSEFONT_GETLOGFONT = WM_USER + 1;
const WM_CHOOSEFONT_SETLOGFONT = WM_USER + 101;
const WM_CHOOSEFONT_SETFLAGS   = WM_USER + 102;

// flags for OpenFileName
enum : DWORD {
	OFN_ALLOWMULTISELECT = 512,
	OFN_CREATEPROMPT = 0x2000,
	OFN_ENABLEHOOK = 32,
	OFN_ENABLESIZING = 0x800000,
	OFN_ENABLETEMPLATE = 64,
	OFN_ENABLETEMPLATEHANDLE = 128,
	OFN_EXPLORER = 0x80000,
	OFN_EXTENSIONDIFFERENT = 0x400,
	OFN_FILEMUSTEXIST = 0x1000,
	OFN_HIDEREADONLY = 4,
	OFN_LONGNAMES = 0x200000,
	OFN_NOCHANGEDIR = 8,
	OFN_NODEREFERENCELINKS = 0x100000,
	OFN_NOLONGNAMES = 0x40000,
	OFN_NONETWORKBUTTON = 0x20000,
	OFN_NOREADONLYRETURN = 0x8000,
	OFN_NOTESTFILECREATE = 0x10000,
	OFN_NOVALIDATE = 256,
	OFN_OVERWRITEPROMPT = 2,
	OFN_PATHMUSTEXIST = 0x800,
	OFN_READONLY = 1,
	OFN_SHAREAWARE = 0x4000,
	OFN_SHOWHELP = 16,
	OFN_SHAREFALLTHROUGH = 2,
	OFN_SHARENOWARN = 1,
	OFN_SHAREWARN = 0,
}

const FR_DIALOGTERM=64;
const FR_DOWN=1;
const FR_ENABLEHOOK=256;
const FR_ENABLETEMPLATE=512;
const FR_ENABLETEMPLATEHANDLE=0x2000;
const FR_FINDNEXT=8;
const FR_HIDEUPDOWN=0x4000;
const FR_HIDEMATCHCASE=0x8000;
const FR_HIDEWHOLEWORD=0x10000;
const FR_MATCHALEFHAMZA=0x80000000;
const FR_MATCHCASE=4;
const FR_MATCHDIAC=0x20000000;
const FR_MATCHKASHIDA=0x40000000;
const FR_NOMATCHCASE=0x800;
const FR_NOUPDOWN=0x400;
const FR_NOWHOLEWORD=4096;
const FR_REPLACE=16;
const FR_REPLACEALL=32;
const FR_SHOWHELP=128;
const FR_WHOLEWORD=2;

const PD_ALLPAGES=0;
const PD_SELECTION=1;
const PD_PAGENUMS=2;
const PD_NOSELECTION=4;
const PD_NOPAGENUMS=8;
const PD_COLLATE=16;
const PD_PRINTTOFILE=32;
const PD_PRINTSETUP=64;
const PD_NOWARNING=128;
const PD_RETURNDC=256;
const PD_RETURNIC=512;
const PD_RETURNDEFAULT=1024;
const PD_SHOWHELP=2048;
const PD_ENABLEPRINTHOOK=4096;
const PD_ENABLESETUPHOOK=8192;
const PD_ENABLEPRINTTEMPLATE=16384;
const PD_ENABLESETUPTEMPLATE=32768;
const PD_ENABLEPRINTTEMPLATEHANDLE=65536;
const PD_ENABLESETUPTEMPLATEHANDLE=0x20000;
const PD_USEDEVMODECOPIES=0x40000;
const PD_USEDEVMODECOPIESANDCOLLATE=0x40000;
const PD_DISABLEPRINTTOFILE=0x80000;
const PD_HIDEPRINTTOFILE=0x100000;
const PD_NONETWORKBUTTON=0x200000;

const PSD_DEFAULTMINMARGINS=0;
const PSD_INWININIINTLMEASURE=0;
const PSD_MINMARGINS=1;
const PSD_MARGINS=2;
const PSD_INTHOUSANDTHSOFINCHES=4;
const PSD_INHUNDREDTHSOFMILLIMETERS=8;
const PSD_DISABLEMARGINS=16;
const PSD_DISABLEPRINTER=32;
const PSD_NOWARNING=128;
const PSD_DISABLEORIENTATION=256;
const PSD_DISABLEPAPER=512;
const PSD_RETURNDEFAULT=1024;
const PSD_SHOWHELP=2048;
const PSD_ENABLEPAGESETUPHOOK=8192;
const PSD_ENABLEPAGESETUPTEMPLATE=0x8000;
const PSD_ENABLEPAGESETUPTEMPLATEHANDLE=0x20000;
const PSD_ENABLEPAGEPAINTHOOK=0x40000;
const PSD_DISABLEPAGEPAINTING=0x80000;

const WM_PSD_PAGESETUPDLG   = WM_USER;
const WM_PSD_FULLPAGERECT   = WM_USER+1;
const WM_PSD_MINMARGINRECT  = WM_USER+2;
const WM_PSD_MARGINRECT     = WM_USER+3;
const WM_PSD_GREEKTEXTRECT  = WM_USER+4;
const WM_PSD_ENVSTAMPRECT   = WM_USER+5;
const WM_PSD_YAFULLPAGERECT = WM_USER+6;

const CD_LBSELNOITEMS = -1;
const CD_LBSELCHANGE  = 0;
const CD_LBSELSUB     = 1;
const CD_LBSELADD     = 2;

const DN_DEFAULTPRN=1;

/+
// Both MinGW and the windows docs indicate that there are macros for the send messages
// the controls. These seem to be totally unnecessary -- and at least one of MinGW or
// Windows Docs is buggy!

int CommDlg_OpenSave_GetSpec(HWND hWndControl, LPARAM lparam, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_GETSPEC, wParam, lParam);
}

int CommDlg_OpenSave_GetFilePath(HWND hWndControl, LPARAM lparam, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_GETFILEPATH, wParam, lParam);
}

int CommDlg_OpenSave_GetFolderPath(HWND hWndControl, LPARAM lparam, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_GETFOLDERPATH, wParam, lParam);
}

int CommDlg_OpenSave_GetFolderIDList(HWND hWndControl, LPARAM lparam, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_GETFOLDERIDLIST, wParam, lParam);
}

void CommDlg_OpenSave_SetControlText(HWND hWndControl, LPARAM lparam, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_SETCONTROLTEXT, wParam, lParam);
}

void CommDlg_OpenSave_HideControl(HWND hWndControl, WPARAM wParam) {
	return SendMessage(hWndControl, CDM_HIDECONTROL, wParam, 0);
}

void CommDlg_OpenSave_SetDefExt(HWND hWndControl, TCHAR* lparam) {
	return SendMessage(hWndControl, CDM_SETCONTROLTEXT, 0, cast(LPARAM)lParam);
}

// These aliases seem even more unnecessary
alias CommDlg_OpenSave_GetSpec
	CommDlg_OpenSave_GetSpecA, CommDlg_OpenSave_GetSpecW;
alias CommDlg_OpenSave_GetFilePath
	CommDlg_OpenSave_GetFilePathA, CommDlg_OpenSave_GetFilePathW;
alias CommDlg_OpenSave_GetFolderPath
	CommDlg_OpenSave_GetFolderPathA, CommDlg_OpenSave_GetFolderPathW;
+/

// Callbacks.
extern(Windows) {
alias UINT function (HWND,UINT,WPARAM,LPARAM)
	LPCCHOOKPROC, LPCFHOOKPROC, LPFRHOOKPROC, LPOFNHOOKPROC,
	LPPAGEPAINTHOOK, LPPAGESETUPHOOK, LPSETUPHOOKPROC, LPPRINTHOOKPROC;
}

align (1):

struct CHOOSECOLORA {
	DWORD        lStructSize;
	HWND         hwndOwner;
	HWND         hInstance;
	COLORREF     rgbResult;
	COLORREF*    lpCustColors;
	DWORD        Flags;
	LPARAM       lCustData;
	LPCCHOOKPROC lpfnHook;
	LPCSTR       lpTemplateName;
}
alias CHOOSECOLORA* LPCHOOSECOLORA;

struct CHOOSECOLORW {
	DWORD        lStructSize;
	HWND         hwndOwner;
	HWND         hInstance;
	COLORREF     rgbResult;
	COLORREF*    lpCustColors;
	DWORD        Flags;
	LPARAM       lCustData;
	LPCCHOOKPROC lpfnHook;
	LPCWSTR      lpTemplateName;
}
alias CHOOSECOLORW* LPCHOOSECOLORW;

struct CHOOSEFONTA {
	DWORD        lStructSize;
	HWND         hwndOwner;
	HDC          hDC;
	LPLOGFONTA   lpLogFont;
	INT          iPointSize;
	DWORD        Flags;
	DWORD        rgbColors;
	LPARAM       lCustData;
	LPCFHOOKPROC lpfnHook;
	LPCSTR       lpTemplateName;
	HINSTANCE    hInstance;
	LPSTR        lpszStyle;
	WORD         nFontType;
	WORD         ___MISSING_ALIGNMENT__;
	INT          nSizeMin;
	INT          nSizeMax;
}
alias CHOOSEFONTA* LPCHOOSEFONTA;

struct CHOOSEFONTW {
	DWORD        lStructSize;
	HWND         hwndOwner;
	HDC          hDC;
	LPLOGFONTW   lpLogFont;
	INT          iPointSize;
	DWORD        Flags;
	DWORD        rgbColors;
	LPARAM       lCustData;
	LPCFHOOKPROC lpfnHook;
	LPCWSTR      lpTemplateName;
	HINSTANCE    hInstance;
	LPWSTR       lpszStyle;
	WORD         nFontType;
	WORD         ___MISSING_ALIGNMENT__;
	INT          nSizeMin;
	INT          nSizeMax;
}
alias CHOOSEFONTW* LPCHOOSEFONTW;

struct DEVNAMES {
	WORD wDriverOffset;
	WORD wDeviceOffset;
	WORD wOutputOffset;
	WORD wDefault;
}
alias DEVNAMES* LPDEVNAMES;

struct FINDREPLACEA {
	DWORD lStructSize;
	HWND hwndOwner;
	HINSTANCE hInstance;
	DWORD Flags;
	LPSTR lpstrFindWhat;
	LPSTR lpstrReplaceWith;
	WORD wFindWhatLen;
	WORD wReplaceWithLen;
	LPARAM lCustData;
	LPFRHOOKPROC lpfnHook;
	LPCSTR lpTemplateName;
}
alias FINDREPLACEA* LPFINDREPLACEA;

struct FINDREPLACEW {
	DWORD lStructSize;
	HWND hwndOwner;
	HINSTANCE hInstance;
	DWORD Flags;
	LPWSTR lpstrFindWhat;
	LPWSTR lpstrReplaceWith;
	WORD wFindWhatLen;
	WORD wReplaceWithLen;
	LPARAM lCustData;
	LPFRHOOKPROC lpfnHook;
	LPCWSTR lpTemplateName;
}
alias FINDREPLACEW* LPFINDREPLACEW;

struct OPENFILENAMEA {
	DWORD lStructSize;
	HWND hwndOwner;
	HINSTANCE hInstance;
	LPCSTR lpstrFilter;
	LPSTR lpstrCustomFilter;
	DWORD nMaxCustFilter;
	DWORD nFilterIndex;
	LPSTR lpstrFile;
	DWORD nMaxFile;
	LPSTR lpstrFileTitle;
	DWORD nMaxFileTitle;
	LPCSTR lpstrInitialDir;
	LPCSTR lpstrTitle;
	DWORD Flags;
	WORD nFileOffset;
	WORD nFileExtension;
	LPCSTR lpstrDefExt;
	DWORD lCustData;
	LPOFNHOOKPROC lpfnHook;
	LPCSTR lpTemplateName;
}
alias OPENFILENAMEA* LPOPENFILENAMEA;

struct OPENFILENAMEW {
	DWORD lStructSize;
	HWND hwndOwner;
	HINSTANCE hInstance;
	LPCWSTR lpstrFilter;
	LPWSTR lpstrCustomFilter;
	DWORD nMaxCustFilter;
	DWORD nFilterIndex;
	LPWSTR lpstrFile;
	DWORD nMaxFile;
	LPWSTR lpstrFileTitle;
	DWORD nMaxFileTitle;
	LPCWSTR lpstrInitialDir;
	LPCWSTR lpstrTitle;
	DWORD Flags;
	WORD nFileOffset;
	WORD nFileExtension;
	LPCWSTR lpstrDefExt;
	DWORD lCustData;
	LPOFNHOOKPROC lpfnHook;
	LPCWSTR lpTemplateName;
}
alias OPENFILENAMEW* LPOPENFILENAMEW;

struct OFNOTIFYA {
	NMHDR hdr;
	LPOPENFILENAMEA lpOFN;
	LPSTR pszFile;
}
alias OFNOTIFYA* LPOFNOTIFYA;

struct OFNOTIFYW {
	NMHDR hdr;
	LPOPENFILENAMEW lpOFN;
	LPWSTR pszFile;
}
alias OFNOTIFYW* LPOFNOTIFYW;

struct PAGESETUPDLGA {
	DWORD lStructSize;
	HWND hwndOwner;
	HGLOBAL hDevMode;
	HGLOBAL hDevNames;
	DWORD Flags;
	POINT ptPaperSize;
	RECT rtMinMargin;
	RECT rtMargin;
	HINSTANCE hInstance;
	LPARAM lCustData;
	LPPAGESETUPHOOK lpfnPageSetupHook;
	LPPAGEPAINTHOOK lpfnPagePaintHook;
	LPCSTR lpPageSetupTemplateName;
	HGLOBAL hPageSetupTemplate;
}
alias PAGESETUPDLGA* LPPAGESETUPDLGA;

struct PAGESETUPDLGW {
	DWORD lStructSize;
	HWND hwndOwner;
	HGLOBAL hDevMode;
	HGLOBAL hDevNames;
	DWORD Flags;
	POINT ptPaperSize;
	RECT rtMinMargin;
	RECT rtMargin;
	HINSTANCE hInstance;
	LPARAM lCustData;
	LPPAGESETUPHOOK lpfnPageSetupHook;
	LPPAGEPAINTHOOK lpfnPagePaintHook;
	LPCWSTR lpPageSetupTemplateName;
	HGLOBAL hPageSetupTemplate;
}
alias PAGESETUPDLGW* LPPAGESETUPDLGW;

struct PRINTDLGA {
	DWORD lStructSize;
	HWND hwndOwner;
	HANDLE hDevMode;
	HANDLE hDevNames;
	HDC hDC;
	DWORD Flags;
	WORD nFromPage;
	WORD nToPage;
	WORD nMinPage;
	WORD nMaxPage;
	WORD nCopies;
	HINSTANCE hInstance;
	DWORD lCustData;
	LPPRINTHOOKPROC lpfnPrintHook;
	LPSETUPHOOKPROC lpfnSetupHook;
	LPCSTR lpPrintTemplateName;
	LPCSTR lpSetupTemplateName;
	HANDLE hPrintTemplate;
	HANDLE hSetupTemplate;
}
alias PRINTDLGA* LPPRINTDLGA;

struct PRINTDLGW {
	DWORD lStructSize;
	HWND hwndOwner;
	HANDLE hDevMode;
	HANDLE hDevNames;
	HDC hDC;
	DWORD Flags;
	WORD nFromPage;
	WORD nToPage;
	WORD nMinPage;
	WORD nMaxPage;
	WORD nCopies;
	HINSTANCE hInstance;
	DWORD lCustData;
	LPPRINTHOOKPROC lpfnPrintHook;
	LPSETUPHOOKPROC lpfnSetupHook;
	LPCWSTR lpPrintTemplateName;
	LPCWSTR lpSetupTemplateName;
	HANDLE hPrintTemplate;
	HANDLE hSetupTemplate;
}
alias PRINTDLGW* LPPRINTDLGW;

static if (WINVER >= 0x0500) {
import win32.unknwn; // for LPUNKNOWN
import win32.prsht;  // for HPROPSHEETPAGE

struct PRINTPAGERANGE {
	DWORD  nFromPage;
	DWORD  nToPage;
}
alias PRINTPAGERANGE* LPPRINTPAGERANGE;

struct PRINTDLGEXA {
	DWORD lStructSize;
	HWND hwndOwner;
	HGLOBAL hDevMode;
	HGLOBAL hDevNames;
	HDC hDC;
	DWORD Flags;
	DWORD Flags2;
	DWORD ExclusionFlags;
	DWORD nPageRanges;
	DWORD nMaxPageRanges;
	LPPRINTPAGERANGE lpPageRanges;
	DWORD nMinPage;
	DWORD nMaxPage;
	DWORD nCopies;
	HINSTANCE hInstance;
	LPCSTR lpPrintTemplateName;
	LPUNKNOWN lpCallback;
	DWORD nPropertyPages;
	HPROPSHEETPAGE* lphPropertyPages;
	DWORD nStartPage;
	DWORD dwResultAction;
}
alias PRINTDLGEXA* LPPRINTDLGEXA;

struct PRINTDLGEXW {
	DWORD lStructSize;
	HWND hwndOwner;
	HGLOBAL hDevMode;
	HGLOBAL hDevNames;
	HDC hDC;
	DWORD Flags;
	DWORD Flags2;
	DWORD ExclusionFlags;
	DWORD nPageRanges;
	DWORD nMaxPageRanges;
	LPPRINTPAGERANGE lpPageRanges;
	DWORD nMinPage;
	DWORD nMaxPage;
	DWORD nCopies;
	HINSTANCE hInstance;
	LPCWSTR lpPrintTemplateName;
	LPUNKNOWN lpCallback;
	DWORD nPropertyPages;
	HPROPSHEETPAGE* lphPropertyPages;
	DWORD nStartPage;
	DWORD dwResultAction;
}
alias PRINTDLGEXW* LPPRINTDLGEXW;

} // WINVER >= 0x0500

extern (Windows):

BOOL ChooseColorA(LPCHOOSECOLORA);
BOOL ChooseColorW(LPCHOOSECOLORW);
BOOL ChooseFontA(LPCHOOSEFONTA);
BOOL ChooseFontW(LPCHOOSEFONTW);
DWORD CommDlgExtendedError();
HWND FindTextA(LPFINDREPLACEA);
HWND FindTextW(LPFINDREPLACEW);
short GetFileTitleA(LPCSTR,LPSTR,WORD);
short GetFileTitleW(LPCWSTR,LPWSTR,WORD);
BOOL GetOpenFileNameA(LPOPENFILENAMEA);
BOOL GetOpenFileNameW(LPOPENFILENAMEW);
BOOL GetSaveFileNameA(LPOPENFILENAMEA);
BOOL GetSaveFileNameW(LPOPENFILENAMEW);
BOOL PageSetupDlgA(LPPAGESETUPDLGA);
BOOL PageSetupDlgW(LPPAGESETUPDLGW);
BOOL PrintDlgA(LPPRINTDLGA);
BOOL PrintDlgW(LPPRINTDLGW);
HWND ReplaceTextA(LPFINDREPLACEA);
HWND ReplaceTextW(LPFINDREPLACEW);

static if (WINVER >= 0x0500) {
	HRESULT PrintDlgExA(LPPRINTDLGEXA);
	HRESULT PrintDlgExW(LPPRINTDLGEXW);
}

version(Unicode) {
	alias CHOOSECOLORW CHOOSECOLOR;
	alias CHOOSEFONTW CHOOSEFONT;
	alias FINDREPLACEW FINDREPLACE;
	alias OPENFILENAMEW OPENFILENAME;
	alias OFNOTIFYW OFNOTIFY;
	alias PAGESETUPDLGW PAGESETUPDLG;
	alias PRINTDLGW PRINTDLG;

	alias ChooseColorW ChooseColor;
	alias ChooseFontW ChooseFont;
	alias FindTextW FindText;
	alias GetFileTitleW GetFileTitle;
	alias GetOpenFileNameW GetOpenFileName;
	alias GetSaveFileNameW GetSaveFileName;
	alias PageSetupDlgW PageSetupDlg;
	alias PrintDlgW PrintDlg;
	alias ReplaceTextW ReplaceText;

	static if (WINVER >= 0x0500) {
		alias PRINTDLGEXW PRINTDLGEX;
		alias PrintDlgExW PrintDlgEx;
	} // WINVER >= 0x0500

} else { // UNICODE

	alias CHOOSECOLORA CHOOSECOLOR;
	alias CHOOSEFONTA CHOOSEFONT;
	alias FINDREPLACEA FINDREPLACE;
	alias OPENFILENAMEA OPENFILENAME;
	alias OFNOTIFYA OFNOTIFY;
	alias PAGESETUPDLGA PAGESETUPDLG;
	alias PRINTDLGA PRINTDLG;

	alias ChooseColorA ChooseColor;
	alias ChooseFontA ChooseFont;
	alias FindTextA FindText;
	alias GetFileTitleA GetFileTitle;
	alias GetOpenFileNameA GetOpenFileName;
	alias GetSaveFileNameA GetSaveFileName;
	alias PageSetupDlgA PageSetupDlg;
	alias PrintDlgA PrintDlg;
	alias ReplaceTextA ReplaceText;

	static if (WINVER >= 0x0500) {
		alias PRINTDLGEXA PRINTDLGEX;
		alias PrintDlgExA PrintDlgEx;
	} // WINVER >= 0x0500

} // UNICODE

alias CHOOSECOLOR* LPCHOOSECOLOR;
alias CHOOSEFONT* LPCHOOSEFONT;
alias FINDREPLACE* LPFINDREPLACE;
alias OPENFILENAME* LPOPENFILENAME;
alias OFNOTIFY* LPOFNOTIFY;
alias PAGESETUPDLG* LPPAGESETUPDLG;
alias PRINTDLG* LPPRINTDLG;
static if (WINVER >= 0x0500) {
	alias PRINTDLGEX* LPPRINTDLGEX;
}

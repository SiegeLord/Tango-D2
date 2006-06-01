/***********************************************************************\
*                                windef.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.windef;

import win32.winnt;
private import win32.w32api;

const size_t MAX_PATH = 260;

ushort MAKEWORD(ubyte a, ubyte b) {
	return (cast(ushort) b << 8) | a;
}

uint MAKELONG(ushort a, ushort b) {
	return (cast(uint) b << 16) | a;
}

ushort LOWORD(uint l) {
	return cast(ushort) l;
}

ushort HIWORD(uint l) {
	return cast(ushort) (l >>> 16);
}

ubyte LOBYTE(ushort w) {
	return cast(ubyte) w;
}

ubyte HIBYTE(ushort w) {
	return cast(ubyte) (w >>> 8);
}

template max(T) {
	T max(T a, T b) {
		return a > b ? a : b;
	}
}

template min(T) {
	T min(T a, T b) {
		return a < b ? a : b;
	}
}

alias ushort USHORT;
alias USHORT* PUSHORT;
alias uint ULONG;
alias ULONG* PULONG;

alias ushort WORD, ATOM;
alias ushort* PWORD, LPWORD;
alias ubyte BYTE;
alias ubyte* PBYTE, LPBYTE;
alias uint DWORD, UINT, COLORREF;
alias uint* PDWORD, LPDWORD, PUINT, LPUINT;
alias int WINBOOL, BOOL, INT, LONG, HFILE;
alias int* PWINBOOL, LPWINBOOL, PBOOL, LPBOOL, PINT, LPINT, LPLONG;
alias float FLOAT;
alias float* PFLOAT;
alias void* PCVOID, LPCVOID;

alias UINT_PTR WPARAM;
alias LONG_PTR LPARAM, LRESULT;

alias LONG HRESULT;

alias HANDLE HGLOBAL, HLOCAL, GLOBALHANDLE, LOCALHANDLE, HGDIOBJ, HACCEL,
  HBITMAP, HBRUSH, HCOLORSPACE, HDC, HGLRC, HDESK, HENHMETAFILE, HFONT,
  HICON, HKEY, HMENU, HMETAFILE, HINSTANCE, HMODULE, HPALETTE, HPEN, HRGN,
  HRSRC, HSTR, HTASK, HWND, HWINSTA, HKL, HCURSOR;
alias HANDLE* PHKEY;

static if (WINVER >= 0x410) {
	alias HANDLE HMONITOR;
}

static if (WINVER >= 0x500) {
	alias HANDLE HTERMINAL, HWINEVENTHOOK;
}

alias extern (Windows) int function() FARPROC, NEARPROC, PROC;

struct RECT {
	LONG left;
	LONG top;
	LONG right;
	LONG bottom;
}
alias RECT RECTL;
alias RECT* PRECT, LPRECT, LPCRECT, PRECTL, LPRECTL, LPCRECTL;

struct POINT {
	LONG x;
	LONG y;
}
alias POINT POINTL;
alias POINT* PPOINT, LPPOINT, PPOINTL, LPPOINTL;

struct SIZE {
	LONG cx;
	LONG cy;
}
alias SIZE SIZEL;
alias SIZE* PSIZE, LPSIZE, PSIZEL, LPSIZEL;

struct POINTS {
	SHORT x;
	SHORT y;
}
alias POINTS* PPOINTS, LPPOINTS;

enum : BOOL {
	FALSE = 0,
	TRUE = 1,
}

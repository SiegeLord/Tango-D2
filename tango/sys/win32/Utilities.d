module tango.sys.win32.Utilities;

/*
 	Module:		Windows Utilities
 	Author: 	Trevor Parscal
*/

/+ Imports +/
private
{
	import tango.sys.win32.Types;
	import tango.sys.win32.Common;
}

/+ Types +/
alias void VOID;
alias ubyte BYTE;
alias short INT16;
alias ushort WORD;
alias ushort UINT16;
alias int INT_PTR;
alias uint UINT_PTR;
alias int LONG_PTR;
alias uint ULONG_PTR;
alias uint PROPID;
const BOOL FALSE = 0;
const BOOL TRUE = -1;
alias char* PANSICHAR;
alias wchar* PWIDECHAR;

/+ Functions +/
ushort MAKEWORD(ubyte A, ubyte B)
{
	return A | (B << 8);
}
uint MAKELONG(ushort A, ushort B)
{
	return A | (B << 16);
}
ushort HIWORD(uint L)
{
	return L >> 16;
}
ushort LOWORD(uint L)
{
	return L & 0xFFFF;
}
ubyte HIBYTE(ushort W)
{
	return W >> 8;
}
ubyte LOBYTE(ushort W)
{
	return W & 0xFF;
}
HANDLE GlobalDiscard(HANDLE h)
{
	return GlobalReAlloc(h, 0, GMEM_MOVEABLE);
}
HANDLE LocalDiscard(HANDLE h)
{
	return LocalReAlloc(h, 0, LMEM_MOVEABLE);
}
BOOL SUCCEEDED(HRESULT Status)
{
	return (cast(int)Status & 0x80000000) == 0;
}
BOOL FAILED(HRESULT Status)
{
	return (cast(int)Status & 0x80000000) != 0;
}
BOOL IS_ERROR(HRESULT Status)
{
	return (cast(int)Status >> 31) == SEVERITY_ERROR;
}
int HRESULT_CODE(HRESULT hr)
{
	return cast(int)hr & 0xFFFF;
}
int HRESULT_FACILITY(HRESULT hr)
{
	return (cast(int)hr >> 16) & 0x1FFF;
}
int HRESULT_SEVERITY(HRESULT hr)
{
	return (cast(int)hr >> 31) & 0x1;
}
HRESULT MAKE_HRESULT(int sev, int fac, int code)
{
	return cast(HRESULT)((sev << 31) | (fac << 16) | code);
}
HRESULT HRESULT_FROM_WIN32(int x)
{
	return cast(HRESULT) (x ? (x & 0xFFFF) | (FACILITY_WIN32 << 16) | 0x80000000 : 0);
}
//HRESULT HRESULT_FROM_NT(int x)
//{
//	return x | FACILITY_NT_BIT;
//}
DWORD MAKEROP4(DWORD fore, DWORD back)
{
	return ((back << 8) & 0xFF000000) | fore;
}
ubyte GetKValue(COLORREF cmyk)
{
	return cmyk & 0xFF;
}
ubyte GetYValue(COLORREF cmyk)
{
	return (cmyk >> 8) & 0xFF;
}
ubyte GetMValue(COLORREF cmyk)
{
	return (cmyk >> 16) & 0xFF;
}
ubyte GetCValue(COLORREF cmyk)
{
	return (cmyk >> 24) & 0xFF;
}
COLORREF CMYK(ubyte c, ubyte m, ubyte y, ubyte k)
{
	return k | (y << 8) | (m << 16) | (c << 24);
}
COLORREF RGB(ubyte r, ubyte g, ubyte b)
{
	return r | (g << 8) | (b << 16);
}
COLORREF PALETTERGB(ubyte r, ubyte g, ubyte b)
{
	return 0x02000000 | RGB(r, g, b); 
}
COLORREF PALETTEINDEX(ushort i)
{
	return 0x01000000 | i;
}
ubyte GetRValue(COLORREF rgb)
{
	return rgb & 0xFF;
}
ubyte GetGValue(COLORREF rgb)
{
	return (rgb >> 8) & 0xFF;
}
ubyte GetBValue(COLORREF rgb)
{
	return (rgb >> 16) & 0xFF;
}
WPARAM MAKEWPARAM(ushort l, ushort h)
{
	return MAKELONG(l, h);
}
LPARAM MAKELPARAM(ushort l, ushort h)
{
	return MAKELONG(l, h);
}
LRESULT MAKELRESULT(ushort l, ushort h)
{
	return MAKELONG(l, h);
}
BOOL ExitWindows(DWORD dwReserved, UINT uReserved)
{
	return ExitWindowsEx(EWX_LOGOFF, 0);
}
HWND CreateWindowA(PCHAR b, PCHAR c, DWORD d, int e,
	int f, int g, int h, HWND i, HMENU j, HINST k, POINTER l)
{
	return CreateWindowExA(0, b, c, d, e, f, g, h, i, j, k, l);
}
HWND CreateWindowW(PWIDECHAR b, PWIDECHAR c, DWORD d, int e,
	int f, int g, int h, HWND i, HMENU j, HINST k, POINTER l)
{
	return CreateWindowExW(0, b, c, d, e, f, g, h, i, j, k, l);
}
HWND CreateDialogA(HINST a, PANSICHAR b, HWND c, DLGPROC d)
{
	return CreateDialogParamA(a, b, c, d, 0);	
}
HWND CreateDialogW(HINST a, PWIDECHAR b, HWND c, DLGPROC d)
{
	return CreateDialogParamW(a, b, c, d, 0);	
}
HWND CreateDialogIndirectA(HINST a, DLGTEMPLATE* b, HWND c, DLGPROC d)
{
	return CreateDialogIndirectParamA(a, b, c, d, 0);
}
HWND CreateDialogIndirectW(HINST a, DLGTEMPLATE* b, HWND c, DLGPROC d)
{
	return CreateDialogIndirectParamW(a, b, c, d, 0);
}
int DialogBoxA(HINST a, PANSICHAR b, HWND c, DLGPROC d)
{
	return DialogBoxParamA(a, b, c, d, 0);
}
int DialogBoxW(HINST a, PWIDECHAR b, HWND c, DLGPROC d)
{
	return DialogBoxParamW(a, b, c, d, 0);
}
int DialogBoxIndirectA(HINST a, DLGTEMPLATE* b, HWND c, DLGPROC d)
{
	return DialogBoxIndirectParamA(a, b, c, d, 0);
}
int DialogBoxIndirectW(HINST a, DLGTEMPLATE* b, HWND c, DLGPROC d)
{
	return DialogBoxIndirectParamW(a, b, c, d, 0);
}
extern(C)
{
	void* memset(void*, int, uint);
	void* memmove(void*, void*, uint);
	void* memcpy(void*, void*, uint);
}
void ZeroMemory(void* dest, uint len)
{
	memset(dest, 0, len);
}
void FillMemory(void* dest, uint len, ubyte c)
{
	memset(dest, c, len);
}
void MoveMemory(void* dest, void* src, uint len)
{
	memmove(dest, src, len);
}
void CopyMemory(void* dest, void* src, uint len)
{
	memcpy(dest, src, len);
}

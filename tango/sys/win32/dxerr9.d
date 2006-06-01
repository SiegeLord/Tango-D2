module win32.dxerr9;

/*
	dxerr9.h - Header file for the DirectX 9 Error API

	Written by Filip Navara <xnavara@volny.cz>
	Ported to D by James Pelcis <jpelcis@gmail.com>

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/

private import win32.windef;

extern (Windows) {
	char* DXGetErrorString9A (HRESULT);
	WCHAR* DXGetErrorString9W (HRESULT);
	char* DXGetErrorDescription9A (HRESULT);
	WCHAR* DXGetErrorDescription9W (HRESULT);
	HRESULT DXTraceA (char*, DWORD, HRESULT, char*, BOOL);
	HRESULT DXTraceW (char*, DWORD, HRESULT, WCHAR*, BOOL);
}

version (Unicode) {
	alias DXGetErrorString9W DXGetErrorString9;
	alias DXGetErrorDescription9W DXGetErrorDescription9;
	alias DXTraceW DXTrace;
} else {
	alias DXGetErrorString9A DXGetErrorString9;
	alias DXGetErrorDescription9A DXGetErrorDescription9;
	alias DXTraceA DXTrace;
}

debug (dxerr) {
	version (Unicode) {
		HRESULT DXTRACE_MSG (WCHAR* str) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, 0, str, FALSE);
		}

		HRESULT DXTRACE_ERR (WCHAR* str, HRESULT hr) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, hr, str, FALSE);
		}

		HRESULT DXTRACE_ERR_NOMSGBOX (WCHAR* str, HRESULT hr) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, hr, str, TRUE);
		}
	} else {
		HRESULT DXTRACE_MSG (char* str) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, 0, str, FALSE);
		}

		HRESULT DXTRACE_ERR (char* str, HRESULT hr) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, hr, str, FALSE);
		}

		HRESULT DXTRACE_ERR_NOMSGBOX (char* str, HRESULT hr) {
			return DXTrace(__FILE__, cast(DWORD)__LINE__, hr, str, TRUE);
		}
	}
} else {
	version (Unicode) {
		HRESULT DXTRACE_MSG (WCHAR* str) {
			return 0;
		}

		HRESULT DXTRACE_ERR (WCHAR* str, HRESULT hr) {
			return hr;
		}

		HRESULT DXTRACE_ERR_NOMSGBOX (WCHAR* str, HRESULT hr) {
			return hr;
		}
	} else {
		HRESULT DXTRACE_MSG (char* str) {
			return 0;
		}

		HRESULT DXTRACE_ERR (char* str, HRESULT hr) {
			return hr;
		}

		HRESULT DXTRACE_ERR_NOMSGBOX (char* str, HRESULT hr) {
			return hr;
		}
	}
}

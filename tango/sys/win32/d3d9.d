/***********************************************************************\
*                                 d3d9.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.d3d9;

import win32.objbase;
import win32.d3d9types;
import win32.d3d9caps;
private import win32.wingdi;

// FIXME: check types and gropuing of some constants
// FIXME: check Windows version support

const D3D_SDK_VERSION = 31;

const D3DCREATE_FPU_PRESERVE              = 0x02;
const D3DCREATE_MULTITHREADED             = 0x04;
const D3DCREATE_PUREDEVICE                = 0x10;
const D3DCREATE_SOFTWARE_VERTEXPROCESSING = 0x20;
const D3DCREATE_HARDWARE_VERTEXPROCESSING = 0x40;
const D3DCREATE_MIXED_VERTEXPROCESSING    = 0x80;

const D3DSPD_IUNKNOWN = 1;

enum {
	D3DSGR_NO_CALIBRATION,
	D3DSGR_CALIBRATE
}

HRESULT MAKE_D3DHRESULT(uint code) { return MAKE_HRESULT(1, 0x876, code); }
HRESULT MAKE_D3DSTATUS(uint code)  { return MAKE_HRESULT(0, 0x876, code); }

enum : HRESULT {
	D3D_OK                           = 0,
	D3DOK_NOAUTOGEN                  = 0x0876086F, // = MAKE_D3DSTATUS(2159)
	D3DERR_OUTOFVIDEOMEMORY          = 0x8876017C, // = MAKE_D3DHRESULT(380)
	D3DERR_WASSTILLDRAWING           = 0x8876021C, // = MAKE_D3DHRESULT(540)
	D3DERR_WRONGTEXTUREFORMAT        = 0x88760818, // = MAKE_D3DHRESULT(2072)
	D3DERR_UNSUPPORTEDCOLOROPERATION,
	D3DERR_UNSUPPORTEDCOLORARG,
	D3DERR_UNSUPPORTEDALPHAOPERATION,
	D3DERR_UNSUPPORTEDALPHAARG,
	D3DERR_TOOMANYOPERATIONS,
	D3DERR_CONFLICTINGTEXTUREFILTER,
	D3DERR_UNSUPPORTEDFACTORVALUE,                 // = MAKE_D3DHRESULT(2079)
	D3DERR_CONFLICTINGRENDERSTATE    = 0x88760818, // = MAKE_D3DHRESULT(2081)
	D3DERR_UNSUPPORTEDTEXTUREFILTER,               // = MAKE_D3DHRESULT(2082)
	D3DERR_CONFLICTINGTEXTUREPALETTE = 0x88760826, // = MAKE_D3DHRESULT(2086)
	D3DERR_DRIVERINTERNALERROR,                    // = MAKE_D3DHRESULT(2087)
	D3DERR_NOTFOUND                  = 0x88760866, // = MAKE_D3DHRESULT(2150)
	D3DERR_MOREDATA,
	D3DERR_DEVICELOST,
	D3DERR_DEVICENOTRESET,
	D3DERR_NOTAVAILABLE,
	D3DERR_INVALIDDEVICE,
	D3DERR_INVALIDCALL,
	D3DERR_DRIVERINVALIDCALL                       // = MAKE_D3DHRESULT(2157)
}

const D3DADAPTER_DEFAULT                 = 0;
const D3DCURSOR_IMMEDIATE_UPDATE         = 1;
const D3DENUM_HOST_ADAPTER               = 1;
const D3DPRESENTFLAG_LOCKABLE_BACKBUFFER = 1;
const D3DPV_DONOTCOPYDATA                = 1;
const D3DENUM_NO_WHQL_LEVEL              = 2;
const D3DPRESENT_BACK_BUFFERS_MAX        = 3;
const VALID_D3DENUM_FLAGS                = 3;
const D3DMAXNUMPRIMITIVES                = 0xFFFF;
const D3DMAXNUMVERTICES                  = 0xFFFF;
const D3DCURRENT_DISPLAY_MODE            = 0xEFFFFF;

extern (C) const GUID
	IID_IDirect3D9,
	IID_IDirect3DDevice9,
	IID_IDirect3DVolume9,
	IID_IDirect3DSwapChain9,
	IID_IDirect3DResource9,
	IID_IDirect3DSurface9,
	IID_IDirect3DVertexBuffer9,
	IID_IDirect3DIndexBuffer9,
	IID_IDirect3DBaseTexture9,
	IID_IDirect3DCubeTexture9,
	IID_IDirect3DTexture9,
	IID_IDirect3DVolumeTexture9,
	IID_IDirect3DVertexDeclaration9,
	IID_IDirect3DVertexShader9,
	IID_IDirect3DPixelShader9,
	IID_IDirect3DStateBlock9,
	IID_IDirect3DQuery9;

interface IDirect3D9 : IUnknown {
	HRESULT RegisterSoftwareDevice(void* pInitializeFunction);
	UINT GetAdapterCount();
	HRESULT GetAdapterIdentifier(UINT, DWORD, D3DADAPTER_IDENTIFIER9*);
	UINT GetAdapterModeCount(UINT, D3DFORMAT);
	HRESULT EnumAdapterModes(UINT, D3DFORMAT, UINT, D3DDISPLAYMODE*);
	HRESULT GetAdapterDisplayMode(UINT, D3DDISPLAYMODE*);
	HRESULT CheckDeviceType(UINT, D3DDEVTYPE, D3DFORMAT, D3DFORMAT, BOOL);
	HRESULT CheckDeviceFormat(UINT, D3DDEVTYPE, D3DFORMAT, DWORD,
	  D3DRESOURCETYPE, D3DFORMAT);
	HRESULT CheckDeviceMultiSampleType(UINT, D3DDEVTYPE, D3DFORMAT, BOOL,
	  D3DMULTISAMPLE_TYPE, DWORD*);
	HRESULT CheckDepthStencilMatch(UINT, D3DDEVTYPE, D3DFORMAT, D3DFORMAT,
	  D3DFORMAT);
	HRESULT CheckDeviceFormatConversion(UINT, D3DDEVTYPE, D3DFORMAT,
	  D3DFORMAT);
	HRESULT GetDeviceCaps(UINT, D3DDEVTYPE, D3DCAPS9*);
	HANDLE GetAdapterMonitor(UINT); // originally HMONITOR
	HRESULT CreateDevice(UINT, D3DDEVTYPE, HWND, DWORD,
	  D3DPRESENT_PARAMETERS*, IDirect3DDevice9**);
}
alias IDirect3D9* LPDIRECT3D9, PDIRECT3D9;

interface IDirect3DDevice9 : IUnknown {
	HRESULT TestCooperativeLevel();
	UINT GetAvailableTextureMem();
	HRESULT EvictManagedResources();
	HRESULT GetDirect3D(IDirect3D9**);
	HRESULT GetDeviceCaps(D3DCAPS9*);
	HRESULT GetDisplayMode(UINT, D3DDISPLAYMODE*);
	HRESULT GetCreationParameters(D3DDEVICE_CREATION_PARAMETERS*);
	HRESULT SetCursorProperties(UINT, UINT, IDirect3DSurface9*);
	void SetCursorPosition(int, int, DWORD);
	BOOL ShowCursor(BOOL);
	HRESULT CreateAdditionalSwapChain(D3DPRESENT_PARAMETERS*,
	  IDirect3DSwapChain9**);
	HRESULT GetSwapChain(UINT, IDirect3DSwapChain9**);
	UINT GetNumberOfSwapChains();
	HRESULT Reset(D3DPRESENT_PARAMETERS*);
	HRESULT Present(RECT*, RECT*, HWND, RGNDATA*);
	HRESULT GetBackBuffer(UINT, UINT, D3DBACKBUFFER_TYPE, IDirect3DSurface9**);
	HRESULT GetRasterStatus(UINT, D3DRASTER_STATUS*);
	HRESULT SetDialogBoxMode(BOOL);
	void SetGammaRamp(UINT, DWORD, D3DGAMMARAMP*);
	void GetGammaRamp(UINT, D3DGAMMARAMP*);
	HRESULT CreateTexture(UINT, UINT, UINT, DWORD, D3DFORMAT, D3DPOOL,
	  IDirect3DTexture9**, HANDLE*);
	HRESULT CreateVolumeTexture(UINT, UINT, UINT, UINT, DWORD, D3DFORMAT,
	  D3DPOOL, IDirect3DVolumeTexture9**, HANDLE*);
	HRESULT CreateCubeTexture(UINT, UINT, DWORD, D3DFORMAT, D3DPOOL,
	  IDirect3DCubeTexture9**, HANDLE*);
	HRESULT CreateVertexBuffer(UINT, DWORD, DWORD, D3DPOOL,
	  IDirect3DVertexBuffer9**, HANDLE*);
	HRESULT CreateIndexBuffer(UINT, DWORD, D3DFORMAT, D3DPOOL,
	  IDirect3DIndexBuffer9**, HANDLE*);
	HRESULT CreateRenderTarget(UINT, UINT, D3DFORMAT, D3DMULTISAMPLE_TYPE,
	  DWORD, BOOL, IDirect3DSurface9**, HANDLE*);
	HRESULT CreateDepthStencilSurface(UINT, UINT, D3DFORMAT,
	  D3DMULTISAMPLE_TYPE, DWORD, BOOL, IDirect3DSurface9**, HANDLE*);
	HRESULT UpdateSurface(IDirect3DSurface9*, RECT*, IDirect3DSurface9*,
	  POINT*);
	HRESULT UpdateTexture(IDirect3DBaseTexture9*, IDirect3DBaseTexture9*);
	HRESULT GetRenderTargetData(IDirect3DSurface9*, IDirect3DSurface9*);
	HRESULT GetFrontBufferData(UINT, IDirect3DSurface9*);
	HRESULT StretchRect(IDirect3DSurface9*, RECT*, IDirect3DSurface9*, RECT*,
	  D3DTEXTUREFILTERTYPE);
	HRESULT ColorFill(IDirect3DSurface9*, RECT*, D3DCOLOR);
	HRESULT CreateOffscreenPlainSurface(UINT, UINT, D3DFORMAT, D3DPOOL,
	  IDirect3DSurface9**, HANDLE*);
	HRESULT SetRenderTarget(DWORD, IDirect3DSurface9*);
	HRESULT GetRenderTarget(DWORD, IDirect3DSurface9**);
	HRESULT SetDepthStencilSurface(IDirect3DSurface9*);
	HRESULT GetDepthStencilSurface(IDirect3DSurface9**);
	HRESULT BeginScene();
	HRESULT EndScene();
	HRESULT Clear(DWORD, D3DRECT*, DWORD, D3DCOLOR, float, DWORD);
	HRESULT SetTransform(D3DTRANSFORMSTATETYPE, D3DMATRIX*);
	HRESULT GetTransform(D3DTRANSFORMSTATETYPE, D3DMATRIX*);
	HRESULT MultiplyTransform(D3DTRANSFORMSTATETYPE, D3DMATRIX*);
	HRESULT SetViewport(D3DVIEWPORT9*);
	HRESULT GetViewport(D3DVIEWPORT9*);
	HRESULT SetMaterial(D3DMATERIAL9*);
	HRESULT GetMaterial(D3DMATERIAL9*);
	HRESULT SetLight(DWORD, D3DLIGHT9*);
	HRESULT GetLight(DWORD, D3DLIGHT9*);
	HRESULT LightEnable(DWORD, BOOL);
	HRESULT GetLightEnable(DWORD, BOOL*);
	HRESULT SetClipPlane(DWORD, float*);
	HRESULT GetClipPlane(DWORD, float*);
	HRESULT SetRenderState(D3DRENDERSTATETYPE, DWORD);
	HRESULT GetRenderState(D3DRENDERSTATETYPE, DWORD*);
	HRESULT CreateStateBlock(D3DSTATEBLOCKTYPE, IDirect3DStateBlock9**);
	HRESULT BeginStateBlock();
	HRESULT EndStateBlock(IDirect3DStateBlock9**);
	HRESULT SetClipStatus(D3DCLIPSTATUS9*);
	HRESULT GetClipStatus(D3DCLIPSTATUS9*);
	HRESULT GetTexture(DWORD, IDirect3DBaseTexture9**);
	HRESULT SetTexture(DWORD, IDirect3DBaseTexture9*);
	HRESULT GetTextureStageState(DWORD, D3DTEXTURESTAGESTATETYPE, DWORD*);
	HRESULT SetTextureStageState(DWORD, D3DTEXTURESTAGESTATETYPE, DWORD);
	HRESULT GetSamplerState(DWORD, D3DSAMPLERSTATETYPE, DWORD*);
	HRESULT SetSamplerState(DWORD, D3DSAMPLERSTATETYPE, DWORD);
	HRESULT ValidateDevice(DWORD*);
	HRESULT SetPaletteEntries(UINT, PALETTEENTRY*);
	HRESULT GetPaletteEntries(UINT, PALETTEENTRY*);
	HRESULT SetCurrentTexturePalette(UINT);
	HRESULT GetCurrentTexturePalette(UINT*);
	HRESULT SetScissorRect(RECT*);
	HRESULT GetScissorRect(RECT*);
	HRESULT SetSoftwareVertexProcessing(BOOL);
	BOOL GetSoftwareVertexProcessing();
	HRESULT SetNPatchMode(float);
	float GetNPatchMode();
	HRESULT DrawPrimitive(D3DPRIMITIVETYPE, UINT, UINT);
	HRESULT DrawIndexedPrimitive(D3DPRIMITIVETYPE, INT, UINT, UINT, UINT,
	  UINT);
	HRESULT DrawPrimitiveUP(D3DPRIMITIVETYPE, UINT, void*, UINT);
	HRESULT DrawIndexedPrimitiveUP(D3DPRIMITIVETYPE, UINT, UINT, UINT,
	  void*, D3DFORMAT, void*, UINT);
	HRESULT ProcessVertices(UINT, UINT, UINT, IDirect3DVertexBuffer9*,
	  IDirect3DVertexDeclaration9*, DWORD);
	HRESULT CreateVertexDeclaration(D3DVERTEXELEMENT9*,
	  IDirect3DVertexDeclaration9**);
	HRESULT SetVertexDeclaration(IDirect3DVertexDeclaration9*);
	HRESULT GetVertexDeclaration(IDirect3DVertexDeclaration9**);
	HRESULT SetFVF(DWORD);
	HRESULT GetFVF(DWORD*);
	HRESULT CreateVertexShader(DWORD*, IDirect3DVertexShader9**);
	HRESULT SetVertexShader(IDirect3DVertexShader9*);
	HRESULT GetVertexShader(IDirect3DVertexShader9**);
	HRESULT SetVertexShaderConstantF(UINT, float*, UINT);
	HRESULT GetVertexShaderConstantF(UINT, float*, UINT);
	HRESULT SetVertexShaderConstantI(UINT, int*, UINT);
	HRESULT GetVertexShaderConstantI(UINT, int*, UINT);
	HRESULT SetVertexShaderConstantB(UINT, BOOL*, UINT);
	HRESULT GetVertexShaderConstantB(UINT, BOOL*, UINT);
	HRESULT SetStreamSource(UINT, IDirect3DVertexBuffer9*, UINT, UINT);
	HRESULT GetStreamSource(UINT, IDirect3DVertexBuffer9**, UINT*, UINT*);
	HRESULT SetStreamSourceFreq(UINT, UINT);
	HRESULT GetStreamSourceFreq(UINT, UINT*);
	HRESULT SetIndices(IDirect3DIndexBuffer9*);
	HRESULT GetIndices(IDirect3DIndexBuffer9**);
	HRESULT CreatePixelShader(DWORD*, IDirect3DPixelShader9**);
	HRESULT SetPixelShader(IDirect3DPixelShader9*);
	HRESULT GetPixelShader(IDirect3DPixelShader9**);
	HRESULT SetPixelShaderConstantF(UINT, float*, UINT);
	HRESULT GetPixelShaderConstantF(UINT, float*, UINT);
	HRESULT SetPixelShaderConstantI(UINT, int*, UINT);
	HRESULT GetPixelShaderConstantI(UINT, int*, UINT);
	HRESULT SetPixelShaderConstantB(UINT, BOOL*, UINT);
	HRESULT GetPixelShaderConstantB(UINT, BOOL*, UINT);
	HRESULT DrawRectPatch(UINT, float*, D3DRECTPATCH_INFO*);
	HRESULT DrawTriPatch(UINT, float*, D3DTRIPATCH_INFO*);
	HRESULT DeletePatch(UINT);
	HRESULT CreateQuery(D3DQUERYTYPE, IDirect3DQuery9**);
}
alias IDirect3DDevice9* LPDIRECT3DDEVICE9, PDIRECT3DDEVICE9;

interface IDirect3DVolume9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT SetPrivateData(REFGUID, void*, DWORD, DWORD);
	HRESULT GetPrivateData(REFGUID, void*, DWORD*);
	HRESULT FreePrivateData(REFGUID);
	HRESULT GetContainer(REFIID, void**);
	HRESULT GetDesc(D3DVOLUME_DESC*);
	HRESULT LockBox(D3DLOCKED_BOX*, D3DBOX*, DWORD);
	HRESULT UnlockBox();
}
alias IDirect3DVolume9* LPDIRECT3DVOLUME9, PDIRECT3DVOLUME9;

interface IDirect3DSwapChain9 : IUnknown {
	HRESULT Present(RECT*, RECT*, HWND, RGNDATA*, DWORD);
	HRESULT GetFrontBufferData(IDirect3DSurface9*);
	HRESULT GetBackBuffer(UINT, D3DBACKBUFFER_TYPE, IDirect3DSurface9**);
	HRESULT GetRasterStatus(D3DRASTER_STATUS*);
	HRESULT GetDisplayMode(D3DDISPLAYMODE*);
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT GetPresentParameters(D3DPRESENT_PARAMETERS*);
}
alias IDirect3DSwapChain9* LPDIRECT3DSWAPCHAIN9, PDIRECT3DSWAPCHAIN9;

interface IDirect3DResource9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT SetPrivateData(REFGUID, void*, DWORD, DWORD);
	HRESULT GetPrivateData(REFGUID, void*, DWORD*);
	HRESULT FreePrivateData(REFGUID);
	DWORD SetPriority(DWORD);
	DWORD GetPriority();
	void PreLoad();
	D3DRESOURCETYPE GetType();
}
alias IDirect3DResource9* LPDIRECT3DRESOURCE9, PDIRECT3DRESOURCE9;

interface IDirect3DSurface9 : IDirect3DResource9 {
	HRESULT GetContainer(REFIID, void**);
	HRESULT GetDesc(D3DSURFACE_DESC*);
	HRESULT LockRect(D3DLOCKED_RECT*, RECT*, DWORD);
	HRESULT UnlockRect();
	HRESULT GetDC(HDC*);
	HRESULT ReleaseDC(HDC);
}
alias IDirect3DSurface9* LPDIRECT3DSURFACE9, PDIRECT3DSURFACE9;

interface IDirect3DVertexBuffer9 : IDirect3DResource9 {
	HRESULT Lock(UINT, UINT, void**, DWORD);
	HRESULT Unlock();
	HRESULT GetDesc(D3DVERTEXBUFFER_DESC*);
}
alias IDirect3DVertexBuffer9* LPDIRECT3DVERTEXBUFFER9,
  PDIRECT3DVERTEXBUFFER9;

interface IDirect3DIndexBuffer9 : IDirect3DResource9 {
	HRESULT Lock(UINT, UINT, void**, DWORD);
	HRESULT Unlock();
	HRESULT GetDesc(D3DINDEXBUFFER_DESC*);
}
alias IDirect3DIndexBuffer9* LPDIRECT3DINDEXBUFFER9, PDIRECT3DINDEXBUFFER9;

interface IDirect3DBaseTexture9 : IDirect3DResource9 {
	DWORD SetLOD(DWORD);
	DWORD GetLOD();
	DWORD GetLevelCount();
	HRESULT SetAutoGenFilterType(D3DTEXTUREFILTERTYPE);
	D3DTEXTUREFILTERTYPE GetAutoGenFilterType();
	void GenerateMipSubLevels();
}
alias IDirect3DBaseTexture9* LPDIRECT3DBASETEXTURE9, PDIRECT3DBASETEXTURE9;

interface IDirect3DCubeTexture9 : IDirect3DBaseTexture9 {
	HRESULT GetLevelDesc(UINT, D3DSURFACE_DESC*);
	HRESULT GetCubeMapSurface(D3DCUBEMAP_FACES, UINT, IDirect3DSurface9**);
	HRESULT LockRect(D3DCUBEMAP_FACES, UINT, D3DLOCKED_RECT*, RECT*, DWORD);
	HRESULT UnlockRect(D3DCUBEMAP_FACES, UINT);
	HRESULT AddDirtyRect(D3DCUBEMAP_FACES, RECT*);
}
alias IDirect3DCubeTexture9* LPDIRECT3DCUBETEXTURE9, PDIRECT3DCUBETEXTURE9;

interface IDirect3DTexture9 : IDirect3DBaseTexture9 {
	HRESULT GetLevelDesc(UINT, D3DSURFACE_DESC*);
	HRESULT GetSurfaceLevel(UINT, IDirect3DSurface9**);
	HRESULT LockRect(UINT, D3DLOCKED_RECT*, RECT*, DWORD);
	HRESULT UnlockRect(UINT);
	HRESULT AddDirtyRect(RECT*);
}
alias IDirect3DTexture9* LPDIRECT3DTEXTURE9, PDIRECT3DTEXTURE9;

interface IDirect3DVolumeTexture9 : IDirect3DBaseTexture9 {
	HRESULT GetLevelDesc(UINT, D3DVOLUME_DESC*);
	HRESULT GetVolumeLevel(UINT, IDirect3DVolume9**);
	HRESULT LockBox(UINT, D3DLOCKED_BOX*, D3DBOX*, DWORD);
	HRESULT UnlockBox(UINT);
	HRESULT AddDirtyBox(D3DBOX*);
}
alias IDirect3DVolumeTexture9* LPDIRECT3DVOLUMETEXTURE9,
  PDIRECT3DVOLUMETEXTURE9;

interface IDirect3DVertexDeclaration9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT GetDeclaration(D3DVERTEXELEMENT9*, UINT*);
}
alias IDirect3DVertexDeclaration9 LPDIRECT3DVERTEXDECLARATION9,
  PDIRECT3DVERTEXDECLARATION9;

interface IDirect3DVertexShader9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT GetFunction(void*, UINT*);
}
alias IDirect3DVertexShader9* LPDIRECT3DVERTEXSHADER9,
  PDIRECT3DVERTEXSHADER9;

interface IDirect3DPixelShader9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT GetFunction(void*, UINT*);
}
alias IDirect3DPixelShader9* LPDIRECT3DPIXELSHADER9, PDIRECT3DPIXELSHADER9;

interface IDirect3DStateBlock9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	HRESULT Capture();
	HRESULT Apply();
}
alias IDirect3DStateBlock9* LPDIRECT3DSTATEBLOCK9, PDIRECT3DSTATEBLOCK9;

interface IDirect3DQuery9 : IUnknown {
	HRESULT GetDevice(IDirect3DDevice9**);
	D3DQUERYTYPE GetType();
	DWORD GetDataSize();
	HRESULT Issue(DWORD);
	HRESULT GetData(void*, DWORD, DWORD);
}
alias IDirect3DQuery9* LPDIRECT3DQUERY9, PDIRECT3DQUERY9;

extern (Windows) IDirect3D9* Direct3DCreate9(UINT SDKVersion);

/***********************************************************************\
*                               d3d9caps.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.d3d9caps;

private import win32.windef, win32.d3d9types;

// FIXME: check types of constants

enum {
	D3DCURSORCAPS_COLOR = 1,
	D3DCURSORCAPS_LOWRES
}

const D3DDEVCAPS_EXECUTESYSTEMMEMORY     = 0x00000010;
const D3DDEVCAPS_EXECUTEVIDEOMEMORY      = 0x00000020;
const D3DDEVCAPS_TLVERTEXSYSTEMMEMORY    = 0x00000040;
const D3DDEVCAPS_TLVERTEXVIDEOMEMORY     = 0x00000080;
const D3DDEVCAPS_TEXTURESYSTEMMEMORY     = 0x00000100;
const D3DDEVCAPS_TEXTUREVIDEOMEMORY      = 0x00000200;
const D3DDEVCAPS_DRAWPRIMTLVERTEX        = 0x00000400;
const D3DDEVCAPS_CANRENDERAFTERFLIP      = 0x00000800;
const D3DDEVCAPS_TEXTURENONLOCALVIDMEM   = 0x00001000;
const D3DDEVCAPS_DRAWPRIMITIVES2         = 0x00002000;
const D3DDEVCAPS_SEPARATETEXTUREMEMORIES = 0x00004000;
const D3DDEVCAPS_DRAWPRIMITIVES2EX       = 0x00008000;
const D3DDEVCAPS_HWTRANSFORMANDLIGHT     = 0x00010000;
const D3DDEVCAPS_CANBLTSYSTONONLOCAL     = 0x00020000;
const D3DDEVCAPS_HWRASTERIZATION         = 0x00080000;
const D3DDEVCAPS_PUREDEVICE              = 0x00100000;
const D3DDEVCAPS_QUINTICRTPATCHES        = 0x00200000;
const D3DDEVCAPS_RTPATCHES               = 0x00400000;
const D3DDEVCAPS_RTPATCHHANDLEZERO       = 0x00800000;
const D3DDEVCAPS_NPATCHES                = 0x01000000;

const D3DDEVCAPS2_STREAMOFFSET                       = 0x01;
const D3DDEVCAPS2_DMAPNPATCH                         = 0x02;
const D3DDEVCAPS2_ADAPTIVETESSRTPATCH                = 0x04;
const D3DDEVCAPS2_ADAPTIVETESSNPATCH                 = 0x08;
const D3DDEVCAPS2_CAN_STRETCHRECT_FROM_TEXTURES      = 0x10;
const D3DDEVCAPS2_PRESAMPLEDDMAPNPATCH               = 0x20;
const D3DDEVCAPS2_VERTEXELEMENTSCANSHARESTREAMOFFSET = 0x40;

const D3DFVFCAPS_TEXCOORDCOUNTMASK  = 0x00FFFF;
const D3DFVFCAPS_DONOTSTRIPELEMENTS = 0x080000;
const D3DFVFCAPS_PSIZE              = 0x100000;

const D3DLINECAPS_TEXTURE   = 0x01;
const D3DLINECAPS_ZTEST     = 0x02;
const D3DLINECAPS_BLEND     = 0x04;
const D3DLINECAPS_ALPHACMP  = 0x08;
const D3DLINECAPS_FOG       = 0x10;
const D3DLINECAPS_ANTIALIAS = 0x20;

const D3DPBLENDCAPS_ZERO            = 0x0001;
const D3DPBLENDCAPS_ONE             = 0x0002;
const D3DPBLENDCAPS_SRCCOLOR        = 0x0004;
const D3DPBLENDCAPS_INVSRCCOLOR     = 0x0008;
const D3DPBLENDCAPS_SRCALPHA        = 0x0010;
const D3DPBLENDCAPS_INVSRCALPHA     = 0x0020;
const D3DPBLENDCAPS_DESTALPHA       = 0x0040;
const D3DPBLENDCAPS_INVDESTALPHA    = 0x0080;
const D3DPBLENDCAPS_DESTCOLOR       = 0x0100;
const D3DPBLENDCAPS_INVDESTCOLOR    = 0x0200;
const D3DPBLENDCAPS_SRCALPHASAT     = 0x0400;
const D3DPBLENDCAPS_BOTHSRCALPHA    = 0x0800;
const D3DPBLENDCAPS_BOTHINVSRCALPHA = 0x1000;
const D3DPBLENDCAPS_BLENDFACTOR     = 0x2000;

const D3DPCMPCAPS_NEVER        = 0x01;
const D3DPCMPCAPS_LESS         = 0x02;
const D3DPCMPCAPS_EQUAL        = 0x04;
const D3DPCMPCAPS_LESSEQUAL    = 0x08;
const D3DPCMPCAPS_GREATER      = 0x10;
const D3DPCMPCAPS_NOTEQUAL     = 0x20;
const D3DPCMPCAPS_GREATEREQUAL = 0x40;
const D3DPCMPCAPS_ALWAYS       = 0x80;

const D3DPMISCCAPS_MASKZ                      = 0x000002;
const D3DPMISCCAPS_CULLNONE                   = 0x000010;
const D3DPMISCCAPS_CULLCW                     = 0x000020;
const D3DPMISCCAPS_CULLCCW                    = 0x000040;
const D3DPMISCCAPS_COLORWRITEENABLE           = 0x000080;
const D3DPMISCCAPS_CLIPPLANESCALEDPOINTS      = 0x000100;
const D3DPMISCCAPS_CLIPTLVERTS                = 0x000200;
const D3DPMISCCAPS_TSSARGTEMP                 = 0x000400;
const D3DPMISCCAPS_BLENDOP                    = 0x000800;
const D3DPMISCCAPS_NULLREFERENCE              = 0x001000;
const D3DPMISCCAPS_INDEPENDENTWRITEMASKS      = 0x004000;
const D3DPMISCCAPS_PERSTAGECONSTANT           = 0x008000;
const D3DPMISCCAPS_FOGANDSPECULARALPHA        = 0x010000;
const D3DPMISCCAPS_SEPARATEALPHABLEND         = 0x020000;
const D3DPMISCCAPS_MRTINDEPENDENTBITDEPTHS    = 0x040000;
const D3DPMISCCAPS_MRTPOSTPIXELSHADERBLENDING = 0x080000;
const D3DPMISCCAPS_FOGVERTEXCLAMPED           = 0x100000;

const D3DPRASTERCAPS_DITHER              = 0x00000001;
const D3DPRASTERCAPS_ZTEST               = 0x00000010;
const D3DPRASTERCAPS_FOGVERTEX           = 0x00000080;
const D3DPRASTERCAPS_FOGTABLE            = 0x00000100;
const D3DPRASTERCAPS_MIPMAPLODBIAS       = 0x00002000;
const D3DPRASTERCAPS_ZBUFFERLESSHSR      = 0x00008000;
const D3DPRASTERCAPS_FOGRANGE            = 0x00010000;
const D3DPRASTERCAPS_ANISOTROPY          = 0x00020000;
const D3DPRASTERCAPS_WBUFFER             = 0x00040000;
const D3DPRASTERCAPS_WFOG                = 0x00100000;
const D3DPRASTERCAPS_ZFOG                = 0x00200000;
const D3DPRASTERCAPS_COLORPERSPECTIVE    = 0x00400000;
const D3DPRASTERCAPS_SCISSORTEST         = 0x01000000;
const D3DPRASTERCAPS_SLOPESCALEDEPTHBIAS = 0x02000000;
const D3DPRASTERCAPS_DEPTHBIAS           = 0x04000000;
const D3DPRASTERCAPS_MULTISAMPLE_TOGGLE  = 0x08000000;

const DWORD
	D3DPRESENT_INTERVAL_DEFAULT   = 0x00000000,
	D3DPRESENT_INTERVAL_ONE       = 0x00000001,
	D3DPRESENT_INTERVAL_TWO       = 0x00000002,
	D3DPRESENT_INTERVAL_THREE     = 0x00000004,
	D3DPRESENT_INTERVAL_FOUR      = 0x00000008,
	D3DPRESENT_INTERVAL_IMMEDIATE = 0x80000000;

const D3DPSHADECAPS_COLORGOURAUDRGB    = 0x000008;
const D3DPSHADECAPS_SPECULARGOURAUDRGB = 0x000200;
const D3DPSHADECAPS_ALPHAGOURAUDBLEND  = 0x004000;
const D3DPSHADECAPS_FOGGOURAUD         = 0x080000;

const D3DPTADDRESSCAPS_WRAP          = 0x01;
const D3DPTADDRESSCAPS_MIRROR        = 0x02;
const D3DPTADDRESSCAPS_CLAMP         = 0x04;
const D3DPTADDRESSCAPS_BORDER        = 0x08;
const D3DPTADDRESSCAPS_INDEPENDENTUV = 0x10;
const D3DPTADDRESSCAPS_MIRRORONCE    = 0x20;

const D3DPTEXTURECAPS_PERSPECTIVE              = 0x000001;
const D3DPTEXTURECAPS_POW2                     = 0x000002;
const D3DPTEXTURECAPS_ALPHA                    = 0x000004;
const D3DPTEXTURECAPS_SQUAREONLY               = 0x000020;
const D3DPTEXTURECAPS_TEXREPEATNOTSCALEDBYSIZE = 0x000040;
const D3DPTEXTURECAPS_ALPHAPALETTE             = 0x000080;
const D3DPTEXTURECAPS_NONPOW2CONDITIONAL       = 0x000100;
const D3DPTEXTURECAPS_PROJECTED                = 0x000400;
const D3DPTEXTURECAPS_CUBEMAP                  = 0x000800;
const D3DPTEXTURECAPS_VOLUMEMAP                = 0x002000;
const D3DPTEXTURECAPS_MIPMAP                   = 0x004000;
const D3DPTEXTURECAPS_MIPVOLUMEMAP             = 0x008000;
const D3DPTEXTURECAPS_MIPCUBEMAP               = 0x010000;
const D3DPTEXTURECAPS_CUBEMAP_POW2             = 0x020000;
const D3DPTEXTURECAPS_VOLUMEMAP_POW2           = 0x040000;
const D3DPTEXTURECAPS_NOPROJECTEDBUMPENV       = 0x200000;

const D3DPTFILTERCAPS_MINFPOINT         = 0x00000100;
const D3DPTFILTERCAPS_MINFLINEAR        = 0x00000200;
const D3DPTFILTERCAPS_MINFANISOTROPIC   = 0x00000400;
const D3DPTFILTERCAPS_MINFPYRAMIDALQUAD = 0x00000800;
const D3DPTFILTERCAPS_MINFGAUSSIANQUAD  = 0x00001000;
const D3DPTFILTERCAPS_MIPFPOINT         = 0x00010000;
const D3DPTFILTERCAPS_MIPFLINEAR        = 0x00020000;
const D3DPTFILTERCAPS_MAGFPOINT         = 0x01000000;
const D3DPTFILTERCAPS_MAGFLINEAR        = 0x02000000;
const D3DPTFILTERCAPS_MAGFANISOTROPIC   = 0x04000000;
const D3DPTFILTERCAPS_MAGFPYRAMIDALQUAD = 0x08000000;
const D3DPTFILTERCAPS_MAGFGAUSSIANQUAD  = 0x10000000;

const D3DSTENCILCAPS_KEEP     = 0x0001;
const D3DSTENCILCAPS_ZERO     = 0x0002;
const D3DSTENCILCAPS_REPLACE  = 0x0004;
const D3DSTENCILCAPS_INCRSAT  = 0x0008;
const D3DSTENCILCAPS_DECRSAT  = 0x0010;
const D3DSTENCILCAPS_INVERT   = 0x0020;
const D3DSTENCILCAPS_INCR     = 0x0040;
const D3DSTENCILCAPS_DECR     = 0x0080;
const D3DSTENCILCAPS_TWOSIDED = 0x0100;

const D3DTEXOPCAPS_DISABLE                   = 0x00000001;
const D3DTEXOPCAPS_SELECTARG1                = 0x00000002;
const D3DTEXOPCAPS_SELECTARG2                = 0x00000004;
const D3DTEXOPCAPS_MODULATE                  = 0x00000008;
const D3DTEXOPCAPS_MODULATE2X                = 0x00000010;
const D3DTEXOPCAPS_MODULATE4X                = 0x00000020;
const D3DTEXOPCAPS_ADD                       = 0x00000040;
const D3DTEXOPCAPS_ADDSIGNED                 = 0x00000080;
const D3DTEXOPCAPS_ADDSIGNED2X               = 0x00000100;
const D3DTEXOPCAPS_SUBTRACT                  = 0x00000200;
const D3DTEXOPCAPS_ADDSMOOTH                 = 0x00000400;
const D3DTEXOPCAPS_BLENDDIFFUSEALPHA         = 0x00000800;
const D3DTEXOPCAPS_BLENDTEXTUREALPHA         = 0x00001000;
const D3DTEXOPCAPS_BLENDFACTORALPHA          = 0x00002000;
const D3DTEXOPCAPS_BLENDTEXTUREALPHAPM       = 0x00004000;
const D3DTEXOPCAPS_BLENDCURRENTALPHA         = 0x00008000;
const D3DTEXOPCAPS_PREMODULATE               = 0x00010000;
const D3DTEXOPCAPS_MODULATEALPHA_ADDCOLOR    = 0x00020000;
const D3DTEXOPCAPS_MODULATECOLOR_ADDALPHA    = 0x00040000;
const D3DTEXOPCAPS_MODULATEINVALPHA_ADDCOLOR = 0x00080000;
const D3DTEXOPCAPS_MODULATEINVCOLOR_ADDALPHA = 0x00100000;
const D3DTEXOPCAPS_BUMPENVMAP                = 0x00200000;
const D3DTEXOPCAPS_BUMPENVMAPLUMINANCE       = 0x00400000;
const D3DTEXOPCAPS_DOTPRODUCT3               = 0x00800000;
const D3DTEXOPCAPS_MULTIPLYADD               = 0x01000000;
const D3DTEXOPCAPS_LERP                      = 0x02000000;

const D3DVTXPCAPS_TEXGEN                   = 0x0001;
const D3DVTXPCAPS_MATERIALSOURCE7          = 0x0002;
const D3DVTXPCAPS_DIRECTIONALLIGHTS        = 0x0008;
const D3DVTXPCAPS_POSITIONALLIGHTS         = 0x0010;
const D3DVTXPCAPS_LOCALVIEWER              = 0x0020;
const D3DVTXPCAPS_TWEENING                 = 0x0040;
const D3DVTXPCAPS_TEXGEN_SPHEREMAP         = 0x0100;
const D3DVTXPCAPS_NO_TEXGEN_NONLOCALVIEWER = 0x0200;

const D3DCAPS_READ_SCANLINE = 0x20000;

const DWORD
	D3DCAPS2_FULLSCREENGAMMA   = 0x00020000,
	D3DCAPS2_CANCALIBRATEGAMMA = 0x00100000,
	D3DCAPS2_RESERVED          = 0x02000000,
	D3DCAPS2_CANMANAGERESOURCE = 0x10000000,
	D3DCAPS2_DYNAMICTEXTURES   = 0x20000000,
	D3DCAPS2_CANAUTOGENMIPMAP  = 0x40000000;

const DWORD
	D3DCAPS3_ALPHA_FULLSCREEN_FLIP_OR_DISCARD = 0x00000020,
	D3DCAPS3_LINEAR_TO_SRGB_PRESENTATION      = 0x00000080,
	D3DCAPS3_COPY_TO_VIDMEM                   = 0x00000100,
	D3DCAPS3_COPY_TO_SYSTEMMEM                = 0x00000200,
	D3DCAPS3_RESERVED                         = 0x8000001F;

const D3DDTCAPS_UBYTE4    = 0x0001;
const D3DDTCAPS_UBYTE4N   = 0x0002;
const D3DDTCAPS_SHORT2N   = 0x0004;
const D3DDTCAPS_SHORT4N   = 0x0008;
const D3DDTCAPS_USHORT2N  = 0x0010;
const D3DDTCAPS_USHORT4N  = 0x0020;
const D3DDTCAPS_UDEC3     = 0x0040;
const D3DDTCAPS_DEC3N     = 0x0080;
const D3DDTCAPS_FLOAT16_2 = 0x0100;
const D3DDTCAPS_FLOAT16_4 = 0x0200;

const D3DMIN30SHADERINSTRUCTIONS = 512;
const D3DMAX30SHADERINSTRUCTIONS = 32768;

const D3DPS20_MAX_DYNAMICFLOWCONTROLDEPTH =  24;
const D3DPS20_MIN_DYNAMICFLOWCONTROLDEPTH =   0;
const D3DPS20_MAX_NUMTEMPS                =  32;
const D3DPS20_MIN_NUMTEMPS                =  12;
const D3DPS20_MAX_STATICFLOWCONTROLDEPTH  =   4;
const D3DPS20_MIN_STATICFLOWCONTROLDEPTH  =   0;
const D3DPS20_MAX_NUMINSTRUCTIONSLOTS     = 512;
const D3DPS20_MIN_NUMINSTRUCTIONSLOTS     =  96;

const D3DPS20CAPS_ARBITRARYSWIZZLE      = 0x01;
const D3DPS20CAPS_GRADIENTINSTRUCTIONS  = 0x02;
const D3DPS20CAPS_PREDICATION           = 0x04;
const D3DPS20CAPS_NODEPENDENTREADLIMIT  = 0x08;
const D3DPS20CAPS_NOTEXINSTRUCTIONLIMIT = 0x10;

const D3DVS20_MAX_DYNAMICFLOWCONTROLDEPTH = 24;
const D3DVS20_MIN_DYNAMICFLOWCONTROLDEPTH =  0;
const D3DVS20_MAX_NUMTEMPS                = 32;
const D3DVS20_MIN_NUMTEMPS                = 12;
const D3DVS20_MAX_STATICFLOWCONTROLDEPTH  =  4;
const D3DVS20_MIN_STATICFLOWCONTROLDEPTH  =  1;
const D3DVS20CAPS_PREDICATION             =  1;

struct D3DVSHADERCAPS2_0 {
	DWORD Caps;
	INT   DynamicFlowControlDepth;
	INT   NumTemps;
	INT   StaticFlowControlDepth;
}

struct D3DPSHADERCAPS2_0 {
	DWORD Caps;
	INT   DynamicFlowControlDepth;
	INT   NumTemps;
	INT   StaticFlowControlDepth;
	INT   NumInstructionSlots;
}

struct D3DCAPS9 {
	D3DDEVTYPE        DeviceType;
	UINT              AdapterOrdinal;
	DWORD             Caps;
	DWORD             Caps2;
	DWORD             Caps3;
	DWORD             PresentationIntervals;
	DWORD             CursorCaps;
	DWORD             DevCaps;
	DWORD             PrimitiveMiscCaps;
	DWORD             RasterCaps;
	DWORD             ZCmpCaps;
	DWORD             SrcBlendCaps;
	DWORD             DestBlendCaps;
	DWORD             AlphaCmpCaps;
	DWORD             ShadeCaps;
	DWORD             TextureCaps;
	DWORD             TextureFilterCaps;
	DWORD             CubeTextureFilterCaps;
	DWORD             VolumeTextureFilterCaps;
	DWORD             TextureAddressCaps;
	DWORD             VolumeTextureAddressCaps;
	DWORD             LineCaps;
	DWORD             MaxTextureWidth;
	DWORD             MaxTextureHeight;
	DWORD             MaxVolumeExtent;
	DWORD             MaxTextureRepeat;
	DWORD             MaxTextureAspectRatio;
	DWORD             MaxAnisotropy;
	float             MaxVertexW;
	float             GuardBandLeft;
	float             GuardBandTop;
	float             GuardBandRight;
	float             GuardBandBottom;
	float             ExtentsAdjust;
	DWORD             StencilCaps;
	DWORD             FVFCaps;
	DWORD             TextureOpCaps;
	DWORD             MaxTextureBlendStages;
	DWORD             MaxSimultaneousTextures;
	DWORD             VertexProcessingCaps;
	DWORD             MaxActiveLights;
	DWORD             MaxUserClipPlanes;
	DWORD             MaxVertexBlendMatrices;
	DWORD             MaxVertexBlendMatrixIndex;
	float             MaxPointSize;
	DWORD             MaxPrimitiveCount;
	DWORD             MaxVertexIndex;
	DWORD             MaxStreams;
	DWORD             MaxStreamStride;
	DWORD             VertexShaderVersion;
	DWORD             MaxVertexShaderConst;
	DWORD             PixelShaderVersion;
	float             PixelShader1xMaxValue;
	DWORD             DevCaps2;
	float             MaxNpatchTessellationLevel;
	DWORD             Reserved5;
	UINT              MasterAdapterOrdinal;
	UINT              AdapterOrdinalInGroup;
	UINT              NumberOfAdaptersInGroup;
	DWORD             DeclTypes;
	DWORD             NumSimultaneousRTs;
	DWORD             StretchRectFilterCaps;
	D3DVSHADERCAPS2_0 VS20Caps;
	D3DPSHADERCAPS2_0 PS20Caps;
	DWORD             VertexTextureFilterCaps;
	DWORD             MaxVShaderInstructionsExecuted;
	DWORD             MaxPShaderInstructionsExecuted;
	DWORD             MaxVertexShader30InstructionSlots;
	DWORD             MaxPixelShader30InstructionSlots;
}

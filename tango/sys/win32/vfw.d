// Converted from w32api\vfw.h
module win32.vfw;

pragma(lib, "vfw32.lib");

private import win32.windows;
private import win32.mmsystem;
private import ole2;

//MACRO #define mmioFOURCC(c0,c1,c2,c3) ((DWORD)(BYTE)(c0)|((DWORD)(BYTE)(c1)<<8)|((DWORD)(BYTE)(c2)<<16)|((DWORD)(BYTE)(c3)<<24))
//MACRO #define aviTWOCC(ch0,ch1) ((WORD)(BYTE)(ch0)|((WORD)(BYTE)(ch1)<<8))

align(8):

const ICERR_OK=0;
const ICERR_DONTDRAW=1;
const ICERR_NEWPALETTE=2;
const ICERR_GOTOKEYFRAME=3;
const ICERR_STOPDRAWING=4;
const ICERR_UNSUPPORTED=-1;
const ICERR_BADFORMAT=-2;
const ICERR_MEMORY=-3;
const ICERR_INTERNAL=-4;
const ICERR_BADFLAGS=-5;
const ICERR_BADPARAM=-6;
const ICERR_BADSIZE=-7;
const ICERR_BADHANDLE=-8;
const ICERR_CANTUPDATE=-9;
const ICERR_ABORT=-10;
const ICERR_ERROR=-100;
const ICERR_BADBITDEPTH=-200;
const ICERR_BADIMAGESIZE=-201;
const ICERR_CUSTOM=-400;
const ICCOMPRESSFRAMES_PADDING=0x01;
const ICM_USER=(DRV_USER+0x0000);
const ICM_RESERVED_LOW=(DRV_USER+0x1000);
const ICM_RESERVED_HIGH=(DRV_USER+0x2000);
const ICM_RESERVED=ICM_RESERVED_LOW;
const ICM_GETSTATE=(ICM_RESERVED+0);
const ICM_SETSTATE=(ICM_RESERVED+1);
const ICM_GETINFO=(ICM_RESERVED+2);
const ICM_CONFIGURE=(ICM_RESERVED+10);
const ICM_ABOUT=(ICM_RESERVED+11);
const ICM_GETDEFAULTQUALITY=(ICM_RESERVED+30);
const ICM_GETQUALITY=(ICM_RESERVED+31);
const ICM_SETQUALITY=(ICM_RESERVED+32);
const ICM_SET=(ICM_RESERVED+40);
const ICM_GET=(ICM_RESERVED+41);
const ICM_FRAMERATE=mmioFOURCC!('F','r','m','R');
const ICM_KEYFRAMERATE=mmioFOURCC!('K','e','y','R');
const ICM_COMPRESS_GET_FORMAT=(ICM_USER+4);
const ICM_COMPRESS_GET_SIZE=(ICM_USER+5);
const ICM_COMPRESS_QUERY=(ICM_USER+6);
const ICM_COMPRESS_BEGIN=(ICM_USER+7);
const ICM_COMPRESS=(ICM_USER+8);
const ICM_COMPRESS_END=(ICM_USER+9);
const ICM_DECOMPRESS_GET_FORMAT=(ICM_USER+10);
const ICM_DECOMPRESS_QUERY=(ICM_USER+11);
const ICM_DECOMPRESS_BEGIN=(ICM_USER+12);
const ICM_DECOMPRESS=(ICM_USER+13);
const ICM_DECOMPRESS_END=(ICM_USER+14);
const ICM_DECOMPRESS_SET_PALETTE=(ICM_USER+29);
const ICM_DECOMPRESS_GET_PALETTE=(ICM_USER+30);
const ICM_DRAW_QUERY=(ICM_USER+31);
const ICM_DRAW_BEGIN=(ICM_USER+15);
const ICM_DRAW_GET_PALETTE=(ICM_USER+16);
const ICM_DRAW_START=(ICM_USER+18);
const ICM_DRAW_STOP=(ICM_USER+19);
const ICM_DRAW_END=(ICM_USER+21);
const ICM_DRAW_GETTIME=(ICM_USER+32);
const ICM_DRAW=(ICM_USER+33);
const ICM_DRAW_WINDOW=(ICM_USER+34);
const ICM_DRAW_SETTIME=(ICM_USER+35);
const ICM_DRAW_REALIZE=(ICM_USER+36);
const ICM_DRAW_FLUSH=(ICM_USER+37);
const ICM_DRAW_RENDERBUFFER=(ICM_USER+38);
const ICM_DRAW_START_PLAY=(ICM_USER+39);
const ICM_DRAW_STOP_PLAY=(ICM_USER+40);
const ICM_DRAW_SUGGESTFORMAT=(ICM_USER+50);
const ICM_DRAW_CHANGEPALETTE=(ICM_USER+51);
const ICM_GETBUFFERSWANTED=(ICM_USER+41);
const ICM_GETDEFAULTKEYFRAMERATE=(ICM_USER+42);
const ICM_DECOMPRESSEX_BEGIN=(ICM_USER+60);
const ICM_DECOMPRESSEX_QUERY=(ICM_USER+61);
const ICM_DECOMPRESSEX=(ICM_USER+62);
const ICM_DECOMPRESSEX_END=(ICM_USER+63);
const ICM_COMPRESS_FRAMES_INFO=(ICM_USER+70);
const ICM_SET_STATUS_PROC=(ICM_USER+72);
const ICMF_CONFIGURE_QUERY=0x01;
const ICCOMPRESS_KEYFRAME=0x01;
const ICSTATUS_START=0;
const ICSTATUS_STATUS=1;
const ICSTATUS_END=2;
const ICSTATUS_ERROR=3;
const ICSTATUS_YIELD=4;
const ICMODE_COMPRESS=1;
const ICMODE_DECOMPRESS=2;
const ICMODE_FASTDECOMPRESS=3;
const ICMODE_QUERY=4;
const ICMODE_FASTCOMPRESS=5;
const ICMODE_DRAW=8;
const ICQUALITY_LOW=0;
const ICQUALITY_HIGH=10000;
const ICQUALITY_DEFAULT=-1;
const VIDCF_QUALITY=0x01;
const VIDCF_CRUNCH=0x02;
const VIDCF_TEMPORAL=0x04;
const VIDCF_COMPRESSFRAMES=0x08;
const VIDCF_DRAW=0x10;
const VIDCF_FASTTEMPORALC=0x20;
const VIDCF_FASTTEMPORALD=0x80;
const VIDCF_QUALITYTIME=0x40;
const VIDCF_FASTTEMPORAL=(VIDCF_FASTTEMPORALC|VIDCF_FASTTEMPORALD);
const ICMF_ABOUT_QUERY=0x01;
const ICDECOMPRESS_HURRYUP=0x80000000;
const ICDECOMPRESS_UPDATE=0x40000000;
const ICDECOMPRESS_PREROLL=0x20000000;
const ICDECOMPRESS_NULLFRAME=0x10000000;
const ICDECOMPRESS_NOTKEYFRAME=0x8000000;
const ICDRAW_QUERY=0x01L;
const ICDRAW_FULLSCREEN=0x02L;
const ICDRAW_HDC=0x04L;
const ICDRAW_ANIMATE=0x08L;
const ICDRAW_CONTINUE=0x10L;
const ICDRAW_MEMORYDC=0x20L;
const ICDRAW_UPDATING=0x40L;
const ICDRAW_RENDER=0x80L;
const ICDRAW_BUFFER=0x100L;
const ICINSTALL_UNICODE=0x8000;
const ICINSTALL_FUNCTION=0x01;
const ICINSTALL_DRIVER=0x02;
const ICINSTALL_HDRV=0x04;
const ICINSTALL_DRIVERW=0x8002;
const ICDRAW_HURRYUP=0x80000000L;
const ICDRAW_UPDATE=0x40000000L;
const ICDRAW_PREROLL=0x20000000L;
const ICDRAW_NULLFRAME=0x10000000L;
const ICDRAW_NOTKEYFRAME=0x8000000L;
const ICMF_COMPVARS_VALID=0x01;
const ICMF_CHOOSE_KEYFRAME=0x01;
const ICMF_CHOOSE_DATARATE=0x02;
const ICMF_CHOOSE_PREVIEW=0x04;
const ICMF_CHOOSE_ALLCOMPRESSORS=0x08;
const ICTYPE_VIDEO=mmioFOURCC!('v','i','d','c');
const ICTYPE_AUDIO=mmioFOURCC!('a','u','d','c');
const formtypeAVI=mmioFOURCC!('A','V','I',' ');
const listtypeAVIHEADER=mmioFOURCC!('h','d','r','l');
const ckidAVIMAINHDR=mmioFOURCC!('a','v','i','h');
const listtypeSTREAMHEADER=mmioFOURCC!('s','t','r','l');
const ckidSTREAMHEADER=mmioFOURCC!('s','t','r','h');
const ckidSTREAMFORMAT=mmioFOURCC!('s','t','r','f');
const ckidSTREAMHANDLERDATA=mmioFOURCC!('s','t','r','d');
const ckidSTREAMNAME=mmioFOURCC!('s','t','r','n');
const listtypeAVIMOVIE=mmioFOURCC!('m','o','v','i');
const listtypeAVIRECORD=mmioFOURCC!('r','e','c',' ');
const ckidAVINEWINDEX=mmioFOURCC!('i', 'd', 'x', '1');
const streamtypeANY=0UL;
const streamtypeVIDEO=mmioFOURCC!('v','i','d','s');
const streamtypeAUDIO=mmioFOURCC!('a','u','d','s');
const streamtypeMIDI=mmioFOURCC!('m','i','d','s');
const streamtypeTEXT=mmioFOURCC!('t','x','t','s');
const cktypeDIBbits=aviTWOCC!('d','b');
const cktypeDIBcompressed=aviTWOCC!('d','c');
const cktypePALchange=aviTWOCC!('p','c');
const cktypeWAVEbytes=aviTWOCC!('w','b');
const ckidAVIPADDING=mmioFOURCC!('J','U','N','K');
//MACRO #define FromHex(n) (((n)>='A')?((n)+10-'A'):((n)-'0'))

//MACRO #define StreamFromFOURCC(fcc) ((WORD)((FromHex(LOBYTE(LOWORD(fcc)))<<4)+(FromHex(HIBYTE(LOWORD(fcc))))))

//MACRO #define TWOCCFromFOURCC(fcc) HIWORD(fcc)

//MACRO #define ToHex(n) ((BYTE)(((n)>9)?((n)-10+'A'):((n)+'0')))

//MACRO #define MAKEAVICKID(tcc, stream) MAKELONG((ToHex((stream)&0x0f)<<8)|(ToHex(((stream)&0xf0)>>4)),tcc)

const AVIF_HASINDEX=0x10;
const AVIF_MUSTUSEINDEX=0x20;
const AVIF_ISINTERLEAVED=0x100;
const AVIF_TRUSTCKTYPE=0x800;
const AVIF_WASCAPTUREFILE=0x10000;
const AVIF_COPYRIGHTED=0x20000;
const AVI_HEADERSIZE=2048;
const AVISF_DISABLED=0x01;
const AVISF_VIDEO_PALCHANGES=0x10000;
const AVIIF_LIST=0x01;
const AVIIF_TWOCC=0x02;
const AVIIF_KEYFRAME=0x10;
const AVIIF_NOTIME=0x100;
const AVIIF_COMPUSE=0xfff0000;

const AVIGETFRAMEF_BESTDISPLAYFMT=1;
const AVISTREAMINFO_DISABLED=0x01;
const AVISTREAMINFO_FORMATCHANGES=0x10000;
const AVIFILEINFO_HASINDEX=0x10;
const AVIFILEINFO_MUSTUSEINDEX=0x20;
const AVIFILEINFO_ISINTERLEAVED=0x100;
const AVIFILEINFO_TRUSTCKTYPE=0x800;
const AVIFILEINFO_WASCAPTUREFILE=0x10000;
const AVIFILEINFO_COPYRIGHTED=0x20000;
const AVIFILECAPS_CANREAD=0x01;
const AVIFILECAPS_CANWRITE=0x02;
const AVIFILECAPS_ALLKEYFRAMES=0x10;
const AVIFILECAPS_NOCOMPRESSION=0x20;
const AVICOMPRESSF_INTERLEAVE=0x01;
const AVICOMPRESSF_DATARATE=0x02;
const AVICOMPRESSF_KEYFRAMES=0x04;
const AVICOMPRESSF_VALID=0x08;

const FIND_DIR=0x0000000fL;
const FIND_NEXT=0x00000001L;
const FIND_PREV=0x00000004L;
const FIND_FROM_START=0x00000008L;
const FIND_TYPE=0x000000f0L;
const FIND_KEY=0x00000010L;
const FIND_ANY=0x00000020L;
const FIND_FORMAT=0x00000040L;
const FIND_RET=0x0000f000L;
const FIND_POS=0x00000000L;
const FIND_LENGTH=0x00001000L;
const FIND_OFFSET=0x00002000L;
const FIND_SIZE=0x00003000L;
const FIND_INDEX=0x00004000L;
const AVIERR_OK=0;
//MACRO #define MAKE_AVIERR(e)	MAKE_SCODE(SEVERITY_ERROR,FACILITY_ITF,0x4000+e)

const AVIERR_UNSUPPORTED=MAKE_AVIERR(101);
const AVIERR_BADFORMAT=MAKE_AVIERR(102);
const AVIERR_MEMORY=MAKE_AVIERR(103);
const AVIERR_INTERNAL=MAKE_AVIERR(104);
const AVIERR_BADFLAGS=MAKE_AVIERR(105);
const AVIERR_BADPARAM=MAKE_AVIERR(106);
const AVIERR_BADSIZE=MAKE_AVIERR(107);
const AVIERR_BADHANDLE=MAKE_AVIERR(108);
const AVIERR_FILEREAD=MAKE_AVIERR(109);
const AVIERR_FILEWRITE=MAKE_AVIERR(110);
const AVIERR_FILEOPEN=MAKE_AVIERR(111);
const AVIERR_COMPRESSOR=MAKE_AVIERR(112);
const AVIERR_NOCOMPRESSOR=MAKE_AVIERR(113);
const AVIERR_READONLY=MAKE_AVIERR(114);
const AVIERR_NODATA=MAKE_AVIERR(115);
const AVIERR_BUFFERTOOSMALL=MAKE_AVIERR(116);
const AVIERR_CANTCOMPRESS=MAKE_AVIERR(117);
const AVIERR_USERABORT=MAKE_AVIERR(198);
const AVIERR_ERROR=MAKE_AVIERR(199);
const MCIWNDOPENF_NEW=0x0001;
const MCIWNDF_NOAUTOSIZEWINDOW=0x0001;
const MCIWNDF_NOPLAYBAR=0x0002;
const MCIWNDF_NOAUTOSIZEMOVIE=0x0004;
const MCIWNDF_NOMENU=0x0008;
const MCIWNDF_SHOWNAME=0x0010;
const MCIWNDF_SHOWPOS=0x0020;
const MCIWNDF_SHOWMODE=0x0040;
const MCIWNDF_SHOWALL=0x0070;
const MCIWNDF_NOTIFYMODE=0x0100;
const MCIWNDF_NOTIFYPOS=0x0200;
const MCIWNDF_NOTIFYSIZE=0x0400;
const MCIWNDF_NOTIFYERROR=0x1000;
const MCIWNDF_NOTIFYALL=0x1F00;
const MCIWNDF_NOTIFYANSI=0x0080;
const MCIWNDF_NOTIFYMEDIAA=0x0880;
const MCIWNDF_NOTIFYMEDIAW=0x0800;
const MCIWNDF_RECORD=0x2000;
const MCIWNDF_NOERRORDLG=0x4000;
const MCIWNDF_NOOPEN=0x8000;
const MCIWNDM_GETDEVICEID=(WM_USER + 100);
const MCIWNDM_GETSTART=(WM_USER + 103);
const MCIWNDM_GETLENGTH=(WM_USER + 104);
const MCIWNDM_GETEND=(WM_USER + 105);
const MCIWNDM_EJECT=(WM_USER + 107);
const MCIWNDM_SETZOOM=(WM_USER + 108);
const MCIWNDM_GETZOOM=(WM_USER + 109);
const MCIWNDM_SETVOLUME=(WM_USER + 110);
const MCIWNDM_GETVOLUME=(WM_USER + 111);
const MCIWNDM_SETSPEED=(WM_USER + 112);
const MCIWNDM_GETSPEED=(WM_USER + 113);
const MCIWNDM_SETREPEAT=(WM_USER + 114);
const MCIWNDM_GETREPEAT=(WM_USER + 115);
const MCIWNDM_REALIZE=(WM_USER + 118);
const MCIWNDM_VALIDATEMEDIA=(WM_USER + 121);
const MCIWNDM_PLAYFROM=(WM_USER + 122);
const MCIWNDM_PLAYTO=(WM_USER + 123);
const MCIWNDM_GETPALETTE=(WM_USER + 126);
const MCIWNDM_SETPALETTE=(WM_USER + 127);
const MCIWNDM_SETTIMERS=(WM_USER + 129);
const MCIWNDM_SETACTIVETIMER=(WM_USER + 130);
const MCIWNDM_SETINACTIVETIMER=(WM_USER + 131);
const MCIWNDM_GETACTIVETIMER=(WM_USER + 132);
const MCIWNDM_GETINACTIVETIMER=(WM_USER + 133);
const MCIWNDM_CHANGESTYLES=(WM_USER + 135);
const MCIWNDM_GETSTYLES=(WM_USER + 136);
const MCIWNDM_GETALIAS=(WM_USER + 137);
const MCIWNDM_PLAYREVERSE=(WM_USER + 139);
const MCIWNDM_GET_SOURCE=(WM_USER + 140);
const MCIWNDM_PUT_SOURCE=(WM_USER + 141);
const MCIWNDM_GET_DEST=(WM_USER + 142);
const MCIWNDM_PUT_DEST=(WM_USER + 143);
const MCIWNDM_CAN_PLAY=(WM_USER + 144);
const MCIWNDM_CAN_WINDOW=(WM_USER + 145);
const MCIWNDM_CAN_RECORD=(WM_USER + 146);
const MCIWNDM_CAN_SAVE=(WM_USER + 147);
const MCIWNDM_CAN_EJECT=(WM_USER + 148);
const MCIWNDM_CAN_CONFIG=(WM_USER + 149);
const MCIWNDM_PALETTEKICK=(WM_USER + 150);
const MCIWNDM_OPENINTERFACE=(WM_USER + 151);
const MCIWNDM_SETOWNER=(WM_USER + 152);
const MCIWNDM_SENDSTRINGA=(WM_USER + 101);
const MCIWNDM_GETPOSITIONA=(WM_USER + 102);
const MCIWNDM_GETMODEA=(WM_USER + 106);
const MCIWNDM_SETTIMEFORMATA=(WM_USER + 119);
const MCIWNDM_GETTIMEFORMATA=(WM_USER + 120);
const MCIWNDM_GETFILENAMEA=(WM_USER + 124);
const MCIWNDM_GETDEVICEA=(WM_USER + 125);
const MCIWNDM_GETERRORA=(WM_USER + 128);
const MCIWNDM_NEWA=(WM_USER + 134);
const MCIWNDM_RETURNSTRINGA=(WM_USER + 138);
const MCIWNDM_OPENA=(WM_USER + 153);
const MCIWNDM_SENDSTRINGW=(WM_USER + 201);
const MCIWNDM_GETPOSITIONW=(WM_USER + 202);
const MCIWNDM_GETMODEW=(WM_USER + 206);
const MCIWNDM_SETTIMEFORMATW=(WM_USER + 219);
const MCIWNDM_GETTIMEFORMATW=(WM_USER + 220);
const MCIWNDM_GETFILENAMEW=(WM_USER + 224);
const MCIWNDM_GETDEVICEW=(WM_USER + 225);
const MCIWNDM_GETERRORW=(WM_USER + 228);
const MCIWNDM_NEWW=(WM_USER + 234);
const MCIWNDM_RETURNSTRINGW=(WM_USER + 238);
const MCIWNDM_OPENW=(WM_USER + 252);
const MCIWNDM_NOTIFYMODE=(WM_USER + 200);
const MCIWNDM_NOTIFYPOS=(WM_USER + 201);
const MCIWNDM_NOTIFYSIZE=(WM_USER + 202);
const MCIWNDM_NOTIFYMEDIA=(WM_USER + 203);
const MCIWNDM_NOTIFYERROR=(WM_USER + 205);
const MCIWND_START=-1;
const MCIWND_END=-2;
const DDF_UPDATE=0x02;
const DDF_SAME_HDC=0x04;
const DDF_SAME_DRAW=0x08;
const DDF_DONTDRAW=0x10;
const DDF_ANIMATE=0x20;
const DDF_BUFFER=0x40;
const DDF_JUSTDRAWIT=0x80;
const DDF_FULLSCREEN=0x100;
const DDF_BACKGROUNDPAL=0x200;
const DDF_NOTKEYFRAME=0x400;
const DDF_HURRYUP=0x800;
const DDF_HALFTONE=0x1000;
const DDF_PREROLL=DDF_DONTDRAW;
const DDF_SAME_DIB=DDF_SAME_DRAW;
const DDF_SAME_SIZE=DDF_SAME_DRAW;
const PD_CAN_DRAW_DIB=0x01;
const PD_CAN_STRETCHDIB=0x02;
const PD_STRETCHDIB_1_1_OK=0x04;
const PD_STRETCHDIB_1_2_OK=0x08;
const PD_STRETCHDIB_1_N_OK=0x10;

alias HANDLE HIC;
alias HANDLE HDRAWDIB;
alias WORD TWOCC;

extern (Windows):
alias BOOL function (INT) AVISAVECALLBACK;
struct ICOPEN {
	DWORD dwSize;
	DWORD fccType;
	DWORD fccHandler;
	DWORD dwVersion;
	DWORD dwFlags;
	LRESULT dwError;
	LPVOID pV1Reserved;
	LPVOID pV2Reserved;
	DWORD dnDevNode;
}
alias ICOPEN* LPICOPEN;

struct ICCOMPRESS {
	DWORD dwFlags;
	LPBITMAPINFOHEADER lpbiOutput;
	LPVOID lpOutput;
	LPBITMAPINFOHEADER lpbiInput;
	LPVOID lpInput;
	LPDWORD lpckid;
	LPDWORD lpdwFlags;
	LONG lFrameNum;
	DWORD dwFrameSize;
	DWORD dwQuality;
	LPBITMAPINFOHEADER lpbiPrev;
	LPVOID lpPrev;
}

struct ICCOMPRESSFRAMES {
	DWORD dwFlags;
	LPBITMAPINFOHEADER lpbiOutput;
	LPARAM lOutput;
	LPBITMAPINFOHEADER lpbiInput;
	LPARAM lInput;
	LONG lStartFrame;
	LONG lFrameCount;
	LONG lQuality;
	LONG lDataRate;
	LONG lKeyRate;
	DWORD dwRate;
	DWORD dwScale;
	DWORD dwOverheadPerFrame;
	DWORD dwReserved2;
	LONG function (LPARAM,LONG,LPVOID,LONG) GetData;
	LONG function (LPARAM,LONG,LPVOID,LONG) PutData;
}

struct ICSETSTATUSPROC {
	DWORD dwFlags;
	LPARAM lParam;
	LONG function(LPARAM,UINT,LONG) Status;
}

struct ICINFO {
	DWORD dwSize;
	DWORD fccType;
	DWORD fccHandler;
	DWORD dwFlags;
	DWORD dwVersion;
	DWORD dwVersionICM;
	WCHAR szName[16];
	WCHAR szDescription[128];
	WCHAR szDriver[128];
}

struct ICDECOMPRESS {
	DWORD dwFlags;
	LPBITMAPINFOHEADER lpbiInput;
	LPVOID lpInput;
	LPBITMAPINFOHEADER lpbiOutput;
	LPVOID lpOutput;
	DWORD ckid;
}

struct ICDECOMPRESSEX {
	DWORD dwFlags;
	LPBITMAPINFOHEADER lpbiSrc;
	LPVOID lpSrc;
	LPBITMAPINFOHEADER lpbiDst;
	LPVOID lpDst;
	INT xDst;
	INT yDst;
	INT dxDst;
	INT dyDst;
	INT xSrc;
	INT ySrc;
	INT dxSrc;
	INT dySrc;
}

struct ICDRAWSUGGEST {
	DWORD dwFlags;
	LPBITMAPINFOHEADER lpbiIn;
	LPBITMAPINFOHEADER lpbiSuggest;
	INT dxSrc;
	INT dySrc;
	INT dxDst;
	INT dyDst;
	HIC hicDecompressor;
}

struct ICPALETTE {
	DWORD dwFlags;
	INT iStart;
	INT iLen;
	LPPALETTEENTRY lppe;
}

struct ICDRAWBEGIN {
	DWORD dwFlags;
	HPALETTE hpal;
	HWND hwnd;
	HDC hdc;
	INT xDst;
	INT yDst;
	INT dxDst;
	INT dyDst;
	LPBITMAPINFOHEADER lpbi;
	INT xSrc;
	INT ySrc;
	INT dxSrc;
	INT dySrc;
	DWORD dwRate;
	DWORD dwScale;
}

struct ICDRAW {
	DWORD dwFlags;
	LPVOID lpFormat;
	LPVOID lpData;
	DWORD cbData;
	LONG lTime;
}

struct COMPVARS {
	LONG cbSize;
	DWORD dwFlags;
	HIC hic;
	DWORD fccType;
	DWORD fccHandler;
	LPBITMAPINFO lpbiIn;
	LPBITMAPINFO lpbiOut;
	LPVOID lpBitsOut;
	LPVOID lpBitsPrev;
	LONG lFrame;
	LONG lKey;
	LONG lDataRate;
	LONG lQ;
	LONG lKeyCount;
	LPVOID lpState;
	LONG cbState;
}
alias COMPVARS* PCOMPVARS;

struct MainAVIHeader
{
	DWORD dwMicroSecPerFrame;
	DWORD dwMaxBytesPerSec;
	DWORD dwPaddingGranularity;
	DWORD dwFlags;
	DWORD dwTotalFrames;
	DWORD dwInitialFrames;
	DWORD dwStreams;
	DWORD dwSuggestedBufferSize;
	DWORD dwWidth;
	DWORD dwHeight;
	DWORD dwReserved[4];
}

struct AVIStreamHeader {
	FOURCC fccType;
	FOURCC fccHandler;
	DWORD dwFlags;
	WORD wPriority;
	WORD wLanguage;
	DWORD dwInitialFrames;
	DWORD dwScale;
	DWORD dwRate;
	DWORD dwStart;
	DWORD dwLength;
	DWORD dwSuggestedBufferSize;
	DWORD dwQuality;
	DWORD dwSampleSize;
	RECT rcFrame;
}

struct AVIINDEXENTRY{
	DWORD ckid;
	DWORD dwFlags;
	DWORD dwChunkOffset;
	DWORD dwChunkLength;
}

struct AVIPALCHANGE{
	BYTE bFirstEntry;
	BYTE bNumEntries;
	WORD wFlags;
	PALETTEENTRY peNew[1];
}

struct AVISTREAMINFOA{
	DWORD fccType;
	DWORD fccHandler;
	DWORD dwFlags;
	DWORD dwCaps;
	WORD wPriority;
	WORD wLanguage;
	DWORD dwScale;
	DWORD dwRate;
	DWORD dwStart;
	DWORD dwLength;
	DWORD dwInitialFrames;
	DWORD dwSuggestedBufferSize;
	DWORD dwQuality;
	DWORD dwSampleSize;
	RECT rcFrame;
	DWORD dwEditCount;
	DWORD dwFormatChangeCount;
	CHAR szName[64];
}
alias AVISTREAMINFOA* LPAVISTREAMINFOA, PAVISTREAMINFOA;

struct AVISTREAMINFOW{
	DWORD fccType;
	DWORD fccHandler;
	DWORD dwFlags;
	DWORD dwCaps;
	WORD wPriority;
	WORD wLanguage;
	DWORD dwScale;
	DWORD dwRate;
	DWORD dwStart;
	DWORD dwLength;
	DWORD dwInitialFrames;
	DWORD dwSuggestedBufferSize;
	DWORD dwQuality;
	DWORD dwSampleSize;
	RECT rcFrame;
	DWORD dwEditCount;
	DWORD dwFormatChangeCount;
	WCHAR szName[64];
}
alias AVISTREAMINFOW* LPAVISTREAMINFOW, PAVISTREAMINFOW;

struct AVIFILEINFOW{
	DWORD dwMaxBytesPerSec;
	DWORD dwFlags;
	DWORD dwCaps;
	DWORD dwStreams;
	DWORD dwSuggestedBufferSize;
	DWORD dwWidth;
	DWORD dwHeight;
	DWORD dwScale;
	DWORD dwRate;
	DWORD dwLength;
	DWORD dwEditCount;
	WCHAR szFileType[64];
}
alias AVIFILEINFOW* LPAVIFILEINFOW, PAVIFILEINFOW;

struct AVIFILEINFOA{
	DWORD dwMaxBytesPerSec;
	DWORD dwFlags;
	DWORD dwCaps;
	DWORD dwStreams;
	DWORD dwSuggestedBufferSize;
	DWORD dwWidth;
	DWORD dwHeight;
	DWORD dwScale;
	DWORD dwRate;
	DWORD dwLength;
	DWORD dwEditCount;
	CHAR szFileType[64];
}
alias AVIFILEINFOA* LPAVIFILEINFOA, PAVIFILEINFOA;

struct AVICOMPRESSOPTIONS{
	DWORD fccType;
	DWORD fccHandler;
	DWORD dwKeyFrameEvery;
	DWORD dwQuality;
	DWORD dwBytesPerSecond;
	DWORD dwFlags;
	LPVOID lpFormat;
	DWORD cbFormat;
	LPVOID lpParms;
	DWORD cbParms;
	DWORD dwInterleaveEvery;
}
alias AVICOMPRESSOPTIONS* LPAVICOMPRESSOPTIONS, PAVICOMPRESSOPTIONS;

//[???] #if !defined (__OBJC__)
//MACRO #define DEFINE_AVIGUID(name,l,w1,w2) DEFINE_GUID(name,l,w1,w2,0xC0,0,0,0,0,0,0,0x46)

DEFINE_AVIGUID(IID_IAVIFile,0x00020020,0,0);
DEFINE_AVIGUID(IID_IAVIStream,0x00020021,0,0);
DEFINE_AVIGUID(IID_IAVIStreaming,0x00020022,0,0);
DEFINE_AVIGUID(IID_IGetFrame,0x00020023,0,0);
DEFINE_AVIGUID(IID_IAVIEditStream,0x00020024,0,0);
DEFINE_AVIGUID(CLSID_AVIFile,0x00020000,0,0);

interface IAVIStream : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();
	HRESULT Create(LPARAM,LPARAM);
	HRESULT Info(AVISTREAMINFOW*,LONG);
	LONG FindSample(LONG,LONG);
	HRESULT ReadFormat(LONG,LPVOID,LONG*);
	HRESULT SetFormat(LONG,LPVOID,LONG);
	HRESULT Read(LONG,LONG,LPVOID,LONG,LONG*,LONG*);
	HRESULT Write(LONG,LONG,LPVOID,LONG,DWORD,LONG*,LONG*);
	HRESULT Delete(LONG,LONG);
	HRESULT ReadData(DWORD,LPVOID,LONG*);
	HRESULT WriteData(DWORD,LPVOID,LONG);
	HRESULT SetInfo(AVISTREAMINFOW*,LONG);
}
alias IAVIStream *PAVISTREAM;

interface IAVIStreaming : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();
	HRESULT Begin(LONG,LONG,LONG);
	HRESULT End();
}
alias IAVIStreaming *PAVISTREAMING;

interface IAVIEditStream : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();
	HRESULT Cut(LONG*,LONG*,PAVISTREAM*);
	HRESULT Copy(LONG*,LONG*,PAVISTREAM*);
	HRESULT Paste(LONG*,LONG*,PAVISTREAM,LONG,LONG);
	HRESULT Clone(PAVISTREAM*);
	HRESULT SetInfo(LPAVISTREAMINFOW,LONG);
}
alias IAVIEditStream *PAVIEDITSTREAM;

interface IAVIFile : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();
	HRESULT Info(AVIFILEINFOW*,LONG);
	HRESULT GetStream(PAVISTREAM*,DWORD,LONG);
	HRESULT CreateStream(PAVISTREAM*,AVISTREAMINFOW*);
	HRESULT WriteData(DWORD,LPVOID,LONG);
	HRESULT ReadData(DWORD,LPVOID,LONG*);
	HRESULT EndRecord();
	HRESULT DeleteStream(DWORD,LONG);
}
alias IAVIFile *PAVIFILE;

interface IGetFrame : public IUnknown
{
	HRESULT QueryInterface(REFIID,PVOID*);
	ULONG AddRef();
	ULONG Release();
	LPVOID GetFrame(LONG);
	HRESULT Begin(LONG,LONG,LONG);
	HRESULT End();
	HRESULT SetFormat(LPBITMAPINFOHEADER,LPVOID,INT,INT,INT,INT);
}
alias IGetFrame *PGETFRAME;

extern(Windows):
DWORD VideoForWindowsVersion();
LONG InitVFW();
LONG TermVFW();
DWORD VFWAPIV ICCompress(HIC,DWORD,LPBITMAPINFOHEADER,LPVOID,LPBITMAPINFOHEADER,LPVOID,LPDWORD,LPDWORD,LONG,DWORD,DWORD,LPBITMAPINFOHEADER,LPVOID);
DWORD VFWAPIV ICDecompress(HIC,DWORD,LPBITMAPINFOHEADER,LPVOID,LPBITMAPINFOHEADER,LPVOID);
LRESULT	ICSendMessage(HIC,UINT,DWORD,DWORD);
HANDLE ICImageCompress(HIC,UINT,LPBITMAPINFO,LPVOID,LPBITMAPINFO,LONG,LONG*);
HANDLE ICImageDecompress(HIC,UINT,LPBITMAPINFO,LPVOID,LPBITMAPINFO);
BOOL ICInfo(DWORD,DWORD,ICINFO*);
BOOL ICInstall(DWORD,DWORD,LPARAM,LPSTR,UINT);
BOOL ICRemove(DWORD,DWORD,UINT);
LRESULT ICGetInfo(HIC,ICINFO*,DWORD);
HIC ICOpen(DWORD,DWORD,UINT);
HIC ICOpenFunction(DWORD,DWORD,UINT,FARPROC);
LRESULT ICClose(HIC hic);
HIC ICLocate(DWORD,DWORD,LPBITMAPINFOHEADER,LPBITMAPINFOHEADER,WORD);
HIC ICGetDisplayFormat(HIC,LPBITMAPINFOHEADER,LPBITMAPINFOHEADER,INT,INT,INT);
DWORD VFWAPIV ICDrawBegin(HIC,DWORD,HPALETTE,HWND,HDC,INT,INT,INT,INT,LPBITMAPINFOHEADER,INT,INT,INT,INT,DWORD,DWORD);
DWORD VFWAPIV ICDraw(HIC,DWORD,LPVOID,LPVOID,DWORD,LONG);
BOOL ICCompressorChoose(HWND,UINT,LPVOID,LPVOID,PCOMPVARS,LPSTR);
BOOL ICSeqCompressFrameStart(PCOMPVARS,LPBITMAPINFO);
void ICSeqCompressFrameEnd(PCOMPVARS);
LPVOID ICSeqCompressFrame(PCOMPVARS,UINT,LPVOID,BOOL*,LONG*);
void ICCompressorFree(PCOMPVARS);

extern (Windows):
ULONG AVIStreamAddRef(PAVISTREAM);
ULONG AVIStreamRelease(PAVISTREAM);
HRESULT AVIStreamCreate(PAVISTREAM*,LONG,LONG,CLSID*);
HRESULT AVIStreamInfoA(PAVISTREAM,AVISTREAMINFOA*,LONG);
HRESULT AVIStreamInfoW(PAVISTREAM,AVISTREAMINFOW*,LONG);
HRESULT AVIStreamFindSample(PAVISTREAM,LONG,DWORD);
HRESULT AVIStreamReadFormat(PAVISTREAM,LONG,LPVOID,LONG*);
HRESULT AVIStreamSetFormat(PAVISTREAM,LONG,LPVOID,LONG);
HRESULT AVIStreamRead(PAVISTREAM,LONG,LONG,LPVOID,LONG,LONG*,LONG*);
HRESULT AVIStreamWrite(PAVISTREAM,LONG,LONG,LPVOID,LONG,DWORD,LONG*,LONG*);
HRESULT AVIStreamReadData(PAVISTREAM,DWORD,LPVOID,LONG*);
HRESULT AVIStreamWriteData(PAVISTREAM,DWORD,LPVOID,LONG);
PGETFRAME AVIStreamGetFrameOpen(PAVISTREAM,LPBITMAPINFOHEADER);
LPVOID AVIStreamGetFrame(PGETFRAME,LONG);
HRESULT AVIStreamGetFrameClose(PGETFRAME);
HRESULT AVIMakeCompressedStream(PAVISTREAM*,PAVISTREAM,AVICOMPRESSOPTIONS*,CLSID*);
HRESULT AVIMakeFileFromStreams(PAVIFILE*,INT,PAVISTREAM*);
HRESULT AVIStreamOpenFromFileA(PAVISTREAM*,LPCSTR,DWORD,LONG,UINT,CLSID*);
HRESULT AVIStreamOpenFromFileW(PAVISTREAM*,LPCWSTR,DWORD,LONG,UINT,CLSID*);
HRESULT AVIBuildFilterA(LPSTR,LONG,BOOL);
HRESULT AVIBuildFilterW(LPWSTR,LONG,BOOL);
BOOL AVISaveOptions(HWND,UINT,INT,PAVISTREAM*,LPAVICOMPRESSOPTIONS*);
HRESULT AVISaveOptionsFree(INT,LPAVICOMPRESSOPTIONS*);
HRESULT AVISaveVA(LPCSTR,CLSID*,AVISAVECALLBACK,INT,PAVISTREAM*,LPAVICOMPRESSOPTIONS*);
HRESULT AVISaveVW(LPCWSTR,CLSID*,AVISAVECALLBACK,INT,PAVISTREAM*,LPAVICOMPRESSOPTIONS*);
LONG AVIStreamStart(PAVISTREAM);
LONG AVIStreamLength(PAVISTREAM);
LONG AVIStreamSampleToTime(PAVISTREAM,LONG);
LONG AVIStreamTimeToSample(PAVISTREAM,LONG);
HRESULT CreateEditableStream(PAVISTREAM*,PAVISTREAM);
HRESULT EditStreamClone(PAVISTREAM,PAVISTREAM*);
HRESULT EditStreamCopy(PAVISTREAM,LONG*,LONG*,PAVISTREAM*);
HRESULT EditStreamCut(PAVISTREAM,LONG*,LONG*,PAVISTREAM*);
HRESULT EditStreamPaste(PAVISTREAM,LONG*,LONG*,PAVISTREAM,LONG,LONG);
HRESULT EditStreamSetInfoA(PAVISTREAM,LPAVISTREAMINFOA,LONG);
HRESULT EditStreamSetInfoW(PAVISTREAM,LPAVISTREAMINFOW,LONG);
HRESULT EditStreamSetNameA(PAVISTREAM,LPCSTR);
HRESULT EditStreamSetNameW(PAVISTREAM,LPCWSTR);
HRESULT CreateEditableStream(PAVISTREAM*,PAVISTREAM);
HRESULT EditStreamClone(PAVISTREAM,PAVISTREAM*);
HRESULT EditStreamCopy(PAVISTREAM,LONG*,LONG*,PAVISTREAM*);
HRESULT EditStreamCut(PAVISTREAM,LONG*,LONG*,PAVISTREAM*);
HRESULT EditStreamPaste(PAVISTREAM,LONG*,LONG*,PAVISTREAM,LONG,LONG);
HRESULT EditStreamSetInfoA(PAVISTREAM,LPAVISTREAMINFOA,LONG);
HRESULT EditStreamSetInfoW(PAVISTREAM,LPAVISTREAMINFOW,LONG);
HRESULT EditStreamSetNameA(PAVISTREAM,LPCSTR);
HRESULT EditStreamSetNameW(PAVISTREAM,LPCWSTR);
void AVIFileInit();
void AVIFileExit();
HRESULT AVIFileOpenA(PAVIFILE*,LPCSTR,UINT,LPCLSID);
HRESULT AVIFileOpenW(PAVIFILE*,LPCWSTR,UINT,LPCLSID);
ULONG AVIFileAddRef(PAVIFILE);
ULONG AVIFileRelease(PAVIFILE);
HRESULT AVIFileInfoA(PAVIFILE,PAVIFILEINFOA,LONG);
HRESULT AVIFileInfoW(PAVIFILE,PAVIFILEINFOW,LONG);
HRESULT AVIFileGetStream(PAVIFILE,PAVISTREAM*,DWORD,LONG);
HRESULT AVIFileCreateStreamA(PAVIFILE,PAVISTREAM*,AVISTREAMINFOA*);
HRESULT AVIFileCreateStreamW(PAVIFILE,PAVISTREAM*,AVISTREAMINFOW*);
HRESULT AVIFileWriteData(PAVIFILE,DWORD,LPVOID,LONG);
HRESULT AVIFileReadData(PAVIFILE,DWORD,LPVOID,LPLONG);
HRESULT AVIFileEndRecord(PAVIFILE);
HRESULT AVIClearClipboard();
HRESULT AVIGetFromClipboard(PAVIFILE*);
HRESULT AVIPutFileOnClipboard(PAVIFILE);

//[No] #ifdef OFN_READONLY
//[No] BOOL WINAPI GetOpenFileNamePreviewA(LPOPENFILENAMEA);
//[No] BOOL WINAPI GetOpenFileNamePreviewW(LPOPENFILENAMEW);
//[No] BOOL WINAPI GetSaveFileNamePreviewA(LPOPENFILENAMEA);
//[No] BOOL WINAPI GetSaveFileNamePreviewW(LPOPENFILENAMEW);
//[No] #endif
HWND VFWAPIV MCIWndCreateA(HWND,HINSTANCE,DWORD,LPCSTR);
HWND VFWAPIV MCIWndCreateW(HWND,HINSTANCE,DWORD,LPCWSTR);
HDRAWDIB VFWAPI DrawDibOpen();
UINT VFWAPI DrawDibRealize(HDRAWDIB,HDC,BOOL);
BOOL VFWAPI DrawDibBegin(HDRAWDIB,HDC,INT,INT,LPBITMAPINFOHEADER,INT,INT,UINT);
BOOL VFWAPI DrawDibDraw(HDRAWDIB,HDC,INT,INT,INT,INT,LPBITMAPINFOHEADER,LPVOID,INT,INT,INT,INT,UINT);
BOOL VFWAPI DrawDibSetPalette(HDRAWDIB,HPALETTE);
HPALETTE VFWAPI DrawDibGetPalette(HDRAWDIB);
BOOL VFWAPI DrawDibChangePalette(HDRAWDIB,int,int,LPPALETTEENTRY);
LPVOID VFWAPI DrawDibGetBuffer(HDRAWDIB,LPBITMAPINFOHEADER,DWORD,DWORD);
BOOL VFWAPI DrawDibStart(HDRAWDIB,DWORD);
BOOL VFWAPI DrawDibStop(HDRAWDIB);
BOOL VFWAPI DrawDibEnd(HDRAWDIB);
BOOL VFWAPI DrawDibClose(HDRAWDIB);
DWORD VFWAPI DrawDibProfileDisplay(LPBITMAPINFOHEADER);

//MACRO #define ICCompressGetFormat(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_COMPRESS_GET_FORMAT,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICCompressGetFormatSize(hic,lpbi) ICCompressGetFormat(hic,lpbi,NULL)

//MACRO #define ICCompressBegin(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_COMPRESS_BEGIN,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICCompressGetSize(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_COMPRESS_GET_SIZE,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICCompressQuery(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_COMPRESS_QUERY,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICCompressEnd(hic) ICSendMessage(hic,ICM_COMPRESS_END,0,0)

//MACRO #define ICQueryAbout(hic) (ICSendMessage(hic,ICM_ABOUT,(DWORD)-1,ICMF_ABOUT_QUERY)==ICERR_OK)

//MACRO #define ICAbout(hic,hwnd) ICSendMessage(hic,ICM_ABOUT,(DWORD)(hwnd),0)

//MACRO #define ICQueryConfigure(hic) (ICSendMessage(hic,ICM_CONFIGURE,(DWORD)-1,ICMF_CONFIGURE_QUERY)==ICERR_OK)

//MACRO #define ICConfigure(hic,hwnd) ICSendMessage(hic,ICM_CONFIGURE,(DWORD)(hwnd),0)

//MACRO #define ICDecompressBegin(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_DECOMPRESS_BEGIN,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICDecompressQuery(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_DECOMPRESS_QUERY,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICDecompressGetFormat(hic,lpbiInput,lpbiOutput) (LONG)ICSendMessage(hic,ICM_DECOMPRESS_GET_FORMAT,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICDecompressGetFormatSize(hic,lpbi) ICDecompressGetFormat(hic, lpbi, NULL)

//MACRO #define ICDecompressGetPalette(hic,lpbiInput,lpbiOutput) ICSendMessage(hic,ICM_DECOMPRESS_GET_PALETTE,(DWORD)(lpbiInput),(DWORD)(lpbiOutput))

//MACRO #define ICDecompressSetPalette(hic,lpbiPalette) ICSendMessage(hic,ICM_DECOMPRESS_SET_PALETTE,(DWORD)(lpbiPalette),0)

//MACRO #define ICDecompressEnd(hic) ICSendMessage(hic,ICM_DECOMPRESS_END,0,0)

//MACRO #define ICDecompressExEnd(hic) ICSendMessage(hic,ICM_DECOMPRESSEX_END,0,0)

//MACRO #define ICDecompressOpen(fccType,fccHandler,lpbiIn,lpbiOut) ICLocate(fccType,fccHandler,lpbiIn,lpbiOut,ICMODE_DECOMPRESS)

//MACRO #define ICDrawOpen(fccType,fccHandler,lpbiIn) ICLocate(fccType,fccHandler,lpbiIn,NULL,ICMODE_DRAW)

//MACRO #define ICGetState(hic,pv,cb) ICSendMessage(hic,ICM_GETSTATE,(DWORD)(pv),(DWORD)(cb))

//MACRO #define ICSetState(hic,pv,cb) ICSendMessage(hic,ICM_SETSTATE,(DWORD)(pv),(DWORD)(cb))

//MACRO #define ICGetStateSize(hic) ICGetState(hic,NULL,0)

//MACRO #define ICDrawWindow(hic,prc) ICSendMessage(hic,ICM_DRAW_WINDOW,(DWORD)(prc),sizeof(RECT))

//MACRO #define ICDrawQuery(hic,lpbiInput) ICSendMessage(hic,ICM_DRAW_QUERY,(DWORD)(lpbiInput),0)

//MACRO #define ICDrawChangePalette(hic,lpbiInput) ICSendMessage(hic,ICM_DRAW_CHANGEPALETTE,(DWORD)(lpbiInput),0)

//MACRO #define ICGetBuffersWanted(hic,lpdwBuffers) ICSendMessage(hic,ICM_GETBUFFERSWANTED,(DWORD)(lpdwBuffers),0)

//MACRO #define ICDrawEnd(hic) ICSendMessage(hic,ICM_DRAW_END,0,0)

//MACRO #define ICDrawStart(hic) ICSendMessage(hic,ICM_DRAW_START,0,0)

//MACRO #define ICDrawStartPlay(hic,lFrom,lTo) ICSendMessage(hic,ICM_DRAW_START_PLAY,(DWORD)(lFrom),(DWORD)(lTo))

//MACRO #define ICDrawStop(hic) ICSendMessage(hic,ICM_DRAW_STOP,0,0)

//MACRO #define ICDrawStopPlay(hic) ICSendMessage(hic,ICM_DRAW_STOP_PLAY,0,0)

//MACRO #define ICDrawGetTime(hic,lplTime) ICSendMessage(hic,ICM_DRAW_GETTIME,(DWORD)(lplTime),0)

//MACRO #define ICDrawSetTime(hic,lTime) ICSendMessage(hic,ICM_DRAW_SETTIME,(DWORD)lTime,0)

//MACRO #define ICDrawRealize(hic,hdc,fBackground) ICSendMessage(hic,ICM_DRAW_REALIZE,(DWORD)(hdc),(DWORD)(fBackground))

//MACRO #define ICDrawFlush(hic) ICSendMessage(hic,ICM_DRAW_FLUSH,0,0)

//MACRO #define ICDrawRenderBuffer(hic) ICSendMessage(hic,ICM_DRAW_RENDERBUFFER,0,0)

//MACRO #define AVIFileClose(pavi) AVIFileRelease(pavi)

//MACRO #define AVIStreamClose(pavi) AVIStreamRelease(pavi);

//MACRO #define AVIStreamEnd(pavi) (AVIStreamStart(pavi)+AVIStreamLength(pavi))

//MACRO #define AVIStreamEndTime(pavi) AVIStreamSampleToTime(pavi,AVIStreamEnd(pavi))

//MACRO #define AVIStreamFormatSize(pavi,lPos,plSize) AVIStreamReadFormat(pavi,lPos,NULL,plSize)

//MACRO #define AVIStreamLengthTime(pavi) AVIStreamSampleToTime(pavi,AVIStreamLength(pavi))

//MACRO #define AVIStreamSampleSize(pavi,pos,psize) AVIStreamRead(pavi,pos,1,NULL,0,psize,NULL)

//MACRO #define AVIStreamSampleToSample(pavi1,pavi2,samp2) AVIStreamTimeToSample(pavi1,AVIStreamSampleToTime(pavi2,samp2))

//MACRO #define AVIStreamStartTime(pavi) AVIStreamSampleToTime(pavi,AVIStreamStart(pavi))

//MACRO #define AVIStreamNextSample(pavi,pos) AVIStreamFindSample(pavi,pos+1,FIND_NEXT|FIND_ANY)

//MACRO #define AVIStreamPrevSample(pavi,pos) AVIStreamFindSample(pavi,pos-1,FIND_PREV|FIND_ANY)

//MACRO #define AVIStreamNearestSample(pavi, pos) AVIStreamFindSample(pavi,pos,FIND_PREV|FIND_ANY)

//MACRO #define AVStreamNextKeyFrame(pavi,pos) AVIStreamFindSample(pavi,pos+1,FIND_NEXT|FIND_KEY)

//MACRO #define AVStreamPrevKeyFrame(pavi,pos) AVIStreamFindSample(pavi,pos-1,FIND_NEXT|FIND_KEY)

//MACRO #define AVIStreamNearestKeyFrame(pavi,pos) AVIStreamFindSample(pavi,pos,FIND_PREV|FIND_KEY)

//MACRO #define AVIStreamIsKeyFrame(pavi, pos) (AVIStreamNearestKeyFrame(pavi,pos) == pos)

alias SendMessage MCIWndSM;

//MACRO #define MCIWndCanPlay(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_PLAY,0,0)

//MACRO #define MCIWndCanRecord(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_RECORD,0,0)

//MACRO #define MCIWndCanSave(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_SAVE,0,0)

//MACRO #define MCIWndCanWindow(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_WINDOW,0,0)

//MACRO #define MCIWndCanEject(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_EJECT,0,0)

//MACRO #define MCIWndCanConfig(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_CAN_CONFIG,0,0)

//MACRO #define MCIWndPaletteKick(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_PALETTEKICK,0,0)

//MACRO #define MCIWndSave(hWnd,szFile) (LONG)MCIWndSM(hWnd,MCI_SAVE,0,(LPARAM)(LPVOID)(szFile))

//MACRO #define MCIWndSaveDialog(hWnd) MCIWndSave(hWnd,-1)

//MACRO #define MCIWndNew(hWnd,lp) (LONG)MCIWndSM(hWnd,MCIWNDM_NEW,0,(LPARAM)(LPVOID)(lp))

//MACRO #define MCIWndRecord(hWnd) (LONG)MCIWndSM(hWnd,MCI_RECORD,0,0)

//MACRO #define MCIWndOpen(hWnd,sz,f) (LONG)MCIWndSM(hWnd,MCIWNDM_OPEN,(WPARAM)(UINT)(f),(LPARAM)(LPVOID)(sz))

//MACRO #define MCIWndOpenDialog(hWnd) MCIWndOpen(hWnd,-1,0)

//MACRO #define MCIWndClose(hWnd) (LONG)MCIWndSM(hWnd,MCI_CLOSE,0,0)

//MACRO #define MCIWndPlay(hWnd) (LONG)MCIWndSM(hWnd,MCI_PLAY,0,0)

//MACRO #define MCIWndStop(hWnd) (LONG)MCIWndSM(hWnd,MCI_STOP,0,0)

//MACRO #define MCIWndPause(hWnd) (LONG)MCIWndSM(hWnd,MCI_PAUSE,0,0)

//MACRO #define MCIWndResume(hWnd) (LONG)MCIWndSM(hWnd,MCI_RESUME,0,0)

//MACRO #define MCIWndSeek(hWnd,lPos) (LONG)MCIWndSM(hWnd,MCI_SEEK,0,(LPARAM)(LONG)(lPos))

//MACRO #define MCIWndEject(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_EJECT,0,0)

//MACRO #define MCIWndHome(hWnd) MCIWndSeek(hWnd,MCIWND_START)

//MACRO #define MCIWndEnd(hWnd) MCIWndSeek(hWnd,MCIWND_END)

//MACRO #define MCIWndGetSource(hWnd,prc) (LONG)MCIWndSM(hWnd,MCIWNDM_GET_SOURCE,0,(LPARAM)(LPRECT)(prc))

//MACRO #define MCIWndPutSource(hWnd,prc) (LONG)MCIWndSM(hWnd,MCIWNDM_PUT_SOURCE,0,(LPARAM)(LPRECT)(prc))

//MACRO #define MCIWndGetDest(hWnd,prc) (LONG)MCIWndSM(hWnd,MCIWNDM_GET_DEST,0,(LPARAM)(LPRECT)(prc))

//MACRO #define MCIWndPutDest(hWnd,prc) (LONG)MCIWndSM(hWnd,MCIWNDM_PUT_DEST,0,(LPARAM)(LPRECT)(prc))

//MACRO #define MCIWndPlayReverse(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_PLAYREVERSE,0,0)

//MACRO #define MCIWndPlayFrom(hWnd,lPos) (LONG)MCIWndSM(hWnd,MCIWNDM_PLAYFROM,0,(LPARAM)(LONG)(lPos))

//MACRO #define MCIWndPlayTo(hWnd,lPos) (LONG)MCIWndSM(hWnd,MCIWNDM_PLAYTO,  0,(LPARAM)(LONG)(lPos))

//MACRO #define MCIWndPlayFromTo(hWnd,lStart,lEnd) (MCIWndSeek(hWnd,lStart),MCIWndPlayTo(hWnd,lEnd))

//MACRO #define MCIWndGetDeviceID(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETDEVICEID,0,0)

//MACRO #define MCIWndGetAlias(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETALIAS,0,0)

//MACRO #define MCIWndGetMode(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETMODE,(WPARAM)(UINT)(len),(LPARAM)(LPTSTR)(lp))

//MACRO #define MCIWndGetPosition(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETPOSITION,0,0)

//MACRO #define MCIWndGetPositionString(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETPOSITION,(WPARAM)(UINT)(len),(LPARAM)(LPTSTR)(lp))

//MACRO #define MCIWndGetStart(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETSTART,0,0)

//MACRO #define MCIWndGetLength(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETLENGTH,0,0)

//MACRO #define MCIWndGetEnd(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETEND,0,0)

//MACRO #define MCIWndStep(hWnd,n) (LONG)MCIWndSM(hWnd,MCI_STEP,0,(LPARAM)(long)(n))

//MACRO #define MCIWndDestroy(hWnd) (VOID)MCIWndSM(hWnd,WM_CLOSE,0,0)

//MACRO #define MCIWndSetZoom(hWnd,iZoom) (VOID)MCIWndSM(hWnd,MCIWNDM_SETZOOM,0,(LPARAM)(UINT)(iZoom))

//MACRO #define MCIWndGetZoom(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETZOOM,0,0)

//MACRO #define MCIWndSetVolume(hWnd,iVol) (LONG)MCIWndSM(hWnd,MCIWNDM_SETVOLUME,0,(LPARAM)(UINT)(iVol))

//MACRO #define MCIWndGetVolume(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETVOLUME,0,0)

//MACRO #define MCIWndSetSpeed(hWnd,iSpeed) (LONG)MCIWndSM(hWnd,MCIWNDM_SETSPEED,0,(LPARAM)(UINT)(iSpeed))

//MACRO #define MCIWndGetSpeed(hWnd) (LONG)MCIWndSM(hWnd,MCIWNDM_GETSPEED,0,0)

//MACRO #define MCIWndSetTimeFormat(hWnd,lp) (LONG)MCIWndSM(hWnd,MCIWNDM_SETTIMEFORMAT,0,(LPARAM)(LPTSTR)(lp))

//MACRO #define MCIWndGetTimeFormat(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETTIMEFORMAT,(WPARAM)(UINT)(len),(LPARAM)(LPTSTR)(lp))

//MACRO #define MCIWndValidateMedia(hWnd) (VOID)MCIWndSM(hWnd,MCIWNDM_VALIDATEMEDIA,0,0)

//MACRO #define MCIWndSetRepeat(hWnd,f) (void)MCIWndSM(hWnd,MCIWNDM_SETREPEAT,0,(LPARAM)(BOOL)(f))

//MACRO #define MCIWndGetRepeat(hWnd) (BOOL)MCIWndSM(hWnd,MCIWNDM_GETREPEAT,0,0)

//MACRO #define MCIWndUseFrames(hWnd) MCIWndSetTimeFormat(hWnd,TEXT("frames"))

//MACRO #define MCIWndUseTime(hWnd) MCIWndSetTimeFormat(hWnd,TEXT("ms"))

//MACRO #define MCIWndSetActiveTimer(hWnd,active) (VOID)MCIWndSM(hWnd,MCIWNDM_SETACTIVETIMER,(WPARAM)(UINT)(active),0L)

//MACRO #define MCIWndSetInactiveTimer(hWnd,inactive) (VOID)MCIWndSM(hWnd,MCIWNDM_SETINACTIVETIMER,(WPARAM)(UINT)(inactive),0L)

//MACRO #define MCIWndSetTimers(hWnd,active,inactive) (VOID)MCIWndSM(hWnd,MCIWNDM_SETTIMERS,(WPARAM)(UINT)(active),(LPARAM)(UINT)(inactive))

//MACRO #define MCIWndGetActiveTimer(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETACTIVETIMER,0,0L);

//MACRO #define MCIWndGetInactiveTimer(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETINACTIVETIMER,0,0L);

//MACRO #define MCIWndRealize(hWnd,fBkgnd) (LONG)MCIWndSM(hWnd,MCIWNDM_REALIZE,(WPARAM)(BOOL)(fBkgnd),0)

//MACRO #define MCIWndSendString(hWnd,sz) (LONG)MCIWndSM(hWnd,MCIWNDM_SENDSTRING,0,(LPARAM)(LPTSTR)(sz))

//MACRO #define MCIWndReturnString(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_RETURNSTRING,(WPARAM)(UINT)(len),(LPARAM)(LPVOID)(lp))

//MACRO #define MCIWndGetError(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETERROR,(WPARAM)(UINT)(len),(LPARAM)(LPVOID)(lp))

//MACRO #define MCIWndGetPalette(hWnd) (HPALETTE)MCIWndSM(hWnd,MCIWNDM_GETPALETTE,0,0)

//MACRO #define MCIWndSetPalette(hWnd,hpal) (LONG)MCIWndSM(hWnd,MCIWNDM_SETPALETTE,(WPARAM)(HPALETTE)(hpal),0)

//MACRO #define MCIWndGetFileName(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETFILENAME,(WPARAM)(UINT)(len),(LPARAM)(LPVOID)(lp))

//MACRO #define MCIWndGetDevice(hWnd,lp,len) (LONG)MCIWndSM(hWnd,MCIWNDM_GETDEVICE,(WPARAM)(UINT)(len),(LPARAM)(LPVOID)(lp))

//MACRO #define MCIWndGetStyles(hWnd) (UINT)MCIWndSM(hWnd,MCIWNDM_GETSTYLES,0,0L)

//MACRO #define MCIWndChangeStyles(hWnd,mask,value) (LONG)MCIWndSM(hWnd,MCIWNDM_CHANGESTYLES,(WPARAM)(UINT)(mask),(LPARAM)(LONG)(value))

//MACRO #define MCIWndOpenInterface(hWnd,pUnk) (LONG)MCIWndSM(hWnd,MCIWNDM_OPENINTERFACE,0,(LPARAM)(LPUNKNOWN)(pUnk))

//MACRO #define MCIWndSetOwner(hWnd,hWndP) (LONG)MCIWndSM(hWnd,MCIWNDM_SETOWNER,(WPARAM)(hWndP),0)

//MACRO #define DrawDibUpdate(hdd,hdc,x,y) DrawDibDraw(hdd,hdc,x,y,0,0,NULL,NULL,0,0,0,0,DDF_UPDATE)

DWORD ICGetDefaultQuality(HIC hic)
{
	DWORD dwICValue;
	ICSendMessage(hic, ICM_GETDEFAULTQUALITY, cast(DWORD)cast(LPVOID)&dwICValue, DWORD.sizeof);
	return dwICValue;
}

DWORD ICGetDefaultKeyFrameRate(HIC hic)
{
	DWORD dwICValue;
	ICSendMessage(hic, ICM_GETDEFAULTKEYFRAMERATE, cast(DWORD)cast(LPVOID)&dwICValue, DWORD.sizeof);
	return dwICValue;
}

LRESULT ICDrawSuggestFormat(HIC hic,LPBITMAPINFOHEADER lpbiIn,LPBITMAPINFOHEADER lpbiOut,INT dxSrc,INT dySrc,INT dxDst,INT dyDst,HIC hicDecomp)
{
	ICDRAWSUGGEST ic;
	ic.lpbiIn = lpbiIn;
	ic.lpbiSuggest = lpbiOut;
	ic.dxSrc = dxSrc;
	ic.dySrc = dySrc;
	ic.dxDst = dxDst;
	ic.dyDst = dyDst;
	ic.hicDecompressor = hicDecomp;
	return ICSendMessage(hic,ICM_DRAW_SUGGESTFORMAT,cast(DWORD)&ic,ic.sizeof);
}

LRESULT ICSetStatusProc(HIC hic,DWORD dwFlags,LRESULT lParam,LONG (CALLBACK *fpfnStatus)(LPARAM,UINT,LONG))
{
	ICSETSTATUSPROC ic;
	ic.dwFlags = dwFlags;
	ic.lParam = lParam;
	ic.Status = fpfnStatus;
	return ICSendMessage(hic,ICM_SET_STATUS_PROC,cast(DWORD)&ic,ic.sizeof);
}

LRESULT ICDecompressEx(HIC hic,DWORD dwFlags,LPBITMAPINFOHEADER lpbiSrc,LPVOID lpSrc,INT xSrc,INT ySrc,INT dxSrc,INT dySrc,LPBITMAPINFOHEADER lpbiDst,LPVOID lpDst,INT xDst,INT yDst,INT dxDst,INT dyDst)
{
	ICDECOMPRESSEX ic;
	ic.dwFlags = dwFlags;
	ic.lpbiSrc = lpbiSrc;
	ic.lpSrc = lpSrc;
	ic.xSrc = xSrc;
	ic.ySrc = ySrc;
	ic.dxSrc = dxSrc;
	ic.dySrc = dySrc;
	ic.lpbiDst = lpbiDst;
	ic.lpDst = lpDst;
	ic.xDst = xDst;
	ic.yDst = yDst;
	ic.dxDst = dxDst;
	ic.dyDst = dyDst;
	return ICSendMessage(hic,ICM_DECOMPRESSEX,cast(DWORD)&ic,ic.sizeof);
}

LRESULT ICDecompressExBegin(HIC hic,DWORD dwFlags,LPBITMAPINFOHEADER lpbiSrc,LPVOID lpSrc,INT xSrc,INT ySrc,INT dxSrc,INT dySrc,LPBITMAPINFOHEADER lpbiDst,LPVOID lpDst,INT xDst,INT yDst,INT dxDst,INT dyDst)
{
	ICDECOMPRESSEX ic;
	ic.dwFlags = dwFlags;
	ic.lpbiSrc = lpbiSrc;
	ic.lpSrc = lpSrc;
	ic.xSrc = xSrc;
	ic.ySrc = ySrc;
	ic.dxSrc = dxSrc;
	ic.dySrc = dySrc;
	ic.lpbiDst = lpbiDst;
	ic.lpDst = lpDst;
	ic.xDst = xDst;
	ic.yDst = yDst;
	ic.dxDst = dxDst;
	ic.dyDst = dyDst;
	return ICSendMessage(hic,ICM_DECOMPRESSEX_BEGIN,cast(DWORD)&ic,ic.sizeof);
}

LRESULT ICDecompressExQuery(HIC hic,DWORD dwFlags,LPBITMAPINFOHEADER lpbiSrc,LPVOID lpSrc,INT xSrc,INT ySrc,INT dxSrc,INT dySrc,LPBITMAPINFOHEADER lpbiDst,LPVOID lpDst,INT xDst,INT yDst,INT dxDst,INT dyDst)
{
	ICDECOMPRESSEX ic;
	ic.dwFlags = dwFlags;
	ic.lpbiSrc = lpbiSrc;
	ic.lpSrc = lpSrc;
	ic.xSrc = xSrc;
	ic.ySrc = ySrc;
	ic.dxSrc = dxSrc;
	ic.dySrc = dySrc;
	ic.lpbiDst = lpbiDst;
	ic.lpDst = lpDst;
	ic.xDst = xDst;
	ic.yDst = yDst;
	ic.dxDst = dxDst;
	ic.dyDst = dyDst;
	return ICSendMessage(hic,ICM_DECOMPRESSEX_QUERY,cast(DWORD)&ic,ic.sizeof);
}

version(Unicode) {
	alias AVISTREAMINFOW AVISTREAMINFO;
	alias LPAVISTREAMINFOW LPAVISTREAMINFO;
	alias PAVISTREAMINFOW PAVISTREAMINFO;
	alias AVIFILEINFOW AVIFILEINFO;
	alias PAVIFILEINFOW PAVIFILEINFO;
	alias LPAVIFILEINFOW LPAVIFILEINFO;
	alias AVIStreamInfoW AVIStreamInfo;
	alias AVIStreamOpenFromFileW AVIStreamOpenFromFile;
	alias AVIBuildFilterW AVIBuildFilter;
	alias AVISaveVW AVISaveV;
	alias EditStreamSetInfoW EditStreamSetInfo;
	alias EditStreamSetNameW EditStreamSetName;
	alias AVIFileOpenW AVIFileOpen;
	alias AVIFileInfoW AVIFileInfo;
	alias AVIFileCreateStreamW AVIFileCreateStream;
	alias GetOpenFileNamePreviewW GetOpenFileNamePreview;
	alias GetSaveFileNamePreviewW GetSaveFileNamePreview;
	alias MCIWndCreateW MCIWndCreate;
	alias MCIWNDF_NOTIFYMEDIAW MCIWNDF_NOTIFYMEDIA;
	alias MCIWNDM_SENDSTRINGW MCIWNDM_SENDSTRING;
	alias MCIWNDM_GETPOSITIONW MCIWNDM_GETPOSITION;
	alias MCIWNDM_GETMODEW MCIWNDM_GETMODE;
	alias MCIWNDM_SETTIMEFORMATW MCIWNDM_SETTIMEFORMAT;
	alias MCIWNDM_GETTIMEFORMATW MCIWNDM_GETTIMEFORMAT;
	alias MCIWNDM_GETFILENAMEW MCIWNDM_GETFILENAME;
	alias MCIWNDM_GETDEVICEW MCIWNDM_GETDEVICE;
	alias MCIWNDM_GETERRORW MCIWNDM_GETERROR;
	alias MCIWNDM_NEWW MCIWNDM_NEW;
	alias MCIWNDM_RETURNSTRINGW MCIWNDM_RETURNSTRING;
	alias MCIWNDM_OPENW MCIWNDM_OPEN;
} else {
	alias AVISTREAMINFOA AVISTREAMINFO;
	alias LPAVISTREAMINFOA LPAVISTREAMINFO;
	alias PAVISTREAMINFOA PAVISTREAMINFO;
	alias AVIFILEINFOA AVIFILEINFO;
	alias PAVIFILEINFOA PAVIFILEINFO;
	alias LPAVIFILEINFOA LPAVIFILEINFO;
	alias AVIStreamInfoA AVIStreamInfo;
	alias AVIStreamOpenFromFileA AVIStreamOpenFromFile;
	alias AVIBuildFilterA AVIBuildFilter;
	alias AVISaveVA AVISaveV;
	alias EditStreamSetInfoA EditStreamSetInfo;
	alias EditStreamSetNameA EditStreamSetName;
	alias AVIFileOpenA AVIFileOpen;
	alias AVIFileInfoA AVIFileInfo;
	alias AVIFileCreateStreamA AVIFileCreateStream;
	alias GetOpenFileNamePreviewA GetOpenFileNamePreview;
	alias GetSaveFileNamePreviewA GetSaveFileNamePreview;
	alias MCIWndCreateA MCIWndCreate;
	alias MCIWNDF_NOTIFYMEDIAA MCIWNDF_NOTIFYMEDIA;
	alias MCIWNDM_SENDSTRINGA MCIWNDM_SENDSTRING;
	alias MCIWNDM_GETPOSITIONA MCIWNDM_GETPOSITION;
	alias MCIWNDM_GETMODEA MCIWNDM_GETMODE;
	alias MCIWNDM_SETTIMEFORMATA MCIWNDM_SETTIMEFORMAT;
	alias MCIWNDM_GETTIMEFORMATA MCIWNDM_GETTIMEFORMAT;
	alias MCIWNDM_GETFILENAMEA MCIWNDM_GETFILENAME;
	alias MCIWNDM_GETDEVICEA MCIWNDM_GETDEVICE;
	alias MCIWNDM_GETERRORA MCIWNDM_GETERROR;
	alias MCIWNDM_NEWA MCIWNDM_NEW;
	alias MCIWNDM_RETURNSTRINGA MCIWNDM_RETURNSTRING;
	alias MCIWNDM_OPENA MCIWNDM_OPEN;
}
align:
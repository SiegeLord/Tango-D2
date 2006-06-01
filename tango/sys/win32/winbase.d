/***********************************************************************\
*                               winbase.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/

/**
Translation Notes:
The following macros are obsolete, and have no effect.

LockSegment(w), MakeProcInstance(p,i), UnlockResource(h), UnlockSegment(w)
FreeModule(m), FreeProcInstance(p), GetFreeSpace(w), DefineHandleTable(w)
SetSwapAreaSize(w), LimitEmsPages(n), Yield()

// The following Win16 functions are obselete in Win32.

 int _hread(HFILE,LPVOID,int);
 int _hwrite(HFILE,LPCSTR,int);
 HFILE _lclose(HFILE);
 HFILE _lcreat(LPCSTR,int);
 LONG _llseek(HFILE,LONG,int);
 HFILE _lopen(LPCSTR,int);
 UINT _lread(HFILE,LPVOID,UINT);
 UINT _lwrite(HFILE,LPCSTR,UINT);
 SIZE_T GlobalCompact(DWORD);
 VOID GlobalFix(HGLOBAL);
 UINT GlobalFlags(HGLOBAL);
 VOID GlobalUnfix(HGLOBAL);
 BOOL GlobalUnWire(HGLOBAL);
 PVOID GlobalWire(HGLOBAL);
 SIZE_T LocalCompact(UINT);
 UINT LocalFlags(HLOCAL);
 SIZE_T LocalShrink(HLOCAL,UINT);

// These are not required for DMD.

//FIXME:
// #ifndef UNDER_CE
	int WinMain(HINSTANCE,HINSTANCE,LPSTR,int);
#else
	int WinMain(HINSTANCE,HINSTANCE,LPWSTR,int);
#endif
int wWinMain(HINSTANCE,HINSTANCE,LPWSTR,int);

*/
module win32.winbase;

import win32.winver;
import win32.windef;
private import win32.w32api;
private import win32.winnt;

pragma(lib, "kernel32.lib");

// FIXME: clean up Windows version support
// FIXME:
alias void va_list;


/+
//--------------------------------------
// These functions are problematic

version(UseNtoSKernel){}else {
	/* CAREFUL: These are exported from ntoskrnl.exe and declared in winddk.h
	   as __fastcall functions, but are  exported from kernel32.dll as __stdcall */
	static if (_WIN32_WINNT >= 0x0501) {
	 VOID InitializeSListHead(PSLIST_HEADER);
	}
	LONG InterlockedCompareExchange(LPLONG,LONG,LONG);
	/* PVOID WINAPI InterlockedCompareExchangePointer(PVOID*,PVOID,PVOID); */
	(PVOID)InterlockedCompareExchange((LPLONG)(d)    (PVOID)InterlockedCompareExchange((LPLONG)(d),(LONG)(e),(LONG)(c))
	LONG InterlockedDecrement(LPLONG);
	LONG InterlockedExchange(LPLONG,LONG);
	/* PVOID WINAPI InterlockedExchangePointer(PVOID*,PVOID); */
	(PVOID)InterlockedExchange((LPLONG)(    (PVOID)InterlockedExchange((LPLONG)(t),(LONG)(v))
	LONG InterlockedExchangeAdd(LPLONG,LONG);

	static if (_WIN32_WINNT >= 0x0501) {
	PSLIST_ENTRY InterlockedFlushSList(PSLIST_HEADER);
	}
	LONG InterlockedIncrement(LPLONG);
	static if (_WIN32_WINNT >= 0x0501) {
	PSLIST_ENTRY InterlockedPopEntrySList(PSLIST_HEADER);
	PSLIST_ENTRY InterlockedPushEntrySList(PSLIST_HEADER,PSLIST_ENTRY);
	}
} // #endif /*  __USE_NTOSKRNL__ */
//--------------------------------------
+/

// ----
// COMMPROP structure, used by GetCommProperties()

// Communications provider type
enum : DWORD {
	PST_UNSPECIFIED=0,
	PST_RS232,
	PST_PARALLELPORT,
	PST_RS422,
	PST_RS423,
	PST_RS449,
	PST_MODEM, // =6
	PST_FAX            = 0x21,
	PST_SCANNER        = 0x22,
	PST_NETWORK_BRIDGE = 0x100,
	PST_LAT            = 0x101,
	PST_TCPIP_TELNET   = 0x102,
	PST_X25            = 0x103
}

// Max baud rate
enum : DWORD {
	BAUD_075    = 1,
	BAUD_110    = 2,
	BAUD_134_5  = 4,
	BAUD_150    = 8,
	BAUD_300    = 16,
	BAUD_600    = 32,
	BAUD_1200   = 64,
	BAUD_1800   = 128,
	BAUD_2400   = 256,
	BAUD_4800   = 512,
	BAUD_7200   = 1024,
	BAUD_9600   = 2048,
	BAUD_14400  = 4096,
	BAUD_19200  = 8192,
	BAUD_38400  = 16384,
	BAUD_56K    = 32768,
	BAUD_128K   = 65536,

	BAUD_57600  = 262144,
	BAUD_115200 = 131072,
	BAUD_USER   = 0x10000000
}

// Comm capabilities
enum : DWORD {
	PCF_DTRDSR       = 1,
	PCF_RTSCTS       = 2,
	PCF_RLSD         = 4,
	PCF_PARITY_CHECK = 8,
	PCF_XONXOFF      = 16,
	PCF_SETXCHAR     = 32,
	PCF_TOTALTIMEOUTS= 64,
	PCF_INTTIMEOUTS  = 128,
	PCF_SPECIALCHARS = 256,
	PCF_16BITMODE    = 512
}

enum  : DWORD {
	SP_PARITY       = 1,
	SP_BAUD         = 2,
	SP_DATABITS     = 4,
	SP_STOPBITS     = 8,
	SP_HANDSHAKING  = 16,
	SP_PARITY_CHECK = 32,
	SP_RLSD         = 64
}

enum : DWORD {
	DATABITS_5   = 1,
	DATABITS_6   = 2,
	DATABITS_7   = 4,
	DATABITS_8   = 8,
	DATABITS_16  = 16,
	DATABITS_16X = 32
}

enum : WORD {
	STOPBITS_10  = 1,
	STOPBITS_15  = 2,
	STOPBITS_20  = 4,
	PARITY_NONE  = 256,
	PARITY_ODD   = 512,
	PARITY_EVEN  = 1024,
	PARITY_MARK  = 2048,
	PARITY_SPACE = 4096
}

// used by dwServiceMask
const SP_SERIALCOMM = 1;

struct COMMPROP {
	WORD	wPacketLength;
	WORD	wPacketVersion;
	DWORD	dwServiceMask;
	DWORD	dwReserved1;
	DWORD	dwMaxTxQueue;
	DWORD	dwMaxRxQueue;
	DWORD	dwMaxBaud;
	DWORD	dwProvSubType;
	DWORD	dwProvCapabilities;
	DWORD	dwSettableParams;
	DWORD	dwSettableBaud;
	WORD	wSettableData;
	WORD	wSettableStopParity;
	DWORD	dwCurrentTxQueue;
	DWORD	dwCurrentRxQueue;
	DWORD	dwProvSpec1;
	DWORD	dwProvSpec2;
	WCHAR	wcProvChar[1];
}
alias COMMPROP * LPCOMMPROP;

//-------
// for DEBUG_EVENT
enum : DWORD {
	EXCEPTION_DEBUG_EVENT = 1,
	CREATE_THREAD_DEBUG_EVENT,
	CREATE_PROCESS_DEBUG_EVENT,
	EXIT_THREAD_DEBUG_EVENT,
	EXIT_PROCESS_DEBUG_EVENT,
	LOAD_DLL_DEBUG_EVENT,
	UNLOAD_DLL_DEBUG_EVENT,
	OUTPUT_DEBUG_STRING_EVENT,
	RIP_EVENT
}

const HFILE HFILE_ERROR = cast(HFILE)(-1);

// for SetFilePointer()
enum : DWORD {
	FILE_BEGIN   = 0,
	FILE_CURRENT = 1,
	FILE_END     = 2
}
const DWORD INVALID_SET_FILE_POINTER = -1;


// for OpenFile()
deprecated {
enum : UINT {
	OF_READ      = 0,
	OF_WRITE     = 1,
	OF_READWRITE = 2,
	OF_SHARE_COMPAT     = 0,
	OF_SHARE_DENY_NONE  = 64,
	OF_SHARE_DENY_READ  = 48,
	OF_SHARE_DENY_WRITE = 32,
	OF_SHARE_EXCLUSIVE  = 16,
	OF_PARSE   = 256,
	OF_DELETE  = 512,
	OF_VERIFY  = 1024,
	OF_CANCEL  = 2048,
	OF_CREATE  = 4096,
	OF_PROMPT  = 8192,
	OF_EXIST   = 16384,
	OF_REOPEN  = 32768
}
}

enum : DWORD {
	NMPWAIT_NOWAIT           = 1,
	NMPWAIT_WAIT_FOREVER     = -1,
	NMPWAIT_USE_DEFAULT_WAIT = 0
}

// for ClearCommError()
const DWORD
	CE_RXOVER   = 1,
	CE_OVERRUN  = 2,
	CE_RXPARITY = 4,
	CE_FRAME    = 8,
	CE_BREAK    = 16,
	CE_TXFULL   = 256,
	CE_PTO      = 512,
	CE_IOE      = 1024,
	CE_DNS      = 2048,
	CE_OOP      = 4096,
	CE_MODE     = 32768;

// for CopyProgressRoutine callback.
enum : DWORD {
	PROGRESS_CONTINUE = 0,
	PROGRESS_CANCEL   = 1,
	PROGRESS_STOP     = 2,
	PROGRESS_QUIET    = 3
}

enum : DWORD {
	CALLBACK_CHUNK_FINISHED = 0,
	CALLBACK_STREAM_SWITCH  = 1
}

// CopyFileEx()
enum : DWORD {
	COPY_FILE_FAIL_IF_EXISTS = 1,
	COPY_FILE_RESTARTABLE    = 2
}

enum : DWORD {
	FILE_MAP_COPY       = 1,
	FILE_MAP_WRITE      = 2,
	FILE_MAP_READ       = 4,
	FILE_MAP_ALL_ACCESS = 0xf001f
}

const DWORD
	MUTEX_ALL_ACCESS       = 0x1f0001,
	MUTEX_MODIFY_STATE     = 1,
	SEMAPHORE_ALL_ACCESS   = 0x1f0003,
	SEMAPHORE_MODIFY_STATE = 2,
	EVENT_ALL_ACCESS       = 0x1f0003,
	EVENT_MODIFY_STATE     = 2;

// CreateNamedPipe()
enum : DWORD {
	PIPE_ACCESS_INBOUND  = 1,
	PIPE_ACCESS_OUTBOUND = 2,
	PIPE_ACCESS_DUPLEX   = 3
}

const DWORD 
	PIPE_TYPE_BYTE        = 0,
	PIPE_TYPE_MESSAGE     = 4,
	PIPE_READMODE_BYTE    = 0,
	PIPE_READMODE_MESSAGE = 2,
	PIPE_WAIT             = 0,
	PIPE_NOWAIT          = 1;

// GetNamedPipeInfo()
const DWORD
	PIPE_CLIENT_END  = 0,
	PIPE_SERVER_END  = 1;
	
const DWORD PIPE_UNLIMITED_INSTANCES = 255;

// dwCreationFlags for CreateProcess() and CreateProcessAsUser()
enum : DWORD  {
	DEBUG_PROCESS               = 0x00000001,
	DEBUG_ONLY_THIS_PROCESS     = 0x00000002,
	CREATE_SUSPENDED            = 0x00000004,
	DETACHED_PROCESS            = 0x00000008,
	CREATE_NEW_CONSOLE          = 0x00000010,
	NORMAL_PRIORITY_CLASS       = 0x00000020,
	IDLE_PRIORITY_CLASS         = 0x00000040,
	HIGH_PRIORITY_CLASS         = 0x00000080,
	REALTIME_PRIORITY_CLASS     = 0x00000100,
	CREATE_NEW_PROCESS_GROUP    = 0x00000200,
	CREATE_UNICODE_ENVIRONMENT  = 0x00000400,
	CREATE_SEPARATE_WOW_VDM     = 0x00000800,
	CREATE_SHARED_WOW_VDM       = 0x00001000,
	CREATE_FORCEDOS             = 0x00002000,
	BELOW_NORMAL_PRIORITY_CLASS = 0x00004000,
	ABOVE_NORMAL_PRIORITY_CLASS = 0x00008000,
	CREATE_BREAKAWAY_FROM_JOB   = 0x01000000,
	CREATE_WITH_USERPROFILE     = 0x02000000,
	CREATE_DEFAULT_ERROR_MODE   = 0x04000000,
	CREATE_NO_WINDOW            = 0x08000000,
	PROFILE_USER                = 0x10000000,
	PROFILE_KERNEL              = 0x20000000,
	PROFILE_SERVER              = 0x40000000
}

const CONSOLE_TEXTMODE_BUFFER = 1;

// CreateFile()
enum : DWORD {
	CREATE_NEW = 1,
	CREATE_ALWAYS,
	OPEN_EXISTING,
	OPEN_ALWAYS,
	TRUNCATE_EXISTING
}

// CreateFile()
enum : DWORD {
	FILE_FLAG_WRITE_THROUGH      = 0x80000000,
	FILE_FLAG_OVERLAPPED         = 1073741824,
	FILE_FLAG_NO_BUFFERING       = 536870912,
	FILE_FLAG_RANDOM_ACCESS      = 268435456,
	FILE_FLAG_SEQUENTIAL_SCAN    = 134217728,
	FILE_FLAG_DELETE_ON_CLOSE    = 67108864,
	FILE_FLAG_BACKUP_SEMANTICS   = 33554432,
	FILE_FLAG_POSIX_SEMANTICS    = 16777216,
	FILE_FLAG_OPEN_REPARSE_POINT = 2097152,
	FILE_FLAG_OPEN_NO_RECALL     = 1048576
}

// for CreateFile()
const DWORD
	SECURITY_ANONYMOUS        = (SECURITY_IMPERSONATION_LEVEL.SecurityAnonymous<<16),
	SECURITY_IDENTIFICATION   = (SECURITY_IMPERSONATION_LEVEL.SecurityIdentification<<16),
	SECURITY_IMPERSONATION    = (SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation<<16),
	SECURITY_DELEGATION       = (SECURITY_IMPERSONATION_LEVEL.SecurityDelegation<<16),
	SECURITY_CONTEXT_TRACKING = 0x40000,
	SECURITY_EFFECTIVE_ONLY   = 0x80000,
	SECURITY_SQOS_PRESENT     = 0x100000,
	SECURITY_VALID_SQOS_FLAGS = 0x1F0000;


static if (_WIN32_WINNT >= 0x0500) {
	const FILE_FLAG_FIRST_PIPE_INSTANCE = 524288;
}

const STILL_ACTIVE = 0x103;

const FIND_FIRST_EX_CASE_SENSITIVE = 1;

enum {
	SCS_32BIT_BINARY = 0,
	SCS_DOS_BINARY,
	SCS_WOW_BINARY,
	SCS_PIF_BINARY,
	SCS_POSIX_BINARY,
	SCS_OS216_BINARY
}

const MAX_COMPUTERNAME_LENGTH = 15;

const HW_PROFILE_GUIDLEN = 39;

const MAX_PROFILE_LEN = 80;

enum {
	DOCKINFO_UNDOCKED      = 1,
	DOCKINFO_DOCKED        = 2,
	DOCKINFO_USER_SUPPLIED = 4,
	DOCKINFO_USER_UNDOCKED = DOCKINFO_USER_SUPPLIED | DOCKINFO_UNDOCKED,
	DOCKINFO_USER_DOCKED   = DOCKINFO_USER_SUPPLIED | DOCKINFO_DOCKED
}

enum {
	DRIVE_UNKNOWN = 0,
	DRIVE_NO_ROOT_DIR,
	DRIVE_REMOVABLE,
	DRIVE_FIXED,
	DRIVE_REMOTE,
	DRIVE_CDROM,
	DRIVE_RAMDISK
}

enum {
	FILE_TYPE_UNKNOWN = 0,
	FILE_TYPE_DISK,
	FILE_TYPE_CHAR,
	FILE_TYPE_PIPE,
	FILE_TYPE_REMOTE = 0x8000
}

/* also in ddk/ntapi.h */
const HANDLE_FLAG_INHERIT            = 0x01;
const HANDLE_FLAG_PROTECT_FROM_CLOSE = 0x02;

/* end ntapi.h */
enum : DWORD {
	STD_INPUT_HANDLE  = 0xfffffff6,
	STD_OUTPUT_HANDLE = 0xfffffff5,
	STD_ERROR_HANDLE  = 0xfffffff4
}

const INVALID_HANDLE_VALUE = cast(HANDLE)(-1);

const GET_TAPE_MEDIA_INFORMATION = 0;
const GET_TAPE_DRIVE_INFORMATION = 1;
const SET_TAPE_MEDIA_INFORMATION = 0;
const SET_TAPE_DRIVE_INFORMATION = 1;

// SetThreadPriority()/GetThreadPriority()
const int
	THREAD_PRIORITY_ABOVE_NORMAL  = 1,
	THREAD_PRIORITY_BELOW_NORMAL  = -1,
	THREAD_PRIORITY_HIGHEST       = 2,
	THREAD_PRIORITY_IDLE          = -15,
	THREAD_PRIORITY_LOWEST        = -2,
	THREAD_PRIORITY_NORMAL        = 0,
	THREAD_PRIORITY_TIME_CRITICAL = 15;
	
const int THREAD_PRIORITY_ERROR_RETURN = 2147483647;

const TIME_ZONE_ID_UNKNOWN  = 0;
const TIME_ZONE_ID_STANDARD = 1;
const TIME_ZONE_ID_DAYLIGHT = 2;
const TIME_ZONE_ID_INVALID  = 0xFFFFFFFF;

const FS_CASE_SENSITIVE         = 1;
const FS_CASE_IS_PRESERVED      = 2;
const FS_UNICODE_STORED_ON_DISK = 4;
const FS_PERSISTENT_ACLS        = 8;
const FS_FILE_COMPRESSION       = 16;
const FS_VOL_IS_COMPRESSED      = 32768;

// Flags for GlobalAlloc
enum : SIZE_T {
	GMEM_FIXED    = 0,
	GMEM_MOVEABLE = 2,
	GMEM_ZEROINIT = 64,
	GPTR          = 66,
	// Used only for GlobalRealloc
	GMEM_MODIFY = 128

/+  // Obselete flags (Win16 only)
	GMEM_NOCOMPACT=16;
	GMEM_NODISCARD=32;
	GMEM_DISCARDABLE=256;
	GMEM_NOT_BANKED=4096;
	GMEM_LOWER=4096;
	GMEM_SHARE=8192;
	GMEM_DDESHARE=8192;

	GMEM_LOCKCOUNT=255;
+/
}

// for GlobalFlags().
const GMEM_DISCARDED      = 16384;
const GMEM_INVALID_HANDLE = 32768;

const GMEM_NOTIFY         = 16384;
const GMEM_VALID_FLAGS    = 32626;

const GHND = 64;

const LMEM_FIXED          = 0;
const LMEM_MOVEABLE       = 2;
const LMEM_NONZEROLHND    = 2;
const LMEM_NONZEROLPTR    = 0;
const LMEM_DISCARDABLE    = 3840;
const LMEM_NOCOMPACT      = 16;
const LMEM_NODISCARD      = 32;
const LMEM_ZEROINIT       = 64;
const LMEM_MODIFY         = 128;
const LMEM_LOCKCOUNT      = 255;
const LMEM_DISCARDED      = 16384;
const LMEM_INVALID_HANDLE = 32768;

const LPTR = 64;
const LHND = 66;

const NONZEROLHND = 2;
const NONZEROLPTR = 0;

// used in EXCEPTION_RECORD
enum : DWORD {
	STATUS_WAIT_0           = 0,
	STATUS_ABANDONED_WAIT_0 = 0x80,
	STATUS_USER_APC         = 0xC0,
	STATUS_TIMEOUT          = 0x102,
	STATUS_PENDING          = 0x103,

	STATUS_SEGMENT_NOTIFICATION  = 0x40000005,
	STATUS_GUARD_PAGE_VIOLATION  = 0x80000001,
	STATUS_DATATYPE_MISALIGNMENT = 0x80000002,
	STATUS_BREAKPOINT            = 0x80000003,
	STATUS_SINGLE_STEP           = 0x80000004,

	STATUS_ACCESS_VIOLATION         = 0xC0000005,
	STATUS_IN_PAGE_ERROR            = 0xC0000006,
	STATUS_INVALID_HANDLE           = 0xC0000008,

	STATUS_NO_MEMORY                = 0xC0000017,
	STATUS_ILLEGAL_INSTRUCTION      = 0xC000001D,
	STATUS_NONCONTINUABLE_EXCEPTION = 0xC0000025,
	STATUS_INVALID_DISPOSITION      = 0xC0000026,
	STATUS_ARRAY_BOUNDS_EXCEEDED    = 0xC000008C,
	STATUS_FLOAT_DENORMAL_OPERAND   = 0xC000008D,
	STATUS_FLOAT_DIVIDE_BY_ZERO     = 0xC000008E,
	STATUS_FLOAT_INEXACT_RESULT     = 0xC000008F,
	STATUS_FLOAT_INVALID_OPERATION  = 0xC0000090,
	STATUS_FLOAT_OVERFLOW           = 0xC0000091,
	STATUS_FLOAT_STACK_CHECK        = 0xC0000092,
	STATUS_FLOAT_UNDERFLOW          = 0xC0000093,
	STATUS_INTEGER_DIVIDE_BY_ZERO   = 0xC0000094,
	STATUS_INTEGER_OVERFLOW         = 0xC0000095,
	STATUS_PRIVILEGED_INSTRUCTION   = 0xC0000096,
	STATUS_STACK_OVERFLOW           = 0xC00000FD,
	STATUS_CONTROL_C_EXIT           = 0xC000013A,

	CONTROL_C_EXIT                    = STATUS_CONTROL_C_EXIT,

	EXCEPTION_ACCESS_VIOLATION        = STATUS_ACCESS_VIOLATION,
	EXCEPTION_DATATYPE_MISALIGNMENT   = STATUS_DATATYPE_MISALIGNMENT,
	EXCEPTION_BREAKPOINT              = STATUS_BREAKPOINT,
	EXCEPTION_SINGLE_STEP             = STATUS_SINGLE_STEP,
	EXCEPTION_ARRAY_BOUNDS_EXCEEDED   = STATUS_ARRAY_BOUNDS_EXCEEDED,
	EXCEPTION_FLT_DENORMAL_OPERAND    = STATUS_FLOAT_DENORMAL_OPERAND,
	EXCEPTION_FLT_DIVIDE_BY_ZERO      = STATUS_FLOAT_DIVIDE_BY_ZERO,
	EXCEPTION_FLT_INEXACT_RESULT      = STATUS_FLOAT_INEXACT_RESULT,
	EXCEPTION_FLT_INVALID_OPERATION   = STATUS_FLOAT_INVALID_OPERATION,
	EXCEPTION_FLT_OVERFLOW            = STATUS_FLOAT_OVERFLOW,
	EXCEPTION_FLT_STACK_CHECK         = STATUS_FLOAT_STACK_CHECK,
	EXCEPTION_FLT_UNDERFLOW           = STATUS_FLOAT_UNDERFLOW,
	EXCEPTION_INT_DIVIDE_BY_ZERO      = STATUS_INTEGER_DIVIDE_BY_ZERO,
	EXCEPTION_INT_OVERFLOW            = STATUS_INTEGER_OVERFLOW,
	EXCEPTION_PRIV_INSTRUCTION        = STATUS_PRIVILEGED_INSTRUCTION,
	EXCEPTION_IN_PAGE_ERROR           = STATUS_IN_PAGE_ERROR,
	EXCEPTION_ILLEGAL_INSTRUCTION     = STATUS_ILLEGAL_INSTRUCTION,
	EXCEPTION_NONCONTINUABLE_EXCEPTION = STATUS_NONCONTINUABLE_EXCEPTION,
	EXCEPTION_STACK_OVERFLOW           = STATUS_STACK_OVERFLOW,
	EXCEPTION_INVALID_DISPOSITION      = STATUS_INVALID_DISPOSITION,
	EXCEPTION_GUARD_PAGE               = STATUS_GUARD_PAGE_VIOLATION,
	EXCEPTION_INVALID_HANDLE           = STATUS_INVALID_HANDLE
}

// for PROCESS_HEAP_ENTRY
const WORD
	PROCESS_HEAP_REGION            = 1,
	PROCESS_HEAP_UNCOMMITTED_RANGE = 2,
	PROCESS_HEAP_ENTRY_BUSY        = 4,
	PROCESS_HEAP_ENTRY_MOVEABLE    = 16,
	PROCESS_HEAP_ENTRY_DDESHARE    = 32;

// for LoadLibraryEx()
const DWORD 
	DONT_RESOLVE_DLL_REFERENCES   = 1, // not for WinME and earlier
	LOAD_LIBRARY_AS_DATAFILE      = 2,
	LOAD_WITH_ALTERED_SEARCH_PATH = 8,
	LOAD_IGNORE_CODE_AUTHZ_LEVEL  = 0x10; // only for XP and later

// for LockFile()
const DWORD
	LOCKFILE_FAIL_IMMEDIATELY = 1,
	LOCKFILE_EXCLUSIVE_LOCK   = 2;

// for LogonUser()
enum : DWORD {
	LOGON32_LOGON_INTERACTIVE = 2,
	LOGON32_LOGON_BATCH       = 4,
	LOGON32_LOGON_SERVICE     = 5
	// TODO(D): More values from MSDN
	//LOGON32_LOGON_NETWORK
	//LOGON32_LOGON_NETWORK_CLEARTEXT
	//LOGON32_LOGON_NEW_CREDENTIALS
	//LOGON32_LOGON_UNLOCK
}

// for LogonUser()
enum : DWORD {
	LOGON32_PROVIDER_DEFAULT  = 0,
	LOGON32_PROVIDER_WINNT35  = 1
	//LOGON32_PROVIDER_WINNT40 = ?
	//LOGON32_PROVIDER_WINNT50 = ?
}

// for MoveFileEx()
const DWORD 
	MOVEFILE_REPLACE_EXISTING   = 1,
	MOVEFILE_COPY_ALLOWED       = 2,
	MOVEFILE_DELAY_UNTIL_REBOOT = 4,
	MOVEFILE_WRITE_THROUGH      = 8;

const MAXIMUM_WAIT_OBJECTS  = 64;
const MAXIMUM_SUSPEND_COUNT = 0x7F;

const WAIT_OBJECT_0    = 0;
const WAIT_ABANDONED_0 = 128;

//const WAIT_TIMEOUT=258;  /* also in winerror.h */

enum : DWORD {
	WAIT_IO_COMPLETION = 0xC0,
	WAIT_ABANDONED     = 128,
	WAIT_FAILED        = 0xFFFFFFFF
}

// PurgeComm()
const DWORD
	PURGE_TXABORT = 1,
	PURGE_RXABORT = 2,
	PURGE_TXCLEAR = 4,
	PURGE_RXCLEAR = 8;

// ReadEventLog()
const DWORD 
	EVENTLOG_SEQUENTIAL_READ = 1,
	EVENTLOG_SEEK_READ       = 2,
	EVENTLOG_FORWARDS_READ   = 4,
	EVENTLOG_BACKWARDS_READ  = 8;

// ReportEvent()
enum : WORD {
	EVENTLOG_SUCCESS          = 0,
	EVENTLOG_ERROR_TYPE       = 1,
	EVENTLOG_WARNING_TYPE     = 2,
	EVENTLOG_INFORMATION_TYPE = 4,
	EVENTLOG_AUDIT_SUCCESS    = 8,
	EVENTLOG_AUDIT_FAILURE    = 16
}

// FormatMessage()
const DWORD
	FORMAT_MESSAGE_ALLOCATE_BUFFER = 256,
	FORMAT_MESSAGE_IGNORE_INSERTS  = 512,
	FORMAT_MESSAGE_FROM_STRING     = 1024,
	FORMAT_MESSAGE_FROM_HMODULE    = 2048,
	FORMAT_MESSAGE_FROM_SYSTEM     = 4096,
	FORMAT_MESSAGE_ARGUMENT_ARRAY  = 8192;

const DWORD FORMAT_MESSAGE_MAX_WIDTH_MASK = 255;

/* also in ddk/ntapi.h */
enum {
	SEM_FAILCRITICALERRORS     = 0x0001,
	SEM_NOGPFAULTERRORBOX      = 0x0002,
	SEM_NOALIGNMENTFAULTEXCEPT = 0x0004,
	SEM_NOOPENFILEERRORBOX     = 0x8000
}
/* end ntapi.h */

enum {
	SLE_ERROR = 1,
	SLE_MINORERROR,
	SLE_WARNING
}

const SHUTDOWN_NORETRY = 1;

enum {
	EXCEPTION_EXECUTE_HANDLER    = 1,
	EXCEPTION_CONTINUE_EXECUTION = -1,
	EXCEPTION_CONTINUE_SEARCH    = 0
}

enum  : ATOM {
	MAXINTATOM   = 0xC000,
	INVALID_ATOM = 0
}

const IGNORE = 0;
const INFINITE = 0xFFFFFFFF;

// EscapeCommFunction()
enum {
	SETXOFF = 1,
	SETXON,
	SETRTS,
	CLRRTS,
	SETDTR,
	CLRDTR, // =6
	SETBREAK = 8,
	CLRBREAK = 9
}


// for SetCommMask()
const DWORD
	EV_RXCHAR   = 1,
	EV_RXFLAG   = 2,
	EV_TXEMPTY  = 4,
	EV_CTS      = 8,
	EV_DSR      = 16,
	EV_RLSD     = 32,
	EV_BREAK    = 64,
	EV_ERR      = 128,
	EV_RING     = 256,
	EV_PERR     = 512,
	EV_RX80FULL = 1024,
	EV_EVENT1   = 2048,
	EV_EVENT2   = 4096;

// GetCommModemStatus()
const DWORD 
	MS_CTS_ON  = 16,
	MS_DSR_ON  = 32,
	MS_RING_ON = 64,
	MS_RLSD_ON = 128;


// DCB
enum : BYTE {
	NOPARITY = 0,
	ODDPARITY,
	EVENPARITY,
	MARKPARITY,
	SPACEPARITY
}
// DCB
enum : BYTE {
	ONESTOPBIT = 0,
	ONE5STOPBITS,
	TWOSTOPBITS
}
// DCB
enum : DWORD {
	CBR_110    = 110,
	CBR_300    = 300,
	CBR_600    = 600,
	CBR_1200   = 1200,
	CBR_2400   = 2400,
	CBR_4800   = 4800,
	CBR_9600   = 9600,
	CBR_14400  = 14400,
	CBR_19200  = 19200,
	CBR_38400  = 38400,
	CBR_56000  = 56000,
	CBR_57600  = 57600,
	CBR_115200 = 115200,
	CBR_128000 = 128000,
	CBR_256000 = 256000
}
// DCB, 2-bit bitfield
enum {
	DTR_CONTROL_DISABLE = 0,
	DTR_CONTROL_ENABLE,
	DTR_CONTROL_HANDSHAKE
}

// DCB, 2-bit bitfield
enum {
	RTS_CONTROL_DISABLE = 0,
	RTS_CONTROL_ENABLE,
	RTS_CONTROL_HANDSHAKE,
	RTS_CONTROL_TOGGLE,
}

// WIN32_STREAM_ID
enum : DWORD {
	BACKUP_INVALID = 0,
	BACKUP_DATA,
	BACKUP_EA_DATA,
	BACKUP_SECURITY_DATA,
	BACKUP_ALTERNATE_DATA,
	BACKUP_LINK,
	BACKUP_PROPERTY_DATA,
	BACKUP_OBJECT_ID,
	BACKUP_REPARSE_DATA,
	BACKUP_SPARSE_BLOCK
}

// WIN32_STREAM_ID
enum : DWORD {
	STREAM_NORMAL_ATTRIBUTE    = 0,
	STREAM_MODIFIED_WHEN_READ  = 1,
	STREAM_CONTAINS_SECURITY   = 2,
	STREAM_CONTAINS_PROPERTIES = 4
}

// STARTUPINFO
const DWORD
	STARTF_USESHOWWINDOW    = 1,
	STARTF_USESIZE          = 2,
	STARTF_USEPOSITION      = 4,
	STARTF_USECOUNTCHARS    = 8,
	STARTF_USEFILLATTRIBUTE = 16,
	STARTF_RUNFULLSCREEN    = 32,
	STARTF_FORCEONFEEDBACK  = 64,
	STARTF_FORCEOFFFEEDBACK = 128,
	STARTF_USESTDHANDLES    = 256,
	STARTF_USEHOTKEY        = 512;

enum {
	TC_NORMAL  = 0,
	TC_HARDERR = 1,
	TC_GP_TRAP = 2,
	TC_SIGNAL  = 3
}

enum {
	AC_LINE_OFFLINE      = 0,
	AC_LINE_ONLINE       = 1,
	AC_LINE_BACKUP_POWER = 2,
	AC_LINE_UNKNOWN      = 255
}

enum {
	BATTERY_FLAG_HIGH          = 1,
	BATTERY_FLAG_LOW           = 2,
	BATTERY_FLAG_CRITICAL      = 4,
	BATTERY_FLAG_CHARGING      = 8,
	BATTERY_FLAG_NO_BATTERY    = 128,
	BATTERY_FLAG_UNKNOWN       = 255,
	BATTERY_PERCENTAGE_UNKNOWN = 255,
	BATTERY_LIFE_UNKNOWN       = 0xFFFFFFFF
}

// DefineDosDevice
const DWORD
	DDD_RAW_TARGET_PATH       = 1,
	DDD_REMOVE_DEFINITION     = 2,
	DDD_EXACT_MATCH_ON_REMOVE = 4;

const HINSTANCE_ERROR = 32;

const INVALID_FILE_SIZE = 0xFFFFFFFF;

const DWORD TLS_OUT_OF_INDEXES = 0xFFFFFFFF;

static if (_WIN32_WINNT >= 0x0501) {
	// for ACTCTX
	const DWORD
		ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID = 0x00000001,
		ACTCTX_FLAG_LANGID_VALID                 = 0x00000002,
		ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID     = 0x00000004,
		ACTCTX_FLAG_RESOURCE_NAME_VALID          = 0x00000008,
		ACTCTX_FLAG_SET_PROCESS_DEFAULT          = 0x00000010,
		ACTCTX_FLAG_APPLICATION_NAME_VALID       = 0x00000020,
		ACTCTX_FLAG_HMODULE_VALID                = 0x00000080;

	// DeactivateActCtx()
	const DWORD DEACTIVATE_ACTCTX_FLAG_FORCE_EARLY_DEACTIVATION = 0x00000001;
	// FindActCtxSectionString()
	const DWORD FIND_ACTCTX_SECTION_KEY_RETURN_HACTCTX          = 0x00000001;
	// QueryActCtxW()
	const DWORD
		QUERY_ACTCTX_FLAG_USE_ACTIVE_ACTCTX             = 0x00000004,
		QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE             = 0x00000008,
		QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS             = 0x00000010;
}

static if (_WIN32_WINNT >= 0x0500) {
	const REPLACEFILE_WRITE_THROUGH       = 0x00000001;
	const REPLACEFILE_IGNORE_MERGE_ERRORS = 0x00000002;
}

const WRITE_WATCH_FLAG_RESET = 1;

struct FILETIME {
	DWORD dwLowDateTime;
	DWORD dwHighDateTime;
}
alias FILETIME* PFILETIME, LPFILETIME;

struct BY_HANDLE_FILE_INFORMATION {
	DWORD	dwFileAttributes;
	FILETIME	ftCreationTime;
	FILETIME	ftLastAccessTime;
	FILETIME	ftLastWriteTime;
	DWORD	dwVolumeSerialNumber;
	DWORD	nFileSizeHigh;
	DWORD	nFileSizeLow;
	DWORD	nNumberOfLinks;
	DWORD	nFileIndexHigh;
	DWORD	nFileIndexLow;
}
alias BY_HANDLE_FILE_INFORMATION* LPBY_HANDLE_FILE_INFORMATION;

struct DCB {
	DWORD DCBlength = DCB.sizeof;
	DWORD BaudRate;
/+
	DWORD fBinary:1;              /* Binary Mode (skip EOF check)    */
	DWORD fParity:1;              /* Enable parity checking          */
	DWORD fOutxCtsFlow:1;         /* CTS handshaking on output       */
	DWORD fOutxDsrFlow:1;         /* DSR handshaking on output       */
	DWORD fDtrControl:2;          /* DTR Flow control                */
	DWORD fDsrSensitivity:1;      /* DSR Sensitivity              */
	DWORD fTXContinueOnXoff:1;    /* Continue TX when Xoff sent */
	DWORD fOutX:1;                /* Enable output X-ON/X-OFF        */
	DWORD fInX:1;                 /* Enable input X-ON/X-OFF         */
	DWORD fErrorChar:1;           /* Enable Err Replacement          */
	DWORD fNull:1;                /* Enable Null stripping           */
	DWORD fRtsControl:2;          /* Rts Flow control                */
	DWORD fAbortOnError:1;        /* Abort all reads and writes on Error */
	DWORD fDummy2:17;             /* Reserved                        */
+/
	uint _bf;
	void fBinary(bool f)         { _bf = (_bf & ~1) | f; }
	void fParity(bool f)         { _bf = (_bf & ~2) | (f<<1); }
	void fOutxCtsFlow(bool f)    { _bf = (_bf & ~4)| (f<<2); }
	void fOutxDsrFlow(bool f)    { _bf = (_bf & ~8) | (f<<3);}
	void fDtrControl(byte x)     { _bf = (_bf & ~(32+16)) | (x<<4); }
	void fDsrSensitivity(bool f) { _bf = (_bf & ~64) | (f<<6); }
	void fTXContinueOnXoff(bool f) { _bf = (_bf & ~128) | (f<<7); }
	void fOutX(bool f)           { _bf = (_bf & ~256) | (f<<8); }
	void fInX(bool f)            { _bf = (_bf & ~512) | (f<<9); }
	void fErrorChar(bool f)      { _bf = (_bf & ~1024) | (f<<10); }
	void fNull(bool f)           { _bf = (_bf & ~2048) | (f<<11); }
	void fRtsControl(byte x)     { _bf = (_bf & ~(4096+8192)) | (x<<12); }
	void fAbortOnError(bool f)   { _bf = (_bf & ~16384) | (f<<14); }

	bool fBinary()         { return cast(bool) (_bf & 1); }
	bool fParity()         { return cast(bool) (_bf & 2); }
	bool fOutxCtsFlow()    { return cast(bool) (_bf & 4); }
	bool fOutxDsrFlow()    { return cast(bool) (_bf & 8); }
	byte fDtrControl()     { return (_bf & (32+16))>>4; }
	bool fDsrSensitivity() { return cast(bool) (_bf & 64); }
	bool fTXContinueOnXoff() { return cast(bool) (_bf & 128); }
	bool fOutX()           { return cast(bool) (_bf & 256); }
	bool fInX()            { return cast(bool) (_bf & 512); }
	bool fErrorChar()      { return cast(bool) (_bf & 1024); }
	bool fNull()           { return cast(bool) (_bf & 2048); }
	byte fRtsControl()     { return (_bf & (4096+8192))>>12; }
	bool fAbortOnError()   { return cast(bool) (_bf & 16384); }

	WORD wReserved;
	WORD XonLim;
	WORD XoffLim;
	BYTE ByteSize;
	BYTE Parity;
	BYTE StopBits;
	char XonChar;
	char XoffChar;
	char ErrorChar;
	char EofChar;
	char EvtChar;
	WORD wReserved1;
}
alias DCB * LPDCB;

struct COMMCONFIG {
	DWORD dwSize;
	WORD  wVersion;
	WORD  wReserved;
	DCB   dcb;
	DWORD dwProviderSubType;
	DWORD dwProviderOffset;
	DWORD dwProviderSize;
	WCHAR wcProviderData[1];
}
alias COMMCONFIG * LPCOMMCONFIG;

struct COMMTIMEOUTS{
	DWORD ReadIntervalTimeout;
	DWORD ReadTotalTimeoutMultiplier;
	DWORD ReadTotalTimeoutConstant;
	DWORD WriteTotalTimeoutMultiplier;
	DWORD WriteTotalTimeoutConstant;
}
alias COMMTIMEOUTS * LPCOMMTIMEOUTS;

struct COMSTAT{
/+
	DWORD fCtsHold:1;
	DWORD fDsrHold:1;
	DWORD fRlsdHold:1;
	DWORD fXoffHold:1;
	DWORD fXoffSent:1;
	DWORD fEof:1;
	DWORD fTxim:1;
	DWORD fReserved:25;
+/
	DWORD _bf;
    void fCtsHold(bool f)  { _bf = (_bf & ~1) | f ; }
	void fDsrHold(bool f)  { _bf = (_bf & ~2) | (f<<1); }
	void fRlsdHold(bool f) { _bf = (_bf & ~4) | (f<<2); }
	void fXoffHold(bool f) { _bf = (_bf & ~8) | (f<<3); }
	void fXoffSent(bool f) { _bf = (_bf & ~16) | (f<<4); }
	void fEof(bool f)      { _bf = (_bf & ~32) | (f<<5); }
	void fTxim(bool f)     { _bf = (_bf & ~64) | (f<<6); }

    bool fCtsHold()  { return cast(bool) (_bf & 1); }
	bool fDsrHold()  { return cast(bool) (_bf & 2); }
	bool fRlsdHold() { return cast(bool) (_bf & 4); }
	bool fXoffHold() { return cast(bool) (_bf & 8); }
	bool fXoffSent() { return cast(bool) (_bf & 16); }
	bool fEof()      { return cast(bool) (_bf & 32); }
	bool fTxim()     { return cast(bool) (_bf & 64); }

	DWORD cbInQue;
	DWORD cbOutQue;
}
alias COMSTAT * LPCOMSTAT;

struct CREATE_PROCESS_DEBUG_INFO{
	HANDLE hFile;
	HANDLE hProcess;
	HANDLE hThread;
	LPVOID lpBaseOfImage;
	DWORD dwDebugInfoFileOffset;
	DWORD nDebugInfoSize;
	LPVOID lpThreadLocalBase;
	LPTHREAD_START_ROUTINE lpStartAddress;
	LPVOID lpImageName;
	WORD fUnicode;
}
alias CREATE_PROCESS_DEBUG_INFO * LPCREATE_PROCESS_DEBUG_INFO;

struct CREATE_THREAD_DEBUG_INFO{
	HANDLE hThread;
	LPVOID lpThreadLocalBase;
	LPTHREAD_START_ROUTINE lpStartAddress;
}
alias CREATE_THREAD_DEBUG_INFO * LPCREATE_THREAD_DEBUG_INFO;

struct EXCEPTION_DEBUG_INFO{
	EXCEPTION_RECORD ExceptionRecord;
	DWORD dwFirstChance;
}
alias EXCEPTION_DEBUG_INFO * LPEXCEPTION_DEBUG_INFO;

struct EXIT_THREAD_DEBUG_INFO{
	DWORD dwExitCode;
}
alias EXIT_THREAD_DEBUG_INFO * LPEXIT_THREAD_DEBUG_INFO;

struct EXIT_PROCESS_DEBUG_INFO{
	DWORD dwExitCode;
}
alias EXIT_PROCESS_DEBUG_INFO *LPEXIT_PROCESS_DEBUG_INFO;

struct LOAD_DLL_DEBUG_INFO{
	HANDLE hFile;
	LPVOID lpBaseOfDll;
	DWORD dwDebugInfoFileOffset;
	DWORD nDebugInfoSize;
	LPVOID lpImageName;
	WORD fUnicode;
}
alias LOAD_DLL_DEBUG_INFO *LPLOAD_DLL_DEBUG_INFO;

struct UNLOAD_DLL_DEBUG_INFO{
	LPVOID lpBaseOfDll;
}
alias UNLOAD_DLL_DEBUG_INFO * LPUNLOAD_DLL_DEBUG_INFO;

struct OUTPUT_DEBUG_STRING_INFO{
	LPSTR lpDebugStringData;
	WORD fUnicode;
	WORD nDebugStringLength;
}
alias OUTPUT_DEBUG_STRING_INFO * LPOUTPUT_DEBUG_STRING_INFO;

struct RIP_INFO{
	DWORD dwError;
	DWORD dwType;
}
alias RIP_INFO * LPRIP_INFO;

struct DEBUG_EVENT{
	DWORD dwDebugEventCode;
	DWORD dwProcessId;
	DWORD dwThreadId;
	union {
		EXCEPTION_DEBUG_INFO Exception;
		CREATE_THREAD_DEBUG_INFO CreateThread;
		CREATE_PROCESS_DEBUG_INFO CreateProcessInfo;
		EXIT_THREAD_DEBUG_INFO ExitThread;
		EXIT_PROCESS_DEBUG_INFO ExitProcess;
		LOAD_DLL_DEBUG_INFO LoadDll;
		UNLOAD_DLL_DEBUG_INFO UnloadDll;
		OUTPUT_DEBUG_STRING_INFO DebugString;
		RIP_INFO RipInfo;
	}
}
alias DEBUG_EVENT *LPDEBUG_EVENT;

struct OVERLAPPED{
	DWORD Internal;
	DWORD InternalHigh;
	DWORD Offset;
	DWORD OffsetHigh;
	HANDLE hEvent;
}
alias OVERLAPPED * POVERLAPPED, LPOVERLAPPED;

struct STARTUPINFOA{
	DWORD	cb;
	LPSTR	lpReserved;
	LPSTR	lpDesktop;
	LPSTR	lpTitle;
	DWORD	dwX;
	DWORD	dwY;
	DWORD	dwXSize;
	DWORD	dwYSize;
	DWORD	dwXCountChars;
	DWORD	dwYCountChars;
	DWORD	dwFillAttribute;
	DWORD	dwFlags;
	WORD	wShowWindow;
	WORD	cbReserved2;
	PBYTE	lpReserved2;
	HANDLE	hStdInput;
	HANDLE	hStdOutput;
	HANDLE	hStdError;
}
alias STARTUPINFOA * LPSTARTUPINFOA;

struct STARTUPINFOW{
	DWORD	cb;
	LPWSTR	lpReserved;
	LPWSTR	lpDesktop;
	LPWSTR	lpTitle;
	DWORD	dwX;
	DWORD	dwY;
	DWORD	dwXSize;
	DWORD	dwYSize;
	DWORD	dwXCountChars;
	DWORD	dwYCountChars;
	DWORD	dwFillAttribute;
	DWORD	dwFlags;
	WORD	wShowWindow;
	WORD	cbReserved2;
	PBYTE	lpReserved2;
	HANDLE	hStdInput;
	HANDLE	hStdOutput;
	HANDLE	hStdError;
}
alias STARTUPINFOW* LPSTARTUPINFOW;

struct PROCESS_INFORMATION{
	HANDLE hProcess;
	HANDLE hThread;
	DWORD dwProcessId;
	DWORD dwThreadId;
}
alias PROCESS_INFORMATION* PPROCESS_INFORMATION, LPPROCESS_INFORMATION;

struct CRITICAL_SECTION_DEBUG{
	WORD Type;
	WORD CreatorBackTraceIndex;
	CRITICAL_SECTION *CriticalSection;
	LIST_ENTRY ProcessLocksList;
	DWORD EntryCount;
	DWORD ContentionCount;
	DWORD Spare [2];
}
alias CRITICAL_SECTION_DEBUG * PCRITICAL_SECTION_DEBUG;

struct CRITICAL_SECTION{
	PCRITICAL_SECTION_DEBUG DebugInfo;
	LONG LockCount;
	LONG RecursionCount;
	HANDLE OwningThread;
	HANDLE LockSemaphore;
	DWORD SpinCount;
}
alias CRITICAL_SECTION * PCRITICAL_SECTION, LPCRITICAL_SECTION;

struct SYSTEMTIME{
	WORD wYear;
	WORD wMonth;
	WORD wDayOfWeek;
	WORD wDay;
	WORD wHour;
	WORD wMinute;
	WORD wSecond;
	WORD wMilliseconds;
}
alias SYSTEMTIME * LPSYSTEMTIME;

struct WIN32_FILE_ATTRIBUTE_DATA{
	DWORD	dwFileAttributes;
	FILETIME	ftCreationTime;
	FILETIME	ftLastAccessTime;
	FILETIME	ftLastWriteTime;
	DWORD	nFileSizeHigh;
	DWORD	nFileSizeLow;
}
alias WIN32_FILE_ATTRIBUTE_DATA * LPWIN32_FILE_ATTRIBUTE_DATA;

struct WIN32_FIND_DATAA{
	DWORD dwFileAttributes;
	FILETIME ftCreationTime;
	FILETIME ftLastAccessTime;
	FILETIME ftLastWriteTime;
	DWORD nFileSizeHigh;
	DWORD nFileSizeLow;
	DWORD dwReserved0;
	DWORD dwReserved1;
	CHAR cFileName[MAX_PATH];
	CHAR cAlternateFileName[14];
}
alias WIN32_FIND_DATAA * PWIN32_FIND_DATAA, LPWIN32_FIND_DATAA;

struct WIN32_FIND_DATAW{
	DWORD dwFileAttributes;
	FILETIME ftCreationTime;
	FILETIME ftLastAccessTime;
	FILETIME ftLastWriteTime;
	DWORD nFileSizeHigh;
	DWORD nFileSizeLow;
	DWORD dwReserved0;
	DWORD dwReserved1;
	WCHAR cFileName[MAX_PATH];
	WCHAR cAlternateFileName[14];
}
alias WIN32_FIND_DATAW * PWIN32_FIND_DATAW, LPWIN32_FIND_DATAW;

struct WIN32_STREAM_ID{
	DWORD dwStreamId;
	DWORD dwStreamAttributes;
	LARGE_INTEGER Size;
	DWORD dwStreamNameSize;
	WCHAR cStreamName[ANYSIZE_ARRAY];
}
alias WIN32_STREAM_ID *LPWIN32_STREAM_ID;

enum FINDEX_INFO_LEVELS{
	FindExInfoStandard,
	FindExInfoMaxInfoLevel
}

enum FINDEX_SEARCH_OPS{
	FindExSearchNameMatch,
	FindExSearchLimitToDirectories,
	FindExSearchLimitToDevices,
	FindExSearchMaxSearchOp
}

enum ACL_INFORMATION_CLASS{
	AclRevisionInformation=1,
	AclSizeInformation
}

struct HW_PROFILE_INFOA{
	DWORD dwDockInfo;
	CHAR szHwProfileGuid[HW_PROFILE_GUIDLEN];
	CHAR szHwProfileName[MAX_PROFILE_LEN];
}
alias HW_PROFILE_INFOA * LPHW_PROFILE_INFOA;

struct HW_PROFILE_INFOW{
	DWORD dwDockInfo;
	WCHAR szHwProfileGuid[HW_PROFILE_GUIDLEN];
	WCHAR szHwProfileName[MAX_PROFILE_LEN];
}
alias HW_PROFILE_INFOW * LPHW_PROFILE_INFOW;

enum GET_FILEEX_INFO_LEVELS{
	GetFileExInfoStandard,
	GetFileExMaxInfoLevel
}

struct SYSTEM_INFO{
	union {
		DWORD dwOemId;
		struct {
			WORD wProcessorArchitecture;
			WORD wReserved;
		}
	}
	DWORD dwPageSize;
	PVOID lpMinimumApplicationAddress;
	PVOID lpMaximumApplicationAddress;
	DWORD dwActiveProcessorMask;
	DWORD dwNumberOfProcessors;
	DWORD dwProcessorType;
	DWORD dwAllocationGranularity;
	WORD wProcessorLevel;
	WORD wProcessorRevision;
}
alias SYSTEM_INFO *LPSYSTEM_INFO;

struct SYSTEM_POWER_STATUS{
	BYTE ACLineStatus;
	BYTE BatteryFlag;
	BYTE BatteryLifePercent;
	BYTE Reserved1;
	DWORD BatteryLifeTime;
	DWORD BatteryFullLifeTime;
}
alias SYSTEM_POWER_STATUS *LPSYSTEM_POWER_STATUS;

struct TIME_ZONE_INFORMATION{
	LONG Bias;
	WCHAR StandardName[32];
	SYSTEMTIME StandardDate;
	LONG StandardBias;
	WCHAR DaylightName[32];
	SYSTEMTIME DaylightDate;
	LONG DaylightBias;
}
alias TIME_ZONE_INFORMATION *LPTIME_ZONE_INFORMATION;

struct MEMORYSTATUS{
	DWORD dwLength;
	DWORD dwMemoryLoad;
	DWORD dwTotalPhys;
	DWORD dwAvailPhys;
	DWORD dwTotalPageFile;
	DWORD dwAvailPageFile;
	DWORD dwTotalVirtual;
	DWORD dwAvailVirtual;
}
alias MEMORYSTATUS *LPMEMORYSTATUS;

static if (_WIN32_WINNT >= 0x0500) {
	struct MEMORYSTATUSEX{
		DWORD dwLength;
		DWORD dwMemoryLoad;
		DWORDLONG ullTotalPhys;
		DWORDLONG ullAvailPhys;
		DWORDLONG ullTotalPageFile;
		DWORDLONG ullAvailPageFile;
		DWORDLONG ullTotalVirtual;
		DWORDLONG ullAvailVirtual;
		DWORDLONG ullAvailExtendedVirtual;
	}
	alias MEMORYSTATUSEX *LPMEMORYSTATUSEX;
}

struct LDT_ENTRY{
	WORD LimitLow;
	WORD BaseLow;
	struct {
		BYTE BaseMid;
		BYTE Flags1;
		BYTE Flags2;
		BYTE BaseHi;

		void Type(byte f)  { Flags1 = (Flags1 & 0xE0) | f; }
		void Dpl(byte f)   { Flags1 = (Flags1 & 0x9F) | (f<<5); }
		void Pres(bool f)  { Flags1 = (Flags1 & 0x7F) | (f<<7); }

		void LimitHi(byte f) { Flags2 = (Flags2 & 0xF0) | (f&0x0F); }
		void Sys(bool f)     { Flags2 = (Flags2 & 0xEF) | (f<<4); }
		// Next bit is reserved
		void Default_Big(bool f) { Flags2 = (Flags2 & 0xBF) | (f<<6); }
		void Granularity(bool f)  { Flags2 = (Flags2 & 0x7F) | (f<<7); }

		byte Type()  { return (Flags1 & 0x1F); }
		byte Dpl()   { return (Flags1 & 0x60)>>5; }
		bool Pres()  {  return cast(bool) (Flags1 & 0x80); }

		byte LimitHi() { return (Flags2 & 0x0F); }
		bool Sys() { return cast(bool) (Flags2 & 0x10); }
		bool Default_Big() { return cast(bool) (Flags2 & 0x40); }
		bool Granularity() { return cast(bool) (Flags2 & 0x80); }
	}
/+
	union  HighWord {
		struct Bytes {
			BYTE BaseMid;
			BYTE Flags1;
			BYTE Flags2;
			BYTE BaseHi;
		}
	struct Bits {
		DWORD BaseMid:8;
		DWORD Type:5;
		DWORD Dpl:2;
		DWORD Pres:1;
		DWORD LimitHi:4;
		DWORD Sys:1;
		DWORD Reserved_0:1;
		DWORD Default_Big:1;
		DWORD Granularity:1;
		DWORD BaseHi:8;
	}
	}
+/
}
alias LDT_ENTRY * PLDT_ENTRY, LPLDT_ENTRY;

struct PROCESS_HEAP_ENTRY{
	PVOID lpData;
	DWORD cbData;
	BYTE cbOverhead;
	BYTE iRegionIndex;
	WORD wFlags;
	union {
		struct Block {
			HANDLE hMem;
			DWORD dwReserved[3];
		}
		struct Region {
			DWORD dwCommittedSize;
			DWORD dwUnCommittedSize;
			LPVOID lpFirstBlock;
			LPVOID lpLastBlock;
		}
	}
}
alias PROCESS_HEAP_ENTRY * LPPROCESS_HEAP_ENTRY;

deprecated {

struct OFSTRUCT{
	BYTE cBytes;
	BYTE fFixedDisk;
	WORD nErrCode;
	WORD Reserved1;
	WORD Reserved2;
	CHAR szPathName[128]; // const OFS_MAXPATHNAME = 128;
}
alias OFSTRUCT * LPOFSTRUCT, POFSTRUCT;

}

struct WIN_CERTIFICATE{
	DWORD dwLength;
	WORD wRevision;
	WORD wCertificateType;
	BYTE bCertificate[1];
}
alias WIN_CERTIFICATE * LPWIN_CERTIFICATE;

static if (_WIN32_WINNT >= 0x0500) {	
	enum COMPUTER_NAME_FORMAT{
		ComputerNameNetBIOS,
		ComputerNameDnsHostname,
		ComputerNameDnsDomain,
		ComputerNameDnsFullyQualified,
		ComputerNamePhysicalNetBIOS,
		ComputerNamePhysicalDnsHostname,
		ComputerNamePhysicalDnsDomain,
		ComputerNamePhysicalDnsFullyQualified,
		ComputerNameMax
	}
	
}

static if (_WIN32_WINNT >= 0x0501) {
	
	struct ACTCTXA{
		ULONG cbSize;
		DWORD dwFlags;
		LPCSTR lpSource;
		USHORT wProcessorArchitecture;
		LANGID wLangId;
		LPCSTR lpAssemblyDirectory;
		LPCSTR lpResourceName;
		LPCSTR lpApplicationName;
		HMODULE hModule;
	}
	alias  ACTCTXA *PACTCTXA, PCACTCTXA;
	
	struct ACTCTXW{
		ULONG cbSize;
		DWORD dwFlags;
		LPCWSTR lpSource;
		USHORT wProcessorArchitecture;
		LANGID wLangId;
		LPCWSTR lpAssemblyDirectory;
		LPCWSTR lpResourceName;
		LPCWSTR lpApplicationName;
		HMODULE hModule;
	}
	alias ACTCTXW *PACTCTXW, PCACTCTXW;
	
	struct ACTCTX_SECTION_KEYED_DATA{
		ULONG cbSize;
		ULONG ulDataFormatVersion;
		PVOID lpData;
		ULONG ulLength;
		PVOID lpSectionGlobalData;
		ULONG ulSectionGlobalDataLength;
		PVOID lpSectionBase;
		ULONG ulSectionTotalLength;
		HANDLE hActCtx;
		HANDLE ulAssemblyRosterIndex;
	}
	alias ACTCTX_SECTION_KEYED_DATA * PACTCTX_SECTION_KEYED_DATA, PCACTCTX_SECTION_KEYED_DATA;
	
	enum MEMORY_RESOURCE_NOTIFICATION_TYPE {
		LowMemoryResourceNotification,
		HighMemoryResourceNotification
	}
	
}/* (_WIN32_WINNT >= 0x0501) */

static if ((_WIN32_WINNT >= 0x0500) || (_WIN32_WINDOWS >= 0x0410)) {
	alias DWORD EXECUTION_STATE;
}

// Callbacks
extern(Windows) {
	alias DWORD function (LPVOID) LPTHREAD_START_ROUTINE;
	alias DWORD function (LARGE_INTEGER, LARGE_INTEGER, LARGE_INTEGER, LARGE_INTEGER,
		DWORD,DWORD,HANDLE,HANDLE,LPVOID)  LPPROGRESS_ROUTINE;
	alias void function(PVOID) LPFIBER_START_ROUTINE;

	alias BOOL function (HMODULE,LPCTSTR,LPCTSTR,WORD,LONG) ENUMRESLANGPROC;
	alias BOOL function (HMODULE,LPCTSTR,LPTSTR,LONG) ENUMRESNAMEPROC;
	alias BOOL function (HMODULE,LPTSTR,LONG) ENUMRESTYPEPROC;
	alias void function (DWORD,DWORD,LPOVERLAPPED) LPOVERLAPPED_COMPLETION_ROUTINE;
	alias LONG function (LPEXCEPTION_POINTERS) PTOP_LEVEL_EXCEPTION_FILTER;
	alias PTOP_LEVEL_EXCEPTION_FILTER LPTOP_LEVEL_EXCEPTION_FILTER;

	alias void function (DWORD) PAPCFUNC;
	alias void function (PVOID,DWORD,DWORD) PTIMERAPCROUTINE;

	static if (_WIN32_WINNT >= 0x0500) {
		alias void function (PVOID,BOOLEAN) WAITORTIMERCALLBACK;
	}
}

LPTSTR MAKEINTATOM(short i) {
	return cast(LPTSTR)(i);
}

extern (Windows) {

 BOOL AccessCheck(PSECURITY_DESCRIPTOR,HANDLE,DWORD,PGENERIC_MAPPING,PPRIVILEGE_SET,PDWORD,PDWORD,PBOOL);
 BOOL AccessCheckAndAuditAlarmA(LPCSTR,LPVOID,LPSTR,LPSTR,PSECURITY_DESCRIPTOR,DWORD,PGENERIC_MAPPING,BOOL,PDWORD,PBOOL,PBOOL);
 BOOL AccessCheckAndAuditAlarmW(LPCWSTR,LPVOID,LPWSTR,LPWSTR,PSECURITY_DESCRIPTOR,DWORD,PGENERIC_MAPPING,BOOL,PDWORD,PBOOL,PBOOL);
 BOOL AddAccessAllowedAce(PACL,DWORD,DWORD,PSID);
 BOOL AddAccessDeniedAce(PACL,DWORD,DWORD,PSID);
 BOOL AddAce(PACL,DWORD,DWORD,PVOID,DWORD);
 ATOM AddAtomA(LPCSTR);
 ATOM AddAtomW(LPCWSTR);
 BOOL AddAuditAccessAce(PACL,DWORD,DWORD,PSID,BOOL,BOOL);
 BOOL AdjustTokenGroups(HANDLE,BOOL,PTOKEN_GROUPS,DWORD,PTOKEN_GROUPS,PDWORD);
 BOOL AdjustTokenPrivileges(HANDLE,BOOL,PTOKEN_PRIVILEGES,DWORD,PTOKEN_PRIVILEGES,PDWORD);
 BOOL AllocateAndInitializeSid(PSID_IDENTIFIER_AUTHORITY,BYTE,DWORD,DWORD,DWORD,DWORD,DWORD,DWORD,DWORD,DWORD,PSID*);
 BOOL AllocateLocallyUniqueId(PLUID);
 BOOL AreAllAccessesGranted(DWORD,DWORD);
 BOOL AreAnyAccessesGranted(DWORD,DWORD);
 BOOL AreFileApisANSI();
 BOOL BackupEventLogA(HANDLE,LPCSTR);
 BOOL BackupEventLogW(HANDLE,LPCWSTR);
 BOOL BackupRead(HANDLE,LPBYTE,DWORD,LPDWORD,BOOL,BOOL,LPVOID*);
 BOOL BackupSeek(HANDLE,DWORD,DWORD,LPDWORD,LPDWORD,LPVOID*);
 BOOL BackupWrite(HANDLE,LPBYTE,DWORD,LPDWORD,BOOL,BOOL,LPVOID*);
 BOOL Beep(DWORD,DWORD);
 HANDLE BeginUpdateResourceA(LPCSTR,BOOL);
 HANDLE BeginUpdateResourceW(LPCWSTR,BOOL);
 BOOL BuildCommDCBA(LPCSTR,LPDCB);
 BOOL BuildCommDCBW(LPCWSTR,LPDCB);
 BOOL BuildCommDCBAndTimeoutsA(LPCSTR,LPDCB,LPCOMMTIMEOUTS);
 BOOL BuildCommDCBAndTimeoutsW(LPCWSTR,LPDCB,LPCOMMTIMEOUTS);
 BOOL CallNamedPipeA(LPCSTR,PVOID,DWORD,PVOID,DWORD,PDWORD,DWORD);
 BOOL CallNamedPipeW(LPCWSTR,PVOID,DWORD,PVOID,DWORD,PDWORD,DWORD);
 BOOL CancelDeviceWakeupRequest(HANDLE);
 BOOL CancelIo(HANDLE);
 BOOL CancelWaitableTimer(HANDLE);
 BOOL ClearCommBreak(HANDLE);
 BOOL ClearCommError(HANDLE,PDWORD,LPCOMSTAT);
 BOOL ClearEventLogA(HANDLE,LPCSTR);
 BOOL ClearEventLogW(HANDLE,LPCWSTR);
 BOOL CloseEventLog(HANDLE);
 BOOL CloseHandle(HANDLE);
 BOOL CommConfigDialogA(LPCSTR,HWND,LPCOMMCONFIG);
 BOOL CommConfigDialogW(LPCWSTR,HWND,LPCOMMCONFIG);
 LONG CompareFileTime(FILETIME*, FILETIME*);
 BOOL ConnectNamedPipe(HANDLE,LPOVERLAPPED);
 BOOL ContinueDebugEvent(DWORD,DWORD,DWORD);
 PVOID ConvertThreadToFiber(PVOID);
 BOOL CopyFileA(LPCSTR,LPCSTR,BOOL);
 BOOL CopyFileW(LPCWSTR,LPCWSTR,BOOL);
 BOOL CopyFileExA(LPCSTR,LPCSTR,LPPROGRESS_ROUTINE,LPVOID,LPBOOL,DWORD);
 BOOL CopyFileExW(LPCWSTR,LPCWSTR,LPPROGRESS_ROUTINE,LPVOID,LPBOOL,DWORD);

/+ FIXME
alias memmove RtlMoveMemory;
alias memcpy RtlCopyMemory;

void RtlFillMemory(PVOID dest,SIZE_T len, BYTE fill) {
	memset(dest, fill, len);
}

void RtlZeroMemory(PVOID dest, SIZE_T len) {
	RtlFillMemory(dest, len , 0);
}

alias RtlMoveMemory MoveMemory;
alias RtlCopyMemory CopyMemory;
alias RtlFillMemory FillMemory;
alias RtlZeroMemory ZeroMemory;
+/

 BOOL CopySid(DWORD,PSID,PSID);
 BOOL CreateDirectoryA(LPCSTR,LPSECURITY_ATTRIBUTES);
 BOOL CreateDirectoryW(LPCWSTR,LPSECURITY_ATTRIBUTES);
 BOOL CreateDirectoryExA(LPCSTR,LPCSTR,LPSECURITY_ATTRIBUTES);
 BOOL CreateDirectoryExW(LPCWSTR,LPCWSTR,LPSECURITY_ATTRIBUTES);
 HANDLE CreateEventA(LPSECURITY_ATTRIBUTES,BOOL,BOOL,LPCSTR);
 HANDLE CreateEventW(LPSECURITY_ATTRIBUTES,BOOL,BOOL,LPCWSTR);
 LPVOID CreateFiber(SIZE_T,LPFIBER_START_ROUTINE,LPVOID);
 HANDLE CreateFileA(LPCSTR,DWORD,DWORD,LPSECURITY_ATTRIBUTES,DWORD,DWORD,HANDLE);
 HANDLE CreateFileW(LPCWSTR,DWORD,DWORD,LPSECURITY_ATTRIBUTES,DWORD,DWORD,HANDLE);
 HANDLE CreateFileMappingA(HANDLE,LPSECURITY_ATTRIBUTES,DWORD,DWORD,DWORD,LPCSTR);
 HANDLE CreateFileMappingW(HANDLE,LPSECURITY_ATTRIBUTES,DWORD,DWORD,DWORD,LPCWSTR);
 HANDLE CreateIoCompletionPort(HANDLE,HANDLE,DWORD,DWORD);
 HANDLE CreateMailslotA(LPCSTR,DWORD,DWORD,LPSECURITY_ATTRIBUTES);
 HANDLE CreateMailslotW(LPCWSTR,DWORD,DWORD,LPSECURITY_ATTRIBUTES);
 HANDLE CreateMutexA(LPSECURITY_ATTRIBUTES,BOOL,LPCSTR);
 HANDLE CreateMutexW(LPSECURITY_ATTRIBUTES,BOOL,LPCWSTR);
 HANDLE CreateNamedPipeA(LPCSTR,DWORD,DWORD,DWORD,DWORD,DWORD,DWORD,LPSECURITY_ATTRIBUTES);
 HANDLE CreateNamedPipeW(LPCWSTR,DWORD,DWORD,DWORD,DWORD,DWORD,DWORD,LPSECURITY_ATTRIBUTES);
 BOOL CreatePipe(PHANDLE,PHANDLE,LPSECURITY_ATTRIBUTES,DWORD);
 BOOL CreatePrivateObjectSecurity(PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR*,BOOL,HANDLE,PGENERIC_MAPPING);
 BOOL CreateProcessA(LPCSTR,LPSTR,LPSECURITY_ATTRIBUTES,LPSECURITY_ATTRIBUTES,BOOL,DWORD,PVOID,LPCSTR,LPSTARTUPINFOA,LPPROCESS_INFORMATION);
 BOOL CreateProcessW(LPCWSTR,LPWSTR,LPSECURITY_ATTRIBUTES,LPSECURITY_ATTRIBUTES,BOOL,DWORD,PVOID,LPCWSTR,LPSTARTUPINFOW,LPPROCESS_INFORMATION);
 BOOL CreateProcessAsUserA(HANDLE,LPCSTR,LPSTR,LPSECURITY_ATTRIBUTES,LPSECURITY_ATTRIBUTES,BOOL,DWORD,PVOID,LPCSTR,LPSTARTUPINFOA,LPPROCESS_INFORMATION);
 BOOL CreateProcessAsUserW(HANDLE,LPCWSTR,LPWSTR,LPSECURITY_ATTRIBUTES,LPSECURITY_ATTRIBUTES,BOOL,DWORD,PVOID,LPCWSTR,LPSTARTUPINFOW,LPPROCESS_INFORMATION);
 HANDLE CreateRemoteThread(HANDLE,LPSECURITY_ATTRIBUTES,DWORD,LPTHREAD_START_ROUTINE,LPVOID,DWORD,LPDWORD);
 HANDLE CreateSemaphoreA(LPSECURITY_ATTRIBUTES,LONG,LONG,LPCSTR);
 HANDLE CreateSemaphoreW(LPSECURITY_ATTRIBUTES,LONG,LONG,LPCWSTR);
 DWORD CreateTapePartition(HANDLE,DWORD,DWORD,DWORD);
 HANDLE CreateThread(LPSECURITY_ATTRIBUTES,DWORD,LPTHREAD_START_ROUTINE,PVOID,DWORD,PDWORD);
 HANDLE CreateWaitableTimerA(LPSECURITY_ATTRIBUTES,BOOL,LPCSTR);
 HANDLE CreateWaitableTimerW(LPSECURITY_ATTRIBUTES,BOOL,LPCWSTR);
 BOOL DebugActiveProcess(DWORD);
 void DebugBreak();
 BOOL DefineDosDeviceA(DWORD,LPCSTR,LPCSTR);
 BOOL DefineDosDeviceW(DWORD,LPCWSTR,LPCWSTR);
 BOOL DeleteAce(PACL,DWORD);
 ATOM DeleteAtom(ATOM);
 void DeleteCriticalSection(PCRITICAL_SECTION);
 void DeleteFiber(PVOID);
 BOOL DeleteFileA(LPCSTR);
 BOOL DeleteFileW(LPCWSTR);
 BOOL DeregisterEventSource(HANDLE);
 BOOL DestroyPrivateObjectSecurity(PSECURITY_DESCRIPTOR*);
 BOOL DeviceIoControl(HANDLE,DWORD,PVOID,DWORD,PVOID,DWORD,PDWORD,POVERLAPPED);
 BOOL DisableThreadLibraryCalls(HMODULE);
 BOOL DisconnectNamedPipe(HANDLE);
 BOOL DosDateTimeToFileTime(WORD,WORD,LPFILETIME);
 BOOL DuplicateHandle(HANDLE,HANDLE,HANDLE,PHANDLE,DWORD,BOOL,DWORD);
 BOOL DuplicateToken(HANDLE,SECURITY_IMPERSONATION_LEVEL,PHANDLE);
 BOOL DuplicateTokenEx(HANDLE,DWORD,LPSECURITY_ATTRIBUTES,SECURITY_IMPERSONATION_LEVEL,TOKEN_TYPE,PHANDLE);
 BOOL EncryptFileA(LPCSTR);
 BOOL EncryptFileW(LPCWSTR);
 BOOL EndUpdateResourceA(HANDLE,BOOL);
 BOOL EndUpdateResourceW(HANDLE,BOOL);
 void EnterCriticalSection(LPCRITICAL_SECTION);
 BOOL EnumResourceLanguagesA(HMODULE,LPCSTR,LPCSTR,ENUMRESLANGPROC,LONG_PTR);
 BOOL EnumResourceLanguagesW(HMODULE,LPCWSTR,LPCWSTR,ENUMRESLANGPROC,LONG_PTR);
 BOOL EnumResourceNamesA(HMODULE,LPCSTR,ENUMRESNAMEPROC,LONG_PTR);
 BOOL EnumResourceNamesW(HMODULE,LPCWSTR,ENUMRESNAMEPROC,LONG_PTR);
 BOOL EnumResourceTypesA(HMODULE,ENUMRESTYPEPROC,LONG_PTR);
 BOOL EnumResourceTypesW(HMODULE,ENUMRESTYPEPROC,LONG_PTR);
 BOOL EqualPrefixSid(PSID,PSID);
 BOOL EqualSid(PSID,PSID);
 DWORD EraseTape(HANDLE,DWORD,BOOL);
 BOOL EscapeCommFunction(HANDLE,DWORD);
 void ExitProcess(UINT); // Never returns
 void ExitThread(DWORD); // Never returns
 DWORD ExpandEnvironmentStringsA(LPCSTR,LPSTR,DWORD);
 DWORD ExpandEnvironmentStringsW(LPCWSTR,LPWSTR,DWORD);
 void FatalAppExitA(UINT,LPCSTR);
 void FatalAppExitW(UINT,LPCWSTR);
 void FatalExit(int);
 BOOL FileEncryptionStatusA(LPCSTR,LPDWORD);
 BOOL FileEncryptionStatusW(LPCWSTR,LPDWORD);
 BOOL FileTimeToDosDateTime(FILETIME *,LPWORD,LPWORD);
 BOOL FileTimeToLocalFileTime(FILETIME *,LPFILETIME);
 BOOL FileTimeToSystemTime(FILETIME *,LPSYSTEMTIME);
 ATOM FindAtomA(LPCSTR);
 ATOM FindAtomW(LPCWSTR);
 BOOL FindClose(HANDLE);
 BOOL FindCloseChangeNotification(HANDLE);
 HANDLE FindFirstChangeNotificationA(LPCSTR,BOOL,DWORD);
 HANDLE FindFirstChangeNotificationW(LPCWSTR,BOOL,DWORD);
 HANDLE FindFirstFileA(LPCSTR,LPWIN32_FIND_DATAA);
 HANDLE FindFirstFileW(LPCWSTR,LPWIN32_FIND_DATAW);
 HANDLE FindFirstFileExA(LPCSTR,FINDEX_INFO_LEVELS,PVOID,FINDEX_SEARCH_OPS,PVOID,DWORD);
 HANDLE FindFirstFileExW(LPCWSTR,FINDEX_INFO_LEVELS,PVOID,FINDEX_SEARCH_OPS,PVOID,DWORD);
 BOOL FindFirstFreeAce(PACL,PVOID*);
 BOOL FindNextChangeNotification(HANDLE);
 BOOL FindNextFileA(HANDLE,LPWIN32_FIND_DATAA);
 BOOL FindNextFileW(HANDLE,LPWIN32_FIND_DATAW);
 HRSRC FindResourceA(HMODULE,LPCSTR,LPCSTR);
 HRSRC FindResourceW(HINSTANCE,LPCWSTR,LPCWSTR);
 HRSRC FindResourceExA(HINSTANCE,LPCSTR,LPCSTR,WORD);
 HRSRC FindResourceExW(HINSTANCE,LPCWSTR,LPCWSTR,WORD);
 BOOL FlushFileBuffers(HANDLE);
 BOOL FlushInstructionCache(HANDLE,PCVOID,DWORD);
 BOOL FlushViewOfFile(PCVOID,DWORD);
 DWORD FormatMessageA(DWORD,PCVOID,DWORD,DWORD,LPSTR,DWORD,va_list*);
 DWORD FormatMessageW(DWORD,PCVOID,DWORD,DWORD,LPWSTR,DWORD,va_list*);
 BOOL FreeEnvironmentStringsA(LPSTR);
 BOOL FreeEnvironmentStringsW(LPWSTR);
 BOOL FreeLibrary(HMODULE);
 void FreeLibraryAndExitThread(HMODULE,DWORD); // never returns
 BOOL FreeResource(HGLOBAL);
 PVOID FreeSid(PSID);
 BOOL GetAce(PACL,DWORD,LPVOID*);
 BOOL GetAclInformation(PACL,PVOID,DWORD,ACL_INFORMATION_CLASS);
 UINT GetAtomNameA(ATOM,LPSTR,int);
 UINT GetAtomNameW(ATOM,LPWSTR,int);
 BOOL GetBinaryTypeA(LPCSTR,PDWORD);
 BOOL GetBinaryTypeW(LPCWSTR,PDWORD);
 LPSTR GetCommandLineA();
 LPWSTR GetCommandLineW();
 BOOL GetCommConfig(HANDLE,LPCOMMCONFIG,PDWORD);
 BOOL GetCommMask(HANDLE,PDWORD);
 BOOL GetCommModemStatus(HANDLE,PDWORD);
 BOOL GetCommProperties(HANDLE,LPCOMMPROP);
 BOOL GetCommState(HANDLE,LPDCB);
 BOOL GetCommTimeouts(HANDLE,LPCOMMTIMEOUTS);
 DWORD GetCompressedFileSizeA(LPCSTR,PDWORD);
 DWORD GetCompressedFileSizeW(LPCWSTR,PDWORD);
 BOOL GetComputerNameA(LPSTR,PDWORD);
 BOOL GetComputerNameW(LPWSTR,PDWORD);
 DWORD GetCurrentDirectoryA(DWORD,LPSTR);
 DWORD GetCurrentDirectoryW(DWORD,LPWSTR);
 BOOL GetCurrentHwProfileA(LPHW_PROFILE_INFOA);
 BOOL GetCurrentHwProfileW(LPHW_PROFILE_INFOW);
 HANDLE GetCurrentProcess();
 DWORD GetCurrentProcessId();
 HANDLE GetCurrentThread();
 DWORD GetCurrentThreadId();

alias GetTickCount GetCurrentTime;

 BOOL GetDefaultCommConfigA(LPCSTR,LPCOMMCONFIG,PDWORD);
 BOOL GetDefaultCommConfigW(LPCWSTR,LPCOMMCONFIG,PDWORD);
 BOOL GetDiskFreeSpaceA(LPCSTR,PDWORD,PDWORD,PDWORD,PDWORD);
 BOOL GetDiskFreeSpaceW(LPCWSTR,PDWORD,PDWORD,PDWORD,PDWORD);
 BOOL GetDiskFreeSpaceExA(LPCSTR,PULARGE_INTEGER,PULARGE_INTEGER,PULARGE_INTEGER);
 BOOL GetDiskFreeSpaceExW(LPCWSTR,PULARGE_INTEGER,PULARGE_INTEGER,PULARGE_INTEGER);
 UINT GetDriveTypeA(LPCSTR);
 UINT GetDriveTypeW(LPCWSTR);
 LPSTR GetEnvironmentStrings();
 LPSTR GetEnvironmentStringsA();
 LPWSTR GetEnvironmentStringsW();
 DWORD GetEnvironmentVariableA(LPCSTR,LPSTR,DWORD);
 DWORD GetEnvironmentVariableW(LPCWSTR,LPWSTR,DWORD);
 BOOL GetExitCodeProcess(HANDLE,PDWORD);
 BOOL GetExitCodeThread(HANDLE,PDWORD);
 DWORD GetFileAttributesA(LPCSTR);
 DWORD GetFileAttributesW(LPCWSTR);
 BOOL GetFileAttributesExA(LPCSTR,GET_FILEEX_INFO_LEVELS,PVOID);
 BOOL GetFileAttributesExW(LPCWSTR,GET_FILEEX_INFO_LEVELS,PVOID);
 BOOL GetFileInformationByHandle(HANDLE,LPBY_HANDLE_FILE_INFORMATION);
 BOOL GetFileSecurityA(LPCSTR,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR,DWORD,PDWORD);
 BOOL GetFileSecurityW(LPCWSTR,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR,DWORD,PDWORD);
 DWORD GetFileSize(HANDLE,PDWORD);
 BOOL GetFileTime(HANDLE,LPFILETIME,LPFILETIME,LPFILETIME);
 DWORD GetFileType(HANDLE);
 DWORD GetFullPathNameA(LPCSTR,DWORD,LPSTR,LPSTR*);
 DWORD GetFullPathNameW(LPCWSTR,DWORD,LPWSTR,LPWSTR*);
 BOOL GetHandleInformation(HANDLE,PDWORD);
 BOOL GetKernelObjectSecurity(HANDLE,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR,DWORD,PDWORD);
 DWORD GetLastError();
 DWORD GetLengthSid(PSID);
 void GetLocalTime(LPSYSTEMTIME);
 DWORD GetLogicalDrives();
 DWORD GetLogicalDriveStringsA(DWORD,LPSTR);
 DWORD GetLogicalDriveStringsW(DWORD,LPWSTR);
 BOOL GetMailslotInfo(HANDLE,PDWORD,PDWORD,PDWORD,PDWORD);
 DWORD GetModuleFileNameA(HINSTANCE,LPSTR,DWORD);
 DWORD GetModuleFileNameW(HINSTANCE,LPWSTR,DWORD);
 HMODULE GetModuleHandleA(LPCSTR);
 HMODULE GetModuleHandleW(LPCWSTR);
 BOOL GetNamedPipeHandleStateA(HANDLE,PDWORD,PDWORD,PDWORD,PDWORD,LPSTR,DWORD);
 BOOL GetNamedPipeHandleStateW(HANDLE,PDWORD,PDWORD,PDWORD,PDWORD,LPWSTR,DWORD);
 BOOL GetNamedPipeInfo(HANDLE,PDWORD,PDWORD,PDWORD,PDWORD);
 BOOL GetNumberOfEventLogRecords(HANDLE,PDWORD);
 BOOL GetOldestEventLogRecord(HANDLE,PDWORD);
 BOOL GetOverlappedResult(HANDLE,LPOVERLAPPED,PDWORD,BOOL);
 DWORD GetPriorityClass(HANDLE);
 BOOL GetPrivateObjectSecurity(PSECURITY_DESCRIPTOR,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR,DWORD,PDWORD);
 UINT GetPrivateProfileIntA(LPCSTR,LPCSTR,INT,LPCSTR);
 UINT GetPrivateProfileIntW(LPCWSTR,LPCWSTR,INT,LPCWSTR);
 DWORD GetPrivateProfileSectionA(LPCSTR,LPSTR,DWORD,LPCSTR);
 DWORD GetPrivateProfileSectionW(LPCWSTR,LPWSTR,DWORD,LPCWSTR);
 DWORD GetPrivateProfileSectionNamesA(LPSTR,DWORD,LPCSTR);
 DWORD GetPrivateProfileSectionNamesW(LPWSTR,DWORD,LPCWSTR);
 DWORD GetPrivateProfileStringA(LPCSTR,LPCSTR,LPCSTR,LPSTR,DWORD,LPCSTR);
 DWORD GetPrivateProfileStringW(LPCWSTR,LPCWSTR,LPCWSTR,LPWSTR,DWORD,LPCWSTR);
 BOOL GetPrivateProfileStructA(LPCSTR,LPCSTR,LPVOID,UINT,LPCSTR);
 BOOL GetPrivateProfileStructW(LPCWSTR,LPCWSTR,LPVOID,UINT,LPCWSTR);
 FARPROC GetProcAddress(HINSTANCE,LPCSTR);
 BOOL GetProcessAffinityMask(HANDLE,PDWORD,PDWORD);
 HANDLE GetProcessHeap();
 DWORD GetProcessHeaps(DWORD,PHANDLE);
 BOOL GetProcessPriorityBoost(HANDLE,PBOOL);
 BOOL GetProcessShutdownParameters(PDWORD,PDWORD);
 BOOL GetProcessTimes(HANDLE,LPFILETIME,LPFILETIME,LPFILETIME,LPFILETIME);
 DWORD GetProcessVersion(DWORD);
 HWINSTA GetProcessWindowStation();
 BOOL GetProcessWorkingSetSize(HANDLE,PSIZE_T,PSIZE_T);
 UINT GetProfileIntA(LPCSTR,LPCSTR,INT);
 UINT GetProfileIntW(LPCWSTR,LPCWSTR,INT);
 DWORD GetProfileSectionA(LPCSTR,LPSTR,DWORD);
 DWORD GetProfileSectionW(LPCWSTR,LPWSTR,DWORD);
 DWORD GetProfileStringA(LPCSTR,LPCSTR,LPCSTR,LPSTR,DWORD);
 DWORD GetProfileStringW(LPCWSTR,LPCWSTR,LPCWSTR,LPWSTR,DWORD);
 BOOL GetQueuedCompletionStatus(HANDLE,PDWORD,PDWORD,LPOVERLAPPED*,DWORD);
 BOOL GetSecurityDescriptorControl(PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR_CONTROL,PDWORD);
 BOOL GetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR,LPBOOL,PACL*,LPBOOL);
 BOOL GetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR,PSID*,LPBOOL);
 DWORD GetSecurityDescriptorLength(PSECURITY_DESCRIPTOR);
 BOOL GetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR,PSID*,LPBOOL);
 BOOL GetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR,LPBOOL,PACL*,LPBOOL);
 DWORD GetShortPathNameA(LPCSTR,LPSTR,DWORD);
 DWORD GetShortPathNameW(LPCWSTR,LPWSTR,DWORD);
 PSID_IDENTIFIER_AUTHORITY GetSidIdentifierAuthority(PSID);
 DWORD GetSidLengthRequired(UCHAR);
 PDWORD GetSidSubAuthority(PSID,DWORD);
 PUCHAR GetSidSubAuthorityCount(PSID);
 VOID GetStartupInfoA(LPSTARTUPINFOA);
 VOID GetStartupInfoW(LPSTARTUPINFOW);
 HANDLE GetStdHandle(DWORD);
 UINT GetSystemDirectoryA(LPSTR,UINT);
 UINT GetSystemDirectoryW(LPWSTR,UINT);
 VOID GetSystemInfo(LPSYSTEM_INFO);
 BOOL GetSystemPowerStatus(LPSYSTEM_POWER_STATUS);
 VOID GetSystemTime(LPSYSTEMTIME);
 BOOL GetSystemTimeAdjustment(PDWORD,PDWORD,PBOOL);
 void GetSystemTimeAsFileTime(LPFILETIME);
 DWORD GetTapeParameters(HANDLE,DWORD,PDWORD,PVOID);
 DWORD GetTapePosition(HANDLE,DWORD,PDWORD,PDWORD,PDWORD);
 DWORD GetTapeStatus(HANDLE);
 UINT GetTempFileNameA(LPCSTR,LPCSTR,UINT,LPSTR);
 UINT GetTempFileNameW(LPCWSTR,LPCWSTR,UINT,LPWSTR);
 DWORD GetTempPathA(DWORD,LPSTR);
 DWORD GetTempPathW(DWORD,LPWSTR);
 BOOL GetThreadContext(HANDLE,LPCONTEXT);
 int GetThreadPriority(HANDLE);
 BOOL GetThreadPriorityBoost(HANDLE,PBOOL);
 BOOL GetThreadSelectorEntry(HANDLE,DWORD,LPLDT_ENTRY);
 BOOL GetThreadTimes(HANDLE,LPFILETIME,LPFILETIME,LPFILETIME,LPFILETIME);
 DWORD GetTickCount();
 DWORD GetTimeZoneInformation(LPTIME_ZONE_INFORMATION);
 BOOL GetTokenInformation(HANDLE,TOKEN_INFORMATION_CLASS,PVOID,DWORD,PDWORD);
 BOOL GetUserNameA (LPSTR,PDWORD);
 BOOL GetUserNameW(LPWSTR,PDWORD);
 DWORD GetVersion();
 BOOL GetVersionExA(LPOSVERSIONINFOA);
 BOOL GetVersionExW(LPOSVERSIONINFOW);
 BOOL GetVolumeInformationA(LPCSTR,LPSTR,DWORD,PDWORD,PDWORD,PDWORD,LPSTR,DWORD);
 BOOL GetVolumeInformationW(LPCWSTR,LPWSTR,DWORD,PDWORD,PDWORD,PDWORD,LPWSTR,DWORD);
 UINT GetWindowsDirectoryA(LPSTR,UINT);
 UINT GetWindowsDirectoryW(LPWSTR,UINT);
 DWORD GetWindowThreadProcessId(HWND,PDWORD);
 UINT GetWriteWatch(DWORD,PVOID,SIZE_T,PVOID*,PULONG_PTR,PULONG);
 ATOM GlobalAddAtomA(LPCSTR);
 ATOM GlobalAddAtomW( LPCWSTR);
 HGLOBAL GlobalAlloc(UINT,DWORD);
 ATOM GlobalDeleteAtom(ATOM);
 HGLOBAL GlobalDiscard(HGLOBAL);
 ATOM GlobalFindAtomA(LPCSTR);
 ATOM GlobalFindAtomW(LPCWSTR);
 HGLOBAL GlobalFree(HGLOBAL);
 UINT GlobalGetAtomNameA(ATOM,LPSTR,int);
 UINT GlobalGetAtomNameW(ATOM,LPWSTR,int);
 HGLOBAL GlobalHandle(PCVOID);
 LPVOID GlobalLock(HGLOBAL);
 VOID GlobalMemoryStatus(LPMEMORYSTATUS);
 HGLOBAL GlobalReAlloc(HGLOBAL,DWORD,UINT);
 DWORD GlobalSize(HGLOBAL);
 BOOL GlobalUnlock(HGLOBAL);

bool HasOverlappedIoCompleted(LPOVERLAPPED lpOverlapped) {
	return lpOverlapped.Internal != STATUS_PENDING;
}

 PVOID HeapAlloc(HANDLE,DWORD,DWORD);
SIZE_T HeapCompact(HANDLE,DWORD);
 HANDLE HeapCreate(DWORD,DWORD,DWORD);
 BOOL HeapDestroy(HANDLE);
 BOOL HeapFree(HANDLE,DWORD,PVOID);
 BOOL HeapLock(HANDLE);
 PVOID HeapReAlloc(HANDLE,DWORD,PVOID,DWORD);
 DWORD HeapSize(HANDLE,DWORD,PCVOID);
 BOOL HeapUnlock(HANDLE);
 BOOL HeapValidate(HANDLE,DWORD,PCVOID);
 BOOL HeapWalk(HANDLE,LPPROCESS_HEAP_ENTRY);
 BOOL ImpersonateLoggedOnUser(HANDLE);
 BOOL ImpersonateNamedPipeClient(HANDLE);
 BOOL ImpersonateSelf(SECURITY_IMPERSONATION_LEVEL);
 BOOL InitAtomTable(DWORD);
 BOOL InitializeAcl(PACL,DWORD,DWORD);
 VOID InitializeCriticalSection(LPCRITICAL_SECTION);
 BOOL InitializeCriticalSectionAndSpinCount(LPCRITICAL_SECTION,DWORD);
 DWORD SetCriticalSectionSpinCount(LPCRITICAL_SECTION,DWORD);
 BOOL InitializeSecurityDescriptor(PSECURITY_DESCRIPTOR,DWORD);
 BOOL InitializeSid (PSID,PSID_IDENTIFIER_AUTHORITY,BYTE);
 BOOL IsBadCodePtr(FARPROC);
 BOOL IsBadHugeReadPtr(PCVOID,UINT);
 BOOL IsBadHugeWritePtr(PVOID,UINT);
 BOOL IsBadReadPtr(PCVOID,UINT);
 BOOL IsBadStringPtrA(LPCSTR,UINT);
 BOOL IsBadStringPtrW(LPCWSTR,UINT);
 BOOL IsBadWritePtr(PVOID,UINT);
 BOOL IsDebuggerPresent();
 BOOL IsProcessorFeaturePresent(DWORD);
 BOOL IsSystemResumeAutomatic();
 BOOL IsTextUnicode(PCVOID,int,LPINT);
 BOOL IsValidAcl(PACL);
 BOOL IsValidSecurityDescriptor(PSECURITY_DESCRIPTOR);
 BOOL IsValidSid(PSID);
 void LeaveCriticalSection(LPCRITICAL_SECTION);
 HINSTANCE LoadLibraryA(LPCSTR);
 HINSTANCE LoadLibraryExA(LPCSTR,HANDLE,DWORD);
 HINSTANCE LoadLibraryExW(LPCWSTR,HANDLE,DWORD);
 HINSTANCE LoadLibraryW(LPCWSTR);
 DWORD LoadModule(LPCSTR,PVOID);
 HGLOBAL LoadResource(HINSTANCE,HRSRC);
 HLOCAL LocalAlloc(UINT,SIZE_T);
 HLOCAL LocalDiscard(HLOCAL);
 BOOL LocalFileTimeToFileTime(FILETIME *,LPFILETIME);
 HLOCAL LocalFree(HLOCAL);
 HLOCAL LocalHandle(LPCVOID);
 PVOID LocalLock(HLOCAL);
 HLOCAL LocalReAlloc(HLOCAL,SIZE_T,UINT);
 UINT LocalSize(HLOCAL);
 BOOL LocalUnlock(HLOCAL);
 BOOL LockFile(HANDLE,DWORD,DWORD,DWORD,DWORD);
 BOOL LockFileEx(HANDLE,DWORD,DWORD,DWORD,DWORD,LPOVERLAPPED);
 PVOID LockResource(HGLOBAL);
 BOOL LogonUserA(LPSTR,LPSTR,LPSTR,DWORD,DWORD,PHANDLE);
 BOOL LogonUserW(LPWSTR,LPWSTR,LPWSTR,DWORD,DWORD,PHANDLE);
 BOOL LookupAccountNameA(LPCSTR,LPCSTR,PSID,PDWORD,LPSTR,PDWORD,PSID_NAME_USE);
 BOOL LookupAccountNameW(LPCWSTR,LPCWSTR,PSID,PDWORD,LPWSTR,PDWORD,PSID_NAME_USE);
 BOOL LookupAccountSidA(LPCSTR,PSID,LPSTR,PDWORD,LPSTR,PDWORD,PSID_NAME_USE);
 BOOL LookupAccountSidW(LPCWSTR,PSID,LPWSTR,PDWORD,LPWSTR,PDWORD,PSID_NAME_USE);
 BOOL LookupPrivilegeDisplayNameA(LPCSTR,LPCSTR,LPSTR,PDWORD,PDWORD);
 BOOL LookupPrivilegeDisplayNameW(LPCWSTR,LPCWSTR,LPWSTR,PDWORD,PDWORD);
 BOOL LookupPrivilegeNameA(LPCSTR,PLUID,LPSTR,PDWORD);
 BOOL LookupPrivilegeNameW(LPCWSTR,PLUID,LPWSTR,PDWORD);
 BOOL LookupPrivilegeValueA(LPCSTR,LPCSTR,PLUID);
 BOOL LookupPrivilegeValueW(LPCWSTR,LPCWSTR,PLUID);

 LPSTR lstrcatA(LPSTR,LPCSTR);
 LPWSTR lstrcatW(LPWSTR,LPCWSTR);
 int lstrcmpA(LPCSTR,LPCSTR);
 int lstrcmpiA(LPCSTR,LPCSTR);
 int lstrcmpiW( LPCWSTR,LPCWSTR);
 int lstrcmpW(LPCWSTR,LPCWSTR);
 LPSTR lstrcpyA(LPSTR,LPCSTR);
 LPSTR lstrcpynA(LPSTR,LPCSTR,int);
 LPWSTR lstrcpynW(LPWSTR,LPCWSTR,int);
 LPWSTR lstrcpyW(LPWSTR,LPCWSTR);
 int lstrlenA(LPCSTR);
 int lstrlenW(LPCWSTR);

 BOOL MakeAbsoluteSD(PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR,PDWORD,PACL,PDWORD,PACL,PDWORD,PSID,PDWORD,PSID,PDWORD);
 BOOL MakeSelfRelativeSD(PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR,PDWORD);
 VOID MapGenericMask(PDWORD,PGENERIC_MAPPING);
 PVOID MapViewOfFile(HANDLE,DWORD,DWORD,DWORD,DWORD);
 PVOID MapViewOfFileEx(HANDLE,DWORD,DWORD,DWORD,DWORD,PVOID);
 BOOL MoveFileA(LPCSTR,LPCSTR);
 BOOL MoveFileExA(LPCSTR,LPCSTR,DWORD);
 BOOL MoveFileExW(LPCWSTR,LPCWSTR,DWORD);
 BOOL MoveFileW(LPCWSTR,LPCWSTR);
 int MulDiv(int,int,int);
 BOOL NotifyChangeEventLog(HANDLE,HANDLE);
 BOOL ObjectCloseAuditAlarmA(LPCSTR,PVOID,BOOL);
 BOOL ObjectCloseAuditAlarmW(LPCWSTR,PVOID,BOOL);
 BOOL ObjectDeleteAuditAlarmA(LPCSTR,PVOID,BOOL);
 BOOL ObjectDeleteAuditAlarmW(LPCWSTR,PVOID,BOOL);
 BOOL ObjectOpenAuditAlarmA(LPCSTR,PVOID,LPSTR,LPSTR,PSECURITY_DESCRIPTOR,HANDLE,DWORD,DWORD,PPRIVILEGE_SET,BOOL,BOOL,PBOOL);
 BOOL ObjectOpenAuditAlarmW(LPCWSTR,PVOID,LPWSTR,LPWSTR,PSECURITY_DESCRIPTOR,HANDLE,DWORD,DWORD,PPRIVILEGE_SET,BOOL,BOOL,PBOOL);
 BOOL ObjectPrivilegeAuditAlarmA(LPCSTR,PVOID,HANDLE,DWORD,PPRIVILEGE_SET,BOOL);
 BOOL ObjectPrivilegeAuditAlarmW(LPCWSTR,PVOID,HANDLE,DWORD,PPRIVILEGE_SET,BOOL);
 HANDLE OpenBackupEventLogA(LPCSTR,LPCSTR);
 HANDLE OpenBackupEventLogW(LPCWSTR,LPCWSTR);
 HANDLE OpenEventA(DWORD,BOOL,LPCSTR);
 HANDLE OpenEventLogA (LPCSTR,LPCSTR);
 HANDLE OpenEventLogW(LPCWSTR,LPCWSTR);
 HANDLE OpenEventW(DWORD,BOOL,LPCWSTR);
deprecated {
 HFILE OpenFile(LPCSTR,LPOFSTRUCT,UINT);
}
 HANDLE OpenFileMappingA(DWORD,BOOL,LPCSTR);
 HANDLE OpenFileMappingW(DWORD,BOOL,LPCWSTR);
 HANDLE OpenMutexA(DWORD,BOOL,LPCSTR);
 HANDLE OpenMutexW(DWORD,BOOL,LPCWSTR);
 HANDLE OpenProcess(DWORD,BOOL,DWORD);
 BOOL OpenProcessToken(HANDLE,DWORD,PHANDLE);
 HANDLE OpenSemaphoreA(DWORD,BOOL,LPCSTR);
 HANDLE OpenSemaphoreW(DWORD,BOOL,LPCWSTR);
 BOOL OpenThreadToken(HANDLE,DWORD,BOOL,PHANDLE);
 HANDLE OpenWaitableTimerA(DWORD,BOOL,LPCSTR);
 HANDLE OpenWaitableTimerW(DWORD,BOOL,LPCWSTR);
 void OutputDebugStringA(LPCSTR);
 void OutputDebugStringW(LPCWSTR);
 BOOL PeekNamedPipe(HANDLE,PVOID,DWORD,PDWORD,PDWORD,PDWORD);
 BOOL PostQueuedCompletionStatus(HANDLE,DWORD,DWORD,LPOVERLAPPED);
 DWORD PrepareTape(HANDLE,DWORD,BOOL);
 BOOL PrivilegeCheck (HANDLE,PPRIVILEGE_SET,PBOOL);
 BOOL PrivilegedServiceAuditAlarmA(LPCSTR,LPCSTR,HANDLE,PPRIVILEGE_SET,BOOL);
 BOOL PrivilegedServiceAuditAlarmW(LPCWSTR,LPCWSTR,HANDLE,PPRIVILEGE_SET,BOOL);
 BOOL PulseEvent(HANDLE);
 BOOL PurgeComm(HANDLE,DWORD);
 DWORD QueryDosDeviceA(LPCSTR,LPSTR,DWORD);
 DWORD QueryDosDeviceW(LPCWSTR,LPWSTR,DWORD);
 BOOL QueryPerformanceCounter(PLARGE_INTEGER);
 BOOL QueryPerformanceFrequency(PLARGE_INTEGER);
 DWORD QueueUserAPC(PAPCFUNC,HANDLE,DWORD);
 void RaiseException(DWORD,DWORD,DWORD, DWORD*);
 BOOL ReadDirectoryChangesW(HANDLE,PVOID,DWORD,BOOL,DWORD,PDWORD,LPOVERLAPPED,LPOVERLAPPED_COMPLETION_ROUTINE);
 BOOL ReadEventLogA(HANDLE,DWORD,DWORD,PVOID,DWORD,DWORD *,DWORD *);
 BOOL ReadEventLogW(HANDLE,DWORD,DWORD,PVOID,DWORD,DWORD *,DWORD *);
 BOOL ReadFile(HANDLE,PVOID,DWORD,PDWORD,LPOVERLAPPED);
 BOOL ReadFileEx(HANDLE,PVOID,DWORD,LPOVERLAPPED,LPOVERLAPPED_COMPLETION_ROUTINE);
 BOOL ReadFileScatter(HANDLE,FILE_SEGMENT_ELEMENT*,DWORD,LPDWORD,LPOVERLAPPED);
 BOOL ReadProcessMemory(HANDLE,PCVOID,PVOID,DWORD,PDWORD);
 HANDLE RegisterEventSourceA (LPCSTR,LPCSTR);
 HANDLE RegisterEventSourceW(LPCWSTR,LPCWSTR);
 BOOL ReleaseMutex(HANDLE);
 BOOL ReleaseSemaphore(HANDLE,LONG,LPLONG);
 BOOL RemoveDirectoryA(LPCSTR);
 BOOL RemoveDirectoryW(LPCWSTR);
 BOOL ReportEventA(HANDLE,WORD,WORD,DWORD,PSID,WORD,DWORD,LPCSTR*,PVOID);
 BOOL ReportEventW(HANDLE,WORD,WORD,DWORD,PSID,WORD,DWORD,LPCWSTR*,PVOID);
 BOOL ResetEvent(HANDLE);
 UINT ResetWriteWatch(LPVOID,SIZE_T);
 DWORD ResumeThread(HANDLE);
 BOOL RevertToSelf();
 DWORD SearchPathA(LPCSTR,LPCSTR,LPCSTR,DWORD,LPSTR,LPSTR*);
 DWORD SearchPathW(LPCWSTR,LPCWSTR,LPCWSTR,DWORD,LPWSTR,LPWSTR*);
 BOOL SetAclInformation(PACL,PVOID,DWORD,ACL_INFORMATION_CLASS);
 BOOL SetCommBreak(HANDLE);
 BOOL SetCommConfig(HANDLE,LPCOMMCONFIG,DWORD);
 BOOL SetCommMask(HANDLE,DWORD);
 BOOL SetCommState(HANDLE,LPDCB);
 BOOL SetCommTimeouts(HANDLE,LPCOMMTIMEOUTS);
 BOOL SetComputerNameA(LPCSTR);
 BOOL SetComputerNameW(LPCWSTR);
 BOOL SetCurrentDirectoryA(LPCSTR);
 BOOL SetCurrentDirectoryW(LPCWSTR);
 BOOL SetDefaultCommConfigA(LPCSTR,LPCOMMCONFIG,DWORD);
 BOOL SetDefaultCommConfigW(LPCWSTR,LPCOMMCONFIG,DWORD);
 BOOL SetEndOfFile(HANDLE);
 BOOL SetEnvironmentVariableA(LPCSTR,LPCSTR);
 BOOL SetEnvironmentVariableW(LPCWSTR,LPCWSTR);
 UINT SetErrorMode(UINT);
 BOOL SetEvent(HANDLE);
 VOID SetFileApisToANSI();
 VOID SetFileApisToOEM();
 BOOL SetFileAttributesA(LPCSTR,DWORD);
 BOOL SetFileAttributesW(LPCWSTR,DWORD);
 DWORD SetFilePointer(HANDLE,LONG,PLONG,DWORD);
 BOOL SetFilePointerEx(HANDLE,LARGE_INTEGER,PLARGE_INTEGER,DWORD);
 BOOL SetFileSecurityA(LPCSTR,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR);
 BOOL SetFileSecurityW(LPCWSTR,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR);
 BOOL SetFileTime(HANDLE, FILETIME*, FILETIME*, FILETIME*);
 UINT SetHandleCount(UINT);
 BOOL SetHandleInformation(HANDLE,DWORD,DWORD);
 BOOL SetKernelObjectSecurity(HANDLE,SECURITY_INFORMATION,PSECURITY_DESCRIPTOR);
 void SetLastError(DWORD);
 void SetLastErrorEx(DWORD,DWORD);
 BOOL SetLocalTime( SYSTEMTIME*);
 BOOL SetMailslotInfo(HANDLE,DWORD);
 BOOL SetNamedPipeHandleState(HANDLE,PDWORD,PDWORD,PDWORD);
 BOOL SetPriorityClass(HANDLE,DWORD);
 BOOL SetPrivateObjectSecurity(SECURITY_INFORMATION,PSECURITY_DESCRIPTOR,PSECURITY_DESCRIPTOR *,PGENERIC_MAPPING,HANDLE);
 BOOL SetProcessAffinityMask(HANDLE,DWORD);
 BOOL SetProcessPriorityBoost(HANDLE,BOOL);
 BOOL SetProcessShutdownParameters(DWORD,DWORD);
 BOOL SetProcessWorkingSetSize(HANDLE,DWORD,DWORD);
 BOOL SetSecurityDescriptorControl(PSECURITY_DESCRIPTOR,SECURITY_DESCRIPTOR_CONTROL,SECURITY_DESCRIPTOR_CONTROL);
 BOOL SetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR,BOOL,PACL,BOOL);
 BOOL SetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR,PSID,BOOL);
 BOOL SetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR,PSID,BOOL);
 BOOL SetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR,BOOL,PACL,BOOL);
 BOOL SetStdHandle(DWORD,HANDLE);
 BOOL SetSystemPowerState(BOOL,BOOL);
 BOOL SetSystemTime( SYSTEMTIME*);
 BOOL SetSystemTimeAdjustment(DWORD,BOOL);
 DWORD SetTapeParameters(HANDLE,DWORD,PVOID);
 DWORD SetTapePosition(HANDLE,DWORD,DWORD,DWORD,DWORD,BOOL);
 DWORD SetThreadAffinityMask(HANDLE,DWORD);
 BOOL SetThreadContext(HANDLE, CONTEXT*);
 DWORD SetThreadIdealProcessor(HANDLE,DWORD);
 BOOL SetThreadPriority(HANDLE,int);
 BOOL SetThreadPriorityBoost(HANDLE,BOOL);
 BOOL SetThreadToken (PHANDLE,HANDLE);
 BOOL SetTimeZoneInformation( TIME_ZONE_INFORMATION *);
 BOOL SetTokenInformation(HANDLE,TOKEN_INFORMATION_CLASS,PVOID,DWORD);
 LPTOP_LEVEL_EXCEPTION_FILTER SetUnhandledExceptionFilter(LPTOP_LEVEL_EXCEPTION_FILTER);
 BOOL SetupComm(HANDLE,DWORD,DWORD);
 BOOL SetVolumeLabelA(LPCSTR,LPCSTR);
 BOOL SetVolumeLabelW(LPCWSTR,LPCWSTR);
 BOOL SetWaitableTimer(HANDLE, LARGE_INTEGER*,LONG,PTIMERAPCROUTINE,PVOID,BOOL);
 DWORD SignalObjectAndWait(HANDLE,HANDLE,DWORD,BOOL);
 DWORD SizeofResource(HINSTANCE,HRSRC);
 void Sleep(DWORD);
 DWORD SleepEx(DWORD,BOOL);
 DWORD SuspendThread(HANDLE);
 void SwitchToFiber(PVOID);
 BOOL SwitchToThread();
 BOOL SystemTimeToFileTime( SYSTEMTIME*,LPFILETIME);
 BOOL SystemTimeToTzSpecificLocalTime(LPTIME_ZONE_INFORMATION,LPSYSTEMTIME,LPSYSTEMTIME);
 BOOL TerminateProcess(HANDLE,UINT);
 BOOL TerminateThread(HANDLE,DWORD);
 DWORD TlsAlloc();
 BOOL TlsFree(DWORD);
 PVOID TlsGetValue(DWORD);
 BOOL TlsSetValue(DWORD,PVOID);
 BOOL TransactNamedPipe(HANDLE,PVOID,DWORD,PVOID,DWORD,PDWORD,LPOVERLAPPED);
 BOOL TransmitCommChar(HANDLE,char);
 BOOL TryEnterCriticalSection(LPCRITICAL_SECTION);
 LONG UnhandledExceptionFilter(LPEXCEPTION_POINTERS);
 BOOL UnlockFile(HANDLE,DWORD,DWORD,DWORD,DWORD);
 BOOL UnlockFileEx(HANDLE,DWORD,DWORD,DWORD,LPOVERLAPPED);
 BOOL UnmapViewOfFile(PVOID);
 BOOL UpdateResourceA(HANDLE,LPCSTR,LPCSTR,WORD,PVOID,DWORD);
 BOOL UpdateResourceW(HANDLE,LPCWSTR,LPCWSTR,WORD,PVOID,DWORD);
 BOOL VerifyVersionInfoA(LPOSVERSIONINFOEXA,DWORD,DWORDLONG);
 BOOL VerifyVersionInfoW(LPOSVERSIONINFOEXW,DWORD,DWORDLONG);
 PVOID VirtualAlloc(PVOID,DWORD,DWORD,DWORD);
 PVOID VirtualAllocEx(HANDLE,PVOID,DWORD,DWORD,DWORD);
 BOOL VirtualFree(PVOID,DWORD,DWORD);
 BOOL VirtualFreeEx(HANDLE,PVOID,DWORD,DWORD);
 BOOL VirtualLock(PVOID,DWORD);
 BOOL VirtualProtect(PVOID,DWORD,DWORD,PDWORD);
 BOOL VirtualProtectEx(HANDLE,PVOID,DWORD,DWORD,PDWORD);
 DWORD VirtualQuery(LPCVOID,PMEMORY_BASIC_INFORMATION,DWORD);
 DWORD VirtualQueryEx(HANDLE,LPCVOID,PMEMORY_BASIC_INFORMATION,DWORD);
 BOOL VirtualUnlock(PVOID,DWORD);
 BOOL WaitCommEvent(HANDLE,PDWORD,LPOVERLAPPED);
 BOOL WaitForDebugEvent(LPDEBUG_EVENT,DWORD);
 DWORD WaitForMultipleObjects(DWORD, HANDLE*,BOOL,DWORD);
 DWORD WaitForMultipleObjectsEx(DWORD, HANDLE*,BOOL,DWORD,BOOL);
 DWORD WaitForSingleObject(HANDLE,DWORD);
 DWORD WaitForSingleObjectEx(HANDLE,DWORD,BOOL);
 BOOL WaitNamedPipeA(LPCSTR,DWORD);
 BOOL WaitNamedPipeW(LPCWSTR,DWORD);
 BOOL WinLoadTrustProvider(GUID*);
 BOOL WriteFile(HANDLE,PCVOID,DWORD,PDWORD,LPOVERLAPPED);
 BOOL WriteFileEx(HANDLE,PCVOID,DWORD,LPOVERLAPPED,LPOVERLAPPED_COMPLETION_ROUTINE);
 BOOL WriteFileGather(HANDLE,FILE_SEGMENT_ELEMENT*,DWORD,LPDWORD,LPOVERLAPPED);
 BOOL WritePrivateProfileSectionA(LPCSTR,LPCSTR,LPCSTR);
 BOOL WritePrivateProfileSectionW(LPCWSTR,LPCWSTR,LPCWSTR);
 BOOL WritePrivateProfileStringA(LPCSTR,LPCSTR,LPCSTR,LPCSTR);
 BOOL WritePrivateProfileStringW(LPCWSTR,LPCWSTR,LPCWSTR,LPCWSTR);
 BOOL WritePrivateProfileStructA(LPCSTR,LPCSTR,LPVOID,UINT,LPCSTR);
 BOOL WritePrivateProfileStructW(LPCWSTR,LPCWSTR,LPVOID,UINT,LPCWSTR);
 BOOL WriteProcessMemory(HANDLE,LPVOID,LPCVOID,SIZE_T,SIZE_T*);
 BOOL WriteProfileSectionA(LPCSTR,LPCSTR);
 BOOL WriteProfileSectionW(LPCWSTR,LPCWSTR);
 BOOL WriteProfileStringA(LPCSTR,LPCSTR,LPCSTR);
 BOOL WriteProfileStringW(LPCWSTR,LPCWSTR,LPCWSTR);
 DWORD WriteTapemark(HANDLE,DWORD,DWORD,BOOL);

// ------
// functions added in later Windows versions

static if (_WIN32_WINNT >= 0x0400) {
 LPVOID CreateFiberEx(SIZE_T,SIZE_T,DWORD,LPFIBER_START_ROUTINE,LPVOID);
 BOOL ConvertFiberToThread();
}
static if ((_WIN32_WINNT >= 0x0500) || (_WIN32_WINDOWS >= 0x0410)) {
 DWORD GetLongPathNameA(LPCSTR,LPSTR,DWORD);
 DWORD GetLongPathNameW(LPCWSTR,LPWSTR,DWORD);
 EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE);
}
static if ((_WIN32_WINNT >= 0x0500) || (_WIN32_WINDOWS >= 0x0490)) {
 HANDLE OpenThread(DWORD,BOOL,DWORD);
}

static if (_WIN32_WINNT >= 0x0500) {
 BOOL AddAccessAllowedAceEx(PACL,DWORD,DWORD,DWORD,PSID);
 BOOL AddAccessDeniedAceEx(PACL,DWORD,DWORD,DWORD,PSID);
 PVOID AddVectoredExceptionHandler(ULONG,PVECTORED_EXCEPTION_HANDLER);
 BOOL CreateHardLinkA(LPCSTR,LPCSTR,LPSECURITY_ATTRIBUTES);
 BOOL CreateHardLinkW(LPCWSTR,LPCWSTR,LPSECURITY_ATTRIBUTES);
 HANDLE CreateJobObjectA(LPSECURITY_ATTRIBUTES,LPCSTR);
 HANDLE CreateJobObjectW(LPSECURITY_ATTRIBUTES,LPCWSTR);
 BOOL TerminateJobObject(HANDLE,UINT);
 BOOL AssignProcessToJobObject(HANDLE,HANDLE);
 BOOL DeleteTimerQueue(HANDLE);
 BOOL DeleteTimerQueueEx(HANDLE,HANDLE);
 BOOL DeleteTimerQueueTimer(HANDLE,HANDLE,HANDLE);
 BOOL DeleteVolumeMountPointA(LPCSTR);
 BOOL DeleteVolumeMountPointW(LPCWSTR);
 BOOL CreateProcessWithLogonW (LPCWSTR,LPCWSTR,LPCWSTR,DWORD,
			LPCWSTR,LPWSTR,DWORD,LPVOID,
			LPCWSTR,LPSTARTUPINFOW,
			LPPROCESS_INFORMATION);
	enum {
		LOGON_WITH_PROFILE=0x00000001,
		LOGON_NETCREDENTIALS_ONLY=0x00000002
	}
 HANDLE CreateTimerQueue();
 BOOL CreateTimerQueueTimer(PHANDLE,HANDLE,WAITORTIMERCALLBACK,PVOID,DWORD,DWORD,ULONG);
 BOOL DnsHostnameToComputerNameA(LPCSTR,LPSTR,LPDWORD);
 BOOL DnsHostnameToComputerNameW(LPCWSTR,LPWSTR,LPDWORD);
 HANDLE FindFirstVolumeA(LPCSTR,DWORD);
 HANDLE FindFirstVolumeW(LPCWSTR,DWORD);
 HANDLE FindFirstVolumeMountPointA(LPSTR,LPSTR,DWORD);
 HANDLE FindFirstVolumeMountPointW(LPWSTR,LPWSTR,DWORD);
 BOOL FindNextVolumeA(HANDLE,LPCSTR,DWORD);
 BOOL FindNextVolumeW(HANDLE,LPWSTR,DWORD);
 BOOL FindNextVolumeMountPointA(HANDLE,LPSTR,DWORD);
 BOOL FindNextVolumeMountPointW(HANDLE,LPWSTR,DWORD);
 BOOL FindVolumeClose(HANDLE);
 BOOL FindVolumeMountPointClose(HANDLE);
 BOOL GetComputerNameExA(COMPUTER_NAME_FORMAT,LPSTR,LPDWORD);
 BOOL GetComputerNameExW(COMPUTER_NAME_FORMAT,LPWSTR,LPDWORD);
 BOOL GetFileSizeEx(HANDLE,PLARGE_INTEGER);
 BOOL GetModuleHandleExA(DWORD,LPCSTR,HMODULE*);
 BOOL GetModuleHandleExW(DWORD,LPCWSTR,HMODULE*);
 BOOL GetProcessIoCounters(HANDLE,PIO_COUNTERS);
 UINT GetSystemWindowsDirectoryA(LPSTR,UINT);
 UINT GetSystemWindowsDirectoryW(LPWSTR,UINT);
 BOOL GetVolumeNameForVolumeMountPointA(LPCSTR,LPSTR,DWORD);
 BOOL GetVolumeNameForVolumeMountPointW(LPCWSTR,LPWSTR,DWORD);
 BOOL GetVolumePathNameA(LPCSTR,LPSTR,DWORD);
 BOOL GetVolumePathNameW(LPCWSTR,LPWSTR,DWORD);
 BOOL GlobalMemoryStatusEx(LPMEMORYSTATUSEX);
 BOOL SetVolumeMountPointA(LPCSTR,LPCSTR);
 BOOL SetVolumeMountPointW(LPCWSTR,LPCWSTR);
 BOOL UnregisterWaitEx(HANDLE,HANDLE);
 BOOL AllocateUserPhysicalPages(HANDLE,PULONG_PTR,PULONG_PTR);
 BOOL FreeUserPhysicalPages(HANDLE,PULONG_PTR,PULONG_PTR);
 BOOL MapUserPhysicalPages(PVOID,ULONG_PTR,PULONG_PTR);
 BOOL MapUserPhysicalPagesScatter(PVOID*,ULONG_PTR,PULONG_PTR);
 BOOL ProcessIdToSessionId(DWORD,DWORD*);
 ULONG RemoveVectoredExceptionHandler(PVOID);
 BOOL ReplaceFileA(LPCSTR,LPCSTR,LPCSTR,DWORD,LPVOID,LPVOID);
 BOOL ReplaceFileW(LPCWSTR,LPCWSTR,LPCWSTR,DWORD,LPVOID,LPVOID);
 BOOL SetComputerNameExA(COMPUTER_NAME_FORMAT,LPCSTR);
 BOOL SetComputerNameExW(COMPUTER_NAME_FORMAT,LPCWSTR);
}

static if (_WIN32_WINNT >= 0x0501) {
 BOOL ActivateActCtx(HANDLE,ULONG_PTR*);
 void AddRefActCtx(HANDLE);
 BOOL CheckNameLegalDOS8Dot3A(LPCSTR,LPSTR,DWORD,PBOOL,PBOOL);
 BOOL CheckNameLegalDOS8Dot3W(LPCWSTR,LPSTR,DWORD,PBOOL,PBOOL);
 BOOL CheckRemoteDebuggerPresent(HANDLE,PBOOL);
 HANDLE CreateActCtxA(PCACTCTXA);
 HANDLE CreateActCtxW(PCACTCTXW);
 HANDLE CreateMemoryResourceNotification(MEMORY_RESOURCE_NOTIFICATION_TYPE);
 BOOL DebugActiveProcessStop(DWORD);
 BOOL DebugBreakProcess(HANDLE);
 BOOL DebugSetProcessKillOnExit(BOOL);
 BOOL DeactivateActCtx(DWORD,ULONG_PTR);
 BOOL GetCurrentActCtx(HANDLE*);
 BOOL FindActCtxSectionGuid(DWORD, GUID*,ULONG, GUID*,PACTCTX_SECTION_KEYED_DATA);
 BOOL FindActCtxSectionStringA(DWORD, GUID*,ULONG,LPCSTR,PACTCTX_SECTION_KEYED_DATA);
 BOOL FindActCtxSectionStringW(DWORD, GUID*,ULONG,LPCWSTR,PACTCTX_SECTION_KEYED_DATA);
 VOID GetNativeSystemInfo(LPSYSTEM_INFO);
 BOOL GetSystemTimes(LPFILETIME,LPFILETIME,LPFILETIME);
 UINT GetSystemWow64DirectoryA(LPSTR,UINT);
 UINT GetSystemWow64DirectoryW(LPWSTR,UINT);
 BOOL GetVolumePathNamesForVolumeNameA(LPCSTR,LPSTR,DWORD,PDWORD);
 BOOL GetVolumePathNamesForVolumeNameW(LPCWSTR,LPWSTR,DWORD,PDWORD);
 BOOL HeapQueryInformation(HANDLE,HEAP_INFORMATION_CLASS,PVOID,SIZE_T,PSIZE_T);
 BOOL HeapSetInformation(HANDLE,HEAP_INFORMATION_CLASS,PVOID,SIZE_T);
 BOOL IsProcessInJob(HANDLE,HANDLE,PBOOL);
 BOOL IsWow64Process(HANDLE,PBOOL);
 BOOL QueryActCtxW(DWORD,HANDLE,PVOID,ULONG,PVOID,SIZE_T,SIZE_T*);
 BOOL QueryMemoryResourceNotification(HANDLE,PBOOL);
 void ReleaseActCtx(HANDLE);
 BOOL SetFileShortNameA(HANDLE,LPCSTR);
 BOOL SetFileShortNameW(HANDLE,LPCWSTR);
 BOOL SetFileValidData(HANDLE,LONGLONG);
 BOOL ZombifyActCtx(HANDLE);
}
static if (_WIN32_WINNT >= 0x0502) {
 DWORD GetFirmwareEnvironmentVariableA(LPCSTR,LPCSTR,PVOID,DWORD);
 DWORD GetFirmwareEnvironmentVariableW(LPCWSTR,LPCWSTR,PVOID,DWORD);
 DWORD GetDllDirectoryA(DWORD,LPSTR);
 DWORD GetDllDirectoryW(DWORD,LPWSTR);
 DWORD GetProcessId(HANDLE);
 BOOL GetProcessHandleCount(HANDLE,PDWORD);
 BOOL GetSystemRegistryQuota(PDWORD,PDWORD);
 BOOL GetThreadIOPendingFlag(HANDLE,PBOOL);
 BOOL SetDllDirectoryA(LPCSTR);
 BOOL SetDllDirectoryW(LPCWSTR);
 BOOL SetFirmwareEnvironmentVariableA(LPCSTR,LPCSTR,PVOID,DWORD);
 BOOL SetFirmwareEnvironmentVariableW(LPCWSTR,LPCWSTR,PVOID,DWORD);
}


static if (_WIN32_WINNT >= 0x0510) {
 VOID RestoreLastError(DWORD);
}
} // extern(Windows)


// ------
// Aliases for ASCII or Unicode versions

version(Unicode) {
alias STARTUPINFOW STARTUPINFO;
alias WIN32_FIND_DATAW WIN32_FIND_DATA;
alias HW_PROFILE_INFOW HW_PROFILE_INFO;
alias STARTUPINFO * LPSTARTUPINFO;
alias WIN32_FIND_DATA * LPWIN32_FIND_DATA;
alias HW_PROFILE_INFO *LPHW_PROFILE_INFO;
alias AccessCheckAndAuditAlarmW AccessCheckAndAuditAlarm;
alias AddAtomW AddAtom;
alias BackupEventLogW BackupEventLog;
alias BeginUpdateResourceW BeginUpdateResource;
alias BuildCommDCBW BuildCommDCB;
alias BuildCommDCBAndTimeoutsW BuildCommDCBAndTimeouts;
alias CallNamedPipeW CallNamedPipe;
alias ClearEventLogW ClearEventLog;
alias CommConfigDialogW CommConfigDialog;
alias CopyFileW CopyFile;
alias CopyFileExW CopyFileEx;
alias CreateDirectoryW CreateDirectory;
alias CreateDirectoryExW CreateDirectoryEx;
alias CreateEventW CreateEvent;
alias CreateFileW CreateFile;
alias CreateFileMappingW CreateFileMapping;
alias CreateMailslotW CreateMailslot;
alias CreateMutexW CreateMutex;
alias CreateNamedPipeW CreateNamedPipe;
alias CreateProcessW CreateProcess;
alias CreateProcessAsUserW CreateProcessAsUser;
alias CreateSemaphoreW CreateSemaphore;
alias CreateWaitableTimerW CreateWaitableTimer;
alias DefineDosDeviceW DefineDosDevice;
alias DeleteFileW DeleteFile;
alias EncryptFileW EncryptFile;
alias EndUpdateResourceW EndUpdateResource;
alias EnumResourceLanguagesW EnumResourceLanguages;
alias EnumResourceNamesW EnumResourceNames;
alias EnumResourceTypesW EnumResourceTypes;
alias ExpandEnvironmentStringsW ExpandEnvironmentStrings;
alias FatalAppExitW FatalAppExit;
alias FileEncryptionStatusW FileEncryptionStatus;
alias FindAtomW FindAtom;
alias FindFirstChangeNotificationW FindFirstChangeNotification;
alias FindFirstFileW FindFirstFile;
alias FindFirstFileExW FindFirstFileEx;
alias FindNextFileW FindNextFile;
alias FindResourceW FindResource;
alias FindResourceExW FindResourceEx;
alias FormatMessageW FormatMessage;
alias FreeEnvironmentStringsW FreeEnvironmentStrings;
alias GetAtomNameW GetAtomName;
alias GetBinaryTypeW GetBinaryType;
alias GetCommandLineW GetCommandLine;
alias GetCompressedFileSizeW GetCompressedFileSize;
alias GetComputerNameW GetComputerName;
alias GetCurrentDirectoryW GetCurrentDirectory;
alias GetDefaultCommConfigW GetDefaultCommConfig;
alias GetDiskFreeSpaceW GetDiskFreeSpace;
alias GetDiskFreeSpaceExW GetDiskFreeSpaceEx;
alias GetDriveTypeW GetDriveType;
alias GetEnvironmentStringsW GetEnvironmentStrings;
alias GetEnvironmentVariableW GetEnvironmentVariable;
alias GetFileAttributesW GetFileAttributes;
alias GetFileSecurityW GetFileSecurity;
alias GetFileAttributesExW GetFileAttributesEx;
alias GetFullPathNameW GetFullPathName;
alias GetLogicalDriveStringsW GetLogicalDriveStrings;
alias GetModuleFileNameW GetModuleFileName;
alias GetModuleHandleW GetModuleHandle;
alias GetNamedPipeHandleStateW GetNamedPipeHandleState;
alias GetPrivateProfileIntW GetPrivateProfileInt;
alias GetPrivateProfileSectionW GetPrivateProfileSection;
alias GetPrivateProfileSectionNamesW GetPrivateProfileSectionNames;
alias GetPrivateProfileStringW GetPrivateProfileString;
alias GetPrivateProfileStructW GetPrivateProfileStruct;
alias GetProfileIntW GetProfileInt;
alias GetProfileSectionW GetProfileSection;
alias GetProfileStringW GetProfileString;
alias GetShortPathNameW GetShortPathName;
alias GetStartupInfoW GetStartupInfo;
alias GetSystemDirectoryW GetSystemDirectory;
alias GetTempFileNameW GetTempFileName;
alias GetTempPathW GetTempPath;
alias GetUserNameW GetUserName;
alias GetVersionExW GetVersionEx;
alias GetVolumeInformationW GetVolumeInformation;
alias GetWindowsDirectoryW GetWindowsDirectory;
alias GlobalAddAtomW GlobalAddAtom;
alias GlobalFindAtomW GlobalFindAtom;
alias GlobalGetAtomNameW GlobalGetAtomName;
alias IsBadStringPtrW IsBadStringPtr;
alias LoadLibraryW LoadLibrary;
alias LoadLibraryExW LoadLibraryEx;
alias LogonUserW LogonUser;
alias LookupAccountNameW LookupAccountName;
alias LookupAccountSidW LookupAccountSid;
alias LookupPrivilegeDisplayNameW LookupPrivilegeDisplayName;
alias LookupPrivilegeNameW LookupPrivilegeName;
alias LookupPrivilegeValueW LookupPrivilegeValue;
alias lstrcatW lstrcat;
alias lstrcmpW lstrcmp;
alias lstrcmpiW lstrcmpi;
alias lstrcpyW lstrcpy;
alias lstrcpynW lstrcpyn;
alias lstrlenW lstrlen;
alias MoveFileW MoveFile;
alias MoveFileExW MoveFileEx;
alias ObjectCloseAuditAlarmW ObjectCloseAuditAlarm;
alias ObjectDeleteAuditAlarmW ObjectDeleteAuditAlarm;
alias ObjectOpenAuditAlarmW ObjectOpenAuditAlarm;
alias ObjectPrivilegeAuditAlarmW ObjectPrivilegeAuditAlarm;
alias OpenBackupEventLogW OpenBackupEventLog;
alias OpenEventW OpenEvent;
alias OpenEventLogW OpenEventLog;
alias OpenFileMappingW OpenFileMapping;
alias OpenMutexW OpenMutex;
alias OpenSemaphoreW OpenSemaphore;
alias OutputDebugStringW OutputDebugString;
alias PrivilegedServiceAuditAlarmW PrivilegedServiceAuditAlarm;
alias QueryDosDeviceW QueryDosDevice;
alias ReadEventLogW ReadEventLog;
alias RegisterEventSourceW RegisterEventSource;
alias RemoveDirectoryW RemoveDirectory;
alias ReportEventW ReportEvent;
alias SearchPathW SearchPath;
alias SetComputerNameW SetComputerName;
alias SetCurrentDirectoryW SetCurrentDirectory;
alias SetDefaultCommConfigW SetDefaultCommConfig;
alias SetEnvironmentVariableW SetEnvironmentVariable;
alias SetFileAttributesW SetFileAttributes;
alias SetFileSecurityW SetFileSecurity;
alias SetVolumeLabelW SetVolumeLabel;
alias UpdateResourceW UpdateResource;
alias VerifyVersionInfoW VerifyVersionInfo;
alias WaitNamedPipeW WaitNamedPipe;
alias WritePrivateProfileSectionW WritePrivateProfileSection;
alias WritePrivateProfileStringW WritePrivateProfileString;
alias WritePrivateProfileStructW WritePrivateProfileStruct;
alias WriteProfileSectionW WriteProfileSection;
alias WriteProfileStringW WriteProfileString;

static if ((_WIN32_WINNT >= 0x0500) || (_WIN32_WINDOWS >= 0x0410)) {
	alias GetLongPathNameW GetLongPathName;
}

static if (_WIN32_WINNT >= 0x0500) {
	alias CreateHardLinkW CreateHardLink;
	alias CreateJobObjectW CreateJobObject;
	alias DeleteVolumeMountPointW DeleteVolumeMountPoint;
	alias DnsHostnameToComputerNameW DnsHostnameToComputerName;
	alias FindFirstVolumeW FindFirstVolume;
	alias FindFirstVolumeMountPointW FindFirstVolumeMountPoint;
	alias FindNextVolumeW FindNextVolume;
	alias FindNextVolumeMountPointW FindNextVolumeMountPoint;
	alias GetSystemWindowsDirectoryW GetSystemWindowsDirectory;
	alias ReplaceFileW ReplaceFile;
	alias GetModuleHandleExW GetModuleHandleEx;
	alias GetVolumeNameForVolumeMountPointW GetVolumeNameForVolumeMountPoint;
	alias GetVolumePathNameW GetVolumePathName;
	alias SetVolumeMountPointW SetVolumeMountPoint;
}
static if (_WIN32_WINNT >= 0x0501) {
	alias ACTCTXW ACTCTX;
	alias ACTCTX * PACTCTX;
	alias PCACTCTXW PCACTCTX;
	alias GetVolumePathNamesForVolumeNameW GetVolumePathNamesForVolumeName;
	alias GetSystemWow64DirectoryW GetSystemWow64Directory;
	alias SetFileShortNameW SetFileShortName;
	alias CheckNameLegalDOS8Dot3W CheckNameLegalDOS8Dot3;
	alias CreateActCtxW CreateActCtx;
	alias FindActCtxSectionStringW FindActCtxSectionString;
}

static if (_WIN32_WINNT >= 0x0502) {
	alias SetFirmwareEnvironmentVariableW SetFirmwareEnvironmentVariable;
	alias SetDllDirectoryW SetDllDirectory;
	alias GetDllDirectoryW GetDllDirectory;
}

} else {
// --------
// Aliases for ASCII

alias STARTUPINFOA STARTUPINFO;
alias WIN32_FIND_DATAA WIN32_FIND_DATA;
alias HW_PROFILE_INFOA HW_PROFILE_INFO;
alias STARTUPINFO * LPSTARTUPINFO;
alias WIN32_FIND_DATA * LPWIN32_FIND_DATA;
alias HW_PROFILE_INFO *LPHW_PROFILE_INFO;
alias AccessCheckAndAuditAlarmA AccessCheckAndAuditAlarm;
alias AddAtomA AddAtom;
alias BackupEventLogA BackupEventLog;
alias BeginUpdateResourceA BeginUpdateResource;
alias BuildCommDCBA BuildCommDCB;
alias BuildCommDCBAndTimeoutsA BuildCommDCBAndTimeouts;
alias CallNamedPipeA CallNamedPipe;
alias ClearEventLogA ClearEventLog;
alias CommConfigDialogA CommConfigDialog;
alias CopyFileA CopyFile;
alias CopyFileExA CopyFileEx;
alias CreateDirectoryA CreateDirectory;
alias CreateDirectoryExA CreateDirectoryEx;
alias CreateEventA CreateEvent;
alias CreateFileA CreateFile;
alias CreateFileMappingA CreateFileMapping;
alias CreateMailslotA CreateMailslot;
alias CreateMutexA CreateMutex;
alias CreateNamedPipeA CreateNamedPipe;
alias CreateProcessA CreateProcess;
alias CreateProcessAsUserA CreateProcessAsUser;
alias CreateSemaphoreA CreateSemaphore;
alias CreateWaitableTimerA CreateWaitableTimer;
alias DefineDosDeviceA DefineDosDevice;
alias DeleteFileA DeleteFile;
alias EncryptFileA EncryptFile;
alias EndUpdateResourceA EndUpdateResource;
alias EnumResourceLanguagesA EnumResourceLanguages;
alias EnumResourceNamesA EnumResourceNames;
alias EnumResourceTypesA EnumResourceTypes;
alias ExpandEnvironmentStringsA ExpandEnvironmentStrings;
alias FatalAppExitA FatalAppExit;
alias FileEncryptionStatusA FileEncryptionStatus;
alias FindAtomA FindAtom;
alias FindFirstChangeNotificationA FindFirstChangeNotification;
alias FindFirstFileA FindFirstFile;
alias FindFirstFileExA FindFirstFileEx;
alias FindNextFileA FindNextFile;
alias FindResourceA FindResource;
alias FindResourceExA FindResourceEx;
alias FormatMessageA FormatMessage;
alias FreeEnvironmentStringsA FreeEnvironmentStrings;
alias GetAtomNameA GetAtomName;
alias GetBinaryTypeA GetBinaryType;
alias GetCommandLineA GetCommandLine;
alias GetComputerNameA GetComputerName;
alias GetCompressedFileSizeA GetCompressedFileSize;
alias GetCurrentDirectoryA GetCurrentDirectory;
alias GetDefaultCommConfigA GetDefaultCommConfig;
alias GetDiskFreeSpaceA GetDiskFreeSpace;
alias GetDiskFreeSpaceExA GetDiskFreeSpaceEx;
alias GetDriveTypeA GetDriveType;
alias GetEnvironmentVariableA GetEnvironmentVariable;
alias GetFileAttributesA GetFileAttributes;
alias GetFileSecurityA GetFileSecurity;
alias GetFileAttributesExA GetFileAttributesEx;
alias GetFullPathNameA GetFullPathName;
alias GetLogicalDriveStringsA GetLogicalDriveStrings;
alias GetNamedPipeHandleStateA GetNamedPipeHandleState;
alias GetModuleHandleA GetModuleHandle;
alias GetModuleFileNameA GetModuleFileName;
alias GetPrivateProfileIntA GetPrivateProfileInt;
alias GetPrivateProfileSectionA GetPrivateProfileSection;
alias GetPrivateProfileSectionNamesA GetPrivateProfileSectionNames;
alias GetPrivateProfileStringA GetPrivateProfileString;
alias GetPrivateProfileStructA GetPrivateProfileStruct;
alias GetProfileIntA GetProfileInt;
alias GetProfileSectionA GetProfileSection;
alias GetProfileStringA GetProfileString;
alias GetShortPathNameA GetShortPathName;
alias GetStartupInfoA GetStartupInfo;
alias GetSystemDirectoryA GetSystemDirectory;
alias GetTempFileNameA GetTempFileName;
alias GetTempPathA GetTempPath;
alias GetUserNameA GetUserName;
alias GetVersionExA GetVersionEx;
alias GetVolumeInformationA GetVolumeInformation;
alias GetWindowsDirectoryA GetWindowsDirectory;
alias GlobalAddAtomA GlobalAddAtom;
alias GlobalFindAtomA GlobalFindAtom;
alias GlobalGetAtomNameA GlobalGetAtomName;
alias IsBadStringPtrA IsBadStringPtr;
alias LoadLibraryA LoadLibrary;
alias LoadLibraryExA LoadLibraryEx;
alias LogonUserA LogonUser;
alias LookupAccountNameA LookupAccountName;
alias LookupAccountSidA LookupAccountSid;
alias LookupPrivilegeDisplayNameA LookupPrivilegeDisplayName;
alias LookupPrivilegeNameA LookupPrivilegeName;
alias LookupPrivilegeValueA LookupPrivilegeValue;
alias lstrcatA lstrcat;
alias lstrcmpA lstrcmp;
alias lstrcmpiA lstrcmpi;
alias lstrcpyA lstrcpy;
alias lstrcpynA lstrcpyn;
alias lstrlenA lstrlen;
alias MoveFileA MoveFile;
alias MoveFileExA MoveFileEx;
alias ObjectCloseAuditAlarmA ObjectCloseAuditAlarm;
alias ObjectDeleteAuditAlarmA ObjectDeleteAuditAlarm;
alias ObjectOpenAuditAlarmA ObjectOpenAuditAlarm;
alias ObjectPrivilegeAuditAlarmA ObjectPrivilegeAuditAlarm;
alias OpenBackupEventLogA OpenBackupEventLog;
alias OpenEventA OpenEvent;
alias OpenEventLogA OpenEventLog;
alias OpenFileMappingA OpenFileMapping;
alias OpenMutexA OpenMutex;
alias OpenSemaphoreA OpenSemaphore;
alias OutputDebugStringA OutputDebugString;
alias PrivilegedServiceAuditAlarmA PrivilegedServiceAuditAlarm;
alias QueryDosDeviceA QueryDosDevice;
alias ReadEventLogA ReadEventLog;
alias RegisterEventSourceA RegisterEventSource;
alias RemoveDirectoryA RemoveDirectory;
alias ReportEventA ReportEvent;
alias SearchPathA SearchPath;
alias SetComputerNameA SetComputerName;
alias SetCurrentDirectoryA SetCurrentDirectory;
alias SetDefaultCommConfigA SetDefaultCommConfig;
alias SetEnvironmentVariableA SetEnvironmentVariable;
alias SetFileAttributesA SetFileAttributes;
alias SetFileSecurityA SetFileSecurity;
alias SetVolumeLabelA SetVolumeLabel;
alias UpdateResourceA UpdateResource;
alias VerifyVersionInfoA VerifyVersionInfo;
alias WaitNamedPipeA WaitNamedPipe;
alias WritePrivateProfileSectionA WritePrivateProfileSection;
alias WritePrivateProfileStringA WritePrivateProfileString;
alias WritePrivateProfileStructA WritePrivateProfileStruct;
alias WriteProfileSectionA WriteProfileSection;
alias WriteProfileStringA WriteProfileString;

static if ((_WIN32_WINNT >= 0x0500) || (_WIN32_WINDOWS >= 0x0410)) {
	alias GetLongPathNameA GetLongPathName;
}

static if (_WIN32_WINNT >= 0x0500) {
	alias GetVolumeNameForVolumeMountPointA GetVolumeNameForVolumeMountPoint;
	alias GetVolumePathNameA GetVolumePathName;
	alias SetVolumeMountPointA SetVolumeMountPoint;
	alias CreateHardLinkA CreateHardLink;
	alias CreateJobObjectA CreateJobObject;
	alias DeleteVolumeMountPointA DeleteVolumeMountPoint;
	alias DnsHostnameToComputerNameA DnsHostnameToComputerName;
	alias GetModuleHandleExA GetModuleHandleEx;
	alias GetSystemWindowsDirectoryA GetSystemWindowsDirectory;
	alias ReplaceFileA ReplaceFile;
	alias FindFirstVolumeA FindFirstVolume;
	alias FindNextVolumeA FindNextVolume;
	alias FindFirstVolumeMountPointA FindFirstVolumeMountPoint;
	alias FindNextVolumeMountPointA FindNextVolumeMountPoint;
}
static if (_WIN32_WINNT >= 0x0501) {
	alias ACTCTXA ACTCTX;
	alias ACTCTXA * PACTCTX;
	alias PCACTCTXA PCACTCTX;
	alias GetVolumePathNamesForVolumeNameA GetVolumePathNamesForVolumeName;
	alias FindActCtxSectionStringA FindActCtxSectionString;
	alias CheckNameLegalDOS8Dot3A CheckNameLegalDOS8Dot3;
	alias CreateActCtxA CreateActCtx;
	alias SetFileShortNameA SetFileShortName;
	alias GetSystemWow64DirectoryA GetSystemWow64Directory;
}

static if (_WIN32_WINNT >= 0x0502) {
	alias GetDllDirectoryA GetDllDirectory;
	alias SetDllDirectoryA SetDllDirectory;
	alias SetFirmwareEnvironmentVariableA SetFirmwareEnvironmentVariable;
}

}

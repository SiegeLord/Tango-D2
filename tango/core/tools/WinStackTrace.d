/**
 *   Stacktracing
 *
 *   Inclusion of this module activates traced exceptions using the tango own tracers if possible.
 *
 *  Copyright: Copyright (C) 2009 h3r3tic
 *  License:   Tango License, Apache 2.0
 *  Author:    Tomasz Stachowiak (h3r3tic)
 */
module tango.core.tools.WinStackTrace;

version(Windows) {

import tango.core.Thread;
import tango.core.tools.FrameInfo;

version(D_Version2)
{
    private const(char)[] intToUtf8 (char[] tmp, uint val)
    in {
         assert (tmp.length > 9, "atoi buffer should be more than 9 chars wide");
         }
    body
    {
            char* p = tmp.ptr + tmp.length;

            do {
                 *--p = cast(char)((val % 10) + '0');
                 } while (val /= 10);

            return tmp [cast(size_t)(p - tmp.ptr) .. $];
    }

    // function to compare two strings
    private int stringCompare (in char[] s1, in char[] s2)
    {
            auto len = s1.length;

            if (s2.length < len)
                    len = s2.length;

            int result = memcmp(s1.ptr, s2.ptr, len);

            if (result == 0)
                    result = (s1.length<s2.length)?-1:((s1.length==s2.length)?0:1);

            return result;
    }
}

    private {
        import tango.core.tools.Demangler;
        import tango.core.Runtime;
        static import tango.stdc.stdlib;
        static import tango.stdc.string;
        version (StacktraceSpam) import tango.stdc.stdio : printf;
    }

    version = StacktraceTryMatchCallAddresses;
    version = StacktraceTryToBeSmart;
    //version = UseCustomFiberForDemangling;
    version = DemangleFunctionNames;

    struct TraceContext{
        LPCONTEXT context;
        HANDLE hProcess;
        HANDLE hThread;
    }

    size_t winAddrBacktrace(TraceContext* winCtx,TraceContext* contextOut,size_t*traceBuf,size_t traceBufLength,int *flags){
        CONTEXT     context;
        CONTEXT*    ctxPtr = &context;
        
        HANDLE hProcess = void;
        HANDLE hThread = void;
        
        if (winCtx !is null) {
            ctxPtr=winCtx.context;
            hProcess=winCtx.hProcess;
            hThread=winCtx.hThread;
        } else {
            uint eipReg, espReg, ebpReg;
            asm {
                call GIMMEH_EIP;
                GIMMEH_EIP:
                    pop EAX;
                    mov eipReg, EAX;
                mov espReg, ESP;
                mov ebpReg, EBP;
            }

            hProcess = GetCurrentProcess();
            hThread = GetCurrentThread();
            
            context.ContextFlags = CONTEXT_i386 | CONTEXT_CONTROL;
            GetThreadContext(hThread, &context);
            context.Eip = eipReg;
            context.Esp = espReg;
            context.Ebp = ebpReg;
        }
        if (contextOut !is null){
            contextOut.context=ctxPtr;
            contextOut.hProcess=hProcess;
            contextOut.hThread=hThread;
        }
        
        version (StacktraceSpam) printf("Eip: %x, Esp: %x, Ebp: %x\n", ctxPtr.Eip, ctxPtr.Esp, ctxPtr.Ebp);
    
        version (StacktraceUseWinApiStackWalking) {
            // IsBadReadPtr will always return true here
        } else {
            if (IsBadReadPtr(cast(void*)ctxPtr.Ebp, 4)) {
                ctxPtr.Ebp = ctxPtr.Esp;
            }
        }

        size_t traceLen = 0;
        walkStack(ctxPtr, hProcess, hThread, delegate void(size_t[]tr){
            if (tr.length > traceBufLength) {
                traceLen = traceBufLength;
            } else {
                traceLen = tr.length;
            }

            traceBuf[0..traceLen] = tr[0..traceLen];
        });
        
        version(StacktraceTryMatchCallAddresses){
            *flags=3;
        } else {
            *flags=1;
        }
        return traceLen;
    }
    
    
    bool winSymbolizeFrameInfo(ref FrameInfo fInfo, const(TraceContext) *context,char[] buf){
        HANDLE hProcess;
        if (context!is null){
            hProcess=cast(HANDLE)context.hProcess;
        } else {
            hProcess=GetCurrentProcess();
        }
        return addrToSymbolDetails(fInfo.address, hProcess, (const(char)[] func, const(char)[] file, int line, ptrdiff_t addrOffset) {
            if (func.length > buf.length) {
                buf[] = func[0..buf.length];
                fInfo.func = buf;
            } else {
                buf[0..func.length] = func;
                fInfo.func = buf[0..func.length];
            }
            fInfo.file = file;
            fInfo.line = line;
            fInfo.offsetSymb = addrOffset;
        });
    }

//#line 2 "parts/Main.di"


private extern(C) {
    void        _Dmain();
    void        D4core6thread5Fiber3runMFZv();
}
private {
    size_t  fiberRunFuncLength = 0;
}

struct Context
{
    void*    bstack,
             tstack;
    Context* within;
    Context* next,
             prev;
}

extern(C) Context* D4core6thread6Thread10topContextMFZPS4core6thread6Thread7Context(core.thread.Thread);
alias D4core6thread6Thread10topContextMFZPS4core6thread6Thread7Context Thread_topContext;


void walkStack(LPCONTEXT ContextRecord, HANDLE hProcess, HANDLE hThread, void delegate(size_t[]) traceReceiver) {
    const int maxStackSpace = 32;
    const int maxHeapSpace      = 256;
    static assert (maxHeapSpace  > maxStackSpace);
    
    size_t[maxStackSpace]   stackTraceArr = void;
    size_t[]                            heapTraceArr;
    size_t[]                            stacktrace = stackTraceArr;
    uint                                i = void;
    
    void addAddress(size_t addr) {
        if (i < maxStackSpace) {
            stacktrace[i++] = addr;
        } else {
            if (maxStackSpace == i) {
                if (heapTraceArr is null) {
                    heapTraceArr.alloc(maxHeapSpace, false);
                    heapTraceArr[0..maxStackSpace] = stackTraceArr;
                    stacktrace = heapTraceArr;
                }
                stacktrace[i++] = addr;
            } else if (i < maxHeapSpace) {
                stacktrace[i++] = addr;
            }
        }
    }


    version (StacktraceUseWinApiStackWalking) {
        STACKFRAME64 frame;
        memset(&frame, 0, frame.sizeof);

        frame.AddrStack.Offset  = ContextRecord.Esp;
        frame.AddrPC.Offset     = ContextRecord.Eip;
        frame.AddrFrame.Offset  = ContextRecord.Ebp;
        frame.AddrStack.Mode    = frame.AddrPC.Mode = frame.AddrFrame.Mode = ADDRESS_MODE.AddrModeFlat;

        //for (int sanity = 0; sanity < 256; ++sanity) {
        for (i = 0; i < maxHeapSpace; ) {
            auto swres = StackWalk64(
                IMAGE_FILE_MACHINE_I386,
                hProcess,
                hThread,
                &frame,
                ContextRecord,
                null,
                SymFunctionTableAccess64,
                SymGetModuleBase64,
                null
            );
            
            if (!swres) {
                break;
            }
            
            version (StacktraceSpam) printf("pc:%x ret:%x frm:%x stk:%x parm:%x %x %x %x\n",
                    frame.AddrPC.Offset, frame.AddrReturn.Offset, frame.AddrFrame.Offset, frame.AddrStack.Offset,
                    frame.Params[0], frame.Params[1], frame.Params[2], frame.Params[3]);

            addAddress(frame.AddrPC.Offset);
        }
    } else {
        struct Layout {
            Layout* ebp;
            size_t  ret;
        }
        Layout* p = cast(Layout*)ContextRecord.Esp;
        
        
        bool foundMain = false;     
        enum Phase {
            TryEsp,
            TryEbp,
            GiveUp
        }
        
        Phase phase = ContextRecord.Esp == ContextRecord.Ebp ? Phase.TryEbp : Phase.TryEsp;
        stacktrace[0] = ContextRecord.Eip;
        
        version (StacktraceTryToBeSmart) {
            Thread tobj = Thread.getThis();
        }
        
        while (!foundMain && phase < Phase.GiveUp) {
            version (StacktraceSpam) printf("starting a new tracing phase\n");
            
            version (StacktraceTryToBeSmart) {
                auto curStack = Thread_topContext(tobj);
            }
            
            for (i = 1; p && !IsBadReadPtr(p, Layout.sizeof) && i < maxHeapSpace && !IsBadReadPtr(cast(void*)p.ret, 4);) {
                auto sym = p.ret;
                
                enum {
                    NearPtrCallOpcode = 0xe8,
                    RegisterBasedCallOpcode = 0xff
                }

                uint callAddr = p.ret;
                if (size_t.sizeof == 4 && !IsBadReadPtr(cast(void*)(p.ret - 5), 8) && NearPtrCallOpcode == *cast(ubyte*)(p.ret - 5)) {
                    callAddr += *cast(uint*)(p.ret - 4);
                    version (StacktraceSpam) printf("ret:%x frm:%x call:%x\n", sym, p, callAddr);
                    version (StacktraceTryMatchCallAddresses) {
                        addAddress(p.ret - 5);  // a near call is 5 bytes
                    }
                } else {
                    version (StacktraceTryMatchCallAddresses) {
                        if (!IsBadReadPtr(cast(void*)p.ret - 2, 4) && RegisterBasedCallOpcode == *cast(ubyte*)(p.ret - 2)) {
                            version (StacktraceSpam) printf("ret:%x frm:%x register-based call:[%x]\n", sym, p, *cast(ubyte*)(p.ret - 1));
                            addAddress(p.ret - 2);  // an offset-less register-based call is 2 bytes for the call + register setup
                        } else if (!IsBadReadPtr(cast(void*)p.ret - 3, 4) && RegisterBasedCallOpcode == *cast(ubyte*)(p.ret - 3)) {
                            version (StacktraceSpam) printf("ret:%x frm:%x register-based call:[%x,%x]\n", sym, p, *cast(ubyte*)(p.ret - 2), *cast(ubyte*)(p.ret - 1));
                            addAddress(p.ret - 3);  // a register-based call is 3 bytes for the call + register setup
                        } else {
                            version (StacktraceSpam) printf("ret:%x frm:%x\n", sym, p);
                            addAddress(p.ret);
                        }
                    }
                }

                version (StacktraceTryToBeSmart) {
                    bool inFiber = false;
                    if  (
                            callAddr == cast(uint)&_Dmain
                            || true == (inFiber = (
                                callAddr >= cast(uint)&D4core6thread5Fiber3runMFZv
                                && callAddr < cast(uint)&D4core6thread5Fiber3runMFZv + fiberRunFuncLength
                            ))
                        )
                    {
                        foundMain = true;
                        if (inFiber) {
                            version (StacktraceSpam) printf("Got or Thread.Fiber.run\n");

                            version (StacktraceTryMatchCallAddresses) {
                                // handled above
                            } else {
                                addAddress(p.ret);
                            }

                            curStack = curStack.within;
                            if (curStack) {
                                void* newp = curStack.tstack;

                                if (!IsBadReadPtr(newp + 28, 8)) {
                                    addAddress(*cast(size_t*)(newp + 32));
                                    p = *cast(Layout**)(newp + 28);
                                    continue;
                                }
                            }
                        } else {
                            version (StacktraceSpam) printf("Got _Dmain\n");
                        }
                    }
                }
                
                version (StacktraceTryMatchCallAddresses) {
                    // handled above
                } else {
                    addAddress(p.ret);
                }
                
                p = p.ebp;
            }

            ++phase;
            p = cast(Layout*)ContextRecord.Ebp;
            version (StacktraceSpam) printf("end of phase\n");
        }
        
        version (StacktraceSpam) printf("calling traceReceiver\n");
    }

    traceReceiver(stacktrace[0..i]);
    heapTraceArr.free();
}


bool addrToSymbolDetails(size_t addr, HANDLE hProcess, void delegate(const(char)[] func, const(char)[] file, int line, ptrdiff_t addrOffset) dg) {
    ubyte buffer[256];

    SYMBOL_INFO* symbol_info = cast(SYMBOL_INFO*)buffer.ptr;
    symbol_info.SizeOfStruct = SYMBOL_INFO.sizeof;
    symbol_info.MaxNameLen = buffer.length - SYMBOL_INFO.sizeof + 1;
    
    ptrdiff_t addrOffset = 0;
    auto ln = getAddrDbgInfo(addr, &addrOffset);

    bool success = true;

    char* symname = null;
    if (!SymFromAddr(hProcess, addr, null, symbol_info)) {
        //printf("%.*s\n", SysError.lastMsg);
        symname = ln.func;
        success = ln != AddrDebugInfo.init;
    } else {
        symname = symbol_info.Name.ptr;
    }

    dg(fromStringz(symname).dup, fromStringz(ln.file).dup, ln.line, addrOffset);
    return success;
}


//#line 2 "parts/Memory.di"
private {
    import tango.stdc.stdlib : cMalloc = malloc, cRealloc = realloc, cFree = free;
}

public {
    import tango.stdc.string : memset;
}


/**
    Allocate the array using malloc
    
    Params:
    array = the array which will be resized
    numItems = number of items to be allocated in the array
    init = whether to init the allocated items to their default values or not
    
    Examples:
    ---
    int[] foo;
    foo.alloc(20);
    ---
    
    Remarks:
    The array must be null and empty for this function to succeed. The rationale behind this is that the coder should state his decision clearly. This will help and has
    already helped to spot many intricate bugs. 
*/
void alloc(T, intT)(ref T array, intT numItems, bool init = true) 
in {
    assert (array is null);
    assert (numItems >= 0);
}
out {
    assert (numItems == array.length);
}
body {
    alias typeof(T.init[0]) ItemT;
    array = (cast(ItemT*)cMalloc(ItemT.sizeof * numItems))[0 .. numItems];
    
    static if (is(typeof(ItemT.init))) {
        if (init) {
            array[] = ItemT.init;
        }
    }
}


/**
    Clone the given array. The result is allocated using alloc() and copied piecewise from the param. Then it's returned
*/
T clone(T)(T array) {
    T res;
    res.alloc(array.length, false);
    res[] = array[];
    return res;
}


/**
    Realloc the contents of an array
    
    array = the array which will be resized
    numItems = the new size for the array
    init = whether to init the newly allocated items to their default values or not
    
    Examples:
    ---
    int[] foo;
    foo.alloc(20);
    foo.realloc(10);        // <--
    ---
*/
void realloc(T, intT)(ref T array, intT numItems, bool init = true)
in {
    assert (numItems >= 0);
}
out {
    assert (numItems == array.length);
}
body {
    alias typeof(T.init[0]) ItemT;
    intT oldLen = array.length;
    array = (cast(ItemT*)cRealloc(array.ptr, ItemT.sizeof * numItems))[0 .. numItems];
    
    static if (is(typeof(ItemT.init))) {
        if (init && numItems > oldLen) {
            array[oldLen .. numItems] = ItemT.init;
        }
    }
}


/**
    Deallocate an array allocated with alloc()
*/
void free(T)(ref T array)
out {
    assert (0 == array.length);
}
body {
    cFree(array.ptr);
    array = null;
}


/**
    Append an item to an array. Optionally keep track of an external 'real length', while doing squared reallocation of the array
    
    Params:
    array = the array to append the item to
    elem = the new item to be appended
    realLength = the optional external 'real length'
    
    Remarks:
    if realLength isn't null, the array is not resized by one, but allocated in a std::vector manner. The array's length becomes it's capacity, while 'realLength'
    is the number of items in the array.
    
    Examples:
    ---
    uint barLen = 0;
    int[] bar;
    append(bar, 10, &barLen);
    append(bar, 20, &barLen);
    append(bar, 30, &barLen);
    append(bar, 40, &barLen);
    assert (bar.length == 16);
    assert (barLen == 4);
    ---
*/
void append(T, I)(ref T array, I elem, uint* realLength = null) {
    uint len = realLength is null ? array.length : *realLength;
    uint capacity = array.length;
    alias typeof(T.init[0]) ItemT;
    
    if (len >= capacity) {
        if (realLength is null) {       // just add one element to the array
            int numItems = len+1;
            array = (cast(ItemT*)cRealloc(array.ptr, ItemT.sizeof * numItems))[0 .. numItems];
        } else {                                // be smarter and allocate in power-of-two increments
            const uint initialCapacity = 4;
            int numItems = capacity == 0 ? initialCapacity : capacity * 2; 
            array = (cast(ItemT*)cRealloc(array.ptr, ItemT.sizeof * numItems))[0 .. numItems];
            ++*realLength;
        }
    } else if (realLength !is null) ++*realLength;
    
    array[len] = elem;
}
//#line 2 "parts/WinApi.di"
import tango.text.Util;
import tango.core.Thread;
import tango.core.Array;
import tango.sys.Common : SysError;
import tango.sys.SharedLib : SharedLib;
import tango.stdc.stdio;
import tango.stdc.string;
import tango.stdc.stringz;





enum {
    MAX_PATH = 260,
}

enum : WORD {
    IMAGE_FILE_MACHINE_UNKNOWN = 0,
    IMAGE_FILE_MACHINE_I386    = 332,
    IMAGE_FILE_MACHINE_R3000   = 354,
    IMAGE_FILE_MACHINE_R4000   = 358,
    IMAGE_FILE_MACHINE_R10000  = 360,
    IMAGE_FILE_MACHINE_ALPHA   = 388,
    IMAGE_FILE_MACHINE_POWERPC = 496
}

version(X86) {
    const SIZE_OF_80387_REGISTERS=80;
    const CONTEXT_i386=0x10000;
    const CONTEXT_i486=0x10000;
    const CONTEXT_CONTROL=(CONTEXT_i386|0x00000001L);
    const CONTEXT_INTEGER=(CONTEXT_i386|0x00000002L);
    const CONTEXT_SEGMENTS=(CONTEXT_i386|0x00000004L);
    const CONTEXT_FLOATING_POINT=(CONTEXT_i386|0x00000008L);
    const CONTEXT_DEBUG_REGISTERS=(CONTEXT_i386|0x00000010L);
    const CONTEXT_EXTENDED_REGISTERS=(CONTEXT_i386|0x00000020L);
    const CONTEXT_FULL=(CONTEXT_CONTROL|CONTEXT_INTEGER|CONTEXT_SEGMENTS);
    const MAXIMUM_SUPPORTED_EXTENSION=512;

    struct FLOATING_SAVE_AREA {
        DWORD    ControlWord;
        DWORD    StatusWord;
        DWORD    TagWord;
        DWORD    ErrorOffset;
        DWORD    ErrorSelector;
        DWORD    DataOffset;
        DWORD    DataSelector;
        BYTE[80] RegisterArea;
        DWORD    Cr0NpxState;
    }

    struct CONTEXT {
        DWORD ContextFlags;
        DWORD Dr0;
        DWORD Dr1;
        DWORD Dr2;
        DWORD Dr3;
        DWORD Dr6;
        DWORD Dr7;
        FLOATING_SAVE_AREA FloatSave;
        DWORD SegGs;
        DWORD SegFs;
        DWORD SegEs;
        DWORD SegDs;
        DWORD Edi;
        DWORD Esi;
        DWORD Ebx;
        DWORD Edx;
        DWORD Ecx;
        DWORD Eax;
        DWORD Ebp;
        DWORD Eip;
        DWORD SegCs;
        DWORD EFlags;
        DWORD Esp;
        DWORD SegSs;
        BYTE[MAXIMUM_SUPPORTED_EXTENSION] ExtendedRegisters;
    }

} else {
    pragma(msg, "Unsupported CPU");
    static assert(0);
    // Versions for PowerPC, Alpha, SHX, and MIPS removed.
}


alias CONTEXT* PCONTEXT, LPCONTEXT;

alias void* HANDLE;

alias char CHAR;
alias void* PVOID, LPVOID;

alias wchar WCHAR;
alias WCHAR* PWCHAR, LPWCH, PWCH, LPWSTR, PWSTR;
alias CHAR* PCHAR, LPCH, PCH, LPSTR, PSTR;

// const versions
alias const(WCHAR)* LPCWCH, PCWCH, LPCWSTR, PCWSTR;
alias const(CHAR)* LPCCH, PCSTR, LPCSTR;

version(Unicode) {
    alias WCHAR TCHAR, _TCHAR;
} else {
    alias CHAR TCHAR, _TCHAR;
}

alias TCHAR* PTCH, PTBYTE, LPTCH, PTSTR, LPTSTR, LP, PTCHAR, LPCTSTR;

alias ubyte   BYTE;
alias ubyte*  PBYTE, LPBYTE;
alias ushort  USHORT, WORD, ATOM;
alias ushort* PUSHORT, PWORD, LPWORD;
alias uint    ULONG, DWORD, UINT, COLORREF;
alias uint*   PULONG, PDWORD, LPDWORD, PUINT, LPUINT;
alias int     BOOL, INT, LONG;
alias HANDLE HMODULE;

enum : BOOL {
    FALSE = 0,
    TRUE = 1,
}

struct EXCEPTION_POINTERS {
  void* ExceptionRecord;
  CONTEXT* ContextRecord;
}

version (Win64) {
    alias long INT_PTR, LONG_PTR;
    alias ulong UINT_PTR, ULONG_PTR, HANDLE_PTR;
} else {
    alias int INT_PTR, LONG_PTR;
    alias uint UINT_PTR, ULONG_PTR, HANDLE_PTR;
}

alias ulong ULONG64, DWORD64, UINT64;
alias ulong* PULONG64, PDWORD64, PUINT64;


extern(Windows) {
    HANDLE GetCurrentProcess();
    HANDLE GetCurrentThread();
    BOOL GetThreadContext(HANDLE, LPCONTEXT);
}


void loadWinAPIFunctions() {
    auto dbghelp = SharedLib.load(`dbghelp.dll`);
    
    auto SymEnumerateModules64 = cast(fp_SymEnumerateModules64)dbghelp.getSymbol("SymEnumerateModules64");
    SymFromAddr = cast(fp_SymFromAddr)dbghelp.getSymbol("SymFromAddr");
    assert (SymFromAddr !is null);
    SymFromName = cast(fp_SymFromName)dbghelp.getSymbol("SymFromName");
    assert (SymFromName !is null);
    SymLoadModule64 = cast(fp_SymLoadModule64)dbghelp.getSymbol("SymLoadModule64");
    assert (SymLoadModule64 !is null);
    SymInitialize = cast(fp_SymInitialize)dbghelp.getSymbol("SymInitialize");
    assert (SymInitialize !is null);
    SymCleanup = cast(fp_SymCleanup)dbghelp.getSymbol("SymCleanup");
    assert (SymCleanup !is null);
    SymSetOptions = cast(fp_SymSetOptions)dbghelp.getSymbol("SymSetOptions");
    assert (SymSetOptions !is null);
    SymGetLineFromAddr64 = cast(fp_SymGetLineFromAddr64)dbghelp.getSymbol("SymGetLineFromAddr64");
    assert (SymGetLineFromAddr64 !is null);
    SymEnumSymbols = cast(fp_SymEnumSymbols)dbghelp.getSymbol("SymEnumSymbols");
    assert (SymEnumSymbols !is null);
    SymGetModuleBase64 = cast(fp_SymGetModuleBase64)dbghelp.getSymbol("SymGetModuleBase64");
    assert (SymGetModuleBase64 !is null);
    StackWalk64 = cast(fp_StackWalk64)dbghelp.getSymbol("StackWalk64");
    assert (StackWalk64 !is null);
    SymFunctionTableAccess64 = cast(fp_SymFunctionTableAccess64)dbghelp.getSymbol("SymFunctionTableAccess64");
    assert (SymFunctionTableAccess64 !is null);
    
    
    auto psapi = SharedLib.load(`psapi.dll`);
    GetModuleFileNameExA = cast(fp_GetModuleFileNameExA)psapi.getSymbol("GetModuleFileNameExA");
    assert (GetModuleFileNameExA !is null);
}



extern (Windows) {
    __gshared fp_SymFromAddr      SymFromAddr;
    __gshared fp_SymFromName      SymFromName;
    __gshared fp_SymLoadModule64  SymLoadModule64;
    __gshared fp_SymInitialize            SymInitialize;
    __gshared fp_SymCleanup           SymCleanup;
    __gshared fp_SymSetOptions        SymSetOptions;
    __gshared fp_SymGetLineFromAddr64 SymGetLineFromAddr64;
    __gshared fp_SymEnumSymbols           SymEnumSymbols;
    __gshared fp_SymGetModuleBase64   SymGetModuleBase64;
    __gshared fp_GetModuleFileNameExA     GetModuleFileNameExA;
    __gshared fp_StackWalk64                      StackWalk64;
    __gshared fp_SymFunctionTableAccess64 SymFunctionTableAccess64;


    alias DWORD function(
        DWORD SymOptions
    ) fp_SymSetOptions;
    
    enum {
        SYMOPT_ALLOW_ABSOLUTE_SYMBOLS = 0x00000800,
        SYMOPT_DEFERRED_LOADS = 0x00000004,
        SYMOPT_UNDNAME = 0x00000002
    }

    alias BOOL function(
        HANDLE hProcess,
        LPCTSTR UserSearchPath,
        BOOL fInvadeProcess
    ) fp_SymInitialize;
    
    alias BOOL function(
        HANDLE hProcess
    ) fp_SymCleanup;

    alias DWORD64 function(
        HANDLE hProcess,
        HANDLE hFile,
        LPCSTR ImageName,
        LPCSTR ModuleName,
        DWORD64 BaseOfDll,
        DWORD SizeOfDll
    ) fp_SymLoadModule64;
    
    struct SYMBOL_INFO {
        ULONG SizeOfStruct;
        ULONG TypeIndex;
        ULONG64 Reserved[2];
        ULONG Index;
        ULONG Size;
        ULONG64 ModBase;
        ULONG Flags;
        ULONG64 Value;
        ULONG64 Address;
        ULONG Register;
        ULONG Scope;
        ULONG Tag;
        ULONG NameLen;
        ULONG MaxNameLen;
        TCHAR Name[1];
    }
    alias SYMBOL_INFO* PSYMBOL_INFO;
    
    alias BOOL function(
        HANDLE hProcess,
        DWORD64 Address,
        PDWORD64 Displacement,
        PSYMBOL_INFO Symbol
    ) fp_SymFromAddr;

    alias BOOL function(
        HANDLE hProcess,
        PCSTR Name,
        PSYMBOL_INFO Symbol
    ) fp_SymFromName;

    alias BOOL function(
        HANDLE hProcess,
        PSYM_ENUMMODULES_CALLBACK64 EnumModulesCallback,
        PVOID UserContext
    ) fp_SymEnumerateModules64;
    
    alias BOOL function(
        LPTSTR ModuleName,
        DWORD64 BaseOfDll,
        PVOID UserContext
    ) PSYM_ENUMMODULES_CALLBACK64;

    const DWORD TH32CS_SNAPPROCESS = 0x00000002;
    const DWORD TH32CS_SNAPTHREAD = 0x00000004;
    

    enum {
        MAX_MODULE_NAME32 = 255,
        TH32CS_SNAPMODULE = 0x00000008,
        SYMOPT_LOAD_LINES = 0x10,
    }

    struct IMAGEHLP_LINE64 {
        DWORD SizeOfStruct;
        PVOID Key;
        DWORD LineNumber;
        PTSTR FileName;
        DWORD64 Address;
    }
    alias IMAGEHLP_LINE64* PIMAGEHLP_LINE64;
 
    alias BOOL function(
        HANDLE hProcess,
        DWORD64 dwAddr,
        PDWORD pdwDisplacement,
        PIMAGEHLP_LINE64 Line
    ) fp_SymGetLineFromAddr64;
    

    alias BOOL function(
        PSYMBOL_INFO pSymInfo,
        ULONG SymbolSize,
        PVOID UserContext
    ) PSYM_ENUMERATESYMBOLS_CALLBACK;

    alias BOOL function(
        HANDLE hProcess,
        ULONG64 BaseOfDll,
        LPCTSTR Mask,
        PSYM_ENUMERATESYMBOLS_CALLBACK EnumSymbolsCallback,
        PVOID UserContext
    ) fp_SymEnumSymbols;


    alias DWORD64 function(
        HANDLE hProcess,
        DWORD64 dwAddr
    ) fp_SymGetModuleBase64;
    alias fp_SymGetModuleBase64 PGET_MODULE_BASE_ROUTINE64;
    
    
    alias DWORD function(
      HANDLE hProcess,
      HMODULE hModule,
      LPSTR lpFilename,
      DWORD nSize
    ) fp_GetModuleFileNameExA;
    

    enum ADDRESS_MODE {
        AddrMode1616,
        AddrMode1632,
        AddrModeReal,
        AddrModeFlat
    }
    
    struct KDHELP64 {
        DWORD64 Thread;
        DWORD ThCallbackStack;
        DWORD ThCallbackBStore;
        DWORD NextCallback;
        DWORD FramePointer;
        DWORD64 KiCallUserMode;
        DWORD64 KeUserCallbackDispatcher;
        DWORD64 SystemRangeStart;
        DWORD64 KiUserExceptionDispatcher;
        DWORD64 StackBase;
        DWORD64 StackLimit;
        DWORD64 Reserved[5];
    } 
    alias KDHELP64* PKDHELP64;
    
    struct ADDRESS64 {
        DWORD64 Offset;
        WORD Segment;
        ADDRESS_MODE Mode;
    }
    alias ADDRESS64* LPADDRESS64;


    struct STACKFRAME64 {
        ADDRESS64 AddrPC;
        ADDRESS64 AddrReturn;
        ADDRESS64 AddrFrame;
        ADDRESS64 AddrStack;
        ADDRESS64 AddrBStore;
        PVOID FuncTableEntry;
        DWORD64 Params[4];
        BOOL Far;
        BOOL Virtual;
        DWORD64 Reserved[3];
        KDHELP64 KdHelp;
    }
    alias STACKFRAME64* LPSTACKFRAME64;
    
    
    
    alias BOOL function(
        HANDLE hProcess,
        DWORD64 lpBaseAddress,
        PVOID lpBuffer,
        DWORD nSize,
        LPDWORD lpNumberOfBytesRead
    ) PREAD_PROCESS_MEMORY_ROUTINE64;
    
    alias PVOID function(
        HANDLE hProcess,
        DWORD64 AddrBase
    ) PFUNCTION_TABLE_ACCESS_ROUTINE64;
    alias PFUNCTION_TABLE_ACCESS_ROUTINE64 fp_SymFunctionTableAccess64;
    
    alias DWORD64 function(
        HANDLE hProcess,
        HANDLE hThread,
        LPADDRESS64 lpaddr
    ) PTRANSLATE_ADDRESS_ROUTINE64;
    
    
    alias BOOL function (
        DWORD MachineType,
        HANDLE hProcess,
        HANDLE hThread,
        LPSTACKFRAME64 StackFrame,
        PVOID ContextRecord,
        PREAD_PROCESS_MEMORY_ROUTINE64 ReadMemoryRoutine,
        PFUNCTION_TABLE_ACCESS_ROUTINE64 FunctionTableAccessRoutine,
        PGET_MODULE_BASE_ROUTINE64 GetModuleBaseRoutine,
        PTRANSLATE_ADDRESS_ROUTINE64 TranslateAddress
    ) fp_StackWalk64;
    
    
    BOOL IsBadReadPtr(void*, uint);
}

//#line 2 "parts/DbgInfo.di"
import tango.text.Util;
import tango.stdc.stdio;
import tango.stdc.stringz;
import tango.stdc.string : strcpy;
import tango.sys.win32.CodePage;
import tango.core.Exception;



struct AddrDebugInfo {
    align(1) {
        size_t  addr;
        char*   file;
        char*   func;
        ushort  line;
    }
}

class ModuleDebugInfo {
    AddrDebugInfo[] debugInfo;
    uint                        debugInfoLen;
    size_t[char*]           fileMaxAddr;
    char*[]                 strBuffer;
    uint                        strBufferLen;
    
    void addDebugInfo(size_t addr, char* file, char* func, ushort line) {
        debugInfo.append(AddrDebugInfo(addr, file, func, line), &debugInfoLen);

        if (auto a = file in fileMaxAddr) {
            if (addr > *a) *a = addr;
        } else {
            fileMaxAddr[file] = addr;
        }
    }
    
    char* bufferString(const(char)[] str) {
        char[] res;
        res.alloc(str.length+1, false);
        res[0..$-1] = str[];
        res[str.length] = 0;
        strBuffer.append(res.ptr, &strBufferLen);
        return res.ptr;
    }
    
    void freeArrays() {
        debugInfo.free();
        debugInfoLen = 0;

        fileMaxAddr = null;
        foreach (ref s; strBuffer[0..strBufferLen]) {
            cFree(s);
        }
        strBuffer.free();
        strBufferLen = 0;
    }
    
    ModuleDebugInfo prev;
    ModuleDebugInfo next;
}

class GlobalDebugInfo {
    ModuleDebugInfo head;
    ModuleDebugInfo tail;
    
    
     int opApply(scope int delegate(ref ModuleDebugInfo) dg) {
			synchronized(this)
			{
        for (auto it = head; it !is null; it = it.next) {
            if (auto res = dg(it)) {
                return res;
            }
        }
			}
        return 0;
    }
    
    
     void addDebugInfo(ModuleDebugInfo info) {
			synchronized(this)
        if (head is null) {
            head = tail = info;
            info.next = info.prev = null;
        } else {
            tail.next = info;
            info.prev = tail;
            info.next = null;
            tail = info;
        }
    }
    
    
    void removeDebugInfo(ModuleDebugInfo info) {
        assert (info !is null);
        assert (info.next !is null || info.prev !is null || head is info);
        synchronized(this)
				{
        if (info is head) {
            head = head.next;
        }
        if (info is tail) {
            tail = tail.prev;
        }
        if (info.prev) {
            info.prev.next = info.next;
        }
        if (info.next) {
            info.next.prev = info.prev;
        }
        info.freeArrays();
        info.prev = info.next = null;
        
        delete info;
			}
    }
}

private __gshared GlobalDebugInfo globalDebugInfo;
shared static this() {
    globalDebugInfo = new GlobalDebugInfo;
}

extern(C) void _initLGPLHostExecutableDebugInfo(const(char)[] progName) {
    scope info = new DebugInfo(progName);
    // we'll let it die now :)
}


AddrDebugInfo getAddrDbgInfo(size_t a, ptrdiff_t* diff = null) {
    AddrDebugInfo bestInfo;
    int minDiff = 0x7fffffff;
    int bestOff = 0;
    const int addBias = 0;
    
    foreach (modInfo; globalDebugInfo) {
        bool local = false;
        
        foreach (l; modInfo.debugInfo[0 .. modInfo.debugInfoLen]) {
            int diff = a - l.addr - addBias;
            
            // increasing it will make the lookup give results 'higher' in the code (at lower addresses)
            // using the value of 1 is recommended when not using version StacktraceTryMatchCallAddresses,
            // but it may result in AVs reporting an earlier line in the source code
            const int minSymbolOffset = 0;
            
            if (diff < minSymbolOffset) {
                continue;
            }
            
            int absdiff = diff > 0 ? diff : -diff;
            if (absdiff < minDiff) {
                minDiff = absdiff;
                bestOff = diff;
                bestInfo = l;
                local = true;
            }
        }
        
        if (local) {
            if (minDiff > 0x100) {
                bestInfo = bestInfo.init;
                minDiff = 0x7fffffff;
            }
            else {
                if (auto ma = bestInfo.file in modInfo.fileMaxAddr) {
                    if (a > *ma+addBias) {
                        bestInfo = bestInfo.init;
                        minDiff = 0x7fffffff;
                    }
                } else {
                    version (StacktraceSpam) printf("there ain't '%s' in fileMaxAddr\n", bestInfo.file);
                    bestInfo = bestInfo.init;
                    minDiff = 0x7fffffff;
                }
            }
        }
    }
    
    if (diff !is null) {
        *diff = bestOff;
    }
    return bestInfo;
}

   

class DebugInfo {
    ModuleDebugInfo info;
    
    
    this(const(char)[] filename) {
        info = new ModuleDebugInfo;
        ParseCVFile(filename);
        assert (globalDebugInfo !is null);
        globalDebugInfo.addDebugInfo(info);
    }
     
    private {
        int ParseCVFile(const(char)[] filename) {
            FILE* debugfile;

            if (filename == "") return (-1);

            //try {
                debugfile = fopen((filename ~ "\0").ptr, "rb");
            /+} catch(Exception e){
                return -1;
            }+/

            if (!ParseFileHeaders (debugfile)) return -1;

            g_secthdrs.length = g_nthdr.FileHeader.NumberOfSections;

            if (!ParseSectionHeaders (debugfile)) return -1;

            g_debugdirs.length = g_nthdr.OptionalHeader.DataDirectory[IMAGE_FILE_DEBUG_DIRECTORY].Size /
                IMAGE_DEBUG_DIRECTORY.sizeof;

            if (!ParseDebugDir (debugfile)) return -1;
            if (g_dwStartOfCodeView == 0) return -1;
            if (!ParseCodeViewHeaders (debugfile)) return -1;
            if (!ParseAllModules (debugfile)) return -1;

            g_dwStartOfCodeView = 0;
            g_exe_mode = true;
            g_secthdrs = null;
            g_debugdirs = null;
            g_cvEntries = null;
            g_cvModules = null;
            g_filename = null;
            g_filenameStringz = null;

            fclose(debugfile);
            return 0;
        }
            
        bool ParseFileHeaders(FILE* debugfile) {
            CVHeaderType hdrtype;

            hdrtype = GetHeaderType (debugfile);

            if (hdrtype == CVHeaderType.DOS) {
                if (!ReadDOSFileHeader (debugfile, &g_doshdr))return false;
                hdrtype = GetHeaderType (debugfile);
            }
            if (hdrtype == CVHeaderType.NT) {
                if (!ReadPEFileHeader (debugfile, &g_nthdr)) return false;
            }

            return true;
        }
            
        CVHeaderType GetHeaderType(FILE* debugfile) {
            ushort hdrtype;
            CVHeaderType ret = CVHeaderType.NONE;

            int oldpos = ftell(debugfile);

            if (!ReadChunk (debugfile, &hdrtype, ushort.sizeof, -1)){
                fseek(debugfile, oldpos, SEEK_SET);
                return CVHeaderType.NONE;
            }

            if (hdrtype == 0x5A4D)       // "MZ"
                ret = CVHeaderType.DOS;
            else if (hdrtype == 0x4550)  // "PE"
                ret = CVHeaderType.NT;
            else if (hdrtype == 0x4944)  // "DI"
                ret = CVHeaderType.DBG;

            fseek(debugfile, oldpos, SEEK_SET);

            return ret;
        }
         
        /*
         * Extract the DOS file headers from an executable
         */
        bool ReadDOSFileHeader(FILE* debugfile, IMAGE_DOS_HEADER *doshdr) {
            uint bytes_read;

            bytes_read = fread(doshdr, 1, IMAGE_DOS_HEADER.sizeof, debugfile);
            if (bytes_read < IMAGE_DOS_HEADER.sizeof){
                return false;
            }

            // Skip over stub data, if present
            if (doshdr.e_lfanew) {
                fseek(debugfile, doshdr.e_lfanew, SEEK_SET);
            }

            return true;
        }
         
        /*
         * Extract the DOS and NT file headers from an executable
         */
        bool ReadPEFileHeader(FILE* debugfile, IMAGE_NT_HEADERS *nthdr) {
            uint bytes_read;

            bytes_read = fread(nthdr, 1, IMAGE_NT_HEADERS.sizeof, debugfile);
            if (bytes_read < IMAGE_NT_HEADERS.sizeof) {
                return false;
            }

            return true;
        }
          
        bool ParseSectionHeaders(FILE* debugfile) {
            if (!ReadSectionHeaders (debugfile, g_secthdrs)) return false;
            return true;
        }
            
        bool ReadSectionHeaders(FILE* debugfile, ref IMAGE_SECTION_HEADER[] secthdrs) {
            for(int i=0;i<secthdrs.length;i++){
                uint bytes_read;
                bytes_read = fread((&secthdrs[i]), 1, IMAGE_SECTION_HEADER.sizeof, debugfile);
                if (bytes_read < 1){
                    return false;
                }
            }
            return true;
        }
          
        bool ParseDebugDir(FILE* debugfile) {
            int i;
            int filepos;

            if (g_debugdirs.length == 0) return false;

            filepos = GetOffsetFromRVA (g_nthdr.OptionalHeader.DataDirectory[IMAGE_FILE_DEBUG_DIRECTORY].VirtualAddress);

            fseek(debugfile, filepos, SEEK_SET);

            if (!ReadDebugDir (debugfile, g_debugdirs)) return false;

            for (i = 0; i < g_debugdirs.length; i++) {
                enum {
                    IMAGE_DEBUG_TYPE_CODEVIEW = 2,
                }

                if (g_debugdirs[i].Type == IMAGE_DEBUG_TYPE_CODEVIEW) {
                    g_dwStartOfCodeView = g_debugdirs[i].PointerToRawData;
                }
            }

            g_debugdirs = null;

            return true;
        }
            
        // Calculate the file offset, based on the RVA.
        uint GetOffsetFromRVA(uint rva) {
            int i;
            uint sectbegin;

            for (i = g_secthdrs.length - 1; i >= 0; i--) {
                sectbegin = g_secthdrs[i].VirtualAddress;
                if (rva >= sectbegin) break;
            }
            uint offset = g_secthdrs[i].VirtualAddress - g_secthdrs[i].PointerToRawData;
            uint filepos = rva - offset;
            return filepos;
        }
         
        // Load in the debug directory table.  This directory describes the various
        // blocks of debug data that reside at the end of the file (after the COFF
        // sections), including FPO data, COFF-style debug info, and the CodeView
        // we are *really* after.
        bool ReadDebugDir(FILE* debugfile, ref IMAGE_DEBUG_DIRECTORY debugdirs[]) {
            uint bytes_read;
            for(int i=0;i<debugdirs.length;i++) {
                bytes_read = fread((&debugdirs[i]), 1, IMAGE_DEBUG_DIRECTORY.sizeof, debugfile);
                if (bytes_read < IMAGE_DEBUG_DIRECTORY.sizeof) {
                    return false;
                }
            }
            return true;
        }
          
        bool ParseCodeViewHeaders(FILE* debugfile) {
            fseek(debugfile, g_dwStartOfCodeView, SEEK_SET);
            if (!ReadCodeViewHeader (debugfile, g_cvSig, g_cvHeader)) return false;
            g_cvEntries.length = g_cvHeader.cDir;
            if (!ReadCodeViewDirectory (debugfile, g_cvEntries)) return false;
            return true;
        }

            
        bool ReadCodeViewHeader(FILE* debugfile, out OMFSignature sig, out OMFDirHeader dirhdr) {
            uint bytes_read;

            bytes_read = fread((&sig), 1, OMFSignature.sizeof, debugfile);
            if (bytes_read < OMFSignature.sizeof){
                return false;
            }

            fseek(debugfile, sig.filepos + g_dwStartOfCodeView, SEEK_SET);
            bytes_read = fread((&dirhdr), 1, OMFDirHeader.sizeof, debugfile);
            if (bytes_read < OMFDirHeader.sizeof){
                return false;
            }
            return true;
        }
         
        bool ReadCodeViewDirectory(FILE* debugfile, ref OMFDirEntry[] entries) {
            uint bytes_read;

            for(int i=0;i<entries.length;i++){
                bytes_read = fread((&entries[i]), 1, OMFDirEntry.sizeof, debugfile);
                if (bytes_read < OMFDirEntry.sizeof){
                    return false;
                }
            }
            return true;
        }
          
        bool ParseAllModules (FILE* debugfile) {
            if (g_cvHeader.cDir == 0){
                return true;
            }

            if (g_cvEntries.length == 0){
                return false;
            }

            fseek(debugfile, g_dwStartOfCodeView + g_cvEntries[0].lfo, SEEK_SET);

            if (!ReadModuleData (debugfile, g_cvEntries, g_cvModules)){
                return false;
            }


            for (int i = 0; i < g_cvModules.length; i++){
                ParseRelatedSections (i, debugfile);
            }

            return true;
        }

            
        bool ReadModuleData(FILE* debugfile, OMFDirEntry[] entries, out OMFModuleFull[] modules) {
            uint bytes_read;
            int pad;

            int module_bytes = (ushort.sizeof * 3) + (char.sizeof * 2);

            if (entries == null) return false;

            modules.length = 0;

            for (int i = 0; i < entries.length; i++){
                if (entries[i].SubSection == sstModule)
                    modules.length = modules.length + 1;
            }

            for (int i = 0; i < modules.length; i++){

                bytes_read = fread((&modules[i]), 1, module_bytes, debugfile);
                if (bytes_read < module_bytes){
                    return false;
                }

                int segnum = modules[i].cSeg;
                OMFSegDesc[] segarray;
                segarray.length=segnum;
                for(int j=0;j<segnum;j++){
                    bytes_read =  fread((&segarray[j]), 1, OMFSegDesc.sizeof, debugfile);
                    if (bytes_read < OMFSegDesc.sizeof){
                        return false;
                    }
                }
                modules[i].SegInfo = segarray.ptr;

                char namelen;
                bytes_read = fread((&namelen), 1, char.sizeof, debugfile);
                if (bytes_read < 1){
                    return false;
                }

                pad = ((namelen + 1) % 4);
                if (pad) namelen += (4 - pad);

                modules[i].Name = (new char[namelen+1]).ptr;
                modules[i].Name[namelen]=0;
                bytes_read = fread((modules[i].Name), 1, namelen, debugfile);
                if (bytes_read < namelen){
                    return false;
                }
            }
            return true;
        }
         
        bool ParseRelatedSections(int index, FILE* debugfile) {
            int i;

            if (g_cvEntries == null)
                return false;

            for (i = 0; i < g_cvHeader.cDir; i++){
                if (g_cvEntries[i].iMod != (index + 1) ||
                    g_cvEntries[i].SubSection == sstModule)
                    continue;

                switch (g_cvEntries[i].SubSection){
                case sstSrcModule:
                    ParseSrcModuleInfo (i, debugfile);
                    break;
                default:
                    break;
                }
            }

            return true;
        }
            
        bool ParseSrcModuleInfo (int index, FILE* debugfile) {
            int i;

            byte *rawdata;
            byte *curpos;
            short filecount;
            short segcount;

            int moduledatalen;
            int filedatalen;
            int linedatalen;

            if (g_cvEntries == null || debugfile == null ||
                g_cvEntries[index].SubSection != sstSrcModule)
                return false;

            int fileoffset = g_dwStartOfCodeView + g_cvEntries[index].lfo;

            rawdata = (new byte[g_cvEntries[index].cb]).ptr;
            if (!rawdata) return false;

            if (!ReadChunk (debugfile, rawdata, g_cvEntries[index].cb, fileoffset)) return false;
            uint[] baseSrcFile;
            ExtractSrcModuleInfo (rawdata, &filecount, &segcount,baseSrcFile);

            for(i=0;i<baseSrcFile.length;i++){
                uint baseSrcLn[];
                ExtractSrcModuleFileInfo (rawdata+baseSrcFile[i],baseSrcLn);
                for(int j=0;j<baseSrcLn.length;j++){
                    ExtractSrcModuleLineInfo (rawdata+baseSrcLn[j], j);
                }
            }

            return true;
        }
        
        void ExtractSrcModuleInfo (byte* rawdata, short *filecount, short *segcount,out uint[] fileinfopos) {
            int i;
            int datalen;

            short cFile;
            short cSeg;
            uint *baseSrcFile;
            uint *segarray;
            ushort *segindexarray;

            cFile = *cast(short*)rawdata;
            cSeg = *cast(short*)(rawdata + 2);
            baseSrcFile = cast(uint*)(rawdata + 4);
            segarray = &baseSrcFile[cFile];
            segindexarray = cast(ushort*)(&segarray[cSeg * 2]);

            *filecount = cFile;
            *segcount = cSeg;

            fileinfopos.length=cFile;
            for (i = 0; i < cFile; i++) {
                fileinfopos[i]=baseSrcFile[i];
            }
        }
         
        void ExtractSrcModuleFileInfo(byte* rawdata,out uint[] offset) {
            int i;
            int datalen;

            short cSeg;
            uint *baseSrcLn;
            uint *segarray;
            byte cFName;

            cSeg = *cast(short*)(rawdata);
            // Skip the 'pad' field
            baseSrcLn = cast(uint*)(rawdata + 4);
            segarray = &baseSrcLn[cSeg];
            cFName = *(cast(byte*)&segarray[cSeg*2]);

            g_filename = (cast(char*)&segarray[cSeg*2] + 1)[0..cFName].dup;
            g_filenameStringz = info.bufferString(g_filename);

            offset.length=cSeg;
            for (i = 0; i < cSeg; i++){
                offset[i]=baseSrcLn[i];
            }
        }
         
        void ExtractSrcModuleLineInfo(byte* rawdata, int tablecount) {
            int i;

            ushort Seg;
            ushort cPair;
            uint *offset;
            ushort *linenumber;

            Seg = *cast(ushort*)rawdata;
            cPair = *cast(ushort*)(rawdata + 2);
            offset = cast(uint*)(rawdata + 4);
            linenumber = cast(ushort*)&offset[cPair];

            uint base=0;
            if (Seg != 0){
                base = g_nthdr.OptionalHeader.ImageBase+g_secthdrs[Seg-1].VirtualAddress;
            }
            
            for (i = 0; i < cPair; i++) {
                uint address = offset[i]+base;
                info.addDebugInfo(address, g_filenameStringz, null, linenumber[i]);
            }
        }

           
        bool ReadChunk(FILE* debugfile, void *dest, int length, int fileoffset) {
            uint bytes_read;

            if (fileoffset >= 0) {
                fseek(debugfile, fileoffset, SEEK_SET);
            }

            bytes_read = fread(dest, 1, length, debugfile);
            if (bytes_read < length) {
                return false;
            }

            return true;
        }


        enum CVHeaderType : int {
            NONE,
            DOS,
            NT,
            DBG
        }

        int g_dwStartOfCodeView = 0;

        bool g_exe_mode = true;
        IMAGE_DOS_HEADER g_doshdr;
        IMAGE_SEPARATE_DEBUG_HEADER g_dbghdr;
        IMAGE_NT_HEADERS g_nthdr;

        IMAGE_SECTION_HEADER g_secthdrs[];

        IMAGE_DEBUG_DIRECTORY g_debugdirs[];
        OMFSignature g_cvSig;
        OMFDirHeader g_cvHeader;
        OMFDirEntry g_cvEntries[];
        OMFModuleFull g_cvModules[];
        const(char)[] g_filename;
        char* g_filenameStringz;
    }
}




enum {
    IMAGE_FILE_DEBUG_DIRECTORY = 6
}
 
enum {
    sstModule           = 0x120,
    sstSrcModule        = 0x127,
    sstGlobalPub        = 0x12a,
}
 
struct OMFSignature {
    char    Signature[4];
    int filepos;
}
 
struct OMFDirHeader {
    ushort  cbDirHeader;
    ushort  cbDirEntry;
    uint    cDir;
    int     lfoNextDir;
    uint    flags;
}
 
struct OMFDirEntry {
    ushort  SubSection;
    ushort  iMod;
    int     lfo;
    uint    cb;
}
  
struct OMFSegDesc {
    ushort  Seg;
    ushort  pad;
    uint    Off;
    uint    cbSeg;
}
 
struct OMFModule {
    ushort  ovlNumber;
    ushort  iLib;
    ushort  cSeg;
    char            Style[2];
}
 
struct OMFModuleFull {
    ushort  ovlNumber;
    ushort  iLib;
    ushort  cSeg;
    char            Style[2];
    OMFSegDesc      *SegInfo;
    char            *Name;
}
    
struct OMFSymHash {
    ushort  symhash;
    ushort  addrhash;
    uint    cbSymbol;
    uint    cbHSym;
    uint    cbHAddr;
}
 
struct DATASYM16 {
        ushort reclen;  // Record length
        ushort rectyp;  // S_LDATA or S_GDATA
        int off;        // offset of symbol
        ushort seg;     // segment of symbol
        ushort typind;  // Type index
        byte name[1];   // Length-prefixed name
}
alias DATASYM16 PUBSYM16;
 

struct IMAGE_DOS_HEADER {      // DOS .EXE header
    ushort   e_magic;                     // Magic number
    ushort   e_cblp;                      // Bytes on last page of file
    ushort   e_cp;                        // Pages in file
    ushort   e_crlc;                      // Relocations
    ushort   e_cparhdr;                   // Size of header in paragraphs
    ushort   e_minalloc;                  // Minimum extra paragraphs needed
    ushort   e_maxalloc;                  // Maximum extra paragraphs needed
    ushort   e_ss;                        // Initial (relative) SS value
    ushort   e_sp;                        // Initial SP value
    ushort   e_csum;                      // Checksum
    ushort   e_ip;                        // Initial IP value
    ushort   e_cs;                        // Initial (relative) CS value
    ushort   e_lfarlc;                    // File address of relocation table
    ushort   e_ovno;                      // Overlay number
    ushort   e_res[4];                    // Reserved words
    ushort   e_oemid;                     // OEM identifier (for e_oeminfo)
    ushort   e_oeminfo;                   // OEM information; e_oemid specific
    ushort   e_res2[10];                  // Reserved words
    int      e_lfanew;                    // File address of new exe header
}
 
struct IMAGE_FILE_HEADER {
    ushort    Machine;
    ushort    NumberOfSections;
    uint      TimeDateStamp;
    uint      PointerToSymbolTable;
    uint      NumberOfSymbols;
    ushort    SizeOfOptionalHeader;
    ushort    Characteristics;
}
 
struct IMAGE_SEPARATE_DEBUG_HEADER {
    ushort        Signature;
    ushort        Flags;
    ushort        Machine;
    ushort        Characteristics;
    uint       TimeDateStamp;
    uint       CheckSum;
    uint       ImageBase;
    uint       SizeOfImage;
    uint       NumberOfSections;
    uint       ExportedNamesSize;
    uint       DebugDirectorySize;
    uint       SectionAlignment;
    uint       Reserved[2];
}
 
struct IMAGE_DATA_DIRECTORY {
    uint   VirtualAddress;
    uint   Size;
}
 
struct IMAGE_OPTIONAL_HEADER {
    //
    // Standard fields.
    //

    ushort    Magic;
    byte    MajorLinkerVersion;
    byte    MinorLinkerVersion;
    uint   SizeOfCode;
    uint   SizeOfInitializedData;
    uint   SizeOfUninitializedData;
    uint   AddressOfEntryPoint;
    uint   BaseOfCode;
    uint   BaseOfData;

    //
    // NT additional fields.
    //

    uint   ImageBase;
    uint   SectionAlignment;
    uint   FileAlignment;
    ushort    MajorOperatingSystemVersion;
    ushort    MinorOperatingSystemVersion;
    ushort    MajorImageVersion;
    ushort    MinorImageVersion;
    ushort    MajorSubsystemVersion;
    ushort    MinorSubsystemVersion;
    uint   Win32VersionValue;
    uint   SizeOfImage;
    uint   SizeOfHeaders;
    uint   CheckSum;
    ushort    Subsystem;
    ushort    DllCharacteristics;
    uint   SizeOfStackReserve;
    uint   SizeOfStackCommit;
    uint   SizeOfHeapReserve;
    uint   SizeOfHeapCommit;
    uint   LoaderFlags;
    uint   NumberOfRvaAndSizes;

    enum {
        IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16,
    }

    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
}
 
struct IMAGE_NT_HEADERS {
    uint Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER OptionalHeader;
}
 
enum {
    IMAGE_SIZEOF_SHORT_NAME = 8,
}

struct IMAGE_SECTION_HEADER {
    byte    Name[IMAGE_SIZEOF_SHORT_NAME];//8
    union misc{
            uint   PhysicalAddress;
            uint   VirtualSize;//12
    }
    misc Misc;
    uint   VirtualAddress;//16
    uint   SizeOfRawData;//20
    uint   PointerToRawData;//24
    uint   PointerToRelocations;//28
    uint   PointerToLinenumbers;//32
    ushort NumberOfRelocations;//34
    ushort NumberOfLinenumbers;//36
    uint   Characteristics;//40
}
 
struct IMAGE_DEBUG_DIRECTORY {
    uint   Characteristics;
    uint   TimeDateStamp;
    ushort MajorVersion;
    ushort MinorVersion;
    uint   Type;
    uint   SizeOfData;
    uint   AddressOfRawData;
    uint   PointerToRawData;
}
 
struct OMFSourceLine {
    ushort  Seg;
    ushort  cLnOff;
    uint    offset[1];
    ushort  lineNbr[1];
}
 
struct OMFSourceFile {
    ushort  cSeg;
    ushort  reserved;
    uint    baseSrcLn[1];
    ushort  cFName;
    char    Name;
}
 
struct OMFSourceModule {
    ushort  cFile;
    ushort  cSeg;
    uint    baseSrcFile[1];
}
//#line 2 "parts/CInterface.di"
extern (C) {
    ModuleDebugInfo ModuleDebugInfo_new() {
        return new ModuleDebugInfo;
    }
    
    void ModuleDebugInfo_addDebugInfo(ModuleDebugInfo minfo, size_t addr, char* file, char* func, ushort line) {
        minfo.addDebugInfo(addr, file, func, line);
    }
    
    char* ModuleDebugInfo_bufferString(ModuleDebugInfo minfo, char[] str) {
        char[] res;
        res.alloc(str.length+1, false);
        res[0..$-1] = str[];
        res[str.length] = 0;
        minfo.strBuffer.append(res.ptr, &minfo.strBufferLen);
        return res.ptr;
    }
    
    void GlobalDebugInfo_addDebugInfo(ModuleDebugInfo minfo) {
        globalDebugInfo.addDebugInfo(minfo);
    }
    
    void GlobalDebugInfo_removeDebugInfo(ModuleDebugInfo minfo) {
        globalDebugInfo.removeDebugInfo(minfo);
    }
}
//#line 2 "parts/Init.di"
shared static this() {
    loadWinAPIFunctions();

    for (fiberRunFuncLength = 0; fiberRunFuncLength < 0x100; ++fiberRunFuncLength) {
        ubyte* ptr = cast(ubyte*)&D4core6thread5Fiber3runMFZv + fiberRunFuncLength;
        enum {
            RetOpcode = 0xc3
        }
        if (IsBadReadPtr(ptr, 1) || RetOpcode == *ptr) {
            break;
        }
    }
    
    version (StacktraceSpam) printf ("found Thread.Fiber.run at %p with length %x",
            &D4core6thread5Fiber3runMFZv, fiberRunFuncLength);

    char modNameBuf[512] = 0;
    int modNameLen = GetModuleFileNameExA(GetCurrentProcess(), null, modNameBuf.ptr, modNameBuf.length-1);
    char[] modName = modNameBuf[0..modNameLen];
    SymSetOptions(SYMOPT_DEFERRED_LOADS/+ | SYMOPT_UNDNAME+/);
    SymInitialize(GetCurrentProcess(), null, false);
    DWORD64 base;
    if (0 == (base = SymLoadModule64(GetCurrentProcess(), HANDLE.init, modName.ptr, null, 0, 0))) {
        if (SysError.lastCode != 0) {
            throw new Exception("Could not SymLoadModule64: " ~ SysError.lastMsg.idup);
        }
    }

    size_t slash_idx;
    for(slash_idx = modName.length - 1; slash_idx >= 0; slash_idx--)
    {
        if(modName[slash_idx] == '\\')
            break;
    }
    auto sym_name = modName[slash_idx + 1..$-4] ~ "!__initLGPLHostExecutableDebugInfo\0";

    SYMBOL_INFO sym;
    sym.SizeOfStruct = SYMBOL_INFO.sizeof; 

    extern(C) void function(const(char)[]) initTrace;
    if (SymFromName(GetCurrentProcess(), sym_name.ptr, &sym)) {
        initTrace = cast(typeof(initTrace))sym.Address;
        assert (initTrace !is null); 
        initTrace(modName);
    } else {
        throw new Exception ("Can't initialize the TangoTrace LGPL stuff");
    }
}

}

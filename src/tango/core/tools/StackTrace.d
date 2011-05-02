
/**
 *   Stacktracing
 *
 *   Functions to generate a stacktrace.
 *
 *  Copyright: Copyright (C) 2009 Fawzi
 *  License:   Tango License
 *  Author:    Fawzi Mohamed
 */
module tango.core.tools.StackTrace;
import tango.core.tools.Demangler;
import tango.core.Runtime;
import tango.core.Thread;
import tango.core.Traits: ctfe_i2a;
import tango.stdc.string;
import tango.stdc.stringz : fromStringz;
import tango.stdc.stdlib: abort;
version(Windows){
    import tango.core.tools.WinStackTrace;
} else {
    import tango.stdc.posix.ucontext;
    import tango.stdc.posix.sys.types: pid_t,pthread_t;
    import tango.stdc.signal;
    import tango.stdc.stdlib;
}
version(linux){
    import tango.core.tools.LinuxStackTrace;
}

version(CatchRecursiveTracing){
    ThreadLocal!(int) recursiveStackTraces;

    static this(){
        recursiveStackTraces=new ThreadLocal!(int)(0);
    }
}

version(Windows){
} else {
   struct TraceContext{
       bool hasContext;
       ucontext_t context;
       pid_t hProcess;
       pthread_t hThread;
   }
}

alias size_t function(TraceContext* context,TraceContext* contextOut,size_t*traceBuf,size_t bufLength,int *flags) AddrBacktraceFunc;
AddrBacktraceFunc addrBacktraceFnc;
alias bool function(ref Exception.FrameInfo fInfo,TraceContext* context,char[]buf) SymbolizeFrameInfoFnc;
SymbolizeFrameInfoFnc symbolizeFrameInfoFnc;

static this(){
    addrBacktraceFnc=&defaultAddrBacktrace;
    symbolizeFrameInfoFnc=&defaultSymbolizeFrameInfo;
}

/// Sets the function used for address stacktraces.
extern(C) void rt_setAddrBacktraceFnc(AddrBacktraceFunc f){
    addrBacktraceFnc=f;
}
/// Sets the function used to symbolize a FrameInfo.
extern(C) void rt_setSymbolizeFrameInfoFnc(SymbolizeFrameInfoFnc f){
    symbolizeFrameInfoFnc=f;
}
/// Creates a stack trace (defined in the runtime.)
extern(C) Exception.TraceInfo rt_createTraceContext( void* ptr );

alias Exception.TraceInfo function( void* ptr = null ) TraceHandler;

/// Builds a backtrace of addresses, the addresses are addresses of the *next* instruction,
/// *return* addresses, the most likely the calling instruction is the one before them
/// (stack top excluded.)
extern(C) size_t rt_addrBacktrace(TraceContext* context, TraceContext *contextOut,size_t*traceBuf,size_t bufLength,int *flags){
    if (addrBacktraceFnc !is null){
        return addrBacktraceFnc(context,contextOut,traceBuf,bufLength,flags);
    } else {
        return 0;
    }
}

/// Tries to sybolize a frame information, this should try to build the best
/// backtrace information, if possible finding the calling context, thus 
/// if fInfo.exactAddress is false the address might be changed to the one preceding it
/// returns true if it managed to at least find the function name.
extern(C) bool rt_symbolizeFrameInfo(ref Exception.FrameInfo fInfo,TraceContext* context,char[]buf){
    if (symbolizeFrameInfoFnc !is null){
        return symbolizeFrameInfoFnc(fInfo,context,buf);
    } else {
        return false;
    }
}

// names of the functions that should be ignored for the backtrace
int[char[]] internalFuncs;
static this(){
    internalFuncs["D5tango4core10stacktrace10StackTrace20defaultAddrBacktraceFPS5tango4core10stacktrace10StackTrace12TraceContextPS5tango4core10stacktrace10StackTrace12TraceContextPkkPiZk"]=1;
    internalFuncs["_D5tango4core10stacktrace10StackTrace20defaultAddrBacktraceFPS5tango4core10stacktrace10StackTrace12TraceContextPS5tango4core10stacktrace10StackTrace12TraceContextPmmPiZm"]=1;
    internalFuncs["rt_addrBacktrace"]=1;
    internalFuncs["D5tango4core10stacktrace10StackTrace14BasicTraceInfo5traceMFPS5tango4core10stacktrace10StackTrace12TraceContextiZv"]=1;
    internalFuncs["D5tango4core10stacktrace10StackTrace11basicTracerFPvZC9Exception9TraceInfo"]=1;
    internalFuncs["rt_createTraceContext"]=1;
    internalFuncs["D2rt6dmain24mainUiPPaZi7runMainMFZv"]=1;
    internalFuncs["D2rt6dmain24mainUiPPaZi6runAllMFZv"]=1;
    internalFuncs["D2rt6dmain24mainUiPPaZi7tryExecMFDFZvZv"]=1;
    internalFuncs["_D5tango4core10stacktrace10StackTrace20defaultAddrBacktraceFPS5tango4core10stacktrace10StackTrace12TraceContextPS5tango4core10stacktrace10StackTrace12TraceContextPkkPiZk"]=1;
    internalFuncs["_rt_addrBacktrace"]=1;
    internalFuncs["_D5tango4core10stacktrace10StackTrace14BasicTraceInfo5traceMFPS5tango4core10stacktrace10StackTrace12TraceContextiZv"]=1;
    internalFuncs["_D5tango4core10stacktrace10StackTrace11basicTracerFPvZC9Exception9TraceInfo"]=1;
    internalFuncs["_rt_createTraceContext"]=1;
    internalFuncs["_D2rt6dmain24mainUiPPaZi7runMainMFZv"]=1;
    internalFuncs["_D2rt6dmain24mainUiPPaZi6runAllMFZv"]=1;
    internalFuncs["_D2rt6dmain24mainUiPPaZi7tryExecMFDFZvZv"]=1;
}

/// Returns the name of the function at the given adress (if possible)
/// function@ and then the address. For delegates you can use .funcptr
/// does not demangle.
char[] nameOfFunctionAt(void* addr, char[] buf){
    Exception.FrameInfo fInfo;
    fInfo.clear();
    fInfo.address=cast(size_t)addr;
    if (rt_symbolizeFrameInfo(fInfo,null,buf) && fInfo.func.length){
        return fInfo.func;
    } else {
        return "function@"~ctfe_i2a(cast(size_t)addr);
    }
}
/// ditto
char[] nameOfFunctionAt(void * addr){
    char[1024] buf;
    return nameOfFunctionAt(addr,buf).dup;
}

/// Precision of the addresses given by the backtrace function.
enum AddrPrecision{
    AllReturn=0,
    TopExact=1,
    AllExact=3
}

/// Basic class that represents a stacktrace.
class BasicTraceInfo: Exception.TraceInfo{
    size_t[] traceAddresses;
    size_t[128] traceBuf;
    AddrPrecision addrPrecision;
    TraceContext context;
    /// Creates an empty stacktrace.
    this(){}
    /// Creates a stacktrace with the given traceAddresses.
    this(size_t[] traceAddresses,AddrPrecision addrPrecision){
        this.traceAddresses[]=traceAddresses;
        if (traceAddresses.length<=traceBuf.length){
            // change to either always copy (and truncate) or never copy?
            traceBuf[0..traceAddresses.length]=traceAddresses;
            this.traceAddresses=traceBuf[0..traceAddresses.length];
        }
        this.addrPrecision=addrPrecision;
    }
    /// Takes a stacktrace.
    void trace(TraceContext *contextIn=null,int skipFrames=0){
        int flags;
        size_t nFrames=rt_addrBacktrace(contextIn,&context,traceBuf.ptr,traceBuf.length,&flags);
        traceAddresses=traceBuf[skipFrames..nFrames];
        addrPrecision=cast(AddrPrecision)flags;
        if (flags==AddrPrecision.TopExact && skipFrames!=0)
            addrPrecision=AddrPrecision.AllReturn;
    }
    /// Loops on the stacktrace.
    int opApply( int delegate( ref Exception.FrameInfo fInfo ) loopBody){
        Exception.FrameInfo fInfo;
        for (size_t iframe=0;iframe<traceAddresses.length;++iframe){
            char[2048] buf;
            char[1024] buf2;
            fInfo.clear();
            fInfo.address=cast(size_t)traceAddresses[iframe];
            fInfo.iframe=cast(ptrdiff_t)iframe;
            fInfo.exactAddress=(addrPrecision & 2) || (iframe==0 && (addrPrecision & 1));
            rt_symbolizeFrameInfo(fInfo,&context,buf);
            
            auto r= fInfo.func in internalFuncs;
            fInfo.internalFunction |= (r !is null);
            fInfo.func = demangler.demangle(fInfo.func,buf2);
            int res=loopBody(fInfo);
            if (res) return res;
        }
        return 0;
    }
    /// Writes out the stacktrace.
    void writeOut(void delegate(char[]) sink){
        foreach (ref fInfo; this){
            if (!fInfo.internalFunction){
                fInfo.writeOut(sink);
                sink("\n");
            }
        }
    }
}

version(linux){
    version=LibCBacktrace;
    version=DladdrSymbolification;
    version=ElfSymbolification;
}
version(darwin){
    version=LibCBacktrace;
    version=DladdrSymbolification;
}
version(LibCBacktrace){
    extern(C)int backtrace(void**,int);
}

/// Default (tango given) backtrace function.
size_t defaultAddrBacktrace(TraceContext* context,TraceContext*contextOut,
    size_t*traceBuf,size_t length,int*flags){
    version(LibCBacktrace){
        //if (context!is null) return 0; // now it just gives a local trace, uncomment & skip?
        *flags=AddrPrecision.TopExact;
        return cast(size_t)backtrace(cast(void**)traceBuf,length);
    } else version (Windows){
        return winAddrBacktrace(context,contextOut,traceBuf,length,flags);
    } else {
        return 0;
    }
}

version(DladdrSymbolification){
    extern(C) struct Dl_info {
      char *dli_fname;      /* Filename of defining object */
      void *dli_fbase;      /* Load address of that object */
      char *dli_sname;      /* Name of nearest lower symbol */
      void *dli_saddr;      /* Exact value of nearest symbol */
    }

    extern(C)int dladdr(void* addr, Dl_info* info);

    /// poor symbolication, uses dladdr, gives no line info, limited info on statically linked files
    bool dladdrSymbolizeFrameInfo(ref Exception.FrameInfo fInfo,TraceContext*context,char[]buf){
        Dl_info dli;
        void *ip=cast(void*)(fInfo.address);
        if (!fInfo.exactAddress) --ip;
        if (dladdr(ip, &dli))
        {
            if (dli.dli_fname && dli.dli_fbase){
                fInfo.offsetImg = cast(ptrdiff_t)ip - cast(ptrdiff_t)dli.dli_fbase;
                fInfo.baseImg = cast(size_t)dli.dli_fbase;
                fInfo.file=dli.dli_fname[0..strlen(dli.dli_fname)];
            }
            if (dli.dli_sname && dli.dli_saddr){
                fInfo.offsetSymb = cast(ptrdiff_t)ip - cast(ptrdiff_t)dli.dli_saddr;
                fInfo.baseSymb = cast(size_t)dli.dli_saddr;
                fInfo.func = dli.dli_sname[0..strlen(dli.dli_sname)];
            }
        }
        return true;
    }
}


version(ElfSymbolification){

    bool elfSymbolizeFrameInfo(ref Exception.FrameInfo fInfo,
        TraceContext* context, char[] buf)
    {
        Dl_info dli;
        void *ip=cast(void*)(fInfo.address);
        if (!fInfo.exactAddress) --ip;
        if (dladdr(ip, &dli))
        {
            if (dli.dli_fname && dli.dli_fbase){
                fInfo.offsetImg = cast(ptrdiff_t)ip - cast(ptrdiff_t)dli.dli_fbase;
                fInfo.baseImg = cast(size_t)dli.dli_fbase;
                fInfo.file=dli.dli_fname[0..strlen(dli.dli_fname)];
            }
            if (dli.dli_sname && dli.dli_saddr){
                fInfo.offsetSymb = cast(ptrdiff_t)ip - cast(ptrdiff_t)dli.dli_saddr;
                fInfo.baseSymb = cast(size_t)dli.dli_saddr;
                fInfo.func = dli.dli_sname[0..strlen(dli.dli_sname)];
            } else {
                // try static symbols
                foreach(symName,symAddr,symEnd,pub;StaticSectionInfo) {
                    if (cast(size_t)ip>=symAddr && cast(size_t)ip<symEnd) {
                        fInfo.offsetSymb = cast(ptrdiff_t)ip - cast(ptrdiff_t)symAddr;
                        fInfo.baseSymb = cast(size_t)symAddr;
                        fInfo.func = symName;
                        break;
                    }
                }
            }
        }
        StaticSectionInfo.resolveLineNumber(fInfo);
        return true;
    }
}

/// Loads symbols for the given frame info with the methods defined in tango itself.
bool defaultSymbolizeFrameInfo(ref Exception.FrameInfo fInfo,TraceContext *context,char[]buf){
    version(ElfSymbolification) {
        return elfSymbolizeFrameInfo(fInfo,context,buf);
    } else version(DladdrSymbolification){
        return dladdrSymbolizeFrameInfo(fInfo,context,buf);
    } else version(Windows) {
        return winSymbolizeFrameInfo(fInfo,context,buf);
    } else {
        return false;
    }
}

/// Function that generates a trace (handler compatible with old TraceInfo.)
Exception.TraceInfo basicTracer( void* ptr = null ){
    BasicTraceInfo res;
    try{
        version(CatchRecursiveTracing){
            recursiveStackTraces.val=recursiveStackTraces.val+1;
            scope(exit) recursiveStackTraces.val=recursiveStackTraces.val-1;
            // printf("tracer %d\n",recursiveStackTraces.val);
            if (recursiveStackTraces.val>10) {
                Runtime.console.stderr("hit maximum recursive tracing (tracer asserting...?)\n");
                abort();
                return null;
            }
        }
        res=new BasicTraceInfo();
        res.trace(cast(TraceContext*)ptr);
    } catch (Exception e){
        Runtime.console.stderr("tracer got exception:\n");
        Runtime.console.stderr(e.msg);
        e.writeOut((char[]s){ Runtime.console.stderr(s); });
        Runtime.console.stderr("\n");
    } catch (Object o){
        Runtime.console.stderr("tracer got object exception:\n");
        Runtime.console.stderr(o.toString());
        Runtime.console.stderr("\n");
    }
    return res;
}

// signal handling
version(Posix){
    version(linux){
        version(X86){
            version = haveSegfaultTrace;
        }else version(X86_64){
            version = haveSegfaultTrace;
        }
    }

    extern(C) void tango_stacktrace_fault_handler (int sn, siginfo_t * si, void *ctx){
        Runtime.console.stderr(fromStringz(strsignal(sn)));
        Runtime.console.stderr(" encountered at:\n");
        ucontext_t * context = cast(ucontext_t *) ctx;
        version(haveSegfaultTrace){
            void* stack;
            void* code;
            version(X86){
                code = cast(void*) context.uc_mcontext.gregs[14];
            }else version(X86_64){
                code = cast(void*) context.uc_mcontext.gregs[0x10];
            }else{
                static assert(0);
            }

            Exception.FrameInfo fInfo;
            char[1024] buf1,buf2;
            fInfo.clear();
            fInfo.address=cast(size_t)code;
            rt_symbolizeFrameInfo(fInfo,null,buf1);
            fInfo.func = demangler.demangle(fInfo.func,buf2);
            fInfo.writeOut((char[] s) { Runtime.console.stderr(s); });
        }
        Runtime.console.stderr("\n Stacktrace:\n");
        TraceContext tc;
        tc.hasContext=ctx is null;
        if (tc.hasContext) tc.context=*(cast(ucontext_t*)ctx);
        Exception.TraceInfo info=basicTracer(&tc);
        info.writeOut((char[] s) { Runtime.console.stderr(s); });

        Runtime.console.stderr("Stacktrace signal handler abort().\n");
        abort();
    }

    sigaction_t fault_action;
        
    void setupSegfaultTracer(){
        //use an alternative stack; this is useful when infinite recursion
        //  triggers a SIGSEGV
        void* altstack = malloc(SIGSTKSZ);
        if (altstack) {
            stack_t stack;
            stack.ss_sp = altstack;
            stack.ss_size = SIGSTKSZ;
            sigaltstack(&stack, null);
        }
        fault_action.sa_handler = cast(typeof(fault_action.sa_handler)) &tango_stacktrace_fault_handler;
        sigemptyset(&fault_action.sa_mask);
        fault_action.sa_flags = SA_SIGINFO | SA_ONSTACK;
        foreach (sig;[SIGSEGV,SIGFPE,SIGILL,SIGBUS,SIGINT]){
            sigaction(sig, &fault_action, null);
        }
    }
    
    version(noSegfaultTrace){
    } else {
        static this(){
            setupSegfaultTracer();
        }
    }
}else version(Windows){
}else {
    pragma(msg, "[INFO] SEGFAULT trace not yet implemented for this OS");
}

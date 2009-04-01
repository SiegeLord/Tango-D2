module tango.core.stacktrace.StackTrace;
import tango.core.stacktrace.Demangler;
import tango.core.Thread;
import tango.stdc.string;
import tango.stdc.stdio:printf;
import tango.stdc.stdlib: abort;
version(Windows){
    import tango.core.stacktrace.WinStackTrace;
} else {
    import tango.stdc.posix.ucontext;
    import tango.stdc.posix.sys.types: pid_t,pthread_t;
}

version(CatchRecursiveTracing){
    ThreadLocal!(int) recursiveStackTraces;

    static this(){
        recursiveStackTraces=new ThreadLocal!(int)(0);
    }
}

version(Windows){
} else {
    static if (is(typeof(ucontext_t))){
        struct TraceContext{
            ucontext_t context;
            pid_t hProcess;
            pthread_t hThread;
        }
    } else {
        struct TraceContext{
            void *extra;
            size_t esp;
            size_t gotf;
            size_t ip;
            pid_t hProcess;
            pthread_t hThread;
        }
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

/// sets the function used for address stacktraces
extern(C) void rt_setAddrBacktraceFnc(AddrBacktraceFunc f){
    addrBacktraceFnc=f;
}
/// sets the function used to symbolize a FrameInfo
extern(C) void rt_setSymbolizeFrameInfoFnc(SymbolizeFrameInfoFnc f){
    symbolizeFrameInfoFnc=f;
}
/// creates a stack trace (defined in the runtime)
extern(C) Exception.TraceInfo rt_createTraceContext( void* ptr );

alias Exception.TraceInfo function( void* ptr = null ) TraceHandler;
/// changes the trace handler (defined in the runtime)
extern (C) void  rt_setTraceHandler( TraceHandler h );


/// builds a backtrace of addresses, the addresses are addresses of the *next* instruction, 
/// *return* addresses, the most likely the calling instruction is the one before them
/// (stack top excluded)
extern(C) size_t rt_addrBacktrace(TraceContext* context, TraceContext *contextOut,size_t*traceBuf,size_t bufLength,int *flags){
    if (addrBacktraceFnc !is null){
        return addrBacktraceFnc(context,contextOut,traceBuf,bufLength,flags);
    } else {
        return 0;
    }
}

/// tries to sybolize a frame information, this should try to build the best
/// backtrace information, if possible finding the calling context, thus 
/// exactAddress is false the address might be changed to the one preceding it
/// if topStack is true this frame is the top of the stack, and
/// one should use exactly that information
extern(C) bool rt_symbolizeFrameInfo(ref Exception.FrameInfo fInfo,TraceContext* context,char[]buf){
    if (symbolizeFrameInfoFnc !is null){
        return symbolizeFrameInfoFnc(fInfo,context,buf);
    } else {
        return false;
    }
}

/// precision of the addresses given by the backtrace function
enum AddrPrecision{
    AllReturn=0,
    TopExact=1,
    AllExact=3
}

/// basic class that represents a stacktrace
class BasicTraceInfo: Exception.TraceInfo{
    size_t[] traceAddresses;
    size_t[128] traceBuf;
    AddrPrecision addrPrecision;
    TraceContext context;
    /// cretes an empty stacktrace
    this(){}
    /// creates a stacktrace with the given traceAddresses
    this(size_t[] traceAddresses,AddrPrecision addrPrecision){
        this.traceAddresses[]=traceAddresses;
        if (traceAddresses.length<=traceBuf.length){
            // change to either always copy (and truncate) or never copy?
            traceBuf[0..traceAddresses.length]=traceAddresses;
            this.traceAddresses=traceBuf[0..traceAddresses.length];
        }
        this.addrPrecision=addrPrecision;
    }
    /// takes a stacktrace
    void trace(TraceContext *contextIn=null,int skipFrames=0){
        int flags;
        size_t nFrames=rt_addrBacktrace(contextIn,&context,traceBuf.ptr,traceBuf.length,&flags);
        traceAddresses=traceBuf[skipFrames..nFrames];
        addrPrecision=cast(AddrPrecision)flags;
        if (flags==AddrPrecision.TopExact && skipFrames!=0)
            addrPrecision=AddrPrecision.AllReturn;
    }
    /// loops on the stacktrace
    int opApply( int delegate( ref Exception.FrameInfo fInfo ) loopBody){
        Exception.FrameInfo fInfo;
        for (size_t iframe=0;iframe<traceAddresses.length;++iframe){
            char[2048] buf;
            fInfo.clear();
            fInfo.address=cast(size_t)traceAddresses[iframe];
            fInfo.iframe=cast(ptrdiff_t)iframe;
            fInfo.exactAddress=(addrPrecision & 2) || (iframe==0 && (addrPrecision & 1));
            rt_symbolizeFrameInfo(fInfo,&context,buf);
            int res=loopBody(fInfo);
            if (res) return res;
        }
        return 0;
    }
    /// writes out the stacktrace
    void writeOut(void delegate(char[]) sink){
        foreach (ref fInfo; this){
            fInfo.writeOut(sink);
        }
    }
}

version(linux){
    version=LibCBacktrace;
    version=DladdrSymbolification;
}
version(darwin){
    version=LibCBacktrace;
    version=DladdrSymbolification;
}
version(LibCBacktrace){
    extern(C)int backtrace(void**,int);
}

/// default (tango given) backtrace function
size_t defaultAddrBacktrace(TraceContext* context,TraceContext*contextOut,
    size_t*traceBuf,size_t length,int*flags){
    version(LibCBacktrace){
        if (context!is null) return 0;
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
                fInfo.func = demangler.demangle(fInfo.func,buf);
            }
        }
        return true;
    }
}

bool defaultSymbolizeFrameInfo(ref Exception.FrameInfo fInfo,TraceContext *context,char[]buf){
    version(DladdrSymbolification){
        return dladdrSymbolizeFrameInfo(fInfo,context,buf);
    } else version(Windows) {
        return winSymbolizeFrameInfo(fInfo,context,buf);
    } else {
        return false;
    }
}

Exception.TraceInfo basicTracer( void* ptr = null ){
    BasicTraceInfo res;
    try{
        version(CatchRecursiveTracing){
            recursiveStackTraces.val=recursiveStackTraces.val+1;
            scope(exit) recursiveStackTraces.val=recursiveStackTraces.val-1;
            // printf("tracer %d\n",recursiveStackTraces.val);
            if (recursiveStackTraces.val>10) {
                printf("hit maximum recursive tracing (tracer asserting...?)\n");
                abort();
                return null;
            }
        }
        res=new BasicTraceInfo();
        res.trace(cast(TraceContext*)ptr);
    } catch (Exception e){
        printf("tracer got exception:\n");
        printf((e.msg~"\n\0").ptr);
        e.writeOut((char[]s){ printf((s~"\0").ptr); });
        printf("\n");
    } catch (Object o){
        printf("tracer got object exception:\n");
        printf((o.toString~"\n\0").ptr);
    }
    return res;
}


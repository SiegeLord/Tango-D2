// D import file generated from 'core\thread.d'
module tango.core.thread;
class ThreadError : Exception
{
    this(char[] msg)
{
super(msg);
}
}
version = StackGrowsDown;
private
{
    import tango.stdc.string;
}
version (Win32)
{
    private
{
    import tango.os.windows.c.process;
    import tango.os.windows.c.windows;
    extern (Windows) 
{
    uint threadFunc(void* arg);
}
    HANDLE GetCurrentThreadHandle()
{
const uint DUPLICATE_SAME_ACCESS = 2;
HANDLE curr = GetCurrentThread();
HANDLE proc = GetCurrentProcess();
HANDLE hndl;
DuplicateHandle(proc,curr,proc,&hndl,0,TRUE,DUPLICATE_SAME_ACCESS);
return hndl;
}
    void* getStackBottom();
    void* getStackTop();
}
}
else
{
    version (Posix)
{
    private
{
    import tango.stdc.posix.semaphore;
    import tango.stdc.posix.pthread;
    import tango.stdc.posix.signal;
    import tango.stdc.posix.unistd;
    import tango.stdc.posix.time;
    version (darwin)
{
    import tango.os.darwin.c.darwin;
}
else
{
    import tango.os.linux.c.linux;
}
    extern (C) 
{
    void* threadFunc(void* arg);
}
    sem_t suspendCount;
    extern (C) 
{
    void suspendHandler(int sig);
}
    extern (C) 
{
    void resumeHandler(int sig)
in
{
assert(sig == SIGUSR2);
}
body
{
}
}
    void* getStackBottom();
    void* getStackTop();
}
}
else
{
    static assert(false);
}
}
class Thread
{
    this()
{
m_call = Call.NO;
}
    this(void(* fn)())
{
m_fn = fn;
m_call = Call.FN;
}
    this(void delegate() dg)
{
m_dg = dg;
m_call = Call.DG;
}
    final
{
    void start();
}
    final
{
    void join();
}
    final
{
    char[] name();
}
    final
{
    void name(char[] n);
}
    final
{
    bool isRunning();
}
    static
{
    void sleep(uint milliseconds);
}
    static
{
    void yield();
}
    static
{
    Thread getThis();
}
    static
{
    Thread[] getAll();
}
    static
{
    int opApply(int delegate(inout Thread) dg);
}
    const
{
    uint LOCAL_MAX = 64;
}
    static
{
    uint createLocal();
}
    static
{
    void deleteLocal(uint key);
}
    static
{
    void* getLocal(uint key)
{
return getThis().m_local[key];
}
}
    static
{
    void* setLocal(uint key, void* val)
{
return getThis().m_local[key] = val;
}
}
    protected:
    void run();
    private:
    enum Call 
{
NO,
FN,
DG,
}
    version (Win32)
{
    alias uint TLSKey;
    alias uint ThreadAddr;
}
else
{
    version (Posix)
{
    alias pthread_key_t TLSKey;
    alias pthread_t ThreadAddr;
}
}
    static
{
    ubyte[LOCAL_MAX] sm_local;
}
    static
{
    TLSKey sm_this;
}
    void*[LOCAL_MAX] m_local;
    version (Win32)
{
    HANDLE m_hndl;
}
    ThreadAddr m_addr;
    Call m_call;
    char[] m_name;
    union
{
void(* m_fn)();
void delegate() m_dg;
}
    version (Posix)
{
    bool m_isRunning;
}
    private:
    static
{
    Object slock()
{
return Thread.classinfo;
}
}
    static
{
    void add(Thread t);
}
    static
{
    void remove(Thread t);
}
    static
{
    Thread sm_all;
}
    static
{
    size_t sm_len;
}
    Thread m_prev;
    Thread m_next;
    private:
    void* m_bstack;
    void* m_tstack;
    version (Win32)
{
    uint[8] m_reg;
}
}
extern (C) 
{
    void thread_init();
}
private
{
    bool multiThreadedFlag = false;
}
extern (C) 
{
    bool thread_needLock()
{
return multiThreadedFlag;
}
}
private
{
    uint suspendDepth = 0;
}
extern (C) 
{
    void thread_suspendAll();
}
extern (C) 
{
    void thread_resumeAll();
}
private
{
    alias void delegate(void*, void*) scanAllThreadsFn;
}
extern (C) 
{
    void thread_scanAll(scanAllThreadsFn fn, void* curStackTop = null);
}
class ThreadGroup
{
    Thread create(void(* fn)());
    Thread create(void delegate() dg);
    void add(Thread t);
    void remove(Thread t);
    int opApply(int delegate(inout Thread) dg);
    void joinAll(bool preserve = true);
    private:
    Thread[Thread] m_all;
}

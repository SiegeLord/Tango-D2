/**
 * D header file for POSIX.
 *
 * on posix SIGUSR1 and SIGUSR2 are used by the gc, and should not be used/handled/blocked
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.signal;

private import tango.stdc.posix.config;
version( solaris ) {
    private import tango.stdc.stdint;
}
public import tango.stdc.signal;
public import tango.stdc.stddef;          // for size_t
public import tango.stdc.posix.sys.types; // for pid_t
//public import tango.stdc.posix.time;      // for timespec, now defined here

extern (C):

private alias void function(int) sigfn_t;
private alias void function(int, siginfo_t*, void*) sigactfn_t;

//
// Required
//
/*
SIG_DFL (defined in tango.stdc.signal)
SIG_ERR (defined in tango.stdc.signal)
SIG_IGN (defined in tango.stdc.signal)

sig_atomic_t (defined in tango.stdc.signal)

SIGEV_NONE
SIGEV_SIGNAL
SIGEV_THREAD

union sigval
{
    int   sival_int;
    void* sival_ptr;
}

SIGRTMIN
SIGRTMAX

SIGABRT (defined in tango.stdc.signal)
SIGALRM
SIGBUS
SIGCHLD
SIGCONT
SIGFPE (defined in tango.stdc.signal)
SIGHUP
SIGILL (defined in tango.stdc.signal)
SIGINT (defined in tango.stdc.signal)
SIGKILL
SIGPIPE
SIGQUIT
SIGSEGV (defined in tango.stdc.signal)
SIGSTOP
SIGTERM (defined in tango.stdc.signal)
SIGTSTP
SIGTTIN
SIGTTOU
SIGUSR1
SIGUSR2
SIGURG

struct sigaction_t
{
    sigfn_t     sa_handler;
    sigset_t    sa_mask;
    sigactfn_t  sa_sigaction;
}

sigfn_t signal(int sig, sigfn_t func); (defined in tango.stdc.signal)
int raise(int sig);                    (defined in tango.stdc.signal)
*/

//SIG_DFL (defined in tango.stdc.signal)
//SIG_ERR (defined in tango.stdc.signal)
//SIG_IGN (defined in tango.stdc.signal)

//sig_atomic_t (defined in tango.stdc.signal)

enum
{
  SIGEV_SIGNAL,
  SIGEV_NONE,
  SIGEV_THREAD
}

union sigval
{
    int     sival_int;
    void*   sival_ptr;
}

private extern (C) int __libc_current_sigrtmin();
private extern (C) int __libc_current_sigrtmax();

alias __libc_current_sigrtmin SIGRTMIN;
alias __libc_current_sigrtmax SIGRTMAX;

version( linux )
{
    //SIGABRT (defined in tango.stdc.signal)
    const SIGALRM   = 14;
    const SIGBUS    = 7;
    const SIGCHLD   = 17;
    const SIGCONT   = 18;
    //SIGFPE (defined in tango.stdc.signal)
    const SIGHUP    = 1;
    //SIGILL (defined in tango.stdc.signal)
    //SIGINT (defined in tango.stdc.signal)
    const SIGKILL   = 9;
    const SIGPIPE   = 13;
    const SIGQUIT   = 3;
    //SIGSEGV (defined in tango.stdc.signal)
    const SIGSTOP   = 19;
    //SIGTERM (defined in tango.stdc.signal)
    const SIGTSTP   = 20;
    const SIGTTIN   = 21;
    const SIGTTOU   = 22;
    const SIGUSR1   = 10;
    const SIGUSR2   = 12;
    const SIGURG    = 23;
}
else version( darwin )
{
    //SIGABRT (defined in tango.stdc.signal)
    const SIGALRM   = 14;
    const SIGBUS    = 10;
    const SIGCHLD   = 20;
    const SIGCONT   = 19;
    //SIGFPE (defined in tango.stdc.signal)
    const SIGHUP    = 1;
    //SIGILL (defined in tango.stdc.signal)
    //SIGINT (defined in tango.stdc.signal)
    const SIGKILL   = 9;
    const SIGPIPE   = 13;
    const SIGQUIT   = 3;
    //SIGSEGV (defined in tango.stdc.signal)
    const SIGSTOP   = 17;
    //SIGTERM (defined in tango.stdc.signal)
    const SIGTSTP   = 18;
    const SIGTTIN   = 21;
    const SIGTTOU   = 22;
    const SIGUSR1   = 30;
    const SIGUSR2   = 31;
    const SIGURG    = 16;
}
else version( FreeBSD )
{
    //SIGABRT (defined in tango.stdc.signal)
    const SIGALRM   = 14;
    const SIGBUS    = 10;
    const SIGCHLD   = 20;
    const SIGCONT   = 19;
    //SIGFPE (defined in tango.stdc.signal)
    const SIGHUP    = 1;
    //SIGILL (defined in tango.stdc.signal)
    //SIGINT (defined in tango.stdc.signal)
    const SIGKILL   = 9;
    const SIGPIPE   = 13;
    const SIGQUIT   = 3;
    //SIGSEGV (defined in tango.stdc.signal)
    const SIGSTOP   = 17;
    //SIGTERM (defined in tango.stdc.signal)
    const SIGTSTP   = 18;
    const SIGTTIN   = 21;
    const SIGTTOU   = 22;
    const SIGUSR1   = 30;
    const SIGUSR2   = 31;
    const SIGURG    = 16;
}
else version( solaris )
{
    //SIGABRT (defined in tango.stdc.signal)
    const SIGALRM   = 14;   /* alarm clock */
    const SIGBUS    = 10;   /* bus error */
    const SIGCHLD   = 18;   /* child status change alias (POSIX) */
    const SIGCONT   = 25;   /* stopped process has been continued */
    //SIGFPE (defined in tango.stdc.signal)
    const SIGHUP    = 1;    /* hangup */
    //SIGILL (defined in tango.stdc.signal)
    //SIGINT (defined in tango.stdc.signal)
    const SIGKILL   = 9;    /* kill (cannot be caught or ignored) */
    const SIGPIPE   = 13;   /* write on a pipe with no one to read it */
    const SIGQUIT   = 3;    /* quit (ASCII FS) */
    //SIGSEGV (defined in tango.stdc.signal)
    const SIGSTOP   = 23;   /* stop (cannot be caught or ignored) */
    //SIGTERM (defined in tango.stdc.signal)
    const SIGTSTP   = 24;   /* user stop requested from tty */
    const SIGTTIN   = 26;   /* background tty read attempted */
    const SIGTTOU   = 27;   /* background tty write attempted */
    const SIGUSR1   = 16;   /* user defined signal 1 */
    const SIGUSR2   = 17;   /* user defined signal 2 */
    const SIGURG    = 21;   /* urgent socket condition */
/+
    const SIGTRAP   = 5;    /* trace trap (not reset when caught) */
    const SIGIOT    = 6;    /* IOT instruction */
    const SIGEMT    = 7;    /* EMT instruction */
    const SIGSYS    = 12;   /* bad argument to system call */
    const SIGCLD    = 18;   /* child status change */
    const SIGPWR    = 19;   /* power-fail restart */
    const SIGWINCH  = 20;   /* window size change */
    const SIGPOLL   = 22;   /* pollable event occured */
    const SIGIO     = SIGPOLL;  /* socket I/O possible (SIGPOLL alias) */
    const SIGVTALRM = 28;   /* virtual timer expired */
    const SIGPROF   = 29;   /* profiling timer expired */
    const SIGXCPU   = 30;   /* exceeded cpu limit */
    const SIGXFSZ   = 31;   /* exceeded file size limit */
    const SIGWAITING= 32;   /* reserved signal no longer used by threading code */
    const SIGLWP    = 33;   /* reserved signal no longer used by threading code */
    const SIGFREEZE = 34;   /* special signal used by CPR */
    const SIGTHAW   = 35;   /* special signal used by CPR */
    const SIGCANCEL = 36;   /* reserved signal for thread cancellation */
    const SIGLOST   = 37;   /* resource lost (eg, record-lock lost) */
    const SIGXRES   = 38;   /* resource control exceeded */
    const SIGJVM1   = 39;   /* reserved signal for Java Virtual Machine */
    const SIGJVM2   = 40;   /* reserved signal for Java Virtual Machine */
+/
}
else
{
   static assert(0, "Platform not supported...");
}

struct sigaction_t
{
    static if( true /* __USE_POSIX199309 */ )
    {
        union
        {
            sigfn_t     sa_handler;
            sigactfn_t  sa_sigaction;
        }
    }
    else
    {
        sigfn_t     sa_handler;
    }
    version(FreeBSD){
        int             sa_flags;
        sigset_t        sa_mask;
    }else{
        sigset_t        sa_mask;
        int             sa_flags;
    }

    version( darwin ) {} else {
    void function() sa_restorer;
    }
}

//
// C Extension (CX)
//
/*
SIG_HOLD

sigset_t
pid_t   (defined in sys.types)

SIGABRT (defined in tango.stdc.signal)
SIGFPE  (defined in tango.stdc.signal)
SIGILL  (defined in tango.stdc.signal)
SIGINT  (defined in tango.stdc.signal)
SIGSEGV (defined in tango.stdc.signal)
SIGTERM (defined in tango.stdc.signal)

SA_NOCLDSTOP (CX|XSI)
SIG_BLOCK
SIG_UNBLOCK
SIG_SETMASK

struct siginfo_t
{
    int     si_signo;
    int     si_code;

    version( XSI )
    {
        int     si_errno;
        pid_t   si_pid;
        uid_t   si_uid;
        void*   si_addr;
        int     si_status;
        c_long  si_band;
    }
    version( RTS )
    {
        sigval  si_value;
    }
}

SI_USER
SI_QUEUE
SI_TIMER
SI_ASYNCIO
SI_MESGQ

int kill(pid_t, int);
int sigaction(int, in sigaction_t*, sigaction_t*);
int sigaddset(sigset_t*, int);
int sigdelset(sigset_t*, int);
int sigemptyset(sigset_t*);
int sigfillset(sigset_t*);
int sigismember(in sigset_t*, int);
int sigpending(sigset_t*);
int sigprocmask(int, in sigset_t*, sigset_t*);
int sigsuspend(in sigset_t*);
int sigwait(in sigset_t*, int*);
*/

version( linux )
{
    const SIG_HOLD = cast(sigfn_t) 1;

    private const _SIGSET_NWORDS = 1024 / (8 * c_ulong.sizeof);

    struct sigset_t
    {
        c_ulong[_SIGSET_NWORDS] __val;
    }

    // pid_t  (defined in sys.types)

    //SIGABRT (defined in tango.stdc.signal)
    //SIGFPE  (defined in tango.stdc.signal)
    //SIGILL  (defined in tango.stdc.signal)
    //SIGINT  (defined in tango.stdc.signal)
    //SIGSEGV (defined in tango.stdc.signal)
    //SIGTERM (defined in tango.stdc.signal)

    const SA_NOCLDSTOP  = 1; // (CX|XSI)

    const SIG_BLOCK     = 0;
    const SIG_UNBLOCK   = 1;
    const SIG_SETMASK   = 2;

    private const __SI_MAX_SIZE = 128;

    static if( false /* __WORDSIZE == 64 */ )
    {
        private const __SI_PAD_SIZE = ((__SI_MAX_SIZE / int.sizeof) - 4);
    }
    else
    {
        private const __SI_PAD_SIZE = ((__SI_MAX_SIZE / int.sizeof) - 3);
    }

    struct siginfo_t
    {
        int si_signo;       // Signal number
        int si_errno;       // If non-zero, an errno value associated with
                            // this signal, as defined in <errno.h>
        int si_code;        // Signal code

        union _sifields_t
        {
            int[__SI_PAD_SIZE] _pad;

            // kill()
            struct _kill_t
            {
                pid_t si_pid; // Sending process ID
                uid_t si_uid; // Real user ID of sending process
            } _kill_t _kill;

            // POSIX.1b timers.
            struct _timer_t
            {
                int    si_tid;     // Timer ID
                int    si_overrun; // Overrun count
                sigval si_sigval;  // Signal value
            } _timer_t _timer;

            // POSIX.1b signals
            struct _rt_t
            {
                pid_t  si_pid;    // Sending process ID
                uid_t  si_uid;    // Real user ID of sending process
                sigval si_sigval; // Signal value
            } _rt_t _rt;

            // SIGCHLD
            struct _sigchild_t
            {
                pid_t   si_pid;    // Which child
                uid_t   si_uid;    // Real user ID of sending process
                int     si_status; // Exit value or signal
                clock_t si_utime;
                clock_t si_stime;
            } _sigchild_t _sigchld;

            // SIGILL, SIGFPE, SIGSEGV, SIGBUS
            struct _sigfault_t
            {
                void*     si_addr;  // Faulting insn/memory ref
            } _sigfault_t _sigfault;

            // SIGPOLL
            struct _sigpoll_t
            {
                c_long   si_band;   // Band event for SIGPOLL
                int      si_fd;
            } _sigpoll_t _sigpoll;
        } _sifields_t _sifields;
    }

    enum
    {
        SI_ASYNCNL = -60,
        SI_TKILL   = -6,
        SI_SIGIO,
        SI_ASYNCIO,
        SI_MESGQ,
        SI_TIMER,
        SI_QUEUE,
        SI_USER,
        SI_KERNEL  = 0x80
    }

    int kill(pid_t, int);
    int sigaction(int, in sigaction_t*, sigaction_t*);
    int sigaddset(sigset_t*, int);
    int sigdelset(sigset_t*, int);
    int sigemptyset(sigset_t*);
    int sigfillset(sigset_t*);
    int sigismember(in sigset_t*, int);
    int sigpending(sigset_t*);
    int sigprocmask(int, in sigset_t*, sigset_t*);
    int sigsuspend(in sigset_t*);
    int sigwait(in sigset_t*, int*);
}
else version( darwin )
{
    //SIG_HOLD

    alias uint sigset_t;
    // pid_t  (defined in sys.types)

    //SIGABRT (defined in tango.stdc.signal)
    //SIGFPE  (defined in tango.stdc.signal)
    //SIGILL  (defined in tango.stdc.signal)
    //SIGINT  (defined in tango.stdc.signal)
    //SIGSEGV (defined in tango.stdc.signal)
    //SIGTERM (defined in tango.stdc.signal)

    //SA_NOCLDSTOP (CX|XSI)

    const SIG_BLOCK=1;
    const SIG_UNBLOCK=2;
    const SIG_SETMASK=3;

    struct siginfo_t
    {
        int     si_signo;
        int     si_errno;
        int     si_code;
        pid_t   si_pid;
        uid_t   si_uid;
        int     si_status;
        void*   si_addr;
        sigval  si_value;
        int     si_band;
        uint[7] pad;
    }

    //SI_USER
    //SI_QUEUE
    //SI_TIMER
    //SI_ASYNCIO
    //SI_MESGQ

    int kill(pid_t, int);
    int sigaction(int, in sigaction_t*, sigaction_t*);
    int sigaddset(sigset_t*, int);
    int sigdelset(sigset_t*, int);
    int sigemptyset(sigset_t*);
    int sigfillset(sigset_t*);
    int sigismember(in sigset_t*, int);
    int sigpending(sigset_t*);
    int sigprocmask(int, in sigset_t*, sigset_t*);
    int sigsuspend(in sigset_t*);
    int sigwait(in sigset_t*, int*);
    int sigaltstack(void * , void * );
}
else version( FreeBSD )
{
    struct sigset_t
    {
        uint[4] __bits;
    }
   
    const SIG_BLOCK = 2;
    const SIG_UNBLOCK = 1;
    const SIG_SETMASK = 3;
   
    struct siginfo_t
    {
        int si_signo;
        int si_errno;
        int si_code;
        pid_t si_pid;
        uid_t si_uid;
        int si_status;
        void* si_addr;
        sigval si_value;
        union __reason
        {
            struct __fault
            {
                int _trapno;
            }
            __fault _fault;
            struct __timer
            {
                int _timerid;
                int _overrun;
            }
            __timer _timer;
            struct __mesgq
            {
                int _mqd;
            }
            __mesgq _mesgq;
            struct __poll
            {
                c_long _band;
            }
            __poll _poll;
            struct ___spare___
            {
                c_long __spare1__;
                int[7] __spare2__;
            }
            ___spare___ __spare__;
        }
        __reason _reason;
    }

    int kill(pid_t, int);
    int sigaction(int, in sigaction_t*, sigaction_t*);
    int sigaddset(sigset_t*, int);
    int sigdelset(sigset_t*, int);
    int sigemptyset(sigset_t *);
    int sigfillset(sigset_t *);
    int sigismember(in sigset_t *, int);
    int sigpending(sigset_t *);
    int sigprocmask(int, in sigset_t*, sigset_t*);
    int sigsuspend(in sigset_t *);
    int sigwait(in sigset_t*, int*);
}
else version( solaris )
{
    alias id_t taskid_t;
    alias id_t projid_t;
    alias id_t poolid_t;
    alias id_t zoneid_t;
    alias id_t ctid_t;
    
    const SIG_HOLD = cast(sigfn_t) 2;
    
    struct sigset_t
    {
        uint[4] __sigbits;
    }
    
    // pid_t  (defined in sys.types)

    //SIGABRT (defined in tango.stdc.signal)
    //SIGFPE  (defined in tango.stdc.signal)
    //SIGILL  (defined in tango.stdc.signal)
    //SIGINT  (defined in tango.stdc.signal)
    //SIGSEGV (defined in tango.stdc.signal)
    //SIGTERM (defined in tango.stdc.signal)

    const SA_NOCLDSTOP  = 0x00020000; // (CX|XSI)

    const SIG_BLOCK     = 1;
    const SIG_UNBLOCK   = 2;
    const SIG_SETMASK   = 3;

    static if( /* _LP64 */ size_t.sizeof == 8 ) {
        const SI_MAXSZ  = 256;
        const SI_PAD    = ((SI_MAXSZ / int.sizeof) - 4);
    }
    else {
        const SI_MAXSZ  = 128;
        const SI_PAD    = ((SI_MAXSZ / int.sizeof) - 3);
    }
    
    struct siginfo_t
    {
        int     si_signo;           /* signal from signal.h */
        int     si_code;            /* code from above  */
        int     si_errno;           /* error from errno.h   */
    static if( /* _LP64 */ size_t.sizeof == 8 ) {
        int     si_pad;             /* _LP64 union starts on an 8-byte boundary */
    }
        union __data
        {
            int[SI_PAD] __pad;      /* for future growth    */

            struct __proc           /* kill(), SIGCLD, siqqueue() */
            {
                pid_t   __pid;      /* process ID       */
                union __pdata
                {
                    struct __kill {
                        uid_t   __uid;
                        sigval  __value;
                    }
                    struct __cld {
                        clock_t __utime;
                        int     __status;
                        clock_t __stime;
                    }
                }
                ctid_t      __ctid;     /* contract ID      */
                zoneid_t    __zoneid;   /* zone ID      */
            }
            
            struct __fault  /* SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE */
            {
                void*   __addr;     /* faulting address */
                int     __trapno;   /* illegal trap number  */
                caddr_t __pc;       /* instruction address  */
            }

            struct __file           /* SIGPOLL, SIGXFSZ */
            {
            /* fd not currently available for SIGPOLL */
                int     __fd;       /* file descriptor  */
                long    __band;
            }

            struct __prof           /* SIGPROF */
            {
                caddr_t     __faddr;        /* last fault address   */
                timespec    __tstamp;       /* real time stamp  */
                short       __syscall;      /* current syscall  */
                char        __nsysarg;      /* number of arguments  */
                char        __fault;        /* last fault type  */
                long[8]     __sysarg;       /* syscall arguments    */
                int[10]     __mstate;       /* see <sys/msacct.h>   */
            }

            struct __rctl {         /* SI_RCTL */
                int32_t     __entity;   /* type of entity exceeding */
            }
        }
    }

    enum
    {
        SI_NOINFO   = 32767,    /* no signal information */
        SI_DTRACE   = 2050,     /* kernel generated signal via DTrace action */
        SI_RCTL     = 2049,     /* kernel generated signal via rctl action */
        SI_USER     = 0,        /* user generated signal via kill() */
        SI_LWP      = -1,       /* user generated signal via lwp_kill() */
        SI_QUEUE    = -2,       /* user generated signal via sigqueue() */
        SI_TIMER    = -3,       /* from timer expiration */
        SI_ASYNCIO  = -4,       /* from asynchronous I/O completion */
        SI_MESGQ    = -5        /* from message arrival */
    }

    int kill(pid_t, int);
    int sigaction(int, in sigaction_t*, sigaction_t*);
    int sigaddset(sigset_t*, int);
    int sigdelset(sigset_t*, int);
    int sigemptyset(sigset_t*);
    int sigfillset(sigset_t*);
    int sigismember(in sigset_t*, int);
    int sigpending(sigset_t*);
    int sigprocmask(int, in sigset_t*, sigset_t*);
    int sigsuspend(in sigset_t*);
    int sigwait(in sigset_t*, int*);
}

//
// XOpen (XSI)
//
/*
SIGPOLL
SIGPROF
SIGSYS
SIGTRAP
SIGVTALRM
SIGXCPU
SIGXFSZ

SA_ONSTACK
SA_RESETHAND
SA_RESTART
SA_SIGINFO
SA_NOCLDWAIT
SA_NODEFER
SS_ONSTACK
SS_DISABLE
MINSIGSTKSZ
SIGSTKSZ

ucontext_t // from ucontext
mcontext_t // from ucontext

struct stack_t
{
    void*   ss_sp;
    size_t  ss_size;
    int     ss_flags;
}

struct sigstack
{
    int   ss_onstack;
    void* ss_sp;
}

ILL_ILLOPC
ILL_ILLOPN
ILL_ILLADR
ILL_ILLTRP
ILL_PRVOPC
ILL_PRVREG
ILL_COPROC
ILL_BADSTK

FPE_INTDIV
FPE_INTOVF
FPE_FLTDIV
FPE_FLTOVF
FPE_FLTUND
FPE_FLTRES
FPE_FLTINV
FPE_FLTSUB

SEGV_MAPERR
SEGV_ACCERR

BUS_ADRALN
BUS_ADRERR
BUS_OBJERR

TRAP_BRKPT
TRAP_TRACE

CLD_EXITED
CLD_KILLED
CLD_DUMPED
CLD_TRAPPED
CLD_STOPPED
CLD_CONTINUED

POLL_IN
POLL_OUT
POLL_MSG
POLL_ERR
POLL_PRI
POLL_HUP

sigfn_t bsd_signal(int sig, sigfn_t func);
sigfn_t sigset(int sig, sigfn_t func);

int killpg(pid_t, int);
int sigaltstack(in stack_t*, stack_t*);
int sighold(int);
int sigignore(int);
int siginterrupt(int, int);
int sigpause(int);
int sigrelse(int);
*/

version( linux )
{
    const SIGPOLL       = 29;
    const SIGPROF       = 27;
    const SIGSYS        = 31;
    const SIGTRAP       = 5;
    const SIGVTALRM     = 26;
    const SIGXCPU       = 24;
    const SIGXFSZ       = 25;

    const SA_ONSTACK    = 0x08000000;
    const SA_RESETHAND  = 0x80000000;
    const SA_RESTART    = 0x10000000;
    const SA_SIGINFO    = 4;
    const SA_NOCLDWAIT  = 2;
    const SA_NODEFER    = 0x40000000;
    const SS_ONSTACK    = 1;
    const SS_DISABLE    = 2;
    const MINSIGSTKSZ   = 2048;
    const SIGSTKSZ      = 8192;

    //ucontext_t (defined in tango.stdc.posix.ucontext)
    //mcontext_t (defined in tango.stdc.posix.ucontext)

    struct stack_t
    {
        void*   ss_sp;
        int     ss_flags;
        size_t  ss_size;
    }

    struct sigstack
    {
        void*   ss_sp;
        int     ss_onstack;
    }

    enum
    {
        ILL_ILLOPC = 1,
        ILL_ILLOPN,
        ILL_ILLADR,
        ILL_ILLTRP,
        ILL_PRVOPC,
        ILL_PRVREG,
        ILL_COPROC,
        ILL_BADSTK
    }

    enum
    {
        FPE_INTDIV = 1,
        FPE_INTOVF,
        FPE_FLTDIV,
        FPE_FLTOVF,
        FPE_FLTUND,
        FPE_FLTRES,
        FPE_FLTINV,
        FPE_FLTSUB
    }

    enum
    {
        SEGV_MAPERR = 1,
        SEGV_ACCERR
    }

    enum
    {
        BUS_ADRALN = 1,
        BUS_ADRERR,
        BUS_OBJERR
    }

    enum
    {
        TRAP_BRKPT = 1,
        TRAP_TRACE
    }

    enum
    {
        CLD_EXITED = 1,
        CLD_KILLED,
        CLD_DUMPED,
        CLD_TRAPPED,
        CLD_STOPPED,
        CLD_CONTINUED
    }

    enum
    {
        POLL_IN = 1,
        POLL_OUT,
        POLL_MSG,
        POLL_ERR,
        POLL_PRI,
        POLL_HUP
    }

    sigfn_t bsd_signal(int sig, sigfn_t func);
    sigfn_t sigset(int sig, sigfn_t func);

    int killpg(pid_t, int);
    int sigaltstack(in stack_t*, stack_t*);
    int sighold(int);
    int sigignore(int);
    int siginterrupt(int, int);
    int sigpause(int);
    int sigrelse(int);
}
else version( FreeBSD )
{
    const SIGPROF       = 27;
    const SIGSYS        = 12;
    const SIGTRAP       = 5;
    const SIGVTALRM     = 26;
    const SIGXCPU       = 24;
    const SIGXFSZ       = 25;

    const SA_ONSTACK    = 0x0001;
    const SA_RESETHAND  = 0x0004;
    const SA_RESTART    = 0x0002;
    const SA_SIGINFO    = 0x0040;
    const SA_NOCLDWAIT  = 0x0020;
    const SA_NODEFER    = 0x0010;
    const SS_ONSTACK    = 0x0001;
    const SS_DISABLE    = 0x0004;
    const MINSIGSTKSZ   = (512 * 4);
    const SIGSTKSZ      = (MINSIGSTKSZ + 32768);

    //ucontext_t (defined in tango.stdc.posix.ucontext)
    //mcontext_t (defined in tango.stdc.posix.ucontext)

    struct stack_t
    {
        void* ss_sp;
        size_t ss_size;
        int ss_flags;
    }

    struct sigstack
    {
        char* ss_sp;
        int ss_onstack;
    }

    enum
    {
        ILL_ILLOPC = 1,
        ILL_ILLOPN,
        ILL_ILLADR,
        ILL_ILLTRP,
        ILL_PRVOPC,
        ILL_PRVREG,
        ILL_COPROC,
        ILL_BADSTK
    }

    enum
    {
        FPE_INTOVF = 1,
        FPE_INTDIV,
        FPE_FLTDIV,
        FPE_FLTOVF,
        FPE_FLTUND,
        FPE_FLTRES,
        FPE_FLTINV,
        FPE_FLTSUB
    }

    enum
    {
        SEGV_MAPERR = 1,
        SEGV_ACCERR
    }

    enum
    {
        BUS_ADRALN = 1,
        BUS_ADRERR,
        BUS_OBJERR
    }

    enum
    {
        TRAP_BRKPT = 1,
        TRAP_TRACE
    }

    enum
    {
        CLD_EXITED = 1,
        CLD_KILLED,
        CLD_DUMPED,
        CLD_TRAPPED,
        CLD_STOPPED,
        CLD_CONTINUED
    }

    enum
    {
        POLL_IN = 1,
        POLL_OUT,
        POLL_MSG,
        POLL_ERR,
        POLL_PRI,
        POLL_HUP
    }

    //sigfn_t bsd_signal(int sig, sigfn_t func);
    //sigfn_t sigset(int sig, sigfn_t func);

    int killpg(pid_t, int);
    int sigaltstack(stack_t*, stack_t*);
    //int sighold(int);
    int sigblock(int);
    int sigignore(int);
    int siginterrupt(int, int);
    int sigpause(int);
    int sigrelse(int);
}
version(darwin){
    // to complete
    const int SA_ONSTACK   = 0x0001;
    const int SA_RESTART   = 0x0002;
    const int SA_RESETHAND = 0x0004;
    const int SA_NOCLDSTOP = 0x0008;
    const int SA_NODEFER   = 0x0010;
    const int SA_NOCLDWAIT = 0x0020;
    const int SA_SIGINFO   = 0x0040;
    const int SA_USERTRAMP = 0x0100;
    const MINSIGSTKSZ = 32768;
    const SIGSTKSZ = 131072;
}
version(solaris)
{
    const SA_ONSTACK = 0x00000001;
    const SA_RESETHAND = 0x00000002;
    const SA_RESTART = 0x00000004;
    const SA_SIGINFO = 0x00000008;

    /* this is only valid for SIGCLD */
    const SA_NOCLDWAIT = 0x00010000; /* don't save zombie children  */

    const SA_NODEFER = 0x00000010;
    const SS_ONSTACK = 0x00000001;
    const SS_DISABLE = 0x00000002;
    const MINSIGSTKSZ = 2048;
    const SIGSTKSZ = 8192;

    struct stack_t {
        void* ss_sp;
        size_t ss_size;
        int ss_flags;
    };


    struct sigstack {
        void* ss_sp;
        int ss_onstack;
    };
}


//
// Timer (TMR)
//
/*
NOTE: This should actually be defined in tango.stdc.posix.time.
      It is defined here instead to break a circular import.

struct timespec
{
    time_t  tv_sec;
    int     tv_nsec;
}
*/

version( linux )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version( darwin )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version( FreeBSD )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version ( solaris )
{
    struct timespec         /* definition per POSIX.4 */
    {
        time_t  tv_sec;     /* seconds */
        c_long  tv_nsec;    /* and nanoseconds */
    }
}

//
// Realtime Signals (RTS)
//
/*
struct sigevent
{
    int             sigev_notify;
    int             sigev_signo;
    sigval          sigev_value;
    void(*)(sigval) sigev_notify_function;
    pthread_attr_t* sigev_notify_attributes;
}

int sigqueue(pid_t, int, in sigval);
int sigtimedwait(in sigset_t*, siginfo_t*, in timespec*);
int sigwaitinfo(in sigset_t*, siginfo_t*);
*/

version( linux )
{
    private const __SIGEV_MAX_SIZE = 64;

    static if( false /* __WORDSIZE == 64 */ )
    {
        private const __SIGEV_PAD_SIZE = ((__SIGEV_MAX_SIZE / int.sizeof) - 4);
    }
    else
    {
        private const __SIGEV_PAD_SIZE = ((__SIGEV_MAX_SIZE / int.sizeof) - 3);
    }

    struct sigevent
    {
        sigval      sigev_value;
        int         sigev_signo;
        int         sigev_notify;

        union _sigev_un_t
        {
            int[__SIGEV_PAD_SIZE] _pad;
            pid_t                 _tid;

            struct _sigev_thread_t
            {
                void function(sigval)   _function;
                void*                   _attribute;
            } _sigev_thread_t _sigev_thread;
        } _sigev_un_t _sigev_un;
    }

    int sigqueue(pid_t, int, in sigval);
    int sigtimedwait(in sigset_t*, siginfo_t*, in timespec*);
    int sigwaitinfo(in sigset_t*, siginfo_t*);
}
else version( FreeBSD )
{
    struct sigevent
    {
        int             sigev_notify;
        int             sigev_signo;
        sigval          sigev_value;
        struct __sigev_thread {
            void function(sigval) _function;
            void* _attribute;
        }
        union  _sigev_un
        {
            lwpid_t _threadid;
            __sigev_thread _sigev_thread;
            c_long[8] __spare__;
        }
    }

    int sigqueue(pid_t, int, in sigval);
    int sigtimedwait(in sigset_t*, siginfo_t*, in timespec*);
    int sigwaitinfo(in sigset_t*, siginfo_t*);
}
else version ( solaris )
{
    struct sigevent {
        int                     sigev_notify;   /* notification mode */
        int                     sigev_signo;    /* signal number */
        sigval                  sigev_value;    /* signal value */
        void function(sigval)   sigev_notify_function;
        pthread_attr_t*         sigev_notify_attributes;
        private int             __sigev_pad2;
    }
} else version (darwin){
    struct sigevent {
     int sigev_notify;
     int sigev_signo;
     sigval sigev_value;
     void function(sigval) sigev_notify_function;
     pthread_attr_t *sigev_notify_attributes;
    }
}

//
// Threads (THR)
//
/*
int pthread_kill(pthread_t, int);
int pthread_sigmask(int, in sigset_t*, sigset_t*);
*/

version( linux )
{
    int pthread_kill(pthread_t, int);
    int pthread_sigmask(int, in sigset_t*, sigset_t*);
}
else version( darwin )
{
    int pthread_kill(pthread_t, int);
    int pthread_sigmask(int, in sigset_t*, sigset_t*);
}
else version( FreeBSD )
{
    int pthread_kill(pthread_t, int);
    int pthread_sigmask(int, in sigset_t*, sigset_t*);
}
else version( solaris )
{
    int pthread_kill(pthread_t, int);
    int pthread_sigmask(int, in sigset_t*, sigset_t*);
}

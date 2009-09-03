/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.ucontext;

private import tango.stdc.posix.config;
public import tango.stdc.posix.signal; // for sigset_t, stack_t

extern (C):

//
// XOpen (XSI)
//
/*
mcontext_t

struct ucontext_t
{
    ucontext_t* uc_link;
    sigset_t    uc_sigmask;
    stack_t     uc_stack;
    mcontext_t  uc_mcontext;
}
*/

version( linux )
{

    version( X86_64 )
    {
        private
        {
            struct _libc_fpxreg
            {
                ushort[4] significand;
                ushort    exponent;
                ushort[3] padding;
            }

            struct _libc_xmmreg
            {
                uint[4] element;
            }

            struct _libc_fpstate
            {
                ushort           cwd;
                ushort           swd;
                ushort           ftw;
                ushort           fop;
                ulong            rip;
                ulong            rdp;
                uint             mxcsr;
                uint             mxcr_mask;
                _libc_fpxreg[8]  _st;
                _libc_xmmreg[16] _xmm;
                uint[24]         padding;
            }

            const NGREG = 23;

            alias c_long            greg_t;
            alias greg_t[NGREG]     gregset_t;
            alias _libc_fpstate*    fpregset_t;
        }

        struct mcontext_t
        {
            gregset_t   gregs;
            fpregset_t  fpregs;
            c_ulong[8]  __reserved1;
        }

        struct ucontext_t
        {
            c_ulong         uc_flags;
            ucontext_t*     uc_link;
            stack_t         uc_stack;
            mcontext_t      uc_mcontext;
            sigset_t        uc_sigmask;
            _libc_fpstate   __fpregs_mem;
        }
    }
    else version( X86 )
    {
        private
        {
            struct _libc_fpreg
            {
              ushort[4] significand;
              ushort    exponent;
            }

            struct _libc_fpstate
            {
              c_ulong           cw;
              c_ulong           sw;
              c_ulong           tag;
              c_ulong           ipoff;
              c_ulong           cssel;
              c_ulong           dataoff;
              c_ulong           datasel;
              _libc_fpreg[8]    _st;
              c_ulong           status;
            }

            const NGREG = 19;

            alias int               greg_t;
            alias greg_t[NGREG]     gregset_t;
            alias _libc_fpstate*    fpregset_t;
        }

        struct mcontext_t
        {
            gregset_t   gregs;
            fpregset_t  fpregs;
            c_ulong     oldmask;
            c_ulong     cr2;
        }

        struct ucontext_t
        {
            c_ulong         uc_flags;
            ucontext_t*     uc_link;
            stack_t         uc_stack;
            mcontext_t      uc_mcontext;
            sigset_t        uc_sigmask;
            _libc_fpstate   __fpregs_mem;
        }
    }
}

version(darwin){
    struct mcontext_t{
        int undefined; /// this is architecture dependent, if you need it, then define it from the header files
    }
    
    struct stack_t{
     void *ss_sp;
     size_t ss_size;
     int ss_flags;
    }
    
    alias uint sigset_t;
    struct ucontext_t
    {
        int uc_onstack;
        sigset_t uc_sigmask;
        stack_t uc_stack;
        ucontext_t* uc_link;
        size_t uc_mcsize;
        mcontext_t*uc_mcontext;
    }
}

version( freebsd )
{
    alias int __register_t;
    struct mcontext_t
    {
        /*
        * The first 20 fields must match the definition of
        * sigcontext. So that we can support sigcontext
        * and ucontext_t at the same time.
        */
        __register_t	mc_onstack;	/* XXX - sigcontext compat. */
        __register_t	mc_gs;		/* machine state (struct trapframe) */
        __register_t	mc_fs;
        __register_t	mc_es;
        __register_t	mc_ds;
        __register_t	mc_edi;
        __register_t	mc_esi;
        __register_t	mc_ebp;
        __register_t	mc_isp;
        __register_t	mc_ebx;
        __register_t	mc_edx;
        __register_t	mc_ecx;
        __register_t	mc_eax;
        __register_t	mc_trapno;
        __register_t	mc_err;
        __register_t	mc_eip;
        __register_t	mc_cs;
        __register_t	mc_eflags;
        __register_t	mc_esp;
        __register_t	mc_ss;

        int mc_len;			/* sizeof(mcontext_t) */
        //#define	_MC_FPFMT_NODEV		0x10000	/* device not present or configured */
        //#define	_MC_FPFMT_387		0x10001
        //#define	_MC_FPFMT_XMM		0x10002
        int mc_fpformat;
        //#define	_MC_FPOWNED_NONE	0x20000	/* FP state not used */
        //#define	_MC_FPOWNED_FPU		0x20001	/* FP state came from FPU */
        //#define	_MC_FPOWNED_PCB		0x20002	/* FP state came from PCB */
        int mc_ownedfp;
        int[1] mc_spare1;		/* align next field to 16 bytes */
        /*
        * See <machine/npx.h> for the internals of mc_fpstate[].
        */
        align(16) int[128] mc_fpstate;
        int[8] mc_spare2;
    }
    
    struct ucontext_t
    {
        /*
        * Keep the order of the first two fields. Also,
        * keep them the first two fields in the structure.
        * This way we can have a union with struct
        * sigcontext and ucontext_t. This allows us to
        * support them both at the same time.
        * note: the union is not defined, though.
        */
        sigset_t uc_sigmask;
        mcontext_t uc_mcontext;

        ucontext_t* uc_link;
        stack_t uc_stack;
        int uc_flags;
        //#define	UCF_SWAPPED	0x00000001	/* Used by swapcontext(3). */
        int[4] __spare__;
    }
}

//
// Obsolescent (OB)
//
/*
int  getcontext(ucontext_t*);
void makecontext(ucontext_t*, void function(), int, ...);
int  setcontext(in ucontext_t*);
int  swapcontext(ucontext_t*, in ucontext_t*);
*/

static if( is( ucontext_t ) )
{
    int  getcontext(ucontext_t*);
    void makecontext(ucontext_t*, void function(), int, ...);
    int  setcontext(in ucontext_t*);
    int  swapcontext(ucontext_t*, in ucontext_t*);
}

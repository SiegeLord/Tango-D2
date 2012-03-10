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

version( FreeBSD ) {
    alias int	__register_t;
    alias int	c_int;
    struct mcontext_t { /* from /usr/include/machine/ucontext.h */
        __register_t    mc_onstack;     /* XXX - sigcontext compat. */
        __register_t    mc_gs;          /* machine state (struct trapframe) */
        __register_t    mc_fs;
        __register_t    mc_es;
        __register_t    mc_ds;
        __register_t    mc_edi;
        __register_t    mc_esi;
        __register_t    mc_ebp;
        __register_t    mc_isp;
        __register_t    mc_ebx;
        __register_t    mc_edx;
        __register_t    mc_ecx;
        __register_t    mc_eax;
        __register_t    mc_trapno;
        __register_t    mc_err;
        __register_t    mc_eip;
        __register_t    mc_cs;
        __register_t    mc_eflags;
        __register_t    mc_esp;
        __register_t    mc_ss;

        c_int     	mc_len;                 /* sizeof(mcontext_t) */
        c_int    	mc_fpformat;
        c_int    	mc_ownedfp;
        c_int[1]     mc_spare1;           /* align next field to 16 bytes */
        c_int[128]  mc_fpstate ; // __aligned(16)
        c_int[8]     mc_spare2;
    }

    enum {
        _MC_FPFMT_NODEV        = 0x10000, /* device not present or configured */
        _MC_FPFMT_387           = 0x10001,
        _MC_FPFMT_XMM           = 0x10002,

        _MC_FPOWNED_NONE        = 0x20000, /* FP state not used */
        _MC_FPOWNED_FPU         = 0x20001, /* FP state came from FPU */
        _MC_FPOWNED_PCB         = 0x20002,  /* FP state came from PCB */
    }

    alias uint sigset_t;
    struct ucontext_t { /* from /usr/include/ucontext.h */
        sigset_t 		uc_sigmask;
        mcontext_t		uc_mcontext;
        ucontext_t*		uc_link;
        stack_t		uc_stack;
        c_int			uc_flags;
        c_int[4]		__spare__;
    }
}

version(solaris)
{
    alias uint[4] upad128_t;

    version( X86 )
    {
        const  NGREG = 19;
        alias int greg_t;
        
        /*
        * This definition of the floating point structure is binary
        * compatible with the Intel386 psABI definition, and source
        * compatible with that specification for x87-style floating point.
        * It also allows SSE/SSE2 state to be accessed on machines that
        * possess such hardware capabilities.
        */
        struct fpregset_t {
            union fp_reg_set_ {
                struct fpchip_state_ {
                    uint[27] state;	/* 287/387 saved state */
                    uint status;	/* saved at exception */
                    uint mxcsr;		/* SSE control and status */
                    uint xstatus;	/* SSE mxcsr at exception */
                    uint[2] __pad;	/* align to 128-bits */
                    upad128_t[8] xmm;	/* %xmm0-%xmm7 */
                };
                fpchip_state_ fpchip_state;
                struct fp_emul_space_ {		/* for emulator(s) */
                    ubyte[246]	fp_emul;
                    ubyte[2]	fp_epad;
                };
                fp_emul_space_ fp_emul_space;
                uint[95]	f_fpregs;	/* union of the above */
            };
            fp_reg_set_ fp_reg_set;
        };
    }
    else version( X86_64 )
    {
        const NGREG = 28;
        alias c_long greg_t;

        struct fpregset_t {
            union fp_reg_set_ {
                struct fpchip_state_ {
                    ushort cw;
                    ushort sw;
                    ubyte  fctw;
                    ubyte  __fx_rsvd;
                    ushort fop;
                    ulong rip;
                    ulong rdp;
                    uint mxcsr;
                    uint mxcsr_mask;
                    union st_ {
                        ushort[5] fpr_16;
                        upad128_t __fpr_pad;
                    };
                    st_[8] st;
                    upad128_t[16] xmm;
                    upad128_t[6] __fx_ign2;
                    uint status;	/* sw at exception */
                    uint xstatus;	/* mxcsr at exception */
                } 
                fpchip_state_   fpchip_state;
                uint[130] f_fpregs;
            };
            fp_reg_set_ fp_reg_set;
        };
    }
    
    alias greg_t[NGREG] gregset_t;

    struct mcontext_t
    {
        gregset_t	gregs;		/* general register set */
        fpregset_t	fpregs;		/* floating point register set */
    }

    struct stack_t
    {
        void* ss_sp;
        size_t ss_size;
        int ss_flags;
    }
    
    struct ucontext_t /* from /usr/include/sys/ucontext.h*/
    {
        c_ulong uc_flags;
        ucontext_t *uc_link;
        sigset_t uc_sigmask;
        stack_t uc_stack;
        mcontext_t 	uc_mcontext;
        c_long[5] uc_filler;	/* see ABI spec for Intel386 */
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

/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly, Walter Bright
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.fenv;

extern (C):

version( Win32 )
{
    struct fenv_t
    {
        ushort    status;
        ushort    control;
        ushort    round;
        ushort[2] reserved;
    }

    alias int fexcept_t;
}
else version( linux )
{
    struct fenv_t
    {
        ushort __control_word;
        ushort __unused1;
        ushort __status_word;
        ushort __unused2;
        ushort __tags;
        ushort __unused3;
        uint   __eip;
        ushort __cs_selector;
        ushort __opcode;
        uint   __data_offset;
        ushort __data_selector;
        ushort __unused5;
    }

    alias int fexcept_t;
}
else version ( darwin )
{
    version ( BigEndian )
    {
        alias uint fenv_t;
        alias uint fexcept_t;
    }
    version ( LittleEndian )
    {
        struct fenv_t
        {
            ushort  __control;
            ushort  __status;
            uint    __mxcsr;
            byte[8] __reserved;
        }

        alias ushort fexcept_t;
    }
}
else version ( freebsd )
{
    struct fenv_t
    {
        ushort __control;
        ushort __mxcsr_hi;
        ushort __status;
        ushort __mxcsr_lo;
        uint __tag;
        byte[16] __other;
    }

    alias ushort fexcept_t;
}
else version ( solaris )
{
	private import tango.stdc.config;
	
	struct __fex_handler_struct
	{
		int	__mode;
		void function() handler;
	}
	alias __fex_handler_struct[12] __fex_handler_t;
	
	struct fenv_t
	{
		__fex_handler_t	__handlers;
		c_ulong	__fsr;
	}
	
	alias int fexcept_t;
}
else
{
    static assert( false );
}

enum
{
    FE_INVALID      = 1,
    FE_DENORMAL     = 2, // non-standard
    FE_DIVBYZERO    = 4,
    FE_OVERFLOW     = 8,
    FE_UNDERFLOW    = 0x10,
    FE_INEXACT      = 0x20,
    FE_ALL_EXCEPT   = 0x3F,
    FE_TONEAREST    = 0,
    FE_UPWARD       = 0x800,
    FE_DOWNWARD     = 0x400,
    FE_TOWARDZERO   = 0xC00,
}

version( Win32 )
{
    private extern fenv_t _FE_DFL_ENV;
    __gshared fenv_t* FE_DFL_ENV;
    shared static this()
    {
        FE_DFL_ENV = &_FE_DFL_ENV;
    }
}
else version( linux )
{
    __gshared fenv_t* FE_DFL_ENV = cast(fenv_t*)(-1);
}
else version( darwin )
{
    private extern fenv_t _FE_DFL_ENV;
    __gshared fenv_t* FE_DFL_ENV;
    shared static this()
    {
        FE_DFL_ENV = &_FE_DFL_ENV;
    }
}
else version( freebsd )
{
    private extern fenv_t __fe_dfl_env;
    __gshared fenv_t* FE_DFL_ENV;
    shared static this()
    {
        FE_DFL_ENV = &__fe_dfl_env;
    }
}
else version( solaris )
{
    private extern fenv_t __fenv_dfl_env;
    __gshared fenv_t* FE_DFL_ENV;
    shared static this()
    {
        FE_DFL_ENV = &__fe_dfl_env;
    }
}
else
{
    static assert( false );
}

void feraiseexcept(int excepts);
void feclearexcept(int excepts);

int fetestexcept(int excepts);
int feholdexcept(fenv_t* envp);

void fegetexceptflag(fexcept_t* flagp, int excepts);
void fesetexceptflag(in fexcept_t* flagp, int excepts);

int fegetround();
int fesetround(int round);

void fegetenv(fenv_t* envp);
void fesetenv(in fenv_t* envp);
void feupdateenv(in fenv_t* envp);

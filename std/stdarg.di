/**
 * These functions are built-in intrinsics to the compiler.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   David Friedman
 */
module std.stdarg;

version( GNU )
{
    // va_list might be a pointer, but assuming so is not portable.
    private import gcc.builtins;
    alias __builtin_va_list va_list;

    // va_arg is handled magically by the compiler
}
else
{
    alias void* va_list;
}

template va_arg(T)
{
    T va_arg( inout va_list _argptr )
    {
        /*
        T arg = *cast(T*)_argptr;
        _argptr = _argptr + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1));
        return arg;
        */
        T t; return t;
    }
}

private import std.c.stdarg;
/* The existence of std.stdarg.va_copy isn't standard.  Prevent
   conflicts by using '__'. */
alias std.c.stdarg.va_copy __va_copy;

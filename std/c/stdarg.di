/**
 * These functions are built-in intrinsics to the compiler.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   David Friedman
 */
module std.c.stdarg;

version( GNU )
{
    private import gcc.builtins;
    alias __builtin_va_list va_list;
    alias __builtin_va_end  va_end;
    alias __builtin_va_copy va_copy;
}
else
{
    alias void* va_list;

    void va_end(va_list ap)
    {

    }

    void va_copy( out va_list dest, va_list src )
    {
        static if ( is( dest T == T[1]) )
        {
            dest[0] = src[0];
        }
        else
        {
            dest = src;
        }
    }

}

template va_start(T)
{
    void va_start( out va_list ap, inout T parmn )
    {
        /*
        ap = cast(va_list)(cast(void*)&parmn + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1)));
        */
    }
}

template va_arg(T)
{
    T va_arg( inout va_list ap )
    {
        /*
        T arg = *cast(T*)ap;
        ap = cast(va_list)(cast(void*)ap + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1)));
        return arg;
        */
        T t;
        return t;
    }
}

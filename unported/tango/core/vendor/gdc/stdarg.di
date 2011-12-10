/**
 * These functions are built-in intrinsics to the compiler.
 *
 * Note that this module is only present in Tango because the module name is
 * hardcoded into GDC, see http://d.puremagic.com/issues/show_bug.cgi?id=1949 
 * To correctly use this functionality in Tango, import tango.core.Vararg.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   David Friedman
 */
module std.stdarg;

version( GNU )
{
    private import gcc.builtins;
    alias __builtin_va_list va_list;
    alias __builtin_va_end  va_end;
    alias __builtin_va_copy va_copy;
}

template va_start(T)
{
    void va_start( out va_list ap, ref T parmn )
    {

    }
}

template va_arg(T)
{
    T va_arg( ref va_list ap )
    {
        return T.init;
    }
}

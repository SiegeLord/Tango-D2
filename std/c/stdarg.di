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
    template va_start( T )
    {
        void va_start( out va_list ap, inout T parmn )
        {

        }
    }

    template va_arg( T )
    {
        T va_arg( inout va_list ap )
        {
    	    return T.init;
        }
    }
}

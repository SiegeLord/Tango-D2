/**
 * The vararg module is intended to facilitate vararg manipulation in D.
 * It should be interface compatible with the C module "stdarg," and the
 * two modules may share a common implementation if possible (as is done
 * here).
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Hauke Duden, Walter Bright
 */
module tango.core.Vararg;

public import core.vararg;

/+
/**

  Gdc 


**/


version( GNU )
{
    // GDC doesn't need va_start/va_end
    // If the va_arg template version is used,  

    public import std.stdarg;

    version( X86_64 )
    {
        alias va_list __va_argsave_t;
         //__va_argsave_t __va_argsave;
    }

    // va_start and va_end is not needed for gdc, stubs only exist for eased
    // cross-compiler programming
    void va_start(T)( va_list ap, T parmn)   {   }
    void va_end(va_list ap)    {    }
}
else version( LDC )
{
    public import ldc.vararg;
}
else
{
    version (DigitalMars) version (X86_64) version = DigitalMarsX64;
    version (X86)
    {
        alias void* va_list;

        template va_arg(T)
        {
            T va_arg(ref va_list _argptr)
            {
                T arg = *cast(T*)_argptr;
                _argptr = _argptr + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1));
                return arg;
            }
        }
    }
    else
    {
        public import tango.stdc.stdarg;
    }
}
+/

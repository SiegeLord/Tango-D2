######################################################
# defines the object to compile in ALL_OBJS
######################################################

OBJ_BASE= \
    rt/aaA.obj \
    rt/aApply.obj \
    rt/aApplyR.obj \
    rt/adi.obj \
    rt/arraybyte.obj \
    rt/arraycast.obj \
    rt/arraycat.obj \
    rt/arraydouble.obj \
    rt/arrayfloat.obj \
    rt/arrayint.obj \
    rt/arrayreal.obj \
    rt/arrayshort.obj \
    rt/cast_.obj \
    rt/complex.obj \
    rt/cover.obj \
    rt/critical.obj \
    rt/dmain2.obj \
    invariant.obj \
    rt/invariant_.obj \
    rt/lifetime.obj \
    rt/memory.obj \
    rt/memset.obj \
    rt/monitor.obj \
    rt/obj.obj \
    object_.obj \
    rt/qsort.obj \
    rt/switch_.obj \
    rt/trace.obj

OBJ_POSIX=rt/alloca.obj \
    rt/cmath2.obj \
    rt/gcosx.obj \
    rt/deh2.obj \
    rt/llmath.obj

OBJ_WIN=\
    rt/deh.obj
    
# NOTE: trace.obj and cover.obj are not necessary for a successful build
#       as both are used for debugging features (profiling and coverage)
# NOTE: a pre-compiled minit.obj has been provided in dmd for Win32 and
#       minit.asm is not used by dmd for linux
# NOTE: deh.obj is only needed for Win32, linux uses deh2.obj

OBJ_UTIL= \
    rt/util/console.obj \
    rt/util/cpuid.obj \
    rt/util/ctype.obj \
    rt/util/string.obj \
    rt/util/utf.obj

OBJ_TI= \
    rt/typeinfo/ti_AC.obj \
    rt/typeinfo/ti_Acdouble.obj \
    rt/typeinfo/ti_Acfloat.obj \
    rt/typeinfo/ti_Acreal.obj \
    rt/typeinfo/ti_Adouble.obj \
    rt/typeinfo/ti_Afloat.obj \
    rt/typeinfo/ti_Ag.obj \
    rt/typeinfo/ti_Aint.obj \
    rt/typeinfo/ti_Along.obj \
    rt/typeinfo/ti_Areal.obj \
    rt/typeinfo/ti_Ashort.obj \
    rt/typeinfo/ti_byte.obj \
    rt/typeinfo/ti_C.obj \
    rt/typeinfo/ti_cdouble.obj \
    rt/typeinfo/ti_cfloat.obj \
    rt/typeinfo/ti_char.obj \
    rt/typeinfo/ti_creal.obj \
    rt/typeinfo/ti_dchar.obj \
    rt/typeinfo/ti_delegate.obj \
    rt/typeinfo/ti_double.obj \
    rt/typeinfo/ti_float.obj \
    rt/typeinfo/ti_idouble.obj \
    rt/typeinfo/ti_ifloat.obj \
    rt/typeinfo/ti_int.obj \
    rt/typeinfo/ti_ireal.obj \
    rt/typeinfo/ti_long.obj \
    rt/typeinfo/ti_ptr.obj \
    rt/typeinfo/ti_real.obj \
    rt/typeinfo/ti_short.obj \
    rt/typeinfo/ti_ubyte.obj \
    rt/typeinfo/ti_uint.obj \
    rt/typeinfo/ti_ulong.obj \
    rt/typeinfo/ti_ushort.obj \
    rt/typeinfo/ti_void.obj \
    rt/typeinfo/ti_wchar.obj

ALL_OBJS= \
    $(OBJ_BASE) \
    $(OBJ_UTIL) \
    $(OBJ_TI)

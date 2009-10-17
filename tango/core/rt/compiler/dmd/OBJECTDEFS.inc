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
    complex.obj \
    rt/cover.obj \
    critical.obj \
    rt/cInterface.obj \
    rt/dmain2.obj \
    invariant.obj \
    rt/invariant_.obj \
    rt/lifetime.obj \
    rt/memory.obj \
    rt/memset.obj \
    monitor.obj \
    rt/obj.obj \
    object_.obj \
    rt/qsort.obj \
    rt/switch_.obj \
    rt/trace.obj

OBJ_POSIX=rt/alloca.obj \
    cConst.obj \
    rt/cmath2.obj \
    gcosx.obj \
    rt/deh2.obj \
    rt/llmath.obj

OBJ_WIN=\
    deh.obj
    
# NOTE: trace.obj and cover.obj are not necessary for a successful build
#       as both are used for debugging features (profiling and coverage)
# NOTE: a pre-compiled minit.obj has been provided in dmd for Win32 and
#       minit.asm is not used by dmd for linux
# NOTE: deh.obj is only needed for Win32, linux uses deh2.obj

OBJ_UTIL= \
    rt/util/cpuid.obj \
    ../shared/rt/util/console.obj \
    ../shared/rt/util/ctype.obj \
    ../shared/rt/util/string.obj \
    ../shared/rt/util/utf.obj \
    ../shared/rt/util/hash.obj

OBJ_TI= \
    ../shared/rt/typeinfo/ti_AC.obj \
    ../shared/rt/typeinfo/ti_Acdouble.obj \
    ../shared/rt/typeinfo/ti_Acfloat.obj \
    ../shared/rt/typeinfo/ti_Acreal.obj \
    ../shared/rt/typeinfo/ti_Adouble.obj \
    ../shared/rt/typeinfo/ti_Afloat.obj \
    ../shared/rt/typeinfo/ti_Ag.obj \
    ../shared/rt/typeinfo/ti_Aint.obj \
    ../shared/rt/typeinfo/ti_Along.obj \
    ../shared/rt/typeinfo/ti_Areal.obj \
    ../shared/rt/typeinfo/ti_Ashort.obj \
    ../shared/rt/typeinfo/ti_byte.obj \
    ../shared/rt/typeinfo/ti_C.obj \
    ../shared/rt/typeinfo/ti_cdouble.obj \
    ../shared/rt/typeinfo/ti_cfloat.obj \
    ../shared/rt/typeinfo/ti_char.obj \
    ../shared/rt/typeinfo/ti_creal.obj \
    ../shared/rt/typeinfo/ti_dchar.obj \
    ../shared/rt/typeinfo/ti_delegate.obj \
    ../shared/rt/typeinfo/ti_double.obj \
    ../shared/rt/typeinfo/ti_float.obj \
    ../shared/rt/typeinfo/ti_idouble.obj \
    ../shared/rt/typeinfo/ti_ifloat.obj \
    ../shared/rt/typeinfo/ti_int.obj \
    ../shared/rt/typeinfo/ti_ireal.obj \
    ../shared/rt/typeinfo/ti_long.obj \
    ../shared/rt/typeinfo/ti_ptr.obj \
    ../shared/rt/typeinfo/ti_real.obj \
    ../shared/rt/typeinfo/ti_short.obj \
    ../shared/rt/typeinfo/ti_ubyte.obj \
    ../shared/rt/typeinfo/ti_uint.obj \
    ../shared/rt/typeinfo/ti_ulong.obj \
    ../shared/rt/typeinfo/ti_ushort.obj \
    ../shared/rt/typeinfo/ti_void.obj \
    ../shared/rt/typeinfo/ti_wchar.obj

ALL_OBJS= \
    $(OBJ_BASE) \
    $(OBJ_UTIL) \
    $(OBJ_TI)

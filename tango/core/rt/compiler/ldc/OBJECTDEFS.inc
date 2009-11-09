######################################################
# defines the object to compile in ALL_OBJS
######################################################

OBJ_C= \
    critical.obj \
    monitor.obj \
    cConst.obj

OBJ_BASE= \
    ldc/bitmanip.bc \
    ldc/vararg.bc \
    rt/aaA.bc \
    rt/aApply.bc \
    rt/aApplyR.bc \
    rt/adi.bc \
    rt/arrayInit.bc \
    rt/cast_.bc \
    rt/cInterface.bc \
    rt/dmain2.bc \
    rt/eh.bc \
    object_.bc\
    rt/invariant_.bc \
    rt/lifetime.bc \
    rt/memory.bc \
    rt/qsort2.bc \
    rt/switch_.bc


OBJ_POSIX=

OBJ_WIN=
    
OBJ_UTIL= \
    ../shared/rt/util/console.bc \
    ../shared/rt/util/ctype.bc \
    ../shared/rt/util/string.bc \
    ../shared/rt/util/utf.bc \
    ../shared/rt/util/hash.bc

OBJ_TI= \
    ../shared/rt/typeinfo/ti_AC.bc \
    ../shared/rt/typeinfo/ti_Acdouble.bc \
    ../shared/rt/typeinfo/ti_Acfloat.bc \
    ../shared/rt/typeinfo/ti_Acreal.bc \
    ../shared/rt/typeinfo/ti_Adouble.bc \
    ../shared/rt/typeinfo/ti_Afloat.bc \
    ../shared/rt/typeinfo/ti_Ag.bc \
    ../shared/rt/typeinfo/ti_Aint.bc \
    ../shared/rt/typeinfo/ti_Along.bc \
    ../shared/rt/typeinfo/ti_Areal.bc \
    ../shared/rt/typeinfo/ti_Ashort.bc \
    ../shared/rt/typeinfo/ti_byte.bc \
    ../shared/rt/typeinfo/ti_C.bc \
    ../shared/rt/typeinfo/ti_cdouble.bc \
    ../shared/rt/typeinfo/ti_cfloat.bc \
    ../shared/rt/typeinfo/ti_char.bc \
    ../shared/rt/typeinfo/ti_creal.bc \
    ../shared/rt/typeinfo/ti_dchar.bc \
    ../shared/rt/typeinfo/ti_delegate.bc \
    ../shared/rt/typeinfo/ti_double.bc \
    ../shared/rt/typeinfo/ti_float.bc \
    ../shared/rt/typeinfo/ti_idouble.bc \
    ../shared/rt/typeinfo/ti_ifloat.bc \
    ../shared/rt/typeinfo/ti_int.bc \
    ../shared/rt/typeinfo/ti_ireal.bc \
    ../shared/rt/typeinfo/ti_long.bc \
    ../shared/rt/typeinfo/ti_ptr.bc \
    ../shared/rt/typeinfo/ti_real.bc \
    ../shared/rt/typeinfo/ti_short.bc \
    ../shared/rt/typeinfo/ti_ubyte.bc \
    ../shared/rt/typeinfo/ti_uint.bc \
    ../shared/rt/typeinfo/ti_ulong.bc \
    ../shared/rt/typeinfo/ti_ushort.bc \
    ../shared/rt/typeinfo/ti_void.bc \
    ../shared/rt/typeinfo/ti_wchar.bc

ALL_OBJS_BC= \
    $(OBJ_BASE) \
    $(OBJ_UTIL) \
    $(OBJ_TI)

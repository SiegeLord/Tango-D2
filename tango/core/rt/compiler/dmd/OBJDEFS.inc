COMPILER_MODULES_S= \
 rt.compiler.dmd.typeinfo.ti_void \
 rt.compiler.dmd.typeinfo.ti_wchar \
 rt.compiler.dmd.typeinfo.ti_ptr \
 rt.compiler.dmd.typeinfo.ti_Afloat \
 rt.compiler.dmd.typeinfo.ti_double \
 rt.compiler.dmd.typeinfo.ti_delegate \
 rt.compiler.dmd.typeinfo.ti_Adouble \
 rt.compiler.dmd.typeinfo.ti_char \
 rt.compiler.dmd.typeinfo.ti_Acdouble \
 rt.compiler.dmd.typeinfo.ti_uint \
 rt.compiler.dmd.typeinfo.ti_AC \
 rt.compiler.dmd.typeinfo.ti_ulong \
 rt.compiler.dmd.typeinfo.ti_creal \
 rt.compiler.dmd.typeinfo.ti_ubyte \
 rt.compiler.dmd.typeinfo.ti_Aint \
 rt.compiler.dmd.typeinfo.ti_ireal \
 rt.compiler.dmd.typeinfo.ti_short \
 rt.compiler.dmd.typeinfo.ti_long \
 rt.compiler.dmd.typeinfo.ti_Along \
 rt.compiler.dmd.typeinfo.ti_byte \
 rt.compiler.dmd.typeinfo.ti_float \
 rt.compiler.dmd.typeinfo.ti_cfloat \
 rt.compiler.dmd.typeinfo.ti_Acfloat \
 rt.compiler.dmd.typeinfo.ti_cdouble \
 rt.compiler.dmd.typeinfo.ti_ifloat \
 rt.compiler.dmd.typeinfo.ti_dchar \
 rt.compiler.dmd.typeinfo.ti_C \
 rt.compiler.dmd.typeinfo.ti_real \
 rt.compiler.dmd.typeinfo.ti_idouble \
 rt.compiler.dmd.typeinfo.ti_Areal \
 rt.compiler.dmd.typeinfo.ti_ushort \
 rt.compiler.dmd.typeinfo.ti_Acreal \
 rt.compiler.dmd.typeinfo.ti_Ag \
 rt.compiler.dmd.typeinfo.ti_int \
 rt.compiler.dmd.typeinfo.ti_Ashort \
 rt.compiler.util.utf \
 rt.compiler.util.console \
 rt.compiler.util.hash \
 rt.compiler.util.ctype \
 rt.compiler.util.string \

#end
COMPILER_OO_S=


COMPILER_MODULES_L= \
    object_ \
    rt.compiler.dmd.rt.aaA \
    rt.compiler.dmd.rt.aApply \
    rt.compiler.dmd.rt.aApplyR \
    rt.compiler.dmd.rt.adi \
    rt.compiler.dmd.rt.arraybyte \
    rt.compiler.dmd.rt.arraycast \
    rt.compiler.dmd.rt.arraycat \
    rt.compiler.dmd.rt.arraydouble \
    rt.compiler.dmd.rt.arrayfloat \
    rt.compiler.dmd.rt.arrayint \
    rt.compiler.dmd.rt.arrayreal \
    rt.compiler.dmd.rt.arrayshort \
    rt.compiler.dmd.rt.cast_ \
    rt.compiler.dmd.rt.cover \
    rt.compiler.dmd.rt.dmain2 \
    rt.compiler.dmd.rt.invariant_ \
    rt.compiler.dmd.rt.lifetime \
    rt.compiler.dmd.rt.memory \
    rt.compiler.dmd.rt.memset \
    rt.compiler.dmd.rt.qsort \
    rt.compiler.dmd.rt.switch_ \
    rt.compiler.dmd.rt.trace \
    invariant \

invariant.d : $(TANGO_RUNTIME)/rt/compiler/$(DC_SHORT)/invariant.d
	echo "#line 1 \"$<\"" > $@
	cat $< >> $@

COMPILER_MODULES_POSIX =\
    rt.compiler.dmd.rt.deh2 \
    rt.compiler.dmd.rt.llmath \
    rt.compiler.dmd.rt.cmath2 \
    rt.compiler.dmd.rt.alloca \

COMPILER_OO_L= \
    complex.$(COBJ_EXT) \
    critical.$(COBJ_EXT) \
    monitor.$(COBJ_EXT) \

COMPILER_OO_POSIX = \
    gcosx.$(COBJ_EXT) \
    cConst.$(COBJ_EXT) \
    ThreadASM.$(COBJ_EXT) \

COMPILER_OO_WIN =\
    deh.$(COBJ_EXT) \
    minit.$(COBJ_EXT)

#COMPILER_DI_L= \
# tango/core/internal/runtimeInterface.di \
# std/intrinsic.di

COMPILER_MODULES=$(COMPILER_MODULES_L) $(COMPILER_MODULES_S)
COMPILER_OO=$(COMPILER_OO_L) $(COMPILER_OO_S)
COMPILER_DI=$(COMPILER_DI_L) $(COMPILER_DI_S)

EXCLUDE_DEP_COMP=object

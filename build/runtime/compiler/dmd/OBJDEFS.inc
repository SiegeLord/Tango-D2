COMPILER_MODULES_L= \
    object \
    rt.aaA \
    rt.aApply \
    rt.aApplyR \
    rt.adi \
    rt.arraybyte \
    rt.arraycast \
    rt.arraycat \
    rt.arraydouble \
    rt.arrayfloat \
    rt.arrayint \
    rt.arrayreal \
    rt.arrayshort \
    rt.cast_ \
    rt.cover \
    rt.cImports \
    rt.dmain2 \
    rt.invariant_ \
    rt.lifetime \
    rt.memory \
    rt.memset \
    rt.qsort \
    rt.switch_ \
    rt.util.cpuid \
    rt.trace \
    tango.core.internal.runtimeInterface \
    invariant \

COMPILER_MODULES_POSIX =\
    rt.deh2 \
    rt.llmath \
    rt.cmath2 \
    rt.alloca \

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

COMPILER_DI_L= \
 tango/core/internal/runtimeInterface.di \
 std/intrinsic.di

COMPILER_MODULES=$(COMPILER_MODULES_L) $(COMPILER_MODULES_S)
COMPILER_OO=$(COMPILER_OO_L) $(COMPILER_OO_S)
COMPILER_DI=$(COMPILER_DI_L) $(COMPILER_DI_S)

EXCLUDE_DEP_COMP=object

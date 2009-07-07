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
    rt.cInterface \
    rt.dmain2 \
    rt.invariant_ \
    rt.lifetime \
    rt.memory \
    rt.memset \
    rt.qsort \
    rt.switch_ \
    rt.trace \
    rt.alloca \
    rt.cmath2 \
    rt.deh2 \
    invariant \
    rt.llmath

COMPILER_OO_L= \
    complex.o \
    critical.o \
    cConst.o \
    gcosx.o \
    monitor.o \

COMPILER_DI_L= \
 rt/cInterface.di \
 std/intrinsic.di

COMPILER_MODULES=$(COMPILER_MODULES_L) $(COMPILER_MODULES_S)
COMPILER_OO=$(COMPILER_OO_L) $(COMPILER_OO_S)
COMPILER_DI=$(COMPILER_DI_L) $(COMPILER_DI_S)

EXCLUDE_DEP_COMP=object

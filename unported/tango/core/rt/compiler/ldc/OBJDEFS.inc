COMPILER_MODULES_L= \
 ldc.vararg \
 ldc.bitmanip \
 rt.adi \
 rt.lifetime \
 rt.switch_ \
 rt.arrayInit \
 rt.memory \
 rt.aApplyR \
 rt.aaA \
 rt.aApply \
 rt.cast_ \
 rt.invariant_ \
 rt.qsort2 \
 rt.eh \
 rt.dmain2 \
 rt.cInterface \
 object \

#end
COMPILER_OO_L= \
    critical.o \
    monitor.o \
    cConst.o

COMPILER_DI_L= \
 rt/cInterface.di  \
 ldc/bitmanip.di   \
 ldc/cstdarg.di    \
 ldc/intrinsics.di \
 ldc/llvmasm.di    \
 ldc/vararg.di

COMPILER_MODULES=$(COMPILER_MODULES_L) $(COMPILER_MODULES_S)
COMPILER_OO=$(COMPILER_OO_L) $(COMPILER_OO_S)
COMPILER_DI=$(COMPILER_DI_L) $(COMPILER_DI_S)

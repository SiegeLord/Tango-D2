#COMPILER_MODULES_POSIX =\
#    rt.deh2 \
#    rt.llmath \
#    rt.cmath2 \
#    rt.alloca \

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

COMPILER_MODULES=$(COMPILER_OO)
COMPILER_OO=$(COMPILER_OO_L) $(COMPILER_OO_POSIX)

EXCLUDE_DEP_COMP=object

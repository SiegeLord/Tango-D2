TI = ti_AC.o ti_Ag.o ti_Aint.o ti_Along.o ti_Ashort.o \
    ti_C.o \
    ti_byte.o ti_cdouble.o ti_cfloat.o ti_char.o ti_creal.o \
    ti_dchar.o ti_delegate.o ti_double.o ti_float.o ti_idouble.o ti_ifloat.o \
    ti_int.o  ti_ireal.o ti_long.o ti_ptr.o ti_real.o ti_short.o ti_ubyte.o \
    ti_uint.o ti_ulong.o ti_ushort.o ti_wchar.o \
    ti_Afloat.o ti_Adouble.o ti_Areal.o \
    ti_Acfloat.o ti_Acdouble.o ti_Acreal.o \
    ti_void.o

OBJ_BASE = \
    aaA.o \
    aApply.o \
    aApplyR.o \
    adi.o \
    arraycast.o \
    arraycat.o \
    cast.o \
    cmain.o \
    critical.o \
    dgccmain2.o \
    genobj.o \
    invariant.o \
    lifetime.o \
    memory.o \
    memset.o \
    monitor.o \
    obj.o \
    qsortg.o \
    rundmain.o \
    switch.o \

OBJ_UTIL = \
    shared/rt/util/console.o \
    shared/rt/util/ctype.o \
    shared/rt/util/string.o \
    shared/rt/util/utf.o \
    shared/rt/util/hash.o


COMPILER_MODULES=
COMPILER_OO=$(TI:%=$(TANGO_HOME)/lib/compiler/shared/rt/typeinfo/%) $(OBJ_BASE:%=$(TANGO_HOME)/lib/compiler/gdc/%) $(OBJ_UTIL:%=$(TANGO_HOME)/lib/compiler/%)

COMPILER_DI=

EXCLUDE_DEP_COMP=object

#ADD_DFLAGS=-q,-nostdinc -I`pwd`/common -I`pwd`/.. -I`pwd`/compiler/gdc
_genDeps:
	cp $(TANGO_HOME)/object.di $(TANGO_HOME)/lib/compiler/gdc/object.di
	cd $(TANGO_HOME)/lib/compiler/gdc; ./configure || exit 1
	$(MAKE) -C $(TANGO_HOME)/lib/compiler/gdc CC=$(CC) DC=$(DC) \
          ADD_DFLAGS="" ADD_CFLAGS="" \
          DFLAGS="$(DFLAGS_ALL)" CFLAGS="$(CFLAGS_ALL)" clean
	$(MAKE) -C $(TANGO_HOME)/lib/compiler/gdc CC=$(CC) DC=$(DC) \
          ADD_DFLAGS="" ADD_CFLAGS="" \
          DFLAGS="$(DFLAGS_ALL)" CFLAGS="$(CFLAGS_ALL)"
	$(RM) compiler/gdc/config/*.o compiler/gdc/gcc/configunix.o compiler/gdc/minimal.o

clean:clean-gdc

.PHONY: clean-gdc

clean-gdc:
	$(MAKE) -C $(TANGO_HOME)/lib/compiler/gdc clean clean


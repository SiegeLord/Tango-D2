# Makefile to build D runtime library libdmdrt.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build libdmdrt.a
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=cp -f
RM=rm -f
MD=mkdir -p

#CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

DFLAGS=-release -O -inline -version=Posix
#DFLAGS=-release -O -inline -version=Posix -I../ares
#DFLAGS=-g -release -version=Posix -I../ares

TFLAGS=-O -inline -version=Posix
#TFLAGS=-O -inline -version=Posix -I../ares
#TFLAGS=-g -version=Posix -I../ares

DOCFLAGS=-version=DDoc -version=Posix
#DOCFLAGS=-version=DDoc -version=Posix -I../ares

CC=gcc
LC=$(AR)
DC=dmd

DMDRT_DEST=../..
INC_DEST=$(DMDRT_DEST)/include/dmdrt
LIB_DEST=$(DMDRT_DEST)/lib
DOC_DEST=$(DMDRT_DEST)/doc/dmdrt

.SUFFIXES: .asm .c .cpp .d .html .o

.asm.o:
	$(CC) -c $<

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmdrt.ddoc $<

targets : lib doc
all     : lib doc
dmdrt   : lib
lib     : libdmdrt.a
doc     : dmdrt.doc

######################################################

OBJ_BASE= \
    aaA.o \
    aApply.o \
    adi.o \
    alloca.o \
    arraycast.o \
    arraycat.o \
    cast.o \
    complex.o \
    critical.o \
    deh2.o \
    dmain2.o \
    invariant.o \
    llmath.o \
    memory.o \
    memset.o \
    monitor.o \
    obj.o \
    object.o \
    qsort.o \
    switch.o \
    moduleinit.o \
    trace.o
# NOTE: trace.o is not necessary for a successful build
# NOTE: a pre-compiled minit.obj has been provided in dmd
#       but is only needed for Win32
#   minit.obj
# NOTE: deh.o is only needed for Win32, instead, deh2.o
#	is used

OBJ_UTIL= \
    util/ctype.o \
    util/string.o \
    util/utf.o

OBJ_TI= \
    typeinfo/ti_Aa.o \
    typeinfo/ti_AC.o \
    typeinfo/ti_Acdouble.o \
    typeinfo/ti_Acfloat.o \
    typeinfo/ti_Acreal.o \
    typeinfo/ti_Adchar.o \
    typeinfo/ti_Adouble.o \
    typeinfo/ti_Afloat.o \
    typeinfo/ti_Ag.o \
    typeinfo/ti_Aint.o \
    typeinfo/ti_Along.o \
    typeinfo/ti_Areal.o \
    typeinfo/ti_Ashort.o \
    typeinfo/ti_Aubyte.o \
    typeinfo/ti_Auint.o \
    typeinfo/ti_Aulong.o \
    typeinfo/ti_Aushort.o \
    typeinfo/ti_Awchar.o \
    typeinfo/ti_byte.o \
    typeinfo/ti_C.o \
    typeinfo/ti_cdouble.o \
    typeinfo/ti_cfloat.o \
    typeinfo/ti_char.o \
    typeinfo/ti_creal.o \
    typeinfo/ti_dchar.o \
    typeinfo/ti_Delegate.o \
    typeinfo/ti_double.o \
    typeinfo/ti_float.o \
    typeinfo/ti_idouble.o \
    typeinfo/ti_ifloat.o \
    typeinfo/ti_int.o \
    typeinfo/ti_ireal.o \
    typeinfo/ti_long.o \
    typeinfo/ti_ptr.o \
    typeinfo/ti_real.o \
    typeinfo/ti_short.o \
    typeinfo/ti_ubyte.o \
    typeinfo/ti_uint.o \
    typeinfo/ti_ulong.o \
    typeinfo/ti_ushort.o \
    typeinfo/ti_void.o \
    typeinfo/ti_wchar.o

ALL_OBJS= \
    $(OBJ_BASE) \
    $(OBJ_UTIL) \
    $(OBJ_TI)

######################################################

ALL_DOCS=

######################################################

libdmdrt.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

dmdrt.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) libdmdrt*.a
	$(RM) $(ALL_DOCS)

install :
	$(MD) $(LIB_DEST)
	$(CP) libdmdrt*.a $(LIB_DEST)/.

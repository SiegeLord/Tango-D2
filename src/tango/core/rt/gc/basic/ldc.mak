# Makefile to build the garbage collector D library for LDC
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build the garbage collector library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

LIB_BUILD=
LIB_TARGET_BC=libtango-gc-basic-bc$(LIB_BUILD).a
LIB_TARGET_NATIVE=libtango-gc-basic$(LIB_BUILD).a
LIB_TARGET_SHARED=libtango-gc-basic-shared$(LIB_BUILD).so
LIB_MASK=libtango-gc-basic*.*

targets : libs
all     : lib-release lib-debug

LOCAL_CFLAGS=
LOCAL_DFLAGS=-I../../.. -I../../compiler/ldc/ -I../../common
LOCAL_TFLAGS=
MAKEFILE=ldc.mak

include ../../ldcCommonFlags.mak

vpath %d rt/basicgc

LIB_DEST=..

ifeq ($(SHARED),yes)
libs: $(LIB_TARGET_BC) $(LIB_TARGET_SHARED)
else
libs: $(LIB_TARGET_BC) $(LIB_TARGET_NATIVE)
endif

######################################################

ALL_OBJS_BC= \
    gc.bc \
    gcalloc.bc \
    gcbits.bc \
    gcstats.bc \
    gcx.bc

ALL_OBJS_O= \
    gc.o \
    gcalloc.o \
    gcbits.o \
    gcstats.o \
    gcx.o

######################################################

ALL_DOCS=

$(LIB_TARGET_BC) : $(ALL_OBJS_O)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS_BC)


$(LIB_TARGET_NATIVE) : $(ALL_OBJS_O)
	$(RM) $@
	$(CLC) $@ $(ALL_OBJS_O)


$(LIB_TARGET_SHARED) : $(ALL_OBJS_O)
	$(RM) $@
	$(CC) -shared -o $@ $(ALL_OBJS_O)

doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS_BC)
	$(RM) $(ALL_OBJS_O)
	$(RM) $(ALL_DOCS)

clean-all: clean
	$(RM) $(LIB_MASK)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)/.

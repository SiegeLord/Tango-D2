# Makefile to build the common D runtime library for LLVM
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build the common library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process
#       make clean-all
#               Delete also the libraries
LIB_BUILD=
LIB_TARGET_FULL=libtango-cc-tango$(LIB_BUILD).a
LIB_TARGET_BC_ONLY=libtango-cc-tango-bc-only$(LIB_BUILD).a
LIB_TARGET_C_ONLY=libtango-cc-tango-c-only$(LIB_BUILD).a
LIB_TARGET_SHARED=libtango-cc-tango-shared$(LIB_BUILD).so
LIB_MASK=libtango-cc-tango*.*
target: libs
all: lib-release lib-debug

LOCAL_CFLAGS=
LOCAL_DFLAGS=-I../../..
LOCAL_TFLAGS=
MAKEFILE=ldc.mak

include ../../ldcCommonFlags.mak

INC_DEST=../../../tango
LIB_DEST=..
DOC_DEST=../../../doc/tango


######################################################

OBJ_CORE_BC= \
    core/BitManip.bc \
    core/Exception.bc \
    core/Memory.bc \
    core/Runtime.bc \
    core/Thread.bc
#    core/ThreadASM.o

OBJ_CORE_O= \
    core/BitManip.o \
    core/Exception.o \
    core/Memory.o \
    core/Runtime.o \
    core/Thread.o

OBJ_STDC= \
    stdc/wrap.o
#    stdc/wrap.bc

OBJ_STDC_POSIX= \
    stdc/posix/pthread_darwin.o

ALL_OBJS_BC= \
    $(OBJ_CORE_BC)
#    $(OBJ_STDC)
#    $(OBJ_STDC_POSIX)

ALL_OBJS_O= \
    $(OBJ_CORE_O) \
    $(OBJ_STDC) 
#    $(OBJ_STDC_POSIX)

######################################################

DOC_CORE= \
    core/BitManip.html \
    core/Exception.html \
    core/Memory.html \
    core/Runtime.html \
    core/Thread.html


ALL_DOCS=


######################################################

ifeq ($(SHARED),yes)
libs     : $(LIB_TARGET_SHARED)
else
libs     : $(LIB_TARGET_C_ONLY) $(LIB_TARGET_BC_ONLY) $(LIB_TARGET_FULL)
endif

$(LIB_TARGET_BC_ONLY) : $(ALL_OBJS_O)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS_BC)


$(LIB_TARGET_FULL) : $(ALL_OBJS_O)
	$(RM) $@
	$(CLC) $@ $(ALL_OBJS_O)


$(LIB_TARGET_C_ONLY) : $(OBJ_STDC)
	$(RM) $@
	$(CLC) $@ $(OBJ_STDC)

$(LIB_TARGET_SHARED) : $(ALL_OBJS_O)
	$(RM) $@
	$(CC) -shared -o $@ $(ALL_OBJS_O)


tango.doc : $(ALL_DOCS)
	echo Documentation generated.

######################################################

### stdc/posix

#stdc/posix/pthread_darwin.o : stdc/posix/pthread_darwin.d
#	$(DC) -c $(DFLAGS) stdc/posix/pthread_darwin.d -of$@

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS_BC)
	$(RM) $(ALL_OBJS_O)
	$(RM) $(ALL_DOCS)

clean-all: clean
	find . -name "$(LIB_MASK)" | xargs $(RM)

install :
	$(MD) $(INC_DEST)
	find . -name "*.di" -exec cp -f {} $(INC_DEST)/{} \;
	$(MD) $(DOC_DEST)
	find . -name "*.html" -exec cp -f {} $(DOC_DEST)/{} \;
	$(MD) $(LIB_DEST)
	find . -name "$(LIB_MASK)" -exec cp -f {} $(LIB_DEST)/{} \;

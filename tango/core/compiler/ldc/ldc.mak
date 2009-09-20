# Makefile to build the compiler runtime D library for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all (lib-release lib-debug and doc)
#	make lib
#		Build the compiler runtime library (which version depends on VERSION, name on LIB_BUILD)
#	make lib-release
#		Build the release version of the compiler runtime library
#	make lib-debug
#		Build the debug version of the compiler runtime library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process
#	make clean-all
#		Delete unneeded files created by build process and the libraries created
#	make unittest
#		Performs the unittests of the runtime library

LIB_BASE=libtango-rt-ldc
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).a
LIB_TARGET_SHARED=$(LIB_BASE)$(LIB_BUILD).so
LIB_BC=$(LIB_BASE)$(LIB_BUILD)-bc.a
LIB_C=$(LIB_BASE)$(LIB_BUILD)-c.a
LIB_MASK=$(LIB_BASE)*.a
# OBJ_DIR is not used... yet
OBJ_DIR=objects$(LIB_BUILD)
SRC_DIR=.

.PHONY : lib lib-release lib-debug unittest all doc clean install clean-all
target: libs
all: lib-release lib-debug doc

LOCAL_CFLAGS=
LOCAL_DFLAGS=-I../shared -I../../.. -I$(SRC_DIR)
LOCAL_TFLAGS=
MAKEFILE=ldc.mak

include ../../ldcCommonFlags.mak

LIB_DEST=..

include OBJECTDEFS.inc

OBJS_C=$(OBJ_C:%.obj=$(SRC_DIR)/%.o)
ALL_OBJECTS=$(ALL_OBJS_BC:%.bc=$(SRC_DIR)/%.o) $(OBJS_C)

######################################################

ALL_DOCS=

######################################################

ifeq ($(SHARED),yes)
libs: $(LIB_TARGET_SHARED) $(LIB_BC) $(LIB_C)
else
libs: $(LIB_TARGET) $(LIB_BC) $(LIB_C)
endif

$(LIB_TARGET) : $(ALL_OBJECTS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJECTS)
ifneq ($(RANLIB),)
	$(RANLIB) $@
endif

$(LIB_TARGET_SHARED) : $(ALL_OBJECTS)
	$(RM) $@
	$(CC) -shared -o $@ $(ALL_OBJECTS)
ifneq ($(RANLIB),)
	$(RANLIB) $@
endif

$(LIB_BC): $(ALL_OBJS_BC)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS_BC)

$(LIB_C): $(OBJS_C)
	$(RM) $@
	$(CLC) $@ $(OBJS_C)

doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	$(RM) $(ALL_OBJECTS) $(ALL_OBJS_BC)

clean-all : clean
	find . -name "*.o" | xargs $(RM)
	find ../shared -name "*.o" | xargs $(RM)
	$(RM) $(LIB_MASK)
	$(RM) $(ALL_DOCS)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)/.

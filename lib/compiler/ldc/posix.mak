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
LIB_BC=$(LIB_BASE)$(LIB_BUILD)-bc.a
LIB_C=$(LIB_BASE)$(LIB_BUILD)-c.a
LIB_MASK=$(LIB_BASE)*.a
# OBJ_DIR is not used... yet
OBJ_DIR=objects$(LIB_BUILD)
SRC_DIR=.

CP=cp -f
RM=rm -f
MD=mkdir -p

CFLAGS_RELEASE=-O $(ADD_CFLAGS)
CFLAGS_DEBUG=-g $(ADD_CFLAGS)
DFLAGS_RELEASE=-release -O -w $(SYSTEM_VERSION) $(ADD_DFLAGS) -output-bc -I=. -I=../shared -I=../../.. -I=$(SRC_DIR)
DFLAGS_DEBUG=-g -w $(SYSTEM_VERSION) $(ADD_DFLAGS) -output-bc -I=. -I=../shared -I=../../.. -I=$(SRC_DIR)
TFLAGS_RELEASE=-O -inline -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS)
TFLAGS_DEBUG=-g -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS)
DOCFLAGS=-version=DDoc $(SYSTEM_VERSION)

ifeq ($(VERSION),debug)
CFLAGS=$(CFLAGS_DEBUG)
DFLAGS=$(DFLAGS_DEBUG)
TFLAGS=$(TFLAGS_DEBUG)
else
CFLAGS=$(CFLAGS_RELEASE)
DFLAGS=$(DFLAGS_RELEASE)
TFLAGS=$(TFLAGS_RELEASE)
endif

CC=gcc
LC=llvm-ar rsv
LLINK=llvm-link
LCC=llc
CLC=ar rsv
DC=ldc
LLC=llvm-as


LIB_DEST=..

all: lib-release lib-debug doc

.SUFFIXES: .s .S .c .cpp .d .html .o
.PHONY : lib lib-release lib-debug unittest all doc clean install clean-all

.s.o:
	$(CC) -c $(CFLAGS) $< -o$@

.S.o:
	$(CC) -c $(CFLAGS) $< -o$@

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.bc:.o

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

include OBJECTDEFS.inc

OBJS_C=$(OBJ_C:%.obj=$(SRC_DIR)/%.o)
ALL_OBJECTS=$(ALL_OBJS_BC:%.bc=$(SRC_DIR)/%.o) $(OBJS_C)

######################################################

ALL_DOCS=

######################################################
unittest :
	make -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -fposix.mak lib DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)" \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS) -unittest -debug=UnitTest" \
		SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-release :
	make -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -fposix.mak DC="$(DC)" LIB_BUILD="" VERSION=release lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-debug :
	make -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -fposix.mak DC="$(DC)" LIB_BUILD="-d" VERSION=debug lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"

######################################################

lib : $(LIB_TARGET) $(LIB_BC) $(LIB_C)

$(LIB_TARGET) : $(ALL_OBJECTS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJECTS)
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
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJECTS) $(ALL_OBJS_BC)

clean-all : clean
	find . -name "*.o" | xargs $(RM)
	find ../shared -name "*.o" | xargs $(RM)
	$(RM) $(LIB_MASK)
	$(RM) $(ALL_DOCS)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)/.

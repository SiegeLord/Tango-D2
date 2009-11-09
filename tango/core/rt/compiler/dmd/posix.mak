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

LIB_BASE=libtango-rt-dmd
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).a
LIB_MASK=$(LIB_BASE)*.a
# OBJ_DIR is not used... yet
OBJ_DIR=objects$(LIB_BUILD)
SRC_DIR=.

CP=cp -f
RM=rm -f
MD=mkdir -p

CFLAGS_RELEASE=-O $(ADD_CFLAGS)
CFLAGS_DEBUG=-g $(ADD_CFLAGS)
DFLAGS_RELEASE=-release -O -inline -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I. -I../shared -I../../.. -I$(SRC_DIR)
DFLAGS_DEBUG=-g -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I. -I../shared -I../../.. -I$(SRC_DIR)
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
LC=$(AR) -qsv
DC=dmd

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

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

include OBJECTDEFS.inc

ALL_OBJECTS=$(ALL_OBJS:%.obj=$(SRC_DIR)/%.o) $(OBJ_POSIX:%.obj=$(SRC_DIR)/%.o)

######################################################

ALL_DOCS=

######################################################
unittest :
	$(MAKE) -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	$(MAKE) -fposix.mak lib DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)" \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS) -unittest -debug=UnitTest" \
		SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-release :
	$(MAKE) -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	$(MAKE) -fposix.mak DC="$(DC)" LIB_BUILD="" VERSION=release lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-debug :
	$(MAKE) -fposix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	$(MAKE) -fposix.mak DC="$(DC)" LIB_BUILD="-d" VERSION=debug lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"

######################################################

lib : $(LIB_TARGET)

$(LIB_TARGET) : $(ALL_OBJECTS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJECTS)
ifneq ($(RANLIB),)
	$(RANLIB) $@
endif

doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | grep -v intrinsic.di | xargs $(RM)
	$(RM) $(ALL_OBJECTS)

clean-all : clean
	find . -name "*.o" | xargs $(RM)
	find ../shared -name "*.o" | xargs $(RM)
	$(RM) $(LIB_MASK)
	$(RM) $(ALL_DOCS)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)/.

# Makefile to build the compiler runtime D library for Win32
# Designed to work with DigitalMars make
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
#	make unittest
#		Performs the unittests of the runtime library

LIB_BASE=tango-rt-dmd
LIB_BUILD=
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).lib
LIB_MASK=$(LIB_BASE)*.lib

CP=xcopy /y
RM=del /f
MD=mkdir

CFLAGS_RELEASE=-mn -6 -r $(ADD_CFLAGS)
CFLAGS_DEBUG=-g -mn -6 -r $(ADD_CFLAGS)
DFLAGS_RELEASE=-release -O -inline -w -nofloat -I. -I..\shared -I..\..\.. $(ADD_DFLAGS)
DFLAGS_DEBUG=-g -w -nofloat  -I. -I..\shared -I..\..\.. $(ADD_DFLAGS)
TFLAGS_RELEASE=-O -inline -w  -nofloat $(ADD_DFLAGS)
TFLAGS_DEBUG=-g -w -nofloat $(ADD_DFLAGS)

CFLAGS=$(CFLAGS_RELEASE)
DFLAGS=$(DFLAGS_RELEASE)
TFLAGS=$(TFLAGS_RELEASE)

DOCFLAGS=-version=DDoc

CC=dmc
LC=lib
DC=dmd

LIB_DEST=..

.DEFAULT: .asm .c .cpp .d .html .obj .o

all: lib doc

.asm.obj:
	$(CC) -c $<

.c.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.d.obj:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

######################################################

include OBJECTDEFS_WIN.inc

ALL_OBJECTS= $(ALL_OBJS) $(OBJ_WIN)
# $(patsubst %.o,%.obj,$(ALL_OBJS)) $(OBJ_WIN)


######################################################

ALL_DOCS=

######################################################

#unittest :
#	$(MAKE) -fwin32.mak DC="$(DC)" LIB_BUILD="" DFLAGS="$(DFLAGS_RELEASE) -unittest -version=Unittest"

#lib-release : clean
#	$(MAKE) -fwin32.mak DC="$(DC)" LIB_BUILD="" DFLAGS="$(DFLAGS_RELEASE)"

#lib-debug : clean
#	$(MAKE) -fwin32.mak DC="$(DC)" LIB_BUILD="-d" DFLAGS="$(DFLAGS_DEBUG)"

######################################################

lib : $(ALL_OBJECTS)
	$(RM) $(LIB_TARGET)
	$(LC) -c -n $(LIB_TARGET) $(ALL_OBJECTS) minit.obj

doc : $(ALL_DOCS)
	@echo No documentation available.

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJECTS)
	$(RM) $(ALL_DOCS)
	$(RM) $(LIB_MASK)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)\.

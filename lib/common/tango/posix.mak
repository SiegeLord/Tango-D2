# Makefile to build the common D runtime library for Linux
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

LIB_BASE=libtango-cc-tango
LIB_BUILD=
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).a
LIB_MASK=$(LIB_BASE)*.a

CP=cp -f
RM=rm -f
MD=mkdir -p

ADD_CFLAGS=
ADD_DFLAGS=
SYSTEM_VERSION=

CFLAGS_RELEASE=-O $(ADD_CFLAGS)
CFLAGS_DEBUG=-g $(ADD_CFLAGS)

DFLAGS_RELEASE=-release -O -inline -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I../../..
DFLAGS_DEBUG=-g -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I../../..
TFLAGS_RELEASE=-O -inline -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS)
TFLAGS_DEBUG=-g -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS)

ifeq ($(VERSION),debug)
CFLAGS=$(CFLAGS_DEBUG)
DFLAGS=$(DFLAGS_DEBUG)
TFLAGS=$(TFLAGS_DEBUG)
else
CFLAGS=$(CFLAGS_RELEASE)
DFLAGS=$(DFLAGS_RELEASE)
TFLAGS=$(TFLAGS_RELEASE)
endif

DOCFLAGS=-version=DDoc $(SYSTEM_VERSION)

CC=gcc
LC=$(AR) -qsv
DC=dmd

INC_DEST=../../../tango
LIB_DEST=..
DOC_DEST=../../../doc/tango

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
	$(DC) -c $(DFLAGS) -Hf$*.di $< -of$@
#	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

all     : lib-release lib-debug doc
tango   : lib-release lib-debug

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

OBJ_CORE= \
    core/BitManip.o \
    core/Exception.o \
    core/Memory.o \
    core/Runtime.o \
    core/Thread.o \
    core/ThreadASM.o

OBJ_STDC= \
    stdc/wrap.o

OBJ_STDC_POSIX= \
    stdc/posix/pthread_darwin.o

ALL_OBJS= \
    $(OBJ_CORE) \
    $(OBJ_STDC) \
    $(OBJ_STDC_POSIX)

######################################################

DOC_CORE= \
    core/BitManip.html \
    core/Exception.html \
    core/Memory.html \
    core/Runtime.html \
    core/Thread.html


ALL_DOCS=

######################################################
lib : $(LIB_TARGET)
$(LIB_TARGET) : $(ALL_OBJS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS)

tango.doc:doc
doc : $(ALL_DOCS)
	echo Documentation generated.

######################################################

### stdc/posix

stdc/posix/pthread_darwin.o : stdc/posix/pthread_darwin.d
	$(DC) -c $(DFLAGS) stdc/posix/pthread_darwin.d -of$@

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)

clean-all: clean
	$(RM) $(ALL_DOCS)
	find . -name "$(LIB_MASK)" | xargs $(RM)

install :
	$(MD) $(INC_DEST)
	find . -name "*.di" -exec cp -f {} $(INC_DEST)/{} \;
	$(MD) $(DOC_DEST)
	find . -name "*.html" -exec cp -f {} $(DOC_DEST)/{} \;
	$(MD) $(LIB_DEST)
	find . -name "$(LIB_MASK)" -exec cp -f {} $(LIB_DEST)/{} \;

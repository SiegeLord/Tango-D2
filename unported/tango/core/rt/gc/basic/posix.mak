# Makefile to build the garbage collector D library for Posix
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

LIB_BASE=libtango-gc-basic
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
DFLAGS_RELEASE=-release -O -inline -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I../../common -I../../..
DFLAGS_DEBUG=-g -w -nofloat $(SYSTEM_VERSION) $(ADD_DFLAGS) -I../../common -I../../..
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

vpath %d rt/basicgc

CC=gcc
LC=$(AR) -qsv
DC=dmd

LIB_DEST=..

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
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

targets : lib doc
all     : lib-release lib-debug doc

######################################################

ALL_OBJS= \
    gc.o \
    gcalloc.o \
    gcbits.o \
    gcstats.o \
    gcx.o

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

$(LIB_TARGET) : $(ALL_OBJS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS)

doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)

clean-all : clean
	$(RM) $(LIB_MASK)

install :
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)/.

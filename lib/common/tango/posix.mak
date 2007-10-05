# Makefile to build D common runtime library for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=cp -f
RM=rm -f
MD=mkdir -p

ADD_CFLAGS=
ADD_DFLAGS=

CFLAGS=-O $(ADD_CFLAGS)
#CFLAGS=-g $(ADD_CFLAGS)

DFLAGS=-release -O -inline -version=Posix $(ADD_DFLAGS)
#DFLAGS=-g -version=Posix $(ADD_DFLAGS)

TFLAGS=-O -inline -version=Posix $(ADD_DFLAGS)
#TFLAGS=-g -version=Posix $(ADD_DFLAGS)

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR) -qsv
DC=dmd

INC_DEST=../../../tango
LIB_DEST=..
DOC_DEST=../../../doc/tango

.SUFFIXES: .s .S .c .cpp .d .html .o

.s.o:
	$(CC) -c $(CFLAGS) $< -o$@

.S.o:
	$(CC) -c $(CFLAGS) $< -o$@

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.d.o:
	$(DC) -c $(DFLAGS) -v1 -Hf$*.di $< -of$@
#	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

targets : lib doc
all     : lib doc
tango   : lib
lib     : tango.lib
doc     : tango.doc

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

tango.lib : libtango.a

libtango.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	echo Documentation generated.

######################################################

### stdc/posix

stdc/posix/pthread_darwin.o : stdc/posix/pthread_darwin.d
	$(DC) -c $(DFLAGS) stdc/posix/pthread_darwin.d -of$@

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	find . -name "libtango*.a" | xargs $(RM)

install :
### HACK: This echo line is to work around a compiler bug.
	echo "static this();" >> core/Thread.di
	$(MD) $(INC_DEST)
	find . -name "*.di" -exec cp -f {} $(INC_DEST)/{} \;
	$(MD) $(DOC_DEST)
	find . -name "*.html" -exec cp -f {} $(DOC_DEST)/{} \;
	$(MD) $(LIB_DEST)
	find . -name "libtango*.a" -exec cp -f {} $(LIB_DEST)/{} \;

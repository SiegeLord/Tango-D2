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

CFLAGS=-O -m32
#CFLAGS=-g -m32

ADDFLAGS=

DFLAGS=-release -O -inline -version=Posix $(ADDFLAGS)
#DFLAGS=-g -version=Posix

TFLAGS=-O -inline -version=Posix $(ADDFLAGS)
#TFLAGS=-g -version=Posix

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR) -rsv
DC=dmd

INC_DEST=../../tango
LIB_DEST=..
DOC_DEST=../../doc/tango

.SUFFIXES: .asm .c .cpp .d .html .o

.asm.o:
	$(CC) -c $<

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

targets : lib doc
all     : lib doc
tango   : lib
lib     : tango.lib
doc     : tango.doc

######################################################

OBJ_CONVERT= \
    convert/dtoa.o

OBJ_CORE= \
    core/Exception.o \
    core/Memory.o \
    core/Thread.o

OBJ_STDC= \
    stdc/wrap.o

ALL_OBJS= \
    $(OBJ_CONVERT) \
    $(OBJ_CORE) \
    $(OBJ_STDC)

######################################################

DOC_CORE= \
    core/Exception.html \
    core/Memory.html \
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

### stdc

stdc/stdio.o : stdc/stdio.d
	$(DC) -c $(DFLAGS) stdc/stdio.d -of$@

stdc/stdlib.o : stdc/stdlib.d
	$(DC) -c $(DFLAGS) stdc/stdlib.d -of$@

### pthread

core/pthread.o : ../../tango/stdc/posix/pthread.d
	$(DC) -c $(DFLAGS) ../../tango/stdc/posix/pthread.d -of$@

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	find . -name "libtango*.a" | xargs $(RM)

install :
	$(MD) $(INC_DEST)
	find . -name "*.di" | cpio -p -u -d $(INC_DEST)
	$(MD) $(DOC_DEST)
	find . -name "*.html" | cpio -p -u -d $(DOC_DEST)
	$(MD) $(LIB_DEST)
	find . -name "libtango*.a" | cpio -p -u -d $(LIB_DEST)

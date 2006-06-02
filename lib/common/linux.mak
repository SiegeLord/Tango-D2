# Makefile to build D runtime library libtango.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build libtango.a
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=cp -f
RM=rm -f
MD=mkdir -p

#CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

DFLAGS=-release -O -inline -version=Posix
#DFLAGS=-release -O -inline -version=Posix -I..
#DFLAGS=-g -release -version=Posix -I..

TFLAGS=-O -inline -version=Posix
#TFLAGS=-O -inline -version=Posix -I..
#TFLAGS=-g -version=Posix -I.

DOCFLAGS=-version=DDoc -version=Posix
#DOCFLAGS=-version=DDoc -version=Posix -I..

CC=gcc
LC=$(AR)
DC=dmd

TANGO_DEST=../..
INC_DEST=$(TANGO_DEST)/tango/core
LIB_DEST=$(TANGO_DEST)/lib
DOC_DEST=$(TANGO_DEST)/doc/tango/core

.SUFFIXES: .asm .c .cpp .d .html .o

.asm.o:
	$(CC) -c $<

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@
#	$(DC) -c $(DFLAGS) -Hf$*.di $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

targets : lib doc
all     : lib doc
tango   : lib
lib     : libtango.a
doc     : tango.doc

######################################################

OBJ_CORE= \
    exception.o \
    memory.o \
    thread.o

ALL_OBJS= \
    $(OBJ_CORE)

######################################################

DOC_CORE= \
    exception.html \
    memory.html \
    thread.html

ALL_DOCS= \
    $(DOC_CORE)

######################################################

libtango.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	echo Documentation generated.

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) libtango*.a

install :
	$(MD) $(INC_DEST)
	$(CP) -r *.di $(INC_DEST)/.
	$(MD) $(DOC_DEST)
	$(CP) -r *.html $(DOC_DEST)/.
	$(MD) $(LIB_DEST)
	$(CP) libtango*.a $(LIB_DEST)/.

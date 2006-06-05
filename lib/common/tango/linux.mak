# Makefile to build D runtime library tango.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build tango.a
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

INC_DEST=../../../tango
LIB_DEST=..
DOC_DEST=../../../doc/tango

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
lib     : tango.a
doc     : tango.doc

######################################################

OBJ_CONVERT= \
    convert/dtoa.o

OBJ_CORE= \
    core/exception.o \
    core/memory.o \
    core/thread.o

ALL_OBJS= \
    $(OBJ_CONVERT) \
    $(OBJ_CORE)

######################################################

DOC_CORE= \
    core/exception.html \
    core/memory.html \
    core/thread.html

ALL_DOCS= \
    $(DOC_CORE)

######################################################

tango.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	echo Documentation generated.

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) tango*.a

install :
	$(MD) $(INC_DEST)
	$(CP) -r *.di $(INC_DEST)/.
	$(MD) $(DOC_DEST)
	$(CP) -r *.html $(DOC_DEST)/.
	$(MD) $(LIB_DEST)
	$(CP) tango*.a $(LIB_DEST)/.

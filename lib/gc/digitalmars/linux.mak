# Makefile to build D runtime library libdmdgc.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build libdmdgc.a
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
#DFLAGS=-release -O -inline -version=Posix -I../ares
#DFLAGS=-g -release -version=Posix -I../ares

TFLAGS=-O -inline -version=Posix
#TFLAGS=-O -inline -version=Posix -I../ares
#TFLAGS=-g -version=Posix -I../ares

DOCFLAGS=-version=DDoc -version=Posix
#DOCFLAGS=-version=DDoc -version=Posix -I../ares

CC=gcc
LC=$(AR)
DC=dmd

DMDGC_DEST=../../..
INC_DEST=$(DMDGC_DEST)/include/dmdgc
LIB_DEST=$(DMDGC_DEST)/lib
DOC_DEST=$(DMDGC_DEST)/doc/dmdgc

.SUFFIXES: .asm .c .cpp .d .html .o

.asm.o:
	$(CC) -c $<

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmdgc.ddoc $<

targets : lib doc
all     : lib doc
dmdgc   : lib
lib     : libdmdgc.a
doc     : dmdgc.doc

######################################################

ALL_OBJS= \
    gc.o \
    gcbits.o \
    gclinux.o \
    gcstats.o \
    gcx.o

######################################################

ALL_DOCS=

######################################################

libdmdgc.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

dmdgc.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) libdmdgc*.a

install :
	$(MD) $(LIB_DEST)
	$(CP) libdmdgc*.a $(LIB_DEST)/.

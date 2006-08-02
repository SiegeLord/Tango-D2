# Makefile to build D garbage collector library for Linux
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

#CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

### warnings disabled because gcx has issues ###

DFLAGS=-release -O -inline -version=Posix
#DFLAGS=-release -O -inline -version=Posix -I..
#DFLAGS=-g -release -version=Posix -I..

TFLAGS=-O -inline -version=Posix
#TFLAGS=-O -inline -version=Posix -I..
#TFLAGS=-g -version=Posix -I..

DOCFLAGS=-version=DDoc -version=Posix
#DOCFLAGS=-version=DDoc -version=Posix -I..

CC=gcc
LC=$(AR) -P -r -s -v
DC=gdc

LIB_DEST=..

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
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html gdc.ddoc $<

targets : lib doc
all     : lib doc
lib     : gdc.lib
doc     : gdc.doc

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

gdc.lib : libgdc.a

libgdc.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS)

gdc.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) libgdc*.a

install :
	$(MD) $(LIB_DEST)
	$(CP) libgdc*.a $(LIB_DEST)/.

# Makefile to build D runtime library gdc.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build gdc.a
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
LC=$(AR)
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
lib     : gdc.a
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

gdc.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

gdc.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) gdc*.a

install :
	$(MD) $(LIB_DEST)
	$(CP) gdc*.a $(LIB_DEST)/.

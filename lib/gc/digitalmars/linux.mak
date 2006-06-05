# Makefile to build D runtime library digitalmars.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build digitalmars.a
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
#DFLAGS=-g -release -version=Posix

TFLAGS=-O -inline -version=Posix
#TFLAGS=-g -version=Posix

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR)
DC=dmd

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
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html digitalmars.ddoc $<

targets : lib doc
all     : lib doc
lib     : digitalmars.a
doc     : digitalmars.doc

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

digitalmars.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) -r $@ $(ALL_OBJS)

digitalmars.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) digitalmars*.a

install :
	$(MD) $(LIB_DEST)
	$(CP) digitalmars*.a $(LIB_DEST)/.

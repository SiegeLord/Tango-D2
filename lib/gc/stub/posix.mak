# Makefile to build D garbage collector library for Posix
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

### warnings disabled because gcx has issues ###

ADDFLAGS=

DFLAGS=-release -O -inline -version=Posix $(ADDFLAGS)
#DFLAGS=-g -version=Posix

TFLAGS=-O -inline -version=Posix $(ADDFLAGS)
#TFLAGS=-g -version=Posix

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR) -qsv
DC=dmd

LIB_DEST=..

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
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

targets : lib doc
all     : lib doc
lib     : stub.lib
doc     : stub.doc

######################################################

ALL_OBJS= \
    gc.o

######################################################

ALL_DOCS=

######################################################

stub.lib : libstub.a

libstub.a : $(ALL_OBJS)
	$(RM) $@
	$(LC) $@ $(ALL_OBJS)

stub.doc : $(ALL_DOCS)
	echo No documentation available.

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) libstub*.a

install :
	$(MD) $(LIB_DEST)
	$(CP) libstub*.a $(LIB_DEST)/.

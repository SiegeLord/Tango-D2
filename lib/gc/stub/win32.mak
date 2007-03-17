# Makefile to build D garbage collector library for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=xcopy /y
RM=del /f
MD=mkdir

ADD_CFLAGS=
ADD_DFLAGS=

CFLAGS=-mn -6 -r $(ADD_CFLAGS)
#CFLAGS=-g -mn -6 -r $(ADD_CFLAGS)

### warnings disabled because gcx has issues ###

DFLAGS=-release -O -inline $(ADD_DFLAGS)
#DFLAGS=-g -release $(ADD_DFLAGS)

TFLAGS=-O -inline $(ADD_DFLAGS)
#TFLAGS=-g $(ADD_DFLAGS)

DOCFLAGS=-version=DDoc

CC=dmc
LC=lib
DC=dmd

LIB_DEST=..

.DEFAULT: .asm .c .cpp .d .html .obj

.asm.obj:
	$(CC) -c $<

.c.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.d.obj:
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
    gc.obj

######################################################

ALL_DOCS=

######################################################

stub.lib : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

stub.doc : $(ALL_DOCS)
	@echo No documentation available.

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) stub*.lib

install :
	$(MD) $(LIB_DEST)
	$(CP) stub*.lib $(LIB_DEST)\.

# Makefile to build D runtime library dmd.lib for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build dmd.lib
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=xcopy /y
RM=del /f
MD=mkdir

CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

### warnings disabled because gcx has issues ###

DFLAGS=-release -O -inline
#DFLAGS=-g -release

TFLAGS=-O -inline
#TFLAGS=-g

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
lib     : dmd.lib
doc     : dmd.doc

######################################################

ALL_OBJS= \
    gc.obj \
    gcbits.obj \
    gcstats.obj \
    gcx.obj \
    win32.obj

######################################################

ALL_DOCS=

######################################################

dmd.lib : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

dmd.doc : $(ALL_DOCS)
	@echo No documentation available.

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) dmd*.lib

install :
	$(MD) $(LIB_DEST)
	$(CP) dmd*.lib $(LIB_DEST)\.

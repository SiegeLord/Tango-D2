# Makefile to build D runtime library dmdgc.lib for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build dmdgc.lib
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=xcopy /y
RM=del /f
MD=mkdir

CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

DFLAGS=-release -O -inline
#DFLAGS=-g -release

TFLAGS=-O -inline
#TFLAGS=-g

DOCFLAGS=-version=DDoc

CC=dmc
LC=lib
DC=dmd

DMDGC_DEST=..\..\..
INC_DEST=$(DMDGC_DEST)\include\dmdgc
LIB_DEST=$(DMDGC_DEST)\lib
DOC_DEST=$(DMDGC_DEST)\doc\dmdgc

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
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmdgc.ddoc $<

targets : lib doc
all     : lib doc
dmdgc   : lib
lib     : dmdgc.lib
doc     : dmdgc.doc

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

dmdgc.lib : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

dmdgc.doc : $(ALL_DOCS)
	@echo No documentation available.

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) dmdgc*.lib

install :
	$(MD) $(LIB_DEST)
	$(CP) dmdgc*.lib $(LIB_DEST)\.

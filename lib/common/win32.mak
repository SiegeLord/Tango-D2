# Makefile to build D runtime library tango.lib for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build tango.lib
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

INC_DEST=..\..\tango
LIB_DEST=..
DOC_DEST=..\..\doc\tango

.DEFAULT: .asm .c .cpp .d .html .obj

.asm.obj:
	$(CC) -c $<

.c.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.d.obj:
	$(DC) -c $(DFLAGS) -Hf$*.di $< -of$@
#	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

targets : lib doc
all     : lib doc
tango   : lib
lib     : tango.lib
doc     : tango.doc

######################################################

OBJ_CONVERT= \
    convert\dtoa.obj

OBJ_CORE= \
    core\exception.obj \
    core\memory.obj \
    core\thread.obj

OBJ_OS= \
    os\windows\c\windows.obj

ALL_OBJS= \
    $(OBJ_CONVERT) \
    $(OBJ_CORE) \
    $(OBJ_OS)

######################################################

DOC_CORE= \
    core\exception.html \
    core\memory.html \
    core\thread.html

ALL_DOCS= \
    $(DOC_CORE)

######################################################

tango.lib : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	@echo Documentation generated.

######################################################

### convert

convert\dtoa.obj : convert\dtoa.c
	$(CC) -c $(CFLAGS) -w2 -w7 convert\dtoa.c -o$@

### os\windows\c

os\windows\c\windows.obj : os\windows\c\windows.d
	$(DC) -c $(DFLAGS) os\windows\c\windows.d -of$@

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) tango*.lib

install :
	$(MD) $(INC_DEST)
	$(CP) /s *.di $(INC_DEST)\.
	$(MD) $(DOC_DEST)
	$(CP) /s *.html $(DOC_DEST)\.
	$(MD) $(LIB_DEST)
	$(CP) tango*.lib $(LIB_DEST)\.

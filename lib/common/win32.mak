# Makefile to build D common runtime library for Win32
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

CFLAGS=-mn -6 -r
#CFLAGS=-g -mn -6 -r

DFLAGS=-release -O -inline -w
#DFLAGS=-g -release -w

TFLAGS=-O -inline -w
#TFLAGS=-g -w

DOCFLAGS=-version=DDoc ..\..\doc\html\candydoc\modules.ddoc ..\..\doc\html\candydoc\candy.ddoc

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

OBJ_CORE= \
    core\Exception.obj \
    core\Memory.obj \
    core\Thread.obj

OBJ_STDC= \
    stdc\wrap.obj

OBJ_SYS_WIN32= \
    sys\win32\Macros.obj \
    sys\win32\Process.obj \
    sys\win32\Types.obj \
    sys\win32\UserGdi.obj

ALL_OBJS= \
    $(OBJ_CORE) \
    $(OBJ_STDC) \
    $(OBJ_SYS_WIN32)

######################################################

DOC_CORE= \
    core\Exception.html \
    core\Memory.html \
    core\Thread.html

ALL_DOCS=

######################################################

tango.lib : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	@echo Documentation generated.

######################################################

### sys\win32

# NOTE: sys\win32 is only present in this library because linking a lib file
#       under DMD/Win32 results in a much smaller executable than linking
#       each object separately with a tool like Bud.  This should be
#       periodically re-evaluated to determine whether this workaround may
#       be eliminated.

sys\win32\Macros.obj : sys\win32\Macros.d
	$(DC) -c $(DFLAGS) sys\win32\Macros.d -of$@

sys\win32\Process.obj : sys\win32\Process.d
	$(DC) -c $(DFLAGS) sys\win32\Process.d -of$@

sys\win32\Types.obj : sys\win32\Types.d
	$(DC) -c $(DFLAGS) sys\win32\Types.d -of$@

sys\win32\UserGdi.obj : sys\win32\UserGdi.d
	$(DC) -c $(DFLAGS) sys\win32\UserGdi.d -of$@

######################################################

clean :
	$(RM) /s .\*.di
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

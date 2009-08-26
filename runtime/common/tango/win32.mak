# Makefile to build the common D runtime library for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build the common library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

LIB_BASE=tango-cc-tango
LIB_BUILD=
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).lib
LIB_MASK=$(LIB_BASE)*.lib

CP=xcopy /y
RM=del /f
MD=mkdir

ADD_CFLAGS=
ADD_DFLAGS=-I..

CFLAGS_RELEASE=-mn -6 -r $(ADD_CFLAGS)
CFLAGS_DEBUG=-g -mn -6 -r $(ADD_CFLAGS)
DFLAGS_RELEASE=-release -O -inline -w -nofloat $(ADD_DFLAGS)
DFLAGS_DEBUG=-g -w -nofloat $(ADD_DFLAGS)
TFLAGS_RELEASE=-O -inline -w  -nofloat $(ADD_DFLAGS)
TFLAGS_DEBUG=-g -w -nofloat $(ADD_DFLAGS)

CFLAGS=$(CFLAGS_RELEASE)
DFLAGS=$(DFLAGS_RELEASE)
TFLAGS=$(TFLAGS_RELEASE)

DOCFLAGS=-version=DDoc

CC=dmc
LC=lib
DC=dmd

INC_DEST=..\..\..\user\tango
LIB_DEST=..
DOC_DEST=..\..\..\doc\tango

.DEFAULT: .asm .c .cpp .d .html .obj

.asm.obj:
	$(CC) -c $<

.c.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.obj:
	$(CC) -c $(CFLAGS) $< -o$@

.d.obj:
	$(DC) -c $(DFLAGS) -I.. -Hf$*.di $< -of$@
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
    core\BitManip.obj \
    core\Exception.obj \
    core\Memory.obj \
    core\Runtime.obj \
    core\Thread.obj \
    core\sync\Atomic.obj \
    stdc\config.obj \
    stdc\stdarg.obj \
    stdc\stddef.obj \
    stdc\stdint.obj \
    stdc\stdio.obj \
    sys\win32\Types.obj \
    sys\win32\UserGdi.obj


OBJ_STDC= \
    ..\wrap.obj 

ALL_OBJS= \
    $(OBJ_CORE) \
    $(OBJ_STDC)

######################################################

DOC_CORE= \
    core\BitManip.html \
    core\Exception.html \
    core\Memory.html \
    core\Runtime.html \
    core\Thread.html

ALL_DOCS=

######################################################

tango.lib : $(LIB_TARGET)

$(LIB_TARGET) : $(ALL_OBJS)
	$(RM) $@
	$(LC) -c -n $@ $(ALL_OBJS)

tango.doc : $(ALL_DOCS)
	@echo Documentation generated.

######################################################

### config

# config.obj : config.d
#	$(DC) -c $(DFLAGS) config.d -of$@

######################################################

clean :
	$(RM) /s .\*.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(RM) $(LIB_TARGET)

clean-all: clean
	$(RM) $(LIB_MASK)

install :
	$(MD) $(INC_DEST)
	$(CP) /s *.di $(INC_DEST)\.
	$(MD) $(DOC_DEST)
	$(CP) /s *.html $(DOC_DEST)\.
	$(MD) $(LIB_DEST)
	$(CP) $(LIB_MASK) $(LIB_DEST)\.

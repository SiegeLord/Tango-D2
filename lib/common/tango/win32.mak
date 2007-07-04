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

ADD_CFLAGS=
ADD_DFLAGS=

CFLAGS=-mn -6 -r $(ADD_CFLAGS)
#CFLAGS=-g -mn -6 -r $(ADD_CFLAGS)

DFLAGS=-release -O -inline -w $(ADD_DFLAGS)
#DFLAGS=-g -release -w $(ADD_DFLAGS)

TFLAGS=-O -inline -w $(ADD_DFLAGS)
#TFLAGS=-g -w $(ADD_DFLAGS)

DOCFLAGS=-version=DDoc ..\..\doc\html\candydoc\modules.ddoc ..\..\doc\html\candydoc\candy.ddoc

CC=dmc
LC=lib
DC=dmd

INC_DEST=..\..\..\tango
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
	$(DC) -c $(DFLAGS) -v1 -Hf$*.di $< -of$@
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
    core\Runtime.obj \
    core\Thread.obj

OBJ_STDC= \
    stdc\wrap.obj

ALL_OBJS= \
    $(OBJ_CORE) \
    $(OBJ_STDC)

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

### config

# config.obj : config.d
#	$(DC) -c $(DFLAGS) config.d -of$@

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

# Makefile to build the composite D runtime library for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build the runtime library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

LIB_BASE=tango-base-dmd
LIB_BUILD=
LIB_TARGET=..\build\libs\$(LIB_BASE)$(LIB_BUILD).lib
LIB_MASK=$(LIB_BASE)*.lib

GC=basic
DIR_CC=..\runtime\common\tango
DIR_RT=..\runtime\compiler\dmd
DIR_GC=..\runtime\gc\$(GC)

LIB_CC=$(DIR_CC)\tango-cc-tango$(LIB_BUILD).lib
LIB_RT=$(DIR_RT)\tango-rt-dmd$(LIB_BUILD).lib
LIB_GC=$(DIR_GC)\tango-gc-basic$(LIB_BUILD).lib

MAKE=make

CP=xcopy /y
RM=del /f
MD=mkdir

CC=dmc
LC=lib
DC=dmd

ADD_CFLAGS=
ADD_DFLAGS=-I../../compiler/dmd
CFLAGS_RELEASE=-mn -6 -r $(ADD_CFLAGS)
CFLAGS_DEBUG=-g -mn -6 -r $(ADD_CFLAGS)
DFLAGS_RELEASE=-H -release -O -inline -w -nofloat -I. -I../shared -I../../../user -I../../common -I../../gc/$(GC) $(ADD_DFLAGS)
DFLAGS_DEBUG=-H -g -w -nofloat  -I. -I../shared -I../../../user -I../../common -I../../gc/$(GC) $(ADD_DFLAGS)
TFLAGS_RELEASE=-O -inline -w  -nofloat $(ADD_DFLAGS)
TFLAGS_DEBUG=-g -w -nofloat $(ADD_DFLAGS)

targets : lib-release doc
all     : lib-release lib-debug doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################
lib: lib-release

lib-release:
	$(MAKE) -fdmd-win32.mak clean LIB_BUILD=""
	$(MAKE) -fdmd-win32.mak release-comp LIB_BUILD=""

lib-debug:
	$(MAKE) -fdmd-win32.mak clean LIB_BUILD="-dbg"
	$(MAKE) -fdmd-win32.mak debug-comp LIB_BUILD="-dbg"
	
release-comp : $(ALL_OBJS)
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_RELEASE)" CFLAGS="$(CFLAGS_RELEASE)" \
		TFLAGS="$(TFLAGS_RELEASE)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_RELEASE)" CFLAGS="$(CFLAGS_RELEASE)" \
		TFLAGS="$(TFLAGS_RELEASE)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_RELEASE)" CFLAGS="$(CFLAGS_RELEASE)" \
		TFLAGS="$(TFLAGS_RELEASE)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	$(MD) ..\build\libs
	$(RM) $(LIB_TARGET)
	$(LC) -c -n -p32 $(LIB_TARGET) $(LIB_CC) $(LIB_RT) $(LIB_GC)

debug-comp : $(ALL_OBJS)
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_DEBUG)" CFLAGS="$(CFLAGS_DEBUG)" \
		TFLAGS="$(TFLAGS_DEBUG)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_DEBUG)" CFLAGS="$(CFLAGS_DEBUG)" \
		TFLAGS="$(TFLAGS_DEBUG)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak lib DC=$(DC) DFLAGS="$(DFLAGS_DEBUG)" CFLAGS="$(CFLAGS_DEBUG)" \
		TFLAGS="$(TFLAGS_DEBUG)" LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	$(MD) ..\build\libs
	$(RM) $(LIB_TARGET)
	$(LC) -c -n -p32 $(LIB_TARGET) $(LIB_CC) $(LIB_RT) $(LIB_GC)

doc : $(ALL_DOCS)
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak doc
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak doc
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak doc
	cd ..\..

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak clean LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak clean LIB_BUILD="$(LIB_BUILD)"
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak clean LIB_BUILD="$(LIB_BUILD)"
	cd ..\..

clean-all: clean
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak clean-all
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak clean-all
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak clean-all
	cd ..\..
	$(RM) $(LIB_MASK)
	
install :
	cd $(DIR_CC)
	$(MAKE) -fwin32.mak install
	cd ..\..
	cd $(DIR_RT)
	$(MAKE) -fwin32.mak install
	cd ..\..
	cd $(DIR_GC)
	$(MAKE) -fwin32.mak install
	cd ..\..
#	$(CP) $(LIB_MASK) $(LIB_DEST)\.

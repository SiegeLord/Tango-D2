# Makefile to build D runtime library phobos.lib for Win32
# Designed to work with DigitalMars make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build phobos.lib
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=xcopy /y
RM=del /f
MD=mkdir

CC=dmc
LC=lib
DC=dmd

ADD_CFLAGS=
ADD_DFLAGS=

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################

lib : $(ALL_OBJS)
	cd compiler\dmd
	make -fwin32.mak lib
	cd ..\..
	cd gc\basic
	make -fwin32.mak lib DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	cd ..\..
	cd common\tango
	make -fwin32.mak lib DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	cd ..\..
	$(RM) phobos*.lib
	$(LC) -c -n phobos.lib common\tango\tango.lib compiler\dmd\dmd.lib gc\basic\basic.lib

doc : $(ALL_DOCS)
	cd compiler\dmd
	make -fwin32.mak doc
	cd ..\..
	cd gc\basic
	make -fwin32.mak doc
	cd ..\..
	cd common\tango
	make -fwin32.mak doc
	cd ..\..

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	cd compiler\dmd
	make -fwin32.mak clean
	cd ..\..
	cd gc\basic
	make -fwin32.mak clean
	cd ..\..
	cd common\tango
	make -fwin32.mak clean
	cd ..\..
#	$(RM) phobos*.lib

install :
	cd compiler\dmd
	make -fwin32.mak install
	cd ..\..
	cd gc\basic
	make -fwin32.mak install
	cd ..\..
	cd common\tango
	make -fwin32.mak install
	cd ..\..
#	$(CP) phobos*.lib $(LIB_DEST)\.

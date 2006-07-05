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

CFLAGS=-mn -6 -r

DFLAGS=-release -O -inline

TFLAGS=-O -inline

DOCFLAGS=-version=DDoc

CC=dmc
LC=lib
DC=dmd

LIB_DEST=..\lib
DOC_DEST=..\doc

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
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS= \
    config.obj

######################################################

ALL_DOCS=

######################################################

lib : $(ALL_OBJS)
	$(RM) phobos*.lib
	$(LC) -c -n phobos.lib $(ALL_OBJS)
	cd compiler\dmd
	make -fwin32.mak lib
	cd ..\..
	cd gc\dmd
	make -fwin32.mak lib
	cd ..\..
	cd common
	make -fwin32.mak lib
	cd ..
	$(RM) phobos*.lib
	$(LC) -c -n phobos.lib common\tango.lib compiler\dmd\dmd.lib gc\dmd\dmd.lib

doc : $(ALL_DOCS)
	@echo No documentation available.
	cd compiler\dmd
	make -fwin32.mak doc
	cd ..\..
	cd gc\dmd
	make -fwin32.mak doc
	cd ..\..
	cd common
	make -fwin32.mak doc
	cd ..

######################################################

clean :
	$(RM) /s *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	cd compiler\dmd
	make -fwin32.mak clean
	cd ..\..
	cd gc\dmd
	make -fwin32.mak clean
	cd ..\..
	cd common
	make -fwin32.mak clean
	cd ..
#	$(RM) phobos*.lib

install :
	$(MD) $(LIB_DEST)
	cd compiler\dmd
	make -fwin32.mak install
	cd ..\..
	cd gc\dmd
	make -fwin32.mak install
	cd ..\..
	cd common
	make -fwin32.mak install
	cd ..
#	$(CP) phobos*.lib $(LIB_DEST)\.

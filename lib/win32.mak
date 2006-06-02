CP=xcopy /y
RM=del /f
MD=mkdir

CC=dmc
LC=lib
DC=dmd

DOC_DEST=..\doc
LIB_DEST=..\lib

targets : lib doc
all     : lib doc

lib :
	cd compiler\digitalmars
	make -fwin32.mak lib
	cd ..\..
	cd gc\digitalmars
	make -fwin32.mak lib
	cd ..\..
	cd common
	make -fwin32.mak lib
	cd ..
	$(RM) phobos*.lib
	$(LC) -c -n phobos.lib common\tango.lib compiler\digitalmars\dmdrt.lib gc\digitalmars\dmdgc.lib

doc :
	cd compiler\digitalmars
	make -fwin32.mak doc
	cd ..\..
	cd gc\digitalmars
	make -fwin32.mak doc
	cd ..\..
	cd common
	make -fwin32.mak doc
	cd ..

clean :
	cd compiler\digitalmars
	make -fwin32.mak clean
	cd ..\..
	cd gc\digitalmars
	make -fwin32.mak clean
	cd ..\..
	cd common
	make -fwin32.mak clean
	cd ..
#	$(RM) phobos*.lib

install :
	cd compiler\digitalmars
	make -fwin32.mak install
	cd ..\..
	cd gc\digitalmars
	make -fwin32.mak install
	cd ..\..
	cd common
	make -fwin32.mak install
	cd ..
#	$(CP) phobos*.lib $(LIB_DEST)\.

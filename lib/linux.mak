CP=cp -f
RM=rm -f
MD=mkdir -p

DOC_DEST=../doc
LIB_DEST=../lib

targets : lib doc
all     : lib doc

lib :
	make -C dmdrt -flinux.mak lib
	make -C dmdgc -flinux.mak lib
	make -C ares  -flinux.mak lib
	find . -name "*.o" | xargs ar -r libphobos.a

doc :
	make -C dmdrt -flinux.mak doc
	make -C dmdgc -flinux.mak doc
	make -C ares  -flinux.mak doc

clean :
	make -C dmdrt -flinux.mak clean
	make -C dmdgc -flinux.mak clean
	make -C ares  -flinux.mak clean
	$(RM) libphobos*.a

install :
	make -C dmdrt -flinux.mak install
	make -C dmdgc -flinux.mak install
	make -C ares  -flinux.mak install
	$(CP) libphobos*.a $(LIB_DEST)/.

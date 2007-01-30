# Makefile to build D runtime library libgphobos.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build libgphobos.a
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=cp -f
RM=rm -f
MD=mkdir -p

CC=gcc
LC=$(AR) -qsv
DC=gdmd

ADDFLAGS=-q,-nostdinc -I`pwd`/.. -I`pwd`/compiler/gdc

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################

lib : $(ALL_OBJS)
	make -C compiler/gdc
	$(RM) compiler/gdc/config/*.o compiler/gdc/gcc/configunix.o
	make -C gc/basic -fposix.mak lib DC=$(DC) ADDFLAGS="$(ADDFLAGS)"
	make -C common/tango -fposix.mak lib DC=$(DC) ADDFLAGS="$(ADDFLAGS)"
	find . -name "libgphobos*.a" | xargs $(RM)
	$(LC) libgphobos.a `find ./compiler/gdc -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./gc/basic -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./common/tango -name "*.o" | xargs echo`

doc : $(ALL_DOCS)
	echo No documentation available.
	#make -C compiler/gdc -flinux.mak doc
	make -C gc/basic -fposix.mak doc DC=$(DC)
	make -C common/tango -fposix.mak doc DC=$(DC)

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	make -C compiler/gdc clean
	make -C gc/basic -fposix.mak clean DC=$(DC)
	make -C common/tango -fposix.mak clean DC=$(DC)
#	$(RM) libgphobos*.a

install :
	#$(MD) $(LIB_DEST)
	#make -C compiler/gdc -flinux.mak install
	make -C gc/basic -fposix.mak install DC=$(DC)
	make -C common/tango -fposix.mak install DC=$(DC)
#	$(CP) libgphobos*.a $(LIB_DEST)/.

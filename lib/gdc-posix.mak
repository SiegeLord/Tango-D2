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

ADD_CFLAGS=
ADD_DFLAGS=-q,-nostdinc -I`pwd`/common -I`pwd`/.. -I`pwd`/compiler/gdc

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################

lib : $(ALL_OBJS)
	make -C compiler/gdc
	$(RM) compiler/gdc/config/*.o compiler/gdc/gcc/configunix.o compiler/gdc/minimal.o
	make -C gc/basic -fposix.mak lib CC=$(CC) DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	make -C common/tango -fposix.mak lib CC=$(CC) DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	find . -name "libgphobos*.a" | xargs $(RM)
	$(LC) libgphobos.a `find ./compiler/gdc -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./gc/basic -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./common/tango -name "*.o" | xargs echo`

doc : $(ALL_DOCS)
	echo No documentation available.
	#make -C compiler/gdc -flinux.mak doc
	make -C gc/basic -fposix.mak doc CC=$(CC) DC=$(DC)
	make -C common/tango -fposix.mak doc CC=$(CC) DC=$(DC)

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	make -C compiler/gdc clean
	make -C gc/basic -fposix.mak clean CC=$(CC) DC=$(DC)
	make -C common/tango -fposix.mak clean CC=$(CC) DC=$(DC)
#	$(RM) libgphobos*.a

install :
	#$(MD) $(LIB_DEST)
	#make -C compiler/gdc -flinux.mak install
	make -C gc/basic -fposix.mak install CC=$(CC) DC=$(DC)
	make -C common/tango -fposix.mak install CC=$(CC) DC=$(DC)
#	$(CP) libgphobos*.a $(LIB_DEST)/.

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

MAKE=$(MAKETOOL)
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
	$(MAKE) -C compiler/gdc CC=$(CC) DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)" \
	                                          DFLAGS="-g -frelease -O2 $(ADD_DFLAGS)" CFLAGS="-g -O2 $(ADD_CFLAGS)"
	$(RM) compiler/gdc/config/*.o compiler/gdc/gcc/configunix.o compiler/gdc/minimal.o
	$(MAKE) -C gc/basic -fposix.mak lib CC=$(CC) DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	$(MAKE) -C common/tango -fposix.mak lib CC=$(CC) DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)"
	find . -name "libgphobos*.a" | xargs $(RM)
	$(LC) libgphobos.a `find ./compiler/gdc -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./compiler/shared -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./gc/basic -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./common -name "*.o" | xargs echo`

doc : $(ALL_DOCS)
	echo No documentation available.
	#$(MAKE) -C compiler/gdc -flinux.mak doc CC=$(CC) DC=$(DC)
	$(MAKE) -C gc/basic -fposix.mak doc CC=$(CC) DC=$(DC)
	$(MAKE) -C common/tango -fposix.mak doc CC=$(CC) DC=$(DC)

######################################################

#	find . -name "*.di" | xargs $(RM)
clean :
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	$(MAKE) -C compiler/gdc clean clean
	$(MAKE) -C gc/basic -fposix.mak clean
	$(MAKE) -C common/tango -fposix.mak clean
#	$(RM) libgphobos*.a

install :
	#$(MD) $(LIB_DEST)
	#$(MAKE) -C compiler/gdc -flinux.mak install
	$(MAKE) -C gc/basic -fposix.mak install
	$(MAKE) -C common/tango -fposix.mak install
#	$(CP) libgphobos*.a $(LIB_DEST)/.

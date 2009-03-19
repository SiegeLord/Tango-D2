# Makefile to build the composite D runtime library for Linux
# Designed to work with GNU make
# Targets:
#	make
#		same as make lib
#	make all
#		make lib-release lib-debug and doc
#	make lib
#		Build the compiler runtime library (which version depends on VERSION, name on LIB_BUILD)
#	make lib-release
#		Build the release version of the compiler runtime library
#	make lib-debug
#		Build the debug version of the compiler runtime library
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process
#	make clean-all
#		Delete unneeded files created by build process and the libraries
#	make unittest
#		Performs the unittests of the runtime library

LIB_BASE=libtango-base-dmd
LIB_BUILD=
LIB_TARGET=$(LIB_BASE)$(LIB_BUILD).a
LIB_MASK=$(LIB_BASE)*.a

DIR_CC=./common/tango
DIR_RT=./compiler/dmd
DIR_RT2=./compiler/shared
DIR_GC=./gc/basic

CP=cp -f
RM=rm -f
MD=mkdir -p

CC=gcc
LC=$(AR) -qsv
DC=dmd

ADD_CFLAGS=-m32
ADD_DFLAGS=
#-g -debug -debug=PRINTF

.PHONY : lib lib-release lib-debug unittest all doc clean install clean-all targets

targets : lib doc
all     : lib-release lib-debug doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################
unittest :
	make -fdmd-posix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -fdmd-posix.mak lib DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)" \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS) -unittest -debug=UnitTest" \
		SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-release :
	make -fdmd-posix.mak clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -fdmd-posix.mak DC="$(DC)" LIB_BUILD="" VERSION=release lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-debug :
	make -fdmd-posix.mak clean DC="$(DC)" LIB_BUILD="-d" VERSION="$(VERSION)"
	make -fdmd-posix.mak DC="$(DC)" LIB_BUILD="-d" VERSION=debug lib \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"

lib : $(LIB_TARGET)
$(LIB_TARGET) : $(ALL_OBJS)
	make -C $(DIR_CC) -fposix.mak lib DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)" \
	 	VERSION="$(VERSION)" LIB_BUILD="$(LIB_BUILD)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
	make -C $(DIR_RT) -fposix.mak lib DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)" \
	 	VERSION="$(VERSION)" LIB_BUILD="$(LIB_BUILD)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
	make -C $(DIR_GC) -fposix.mak lib DC=$(DC) ADD_DFLAGS="$(ADD_DFLAGS)" ADD_CFLAGS="$(ADD_CFLAGS)" \
 		VERSION="$(VERSION)" LIB_BUILD="$(LIB_BUILD)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
	find . -name "libphobos*.a" | xargs $(RM)
	$(RM) $@
	$(LC) $@ `find $(DIR_CC) -name "*.o" | xargs echo`
	$(LC) $@ `find $(DIR_RT) -name "*.o" | xargs echo`
	$(LC) $@ `find $(DIR_RT2) -name "*.o" | xargs echo`
	$(LC) $@ `find $(DIR_GC) -name "*.o" | xargs echo`
ifneq ($(RANLIB),)
	$(RANLIB) $@
endif

doc : $(ALL_DOCS)
	make -C $(DIR_CC) -fposix.mak doc DC=$(DC)
	make -C $(DIR_RT) -fposix.mak doc DC=$(DC)
	make -C $(DIR_GC) -fposix.mak doc DC=$(DC)

######################################################

#	find . -name "*.di" | xargs $(RM)
clean :
	$(RM) $(ALL_OBJS)
	make -C $(DIR_CC) -fposix.mak clean
	make -C $(DIR_RT) -fposix.mak clean
	make -C $(DIR_GC) -fposix.mak clean

clean-all : clean
	make -C $(DIR_CC) -fposix.mak clean-all
	make -C $(DIR_RT) -fposix.mak clean-all
	make -C $(DIR_GC) -fposix.mak clean-all
	$(RM) $(ALL_DOCS)
	$(RM) $(LIB_MASK)

install :
	make -C $(DIR_CC) -fposix.mak install
	make -C $(DIR_RT) -fposix.mak install
	make -C $(DIR_GC) -fposix.mak install
#	$(CP) $(LIB_MASK) $(LIB_DEST)/.

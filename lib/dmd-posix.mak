# Makefile to build D runtime library libphobos.a for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make lib
#		Build libphobos.a
#   make doc
#       Generate documentation
#	make clean
#		Delete unneeded files created by build process

CP=cp -f
RM=rm -f
MD=mkdir -p

CC=gcc
LC=$(AR) -qsv
DC=dmd

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################

lib : $(ALL_OBJS)
	make -C compiler/dmd -fposix.mak lib
	make -C gc/basic -fposix.mak lib
	make -C common/tango -fposix.mak lib
	find . -name "libphobos*.a" | xargs $(RM)
	$(LC) libphobos.a `find ./compiler/dmd -name "*.o" | xargs echo`
	$(LC) libphobos.a `find ./gc/basic -name "*.o" | xargs echo`
	$(LC) libphobos.a `find ./common/tango -name "*.o" | xargs echo`

doc : $(ALL_DOCS)
	make -C compiler/dmd -fposix.mak doc
	make -C gc/basic -fposix.mak doc
	make -C common/tango -fposix.mak doc

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	make -C compiler/dmd -fposix.mak clean
	make -C gc/basic -fposix.mak clean
	make -C common/tango -fposix.mak clean
#	$(RM) libphobos*.a

install :
	make -C compiler/dmd -fposix.mak install
	make -C gc/basic -fposix.mak install
	make -C common/tango -fposix.mak install
#	$(CP) libphobos*.a $(LIB_DEST)/.

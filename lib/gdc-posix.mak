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

#CFLAGS=-mn -6 -r

DFLAGS=-release -O -inline -version=Posix

TFLAGS=-O -inline -version=Posix

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR) -P -r -s -v
DC=dmd

LIB_DEST=../lib
DOC_DEST=../doc

.SUFFIXES: .asm .c .cpp .d .html .o

.asm.o:
	$(CC) -c $<

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html $<
#	$(DC) -c -o- $(DOCFLAGS) -Df$*.html tango.ddoc $<

targets : lib doc
all     : lib doc

######################################################

ALL_OBJS=

######################################################

ALL_DOCS=

######################################################

#lib : $(ALL_OBJS)
#	find . -name "libgphobos*.a" | xargs $(RM)
#	$(LC) libgphobos.a $(ALL_OBJS)
lib :
	make -C compiler/gdc
	make -C gc/basic -fposix.mak lib
	make -C common -fposix.mak lib
	find . -name "libgphobos*.a" | xargs $(RM)
	$(LC) libgphobos.a `find ./compiler/gdc -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./gc/basic -name "*.o" | xargs echo`
	$(LC) libgphobos.a `find ./common -name "*.o" | xargs echo`

doc : $(ALL_DOCS)
	echo No documentation available.
	make -C compiler/gdc -flinux.mak doc
	make -C gc/basic -fposix.mak doc
	make -C common -fposix.mak doc

######################################################

clean :
	find . -name "*.di" | xargs $(RM)
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	make -C compiler/gdc -flinux.mak clean
	make -C gc/basic -fposix.mak clean
	make -C common -fposix.mak clean
#	$(RM) libgphobos*.a

install :
	$(MD) $(LIB_DEST)
	make -C compiler/gdc -flinux.mak install
	make -C gc/basic -fposix.mak install
	make -C common -fposix.mak install
#	$(CP) libgphobos*.a $(LIB_DEST)/.

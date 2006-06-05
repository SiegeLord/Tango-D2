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

#CFLAGS=-mn -6 -r

DFLAGS=-release -O -inline -version=Posix

TFLAGS=-O -inline -version=Posix

DOCFLAGS=-version=DDoc -version=Posix

CC=gcc
LC=$(AR)
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

ALL_OBJS= \
    config.o

######################################################

ALL_DOCS=

######################################################

lib :
	$(RM) libphobos*.a
	$(LC) -r libphobos.a $(ALL_OBJS)
	$(RM) libphobos*.a
	make -C compiler/digitalmars -flinux.mak lib
	make -C gc/digitalmars -flinux.mak lib
	make -C common/tango  -flinux.mak lib
	find . -name "*.o" | xargs ar -r libphobos.a

doc : $(ALL_DOCS)
	echo No documentation available.
	make -C compiler/digitalmars -flinux.mak doc
	make -C gc/digitalmars -flinux.mak doc
	make -C common/tango  -flinux.mak doc

######################################################

clean :
	$(RM) -r *.di
	$(RM) $(ALL_OBJS)
	$(RM) $(ALL_DOCS)
	make -C compiler/digitalmars -flinux.mak clean
	make -C gc/digitalmars -flinux.mak clean
	make -C common/tango -flinux.mak clean
#	$(RM) libphobos*.a

install :
	$(MD) $(LIB_DEST)
	make -C compiler/digitalmars -flinux.mak clean
	make -C gc/digitalmars -flinux.mak clean
	make -C common/tango -flinux.mak clean
#	$(CP) libphobos*.a $(LIB_DEST)/.

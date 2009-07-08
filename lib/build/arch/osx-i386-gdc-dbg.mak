include $(ARCHDIR)/gdc.rules
include $(ARCHDIR)/osx.inc

# -Wall breaks the compilation with wrong errors
DFLAGS_COMP=-g -fversion=Posix
CFLAGS_COMP=-g

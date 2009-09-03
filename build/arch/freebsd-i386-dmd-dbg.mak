include $(ARCHDIR)/dmd.rules
include $(ARCHDIR)/freebsd.inc

DFLAGS_COMP=-g -debug -version=freebsd
CFLAGS_COMP=-g

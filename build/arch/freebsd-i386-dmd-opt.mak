include $(ARCHDIR)/dmd.rules
include $(ARCHDIR)/freebsd.inc

DFLAGS_COMP=-inline -release -O -version=freebsd
CFLAGS_COMP=-O2

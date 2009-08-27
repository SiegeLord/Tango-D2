include $(ARCHDIR)/dmd-win.rules
include $(ARCHDIR)/mingw.inc

DFLAGS_COMP=-inline -release -O
CFLAGS_COMP=-mn -6 -r

include $(ARCHDIR)/dmd-win.rules
include $(ARCHDIR)/mingw.inc

DFLAGS_COMP=-g -d -unittest -debug=UnitTest -w
CFLAGS_COMP=-g -mn -6 -r

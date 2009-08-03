include $(ARCHDIR)/dmd-win.rules
include $(ARCHDIR)/mingw.inc

DFLAGS_COMP=-g -w -d -unittest -debug=UnitTest
CFLAGS_COMP=-g -mn -6 -r

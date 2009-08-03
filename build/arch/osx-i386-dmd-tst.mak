include $(ARCHDIR)/dmd.rules
include $(ARCHDIR)/osx.inc

DFLAGS_COMP=-g -debug -debug=UnitTest -unittest -d
CFLAGS_COMP=-g

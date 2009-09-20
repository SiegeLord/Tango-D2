include $(ARCHDIR)/dmd.rules
include $(ARCHDIR)/linux.inc

DFLAGS_COMP=-g -debug -debug=UnitTest -unittest -d
CFLAGS_COMP=-g

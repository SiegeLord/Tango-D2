include $(ARCHDIR)/dmd.rules
include $(ARCHDIR)/freebsd.inc

DFLAGS_COMP=-g -debug -debug=UnitTest -unittest -d -version=freebsd
CFLAGS_COMP=-g

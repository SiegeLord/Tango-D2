LIB_EXT=so
include $(ARCHDIR)/ldcSo.rules
include $(ARCHDIR)/linux.inc

DFLAGS_COMP=-inline -release -O2 -g -relocation-model=pic
CFLAGS_COMP=-O2 -fPIC

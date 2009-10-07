LIB_EXT=dylib
include $(ARCHDIR)/ldcSo.rules
include $(ARCHDIR)/osx.inc

DFLAGS_COMP=-inline -release -O2 -g -relocation-model=pic
CFLAGS_COMP=-O2 -fPIC

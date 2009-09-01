# files to compile for the gc
GC_MODULES = \
  rt.basicgc.gc \
  rt.basicgc.gcalloc \
  rt.basicgc.gcbits \
  rt.basicgc.gcstats \
  tango.core.internal.gcInterface \
  rt.basicgc.gcx

GC_DI= tango/core/internal/gcInterface.di

vpath %d gc/basic


include $(ARCHDIR)/ldc.rules

DFLAGS_COMP=-inline -release -O2
CFLAGS_COMP=-O2
EXCLUDEPAT_OS=*win32* *Win32* *darwin *freebsd

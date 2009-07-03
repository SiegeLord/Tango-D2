include $(ARCHDIR)/dmd.rules

DFLAGS_COMP=-inline -release -O
CFLAGS_COMP=-O2
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

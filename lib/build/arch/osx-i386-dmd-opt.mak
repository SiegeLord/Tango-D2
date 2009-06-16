include $(ARCHDIR)/dmd.rules

DFLAGS_COMP=-inline -release -O
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

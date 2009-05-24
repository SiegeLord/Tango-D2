include $(ARCHDIR)/dmd.rules

DFLAGS_ADD=-inline -release -O
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

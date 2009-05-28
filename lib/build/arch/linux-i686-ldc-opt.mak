include $(ARCHDIR)/ldc.rules

DFLAGS_ADD=-inline -release -O2
EXCLUDEPAT_OS=*win32* *Win32* *darwin *freebsd

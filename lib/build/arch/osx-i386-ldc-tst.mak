include $(ARCHDIR)/ldc.rules

DFLAGS_ADD=-g -debug -unittest -d-debug=UnitTest
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

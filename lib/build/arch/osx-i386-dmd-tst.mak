include $(ARCHDIR)/dmd.rules

DFLAGS_COMP=-g -debug -debug=UnitTest -unittest -d
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

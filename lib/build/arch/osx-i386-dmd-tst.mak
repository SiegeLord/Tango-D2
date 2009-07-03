include $(ARCHDIR)/dmd.rules

DFLAGS_COMP=-g -debug -debug=UnitTest -unittest -d
CFLAGS_COMP=-g
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

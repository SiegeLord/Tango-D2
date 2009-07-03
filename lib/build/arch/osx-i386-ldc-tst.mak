include $(ARCHDIR)/ldc.rules

DFLAGS_COMP=-g -d -unittest -d-debug=UnitTest
CFLAGS_COMP=-g
EXCLUDEPAT_OS=*win32* *Win32* *linux *freebsd

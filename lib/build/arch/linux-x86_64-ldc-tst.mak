include $(ARCHDIR)/ldc.rules

DFLAGS_COMP=-g -w -d -unittest -d-debug=UnitTest
EXCLUDEPAT_OS=*win32* *Win32* *darwin *freebsd

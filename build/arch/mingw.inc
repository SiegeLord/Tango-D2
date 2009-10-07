EXCLUDEPAT_OS=*darwin* *linux *freebsd *posix*
OS_MODULES=\
  tango.sys.win32.Types    \
  tango.sys.win32.UserGdi

OS_OO=$(COMPILER_OO_WIN)
OS_DI=\
  tango/sys/win32/Types.di   \
  tango/sys/win32/UserGdi.di

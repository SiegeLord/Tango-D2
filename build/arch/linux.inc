EXCLUDEPAT_OS=*win32* *Win32* *darwin *freebsd
OS_MODULES=$(COMPILER_MODULES_POSIX)\
  tango.stdc.posix.config \
  tango.stdc.posix.sys.time
OS_OO=$(COMPILER_OO_POSIX)
OS_DI=tango/stdc/posix/config.di \
  tango/stdc/posix/sys/time.di


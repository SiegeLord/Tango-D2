module tango.sys.consts.errno;

version (Windows)
         public import tango.sys.win32.consts.errno;
else
version (linux)
         public import tango.sys.linux.consts.errno;
else
version (FreeBSD)
         public import tango.sys.freebsd.consts.errno;
else
version (darwin)
         public import tango.sys.darwin.consts.errno;
else
version (solaris)
         public import tango.sys.solaris.consts.errno;

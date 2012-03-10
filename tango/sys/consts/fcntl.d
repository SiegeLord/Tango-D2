module tango.sys.consts.fcntl;

version (Windows)
         public import tango.sys.win32.consts.fcntl;
else
version (linux)
         public import tango.sys.linux.consts.fcntl;
else
version (FreeBSD)
         public import tango.sys.freebsd.consts.fcntl;
else
version (darwin)
         public import tango.sys.darwin.consts.fcntl;
else
version (solaris)
         public import tango.sys.solaris.consts.fcntl;

module tango.sys.consts.socket;

version (Windows)
         public import tango.sys.win32.consts.socket;
else
version (linux)
         public import tango.sys.linux.consts.socket;
else
version (FreeBSD)
         public import tango.sys.freebsd.consts.socket;
else
version (darwin)
         public import tango.sys.darwin.consts.socket;
else
version (solaris)
         public import tango.sys.solaris.consts.socket;

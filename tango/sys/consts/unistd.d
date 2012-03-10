module tango.sys.consts.unistd;

version (Windows)
         public import tango.sys.win32.consts.unistd;
else
version (linux)
         public import tango.sys.linux.consts.unistd;
else
version (FreeBSD)
         public import tango.sys.freebsd.consts.unistd;
else
version (darwin)
         public import tango.sys.darwin.consts.unistd;
else
version (solaris)
         public import tango.sys.solaris.consts.unistd;


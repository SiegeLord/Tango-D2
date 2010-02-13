module tango.sys.solaris.consts.fcntl;

import tango.stdc.posix.config;

static if( __USE_LARGEFILE64 )
{
    enum { F_GETLK = 33 }
    enum { F_SETLK = 34 }
    enum { F_SETLKW = 35 }
}
else
{
    enum { F_GETLK = 14  }
    enum { F_SETLK = 6  }
    enum { F_SETLKW = 7 }
}
enum { F_DUPFD = 0 }
enum { F_GETFD = 1 }
enum { F_SETFD = 2 }
enum { F_GETFL = 3 }
enum { F_SETFL = 4 }
enum { F_GETOWN = 23 }
enum { F_SETOWN = 24 }
enum { FD_CLOEXEC = 1 }
enum { F_RDLCK = 01 }
enum { F_UNLCK = 03 }
enum { F_WRLCK = 02 }
enum { O_CREAT = 0x100  }
enum { O_EXCL = 0x400  }
enum { O_NOCTTY = 0x800 }
enum { O_TRUNC = 0x200  }
enum { O_NOFOLLOW = 0x20000 }
enum { O_APPEND = 0x08  }
enum { O_NONBLOCK = 0x80 }
enum { O_SYNC = 0x10  }
enum { O_DSYNC = 0x40  } // optional synchronized io
enum { O_RSYNC = 0x8000  } // optional synchronized io
enum { O_ACCMODE = 3 }
enum { O_RDONLY = 0  }
enum { O_WRONLY = 1  }
enum { O_RDWR = 2  }

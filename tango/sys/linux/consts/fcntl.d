module tango.sys.linux.consts.fcntl;
import tango.stdc.posix.config;
private import tango.core.Octal;

static if( __USE_LARGEFILE64 )
{
    enum { F_GETLK = 12 }
    enum { F_SETLK = 13 }
    enum { F_SETLKW = 14 }
}
else
{
    enum { F_GETLK = 5  }
    enum { F_SETLK = 6  }
    enum { F_SETLKW = 7 }
}
enum { F_DUPFD = 0 }
enum { F_GETFD = 1 }
enum { F_SETFD = 2 }
enum { F_GETFL = 3 }
enum { F_SETFL = 4 }
enum { F_GETOWN = 9 }
enum { F_SETOWN = 8 }
enum { FD_CLOEXEC = 1 }
enum { F_RDLCK = 0 }
enum { F_UNLCK = 2 }
enum { F_WRLCK = 1 }
enum { O_CREAT = octal!(100)  }
enum { O_EXCL = octal!(200)  }
enum { O_NOCTTY = octal!(400) }
enum { O_TRUNC = octal!(1000)  }
enum { O_NOFOLLOW = octal!(400000) }
enum { O_APPEND = octal!(2000)  }
enum { O_NONBLOCK = octal!(4000) }
enum { O_SYNC = octal!(10000)  }
enum { O_DSYNC = octal!(10000)  } // optional synchronized io
enum { O_RSYNC = octal!(10000)  } // optional synchronized io
enum { O_ACCMODE = octal!(3) }
enum { O_RDONLY = octal!(0)  }
enum { O_WRONLY = octal!(1)  }
enum { O_RDWR = octal!(2)  }

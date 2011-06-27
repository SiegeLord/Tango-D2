module tango.sys.linux.consts.fcntl;
import tango.stdc.posix.config;
import tango.util.Convert;

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
enum { O_CREAT = tango.util.Convert.octal!100  }
enum { O_EXCL = tango.util.Convert.octal!200  }
enum { O_NOCTTY = tango.util.Convert.octal!400 }
enum { O_TRUNC = tango.util.Convert.octal!1000  }
enum { O_NOFOLLOW = tango.util.Convert.octal!400000 }
enum { O_APPEND = tango.util.Convert.octal!2000  }
enum { O_NONBLOCK = tango.util.Convert.octal!4000 }
enum { O_SYNC = tango.util.Convert.octal!10000  }
enum { O_DSYNC = tango.util.Convert.octal!10000  } // optional synchronized io
enum { O_RSYNC = tango.util.Convert.octal!10000  } // optional synchronized io
enum { O_ACCMODE = tango.util.Convert.octal!3 }
enum { O_RDONLY = 0  }
enum { O_WRONLY = 1  }
enum { O_RDWR = 2  }

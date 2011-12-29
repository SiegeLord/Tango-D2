module tango.sys.freebsd.consts.fcntl;
    enum { F_GETLK = 11  }
    enum { F_SETLK = 12  }
    enum { F_SETLKW = 13 }
enum { F_DUPFD = 0 }
enum { F_GETFD = 1 }
enum { F_SETFD = 2 }
enum { F_GETFL = 3 }
enum { F_SETFL = 4 }
enum { F_GETOWN = 5 }
enum { F_SETOWN = 6 }
enum { FD_CLOEXEC = 1 }
enum { F_RDLCK = 1 }
enum { F_UNLCK = 2 }
enum { F_WRLCK = 3 }
enum { O_CREAT = 0x0200  }
enum { O_EXCL = 0x0800  }
enum { O_NOCTTY = 0x8000 }
enum { O_TRUNC = 0x0400  }
enum { O_NOFOLLOW = 0x0100 }
enum { O_APPEND = 0x0008  }
enum { O_NONBLOCK = 0x0004 }
enum { O_SYNC = 0x0080  }
// O_DSYNC not defined
// O_RSYNC not defined
enum { O_ACCMODE = 0x0003 }
enum { O_RDONLY = 0x0000  }
enum { O_WRONLY = 0x0001  }
enum { O_RDWR = 0x0002  }

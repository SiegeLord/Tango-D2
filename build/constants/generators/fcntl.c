#include <sys/fcntl.h>
#undef const
tt
xxx start xxx
module tango.stdc.constants.autoconf.fcntl;
#ifdef linux
version (linux){
    version(SMALLFILE)  // Note: makes no difference in X86_64 mode.
    {
      const bool  __USE_LARGEFILE64   = false;
    }
    else
    {
      const bool  __USE_LARGEFILE64   = true;
    }
    const bool  __USE_FILE_OFFSET64 = __USE_LARGEFILE64;
    static if( __USE_FILE_OFFSET64 )
    {
    enum { __XYX__F_GETLK       = F_GETLK64 }
    enum { __XYX__F_SETLK       = F_SETLK64 }
    enum { __XYX__F_SETLKW      = F_SETLKW64 }
     }
    else
    {
    enum { __XYX__F_GETLK       = F_GETLK  }
    enum { __XYX__F_SETLK       = F_SETLK  }
    enum { __XYX__F_SETLKW      = F_SETLKW }
     }
}
#else
     enum { __XYX__F_GETLK       = F_GETLK  }
     enum { __XYX__F_SETLK       = F_SETLK  }
     enum { __XYX__F_SETLKW      = F_SETLKW }
#endif
enum { __XYX__F_DUPFD = F_DUPFD }
enum { __XYX__F_GETFD = F_GETFD }
enum { __XYX__F_SETFD = F_SETFD }
enum { __XYX__F_GETFL = F_GETFL }
enum { __XYX__F_SETFL = F_SETFL }
enum { __XYX__F_GETOWN      = F_GETOWN }
enum { __XYX__F_SETOWN      = F_SETOWN }

enum { __XYX__FD_CLOEXEC    = FD_CLOEXEC }

enum { __XYX__F_RDLCK       = F_RDLCK }
enum { __XYX__F_UNLCK       = F_UNLCK }
enum { __XYX__F_WRLCK       = F_WRLCK }

enum { __XYX__O_CREAT       = O_CREAT  }
enum { __XYX__O_EXCL        = O_EXCL   }
enum { __XYX__O_NOCTTY      = O_NOCTTY }
enum { __XYX__O_TRUNC       = O_TRUNC  }
enum { __XYX__O_NOFOLLOW    = O_NOFOLLOW }

enum { __XYX__O_APPEND      = O_APPEND   }
enum { __XYX__O_NONBLOCK    = O_NONBLOCK }
enum { __XYX__O_SYNC        = O_SYNC     }
#ifdef O_DSYNC
enum { __XYX__O_DSYNC       = O_DSYNC    } // optional synchronized io
#endif
#ifdef O_DSYNC
enum { __XYX__O_RSYNC       = O_RSYNC    } // optional synchronized io
#endif

enum { __XYX__O_ACCMODE     = O_ACCMODE }
enum { __XYX__O_RDONLY      = O_RDONLY  }
enum { __XYX__O_WRONLY      = O_WRONLY  }
enum { __XYX__O_RDWR        = O_RDWR    }

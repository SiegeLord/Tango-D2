/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.stat;

private import tango.stdc.posix.config;
private import tango.stdc.stdint;
private import tango.stdc.posix.time;     // for timespec
public import tango.stdc.stddef;          // for size_t
public import tango.stdc.posix.sys.types; // for off_t, mode_t

extern (C):

//
// Required
//
/*
struct stat
{
    dev_t   st_dev;
    ino_t   st_ino;
    mode_t  st_mode;
    nlink_t st_nlink;
    uid_t   st_uid;
    gid_t   st_gid;
    off_t   st_size;
    time_t  st_atime;
    time_t  st_mtime;
    time_t  st_ctime;
}

S_IRWXU
    S_IRUSR
    S_IWUSR
    S_IXUSR
S_IRWXG
    S_IRGRP
    S_IWGRP
    S_IXGRP
S_IRWXO
    S_IROTH
    S_IWOTH
    S_IXOTH
S_ISUID
S_ISGID
S_ISVTX

S_ISBLK(m)
S_ISCHR(m)
S_ISDIR(m)
S_ISFIFO(m)
S_ISREG(m)
S_ISLNK(m)
S_ISSOCK(m)

S_TYPEISMQ(buf)
S_TYPEISSEM(buf)
S_TYPEISSHM(buf)

int    chmod(in char*, mode_t);
int    fchmod(int, mode_t);
int    fstat(int, stat*);
int    lstat(in char*, stat*);
int    mkdir(in char*, mode_t);
int    mkfifo(in char*, mode_t);
int    stat(in char*, stat*);
mode_t umask(mode_t);
*/

version( linux )
{
    static if( __USE_LARGEFILE64 )
    {
        private alias uint _pad_t;
    }
    else
    {
        private alias ushort _pad_t;
    }

    align (4) struct stat_t
    {
        dev_t       st_dev;             /* Device.  */
      version (X86_64) {} else {
        _pad_t      __pad1;
      }
      static if( __USE_LARGEFILE64 )
      {
        ino_t      __st_ino;            /* 32bit file serial number.    */
      }
      else
      {
        ino_t       st_ino;             /* File serial number.  */
      }
      version (X86_64) {
        nlink_t     st_nlink;
        mode_t      st_mode;
      } else {
        mode_t      st_mode;            /* File mode.  */
        nlink_t     st_nlink;           /* Link count.  */
      }
        uid_t       st_uid;             /* User ID of the file's owner. */
        gid_t       st_gid;             /* Group ID of the file's group.*/
      version (X86_64) {
        int         pad0;
        dev_t       st_rdev;
      } else {
        dev_t       st_rdev;            /* Device number, if device.  */
        _pad_t      __pad2;
      }
        off_t       st_size;            /* Size of file, in bytes.  */
        blksize_t   st_blksize;         /* Optimal block size for I/O.  */
        blkcnt_t    st_blocks;          /* Number 512-byte blocks allocated. */
      static if( false /*__USE_MISC*/ ) // true if _BSD_SOURCE || _SVID_SOURCE
      {
        timespec    st_atim;
        timespec    st_mtim;
        timespec    st_ctim;
        alias st_atim.tv_sec st_atime;
        alias st_mtim.tv_sec st_mtime;
        alias st_ctim.tv_sec st_ctime;
      }
      else
      {
        time_t      st_atime;
        c_ulong     st_atimensec;
        time_t      st_mtime;
        c_ulong     st_mtimensec;
        time_t      st_ctime;
        c_ulong     st_ctimensec;
      }
      version (X86_64) {
        c_long[3]  __unused;
      }
      else static if( __USE_LARGEFILE64 )
      {
        ino64_t     st_ino;             /* File serial number.  */
      }
      else
      {
        c_ulong     __unused4;
        c_ulong     __unused5;
      }
    }

    const S_IRUSR   = 0400;
    const S_IWUSR   = 0200;
    const S_IXUSR   = 0100;
    const S_IRWXU   = S_IRUSR | S_IWUSR | S_IXUSR;

    const S_IRGRP   = S_IRUSR >> 3;
    const S_IWGRP   = S_IWUSR >> 3;
    const S_IXGRP   = S_IXUSR >> 3;
    const S_IRWXG   = S_IRWXU >> 3;

    const S_IROTH   = S_IRGRP >> 3;
    const S_IWOTH   = S_IWGRP >> 3;
    const S_IXOTH   = S_IXGRP >> 3;
    const S_IRWXO   = S_IRWXG >> 3;

    const S_ISUID   = 04000;
    const S_ISGID   = 02000;
    const S_ISVTX   = 01000;

    private
    {
        extern (D) bool S_ISTYPE( mode_t mode, uint mask )
        {
            return ( mode & S_IFMT ) == mask;
        }
    }

    extern (D) bool S_ISBLK( mode_t mode )  { return S_ISTYPE( mode, S_IFBLK );  }
    extern (D) bool S_ISCHR( mode_t mode )  { return S_ISTYPE( mode, S_IFCHR );  }
    extern (D) bool S_ISDIR( mode_t mode )  { return S_ISTYPE( mode, S_IFDIR );  }
    extern (D) bool S_ISFIFO( mode_t mode ) { return S_ISTYPE( mode, S_IFIFO );  }
    extern (D) bool S_ISREG( mode_t mode )  { return S_ISTYPE( mode, S_IFREG );  }
    extern (D) bool S_ISLNK( mode_t mode )  { return S_ISTYPE( mode, S_IFLNK );  }
    extern (D) bool S_ISSOCK( mode_t mode ) { return S_ISTYPE( mode, S_IFSOCK ); }

    static if( true /*__USE_POSIX199309*/ )
    {
        extern bool S_TYPEISMQ( stat_t* buf )  { return false; }
        extern bool S_TYPEISSEM( stat_t* buf ) { return false; }
        extern bool S_TYPEISSHM( stat_t* buf ) { return false; }
    }
}
else version( darwin )
{
    struct stat_t
    {
        dev_t       st_dev;
        ino_t       st_ino;
        mode_t      st_mode;
        nlink_t     st_nlink;
        uid_t       st_uid;
        gid_t       st_gid;
        dev_t       st_rdev;
        time_t      st_atime;
        c_ulong     st_atimensec;
        time_t      st_mtime;
        c_ulong     st_mtimensec;
        time_t      st_ctime;
        c_ulong     st_ctimensec;
        off_t       st_size;
        blkcnt_t    st_blocks;
        blksize_t   st_blksize;
        uint        st_flags;
        uint        st_gen;
        int         st_lspare;
        long[2]     st_qspare;
    }

    const S_IRUSR   = 0400;
    const S_IWUSR   = 0200;
    const S_IXUSR   = 0100;
    const S_IRWXU   = S_IRUSR | S_IWUSR | S_IXUSR;

    const S_IRGRP   = S_IRUSR >> 3;
    const S_IWGRP   = S_IWUSR >> 3;
    const S_IXGRP   = S_IXUSR >> 3;
    const S_IRWXG   = S_IRWXU >> 3;

    const S_IROTH   = S_IRGRP >> 3;
    const S_IWOTH   = S_IWGRP >> 3;
    const S_IXOTH   = S_IXGRP >> 3;
    const S_IRWXO   = S_IRWXG >> 3;

    const S_ISUID   = 04000;
    const S_ISGID   = 02000;
    const S_ISVTX   = 01000;

    private
    {
        extern (D) bool S_ISTYPE( mode_t mode, uint mask )
        {
            return ( mode & S_IFMT ) == mask;
        }
    }

    extern (D) bool S_ISBLK( mode_t mode )  { return S_ISTYPE( mode, S_IFBLK );  }
    extern (D) bool S_ISCHR( mode_t mode )  { return S_ISTYPE( mode, S_IFCHR );  }
    extern (D) bool S_ISDIR( mode_t mode )  { return S_ISTYPE( mode, S_IFDIR );  }
    extern (D) bool S_ISFIFO( mode_t mode ) { return S_ISTYPE( mode, S_IFIFO );  }
    extern (D) bool S_ISREG( mode_t mode )  { return S_ISTYPE( mode, S_IFREG );  }
    extern (D) bool S_ISLNK( mode_t mode )  { return S_ISTYPE( mode, S_IFLNK );  }
    extern (D) bool S_ISSOCK( mode_t mode ) { return S_ISTYPE( mode, S_IFSOCK ); }
}
else version( freebsd )
{
    struct stat_t
    {
        dev_t   st_dev;
        ino_t   st_ino;
        mode_t  st_mode;
        nlink_t st_nlink;
        uid_t   st_uid;
        gid_t   st_gid;
        dev_t   st_rdev;
        time_t  st_atime;
        c_ulong st_atimensec;
        time_t  st_mtime;
        c_ulong st_mtimensec;
        time_t  st_ctime;
        c_ulong st_ctimensec;
    /*  Defined in C as:
        timespec    st_atimespec;
        timespec    st_mtimespec;
        timespec    st_ctimespec; */
        off_t       st_size;
        blkcnt_t    st_blocks;
        blksize_t   st_blksize;
        fflags_t    st_flags;
        uint        st_gen;
        int         st_lspare;
        timespec    st_birthtimespec;

        byte[16 - timespec.sizeof] padding;
    }

    const S_IRUSR   = 0000400;
    const S_IWUSR   = 0000200;
    const S_IXUSR   = 0000100;
    const S_IRWXU   = 0000700;

    const S_IRGRP   = 0000040;
    const S_IWGRP   = 0000020;
    const S_IXGRP   = 0000010;
    const S_IRWXG   = 0000070;

    const S_IROTH   = 0000004;
    const S_IWOTH   = 0000002;
    const S_IXOTH   = 0000001;
    const S_IRWXO   = 0000007;

    const S_ISUID   = 0004000;
    const S_ISGID   = 0002000;
    const S_ISVTX   = 0001000;

    private
    {
        extern (D) bool S_ISTYPE( mode_t mode, uint mask )
        {
            return ( mode & S_IFMT ) == mask;
        }
    }

    extern (D) bool S_ISBLK( mode_t mode )  { return S_ISTYPE( mode, S_IFBLK );  }
    extern (D) bool S_ISCHR( mode_t mode )  { return S_ISTYPE( mode, S_IFCHR );  }
    extern (D) bool S_ISDIR( mode_t mode )  { return S_ISTYPE( mode, S_IFDIR );  }
    extern (D) bool S_ISFIFO( mode_t mode ) { return S_ISTYPE( mode, S_IFIFO );  }
    extern (D) bool S_ISREG( mode_t mode )  { return S_ISTYPE( mode, S_IFREG );  }
    extern (D) bool S_ISLNK( mode_t mode )  { return S_ISTYPE( mode, S_IFLNK );  }
    extern (D) bool S_ISSOCK( mode_t mode ) { return S_ISTYPE( mode, S_IFSOCK ); }
}
else version( solaris )
{
    const _ST_FSTYPSZ = 16;     /* array size for file system type name */
    
    struct stat_t
    {
        version (X86_64)
        {
            dev_t               st_dev;
            ino_t               st_ino;
            mode_t              st_mode;
            nlink_t             st_nlink;
            uid_t               st_uid;
            gid_t               st_gid;
            dev_t               st_rdev;
            off_t               st_size;
            
            time_t              st_atime;
            c_ulong             st_atimensec;
            time_t              st_mtime;
            c_ulong             st_mtimensec;
            time_t              st_ctime;
            c_ulong             st_ctimensec;
        /*  Defined in C as:
            timespec            st_atim;
            timespec            st_mtim;
            timespec            st_ctim; */
            blksize_t           st_blksize;
            blkcnt_t            st_blocks;
            char[_ST_FSTYPSZ]   st_fstype;
        }
        else
        {
            dev_t               st_dev;
            c_long[3]           st_pad1;    /* reserved for network id */
            ino_t               st_ino;
            mode_t              st_mode;
            nlink_t             st_nlink;
            uid_t               st_uid;
            gid_t               st_gid;
            dev_t               st_rdev;
            c_long[2]           st_pad2;
            off_t               st_size;
          static if( !__USE_LARGEFILE64 ) {
            c_long              st_pad3;    /* future off_t expansion */
          } 
            time_t              st_atime;
            c_ulong             st_atimensec;
            time_t              st_mtime;
            c_ulong             st_mtimensec;
            time_t              st_ctime;
            c_ulong             st_ctimensec;
        /*  Defined in C as:
            timespec            st_atim;
            timespec            st_mtim;
            timespec            st_ctim; */
            blksize_t           st_blksize;
            blkcnt_t            st_blocks;
            char[_ST_FSTYPSZ]   st_fstype;
            c_long[8]           st_pad4;    /* expansion area */
        }
    }
    
    /* MODE MASKS */
  enum {
    /* de facto standard definitions */
    S_IFMT      = 0xF000,   /* type of file */
    S_IAMB      = 0x1FF,    /* access mode bits */
    S_IFIFO     = 0x1000,   /* fifo */
    S_IFCHR     = 0x2000,   /* character special */
    S_IFDIR     = 0x4000,   /* directory */
    /* XENIX definitions are not relevant to Solaris */
    S_IFNAM     = 0x5000,   /* XENIX special named file */
    S_INSEM     = 0x1,      /* XENIX semaphore subtype of IFNAM */
    S_INSHD     = 0x2,      /* XENIX shared data subtype of IFNAM */
    S_IFBLK     = 0x6000,   /* block special */
    S_IFREG     = 0x8000,   /* regular */
    S_IFLNK     = 0xA000,   /* symbolic link */
    S_IFSOCK    = 0xC000,   /* socket */
    S_IFDOOR    = 0xD000,   /* door */
    S_IFPORT    = 0xE000,   /* event port */
    S_ISUID     = 0x800,    /* set user id on execution */
    S_ISGID     = 0x400,    /* set group id on execution */
    S_ISVTX     = 0x200,    /* save swapped text even after use */
    S_IREAD     = 00400,    /* read permission, owner */
    S_IWRITE    = 00200,    /* write permission, owner */
    S_IEXEC     = 00100,    /* execute/search permission, owner */
    S_ENFMT     = S_ISGID,  /* record locking enforcement flag */

    S_IRWXU     = 00700,    /* read, write, execute: owner */
    S_IRUSR     = 00400,    /* read permission: owner */
    S_IWUSR     = 00200,    /* write permission: owner */
    S_IXUSR     = 00100,    /* execute permission: owner */
    S_IRWXG     = 00070,    /* read, write, execute: group */
    S_IRGRP     = 00040,    /* read permission: group */
    S_IWGRP     = 00020,    /* write permission: group */
    S_IXGRP     = 00010,    /* execute permission: group */
    S_IRWXO     = 00007,    /* read, write, execute: other */
    S_IROTH     = 00004,    /* read permission: other */
    S_IWOTH     = 00002,    /* write permission: other */
    S_IXOTH     = 00001     /* execute permission: other */
  }

    extern (D) bool S_ISFIFO(mode_t mode)   { return (mode & 0xF000) == 0x1000; }
    extern (D) bool S_ISCHR(mode_t mode)    { return (mode & 0xF000) == 0x2000; }
    extern (D) bool S_ISDIR(mode_t mode)    { return (mode & 0xF000) == 0x4000; }
    extern (D) bool S_ISBLK(mode_t mode)    { return (mode & 0xF000) == 0x6000; }
    extern (D) bool S_ISREG(mode_t mode)    { return (mode & 0xF000) == 0x8000; }
    extern (D) bool S_ISLNK(mode_t mode)    { return (mode & 0xF000) == 0xa000; }
    extern (D) bool S_ISSOCK(mode_t mode)   { return (mode & 0xF000) == 0xc000; }
    extern (D) bool S_ISDOOR(mode_t mode)   { return (mode & 0xF000) == 0xd000; }
    extern (D) bool S_ISPORT(mode_t mode)   { return (mode & 0xF000) == 0xe000; }

}

int    chmod(in char*, mode_t);
int    fchmod(int, mode_t);
//int    fstat(int, stat_t*);
//int    lstat(in char*, stat_t*);
int    mkdir(in char*, mode_t);
int    mkfifo(in char*, mode_t);
//int    stat(in char*, stat_t*);
mode_t umask(mode_t);

static if (__USE_LARGEFILE64)
{
    int   fstat64(int, stat_t*);
    alias fstat64 fstat;

    int   lstat64(in char*, stat_t*);
    alias lstat64 lstat;

    int   stat64(in char*, stat_t*);
    alias stat64 stat;
}
else
{
    int   fstat(int, stat_t*);
    int   lstat(in char*, stat_t*);
    int   stat(in char*, stat_t*);
}

//
// Typed Memory Objects (TYM)
//
/*
S_TYPEISTMO(buf)
*/

//
// XOpen (XSI)
//
/*
S_IFMT
S_IFBLK
S_IFCHR
S_IFIFO
S_IFREG
S_IFDIR
S_IFLNK
S_IFSOCK

int mknod(in 3char*, mode_t, dev_t);
*/

version( linux )
{
    const S_IFMT    = 0170000;
    const S_IFBLK   = 0060000;
    const S_IFCHR   = 0020000;
    const S_IFIFO   = 0010000;
    const S_IFREG   = 0100000;
    const S_IFDIR   = 0040000;
    const S_IFLNK   = 0120000;
    const S_IFSOCK  = 0140000;

    int mknod(in char*, mode_t, dev_t);
}
else version( darwin )
{
    const S_IFMT    = 0170000;
    const S_IFBLK   = 0060000;
    const S_IFCHR   = 0020000;
    const S_IFIFO   = 0010000;
    const S_IFREG   = 0100000;
    const S_IFDIR   = 0040000;
    const S_IFLNK   = 0120000;
    const S_IFSOCK  = 0140000;

    int mknod(in char*, mode_t, dev_t);
}
else version( freebsd )
{
    const S_IFMT    = 0170000;
    const S_IFBLK   = 0060000;
    const S_IFCHR   = 0020000;
    const S_IFIFO   = 0010000;
    const S_IFREG   = 0100000;
    const S_IFDIR   = 0040000;
    const S_IFLNK   = 0120000;
    const S_IFSOCK  = 0140000;

    int mknod(in char*, mode_t, dev_t);
}
else version( solaris )
{
    // Constants defined above
    int mknod(in char*, mode_t, dev_t);
}

/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.stat;

private import tango.stdc.config;
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

int    chmod(char*, mode_t);
int    fchmod(int, mode_t);
int    fstat(int, stat*);
int    lstat(char*, stat*);
int    mkdir(char*, mode_t);
int    mkfifo(char*, mode_t);
int    stat(char*, stat*);
mode_t umask(mode_t);
*/

version( linux )
{
    struct stat
    {
        dev_t       st_dev;
        ushort      __pad1;
      static if( false /*__USE_FILE_OFFSET64*/ )
      {
        ino_t       __st_ino;
      }
      else
      {
        ino_t       st_ino;
      }
        mode_t      st_mode;
        nlink_t     st_nlink;
        uid_t       st_uid;
        gid_t       st_gid;
        dev_t       st_rdev;
        ushort      __pad2;
        off_t       st_size;
        blksize_t   st_blksize;
        blkcnt_t    st_blocks;
      static if( false /*__USE_MISC*/ ) // true if _BSD_SOURCE || _SVID_SOURCE
      {
        /* Nanosecond resolution timestamps are stored in a format
        equivalent to 'struct timespec'.  This is the type used
        whenever possible but the Unix namespace rules do not allow the
        identifier 'timespec' to appear in the <sys/stat.h> header.
        Therefore we have to handle the use of this header in strictly
        standard-compliant sources special. */
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
      static if( false /*__USE_FILE_OFFSET64*/ )
      {
        ino_t       st_ino;
      }
      else
      {
        c_ulong     __unused4;
        c_ulong     __unused5;
      }
    }

    const auto S_IRUSR = 0400;
    const auto S_IWUSR = 0200;
    const auto S_IXUSR = 0100;
    const auto S_IRWXU = S_IRUSR | S_IWUSR | S_IXUSR;

    const auto S_IRGRP = S_IRUSR >> 3;
    const auto S_IWGRP = S_IWUSR >> 3;
    const auto S_IXGRP = S_IXUSR >> 3;
    const auto S_IRWXG = S_IRWXU >> 3;

    const auto S_IROTH = S_IRGRP >> 3;
    const auto S_IWOTH = S_IWGRP >> 3;
    const auto S_IXOTH = S_IXGRP >> 3;
    const auto S_IRWXO = S_IRWXG >> 3;

    const auto S_ISUID = 04000;
    const auto S_ISGID = 02000;
    const auto S_ISVTX = 01000;

    private
    {
        const auto S_IFDIR  = 0040000;
        const auto S_IFCHR  = 0020000;
        const auto S_IFBLK  = 0060000;
        const auto S_IFREG  = 0100000;
        const auto S_IFIFO  = 0010000;
        const auto S_IFLNK  = 0120000;
        const auto S_IFSOCK = 0140000;

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
        extern bool S_TYPEISMQ( stat* buf )  { return false; }
        extern bool S_TYPEISSEM( stat* buf ) { return false; }
        extern bool S_TYPEISSHM( stat* buf ) { return false; }
    }
}
else version( darwin )
{
    struct stat
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
        long        st_qspare[2];
    }
}

int    chmod(char*, mode_t);
int    fchmod(int, mode_t);
int    fstat(int, stat*);
int    lstat(char*, stat*);
int    mkdir(char*, mode_t);
int    mkfifo(char*, mode_t);
int    stat(char*, stat*);
mode_t umask(mode_t);

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

int mknod(char*, mode_t, dev_t);
*/

version( darwin )
{
    const auto S_IFMT   = 0170000;
    const auto S_IFBLK  = 0060000;
    const auto S_IFCHR  = 0020000;
    const auto S_IFIFO  = 0010000;
    const auto S_IFREG  = 0100000;
    const auto S_IFDIR  = 0040000;
    const auto S_IFLNK  = 0120000;
    const auto S_IFSOCK = 0140000;

    int mknod(char*, mode_t, dev_t);
}
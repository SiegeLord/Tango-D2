/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.fcntl;

private import tango.stdc.posix.config;
private import tango.stdc.stdint;
public import tango.stdc.stddef;          // for size_t
public import tango.stdc.posix.sys.types; // for off_t, mode_t
public import tango.stdc.posix.sys.stat;  // for S_IFMT, etc.
public import tango.sys.consts.fcntl;
extern (C):

//
// Required
//
/*
F_DUPFD
F_GETFD
F_SETFD
F_GETFL
F_SETFL
F_GETLK
F_SETLK
F_SETLKW
F_GETOWN
F_SETOWN

FD_CLOEXEC

F_RDLCK
F_UNLCK
F_WRLCK

O_CREAT
O_EXCL
O_NOCTTY
O_TRUNC

O_APPEND
O_DSYNC
O_NONBLOCK
O_RSYNC
O_SYNC

O_ACCMODE
O_RDONLY
O_RDWR
O_WRONLY

struct flock
{
    short   l_type;
    short   l_whence;
    off_t   l_start;
    off_t   l_len;
    pid_t   l_pid;
}

int creat(in char*, mode_t);
int fcntl(int, int, ...);
int open(in char*, int, ...);
*/
version( linux )
{

    struct flock
    {
        short   l_type;
        short   l_whence;
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
    }

    static if( __USE_LARGEFILE64 )
    {
        int   creat64(in char*, mode_t);
        alias creat64 creat;

        int   open64(in char*, int, ...);
        alias open64 open;
    }
    else
    {
        int   creat(in char*, mode_t);
        int   open(in char*, int, ...);
    }
}
else version( darwin )
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version( FreeBSD )
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version( solaris )
{
    struct flock
    {
        short   l_type;
        short   l_whence;
        off_t   l_start;
        off_t   l_len;      /* len == 0 means until end of file */
        int     l_sysid;
        pid_t   l_pid;
        c_long[4] l_pad;       /* reserve area */
    }
    
    int creat(in char*, mode_t);
    int open(in char*, int, ...);

    static if( __USE_LARGEFILE64 )
    {
        alias creat creat64;
        alias open  open64;
    }
}

//int creat(in char*, mode_t);
int fcntl(int, int, ...);
//int open(in char*, int, ...);

//
// Advisory Information (ADV)
//
/*
POSIX_FADV_NORMAL
POSIX_FADV_SEQUENTIAL
POSIX_FADV_RANDOM
POSIX_FADV_WILLNEED
POSIX_FADV_DONTNEED
POSIX_FADV_NOREUSE

int posix_fadvise(int, off_t, off_t, int);
int posix_fallocate(int, off_t, off_t);
*/

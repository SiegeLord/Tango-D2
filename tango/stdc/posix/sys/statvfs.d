/**
*    statvfs - VFS File System information structure
* from sys/statvfs.h
* http://www.opengroup.org/onlinepubs/009695399/basedefs/sys/statvfs.h.html
*
* Copyright: Fawzi Mohamed 
* License:   tango license
* Authors:   Fawzi Mohamed
*/

module tango.stdc.posix.sys.statvfs;
import tango.stdc.config;
/+
// possible errno:
    public import tango.sys.consts.errno:
    EACCES, // (statfs()) Search permission is denied for a component of the path prefix of path. (See also path_resolution(2).) 
    EBADF, // (fstatfs()) fd is not a valid open file descriptor. 
    EFAULT, // buf or path points to an invalid address. 
    EINTR, // This call was interrupted by a signal. 
    EIO, // An I/O error occurred while reading from the file system. 
    ELOOP, // (statfs()) Too many symbolic links were encountered in translating path. 
    ENAMETOOLONG, // (statfs()) path is too long. 
    ENOENT, // (statfs()) The file referred to by path does not exist. 
    ENOMEM, // Insufficient kernel memory was available. 
    ENOSYS, // The file system does not support this call. 
    ENOTDIR, // (statfs()) A component of the path prefix of path is not a directory. 
    EOVERFLOW // Some values were too large to be represented in the returned struct.
;
+/

version(darwin) {

    struct statvfs_t {
     c_ulong f_bsize;
     c_ulong f_frsize;
     uint f_blocks;
     uint f_bfree;
     uint f_bavail;
     uint f_files;
     uint f_ffree;
     uint f_favail;
     c_ulong f_fsid;
     c_ulong f_flag;
     c_ulong f_namemax;
    }

    enum{
        ST_RDONLY=0x00000001,
        ST_NOSUID=0x00000002,
    }
}

version( FreeBSD )
{
    alias ulong __fsblkcnt_t, __fsfilcnt_t;
    struct statvfs_t {
        __fsblkcnt_t      f_bavail;       /* Number of blocks */
        __fsblkcnt_t      f_bfree;
        __fsblkcnt_t      f_blocks;
        __fsfilcnt_t      f_favail;       /* Number of files (e.g., inodes) */
        __fsfilcnt_t      f_ffree;
        __fsfilcnt_t      f_files;
        c_ulong   f_bsize;        /* Size of blocks counted above */
        c_ulong  f_flag;
        c_ulong   f_frsize;       /* Size of fragments */
        c_ulong   f_fsid;         /* Not meaningful */
        c_ulong   f_namemax;      /* Same as pathconf(_PC_NAME_MAX) */
    }
    enum {
        ST_RDONLY = 1,
        ST_NOSUID = 2,
    }
}

version(linux){
    struct statvfs_t
      {
        c_ulong f_bsize;
        c_ulong f_frsize;
        c_ulong f_blocks;
        c_ulong f_bfree;
        c_ulong f_bavail;
        c_ulong f_files;
        c_ulong f_ffree;
        c_ulong f_favail;
        c_ulong f_fsid;
        c_ulong f_flag;
        c_ulong f_namemax;
        int __f_spare[6];
      };
    enum
    {
      ST_RDONLY = 1,
      ST_NOSUID = 2,
    }    
}

version(solaris)
{
    const _FSTYPSZ = 16;

    alias c_ulong fsblkcnt_t;
    alias c_ulong fsfilcnt_t;

    struct statvfs_t {
        c_ulong f_bsize; /* fundamental file system block size */
        c_ulong f_frsize; /* fragment size */
        fsblkcnt_t f_blocks; /* total blocks of f_frsize on fs */
        fsblkcnt_t f_bfree; /* total free blocks of f_frsize */
        fsblkcnt_t f_bavail; /* free blocks avail to non-superuser */
        fsfilcnt_t f_files; /* total file nodes (inodes) */
        fsfilcnt_t f_ffree; /* total free file nodes */
        fsfilcnt_t f_favail; /* free nodes avail to non-superuser */
        c_ulong f_fsid;  /* file system id (dev for now) */
        char[_FSTYPSZ]  f_basetype; /* target fs type name, */
                                                        /* null-terminated */
        c_ulong f_flag;  /* bit-mask of flags */
        c_ulong f_namemax; /* maximum file name length */
        char[32] f_fstr; /* filesystem-specific string */
        static if(size_t.sizeof == 8) //#if !defined(_LP64)
        {
            c_ulong[16]  f_filler; /* reserved for future expansion */
        }
	};

    enum
    {
        ST_RDONLY = 1,
        ST_NOSUID = 2,
    }
}

extern(C){
    int fstatvfs(int, statvfs_t *);
    int statvfs(in char * , statvfs_t *);
}

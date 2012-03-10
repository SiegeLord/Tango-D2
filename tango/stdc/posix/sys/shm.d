/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.shm;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for pid_t, time_t, key_t, size_t
public import tango.stdc.posix.sys.ipc;
private import tango.core.Octal;
extern (C):

//
// XOpen (XSI)
//
/*
SHM_RDONLY
SHM_RND

SHMLBA

shmatt_t

struct shmid_ds
{
    ipc_perm    shm_perm;
    size_t      shm_segsz;
    pid_t       shm_lpid;
    pid_t       shm_cpid;
    shmatt_t    shm_nattch;
    time_t      shm_atime;
    time_t      shm_dtime;
    time_t      shm_ctime;
}

void* shmat(int, in void*, int);
int   shmctl(int, int, shmid_ds*);
int   shmdt(in void*);
int   shmget(key_t, size_t, int);
*/

version( linux )
{
    const SHM_RDONLY    = octal!10000;
    const SHM_RND       = octal!20000;

    int   __getpagesize();
    alias __getpagesize SHMLBA;

    alias c_ulong   shmatt_t;

    struct shmid_ds
    {
        ipc_perm    shm_perm;
        size_t      shm_segsz;
        time_t      shm_atime;
        c_ulong     __unused1;
        time_t      shm_dtime;
        c_ulong     __unused2;
        time_t      shm_ctime;
        c_ulong     __unused3;
        pid_t       shm_cpid;
        pid_t       shm_lpid;
        shmatt_t    shm_nattch;
        c_ulong     __unused4;
        c_ulong     __unused5;
    }

    void* shmat(int, in void*, int);
    int   shmctl(int, int, shmid_ds*);
    int   shmdt(in void*);
    int   shmget(key_t, size_t, int);
}
else version( FreeBSD )
{
    const SHM_RDONLY    = octal!10000;
    const SHM_RND       = octal!20000;
	const SHMLBA		= 1 << 12; // PAGE_SIZE = (1<<PAGE_SHIFT)

    alias c_ulong   shmatt_t;

    struct shmid_ds
    {
        ipc_perm    shm_perm;
        size_t      shm_segsz;
        time_t      shm_atime;
        c_ulong     __unused1;
        time_t      shm_dtime;
        c_ulong     __unused2;
        time_t      shm_ctime;
        c_ulong     __unused3;
        pid_t       shm_cpid;
        pid_t       shm_lpid;
        shmatt_t    shm_nattch;
        c_ulong     __unused4;
        c_ulong     __unused5;
    }

    void* shmat(int, in void*, int);
    int   shmctl(int, int, shmid_ds*);
    int   shmdt(in void*);
    int   shmget(key_t, size_t, int);
}
else version( darwin )
{

}
else version( solaris )
{
	private const _SC_PAGESIZE = 11; // from <sys/unistd.h>
	private c_long _sysconf(int);
	
    const SHM_RDONLY    = octal!10000;
    const SHM_RND       = octal!20000;
	const SHM_SHARE_MMU = octal!40000;
	const SHM_PAGEABLE	= octal!100000; /* pageable ISM */
	extern(D) c_long SHMLBA(){ return _sysconf(_SC_PAGESIZE); };
	
	alias c_ulong   shmatt_t;
	
	struct shmid_ds
	{
		ipc_perm	shm_perm;	/* operation permission struct */
		size_t		shm_segsz;	/* size of segment in bytes */
		void*		shm_amp;	/* segment anon_map pointer */
		ushort		shm_lkcnt;	/* number of times it is being locked */
		pid_t		shm_lpid;	/* pid of last shmop */
		pid_t		shm_cpid;	/* pid of creator */
		shmatt_t	shm_nattch;	/* number of attaches */
		ulong		shm_cnattch;/* number of ISM attaches */
	  version(X86_64) {
		time_t		shm_atime;	/* last shmat time */
		time_t		shm_dtime;	/* last shmdt time */
		time_t		shm_ctime;	/* last change time */
		long[4]		shm_pad4;	/* reserve area */
	  } else {
		time_t		shm_atime;	/* last shmat time */
		int			shm_pad1;	/* reserved for time_t expansion */
		time_t		shm_dtime;	/* last shmdt time */
		int			shm_pad2;	/* reserved for time_t expansion */
		time_t		shm_ctime;	/* last change time */
		int			shm_pad3;	/* reserved for time_t expansion */
		int[4]		shm_pad4;	/* reserve area  */
	  }
	}
	
    void* shmat(int, in void*, int);
    int   shmctl(int, int, shmid_ds*);
    int   shmdt(in void*);
    int   shmget(key_t, size_t, int);
}

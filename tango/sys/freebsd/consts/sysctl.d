module tango.sys.freebsd.consts.sysctl;


/*
 * Definitions for sysctl call.  The sysctl call uses a hierarchical name
 * for objects that can be examined or modified.  The name is expressed as
 * a sequence of integers.  Like a file path name, the meaning of each
 * component depends on its place in the hierarchy.  The top-level and kern
 * identifiers are defined here, and other identifiers are defined in the
 * respective subsystem header files.
 */



/*
 * Each subsystem defined by sysctl defines a list of variables
 * for that subsystem. Each name is either a node with further
 * levels defined below it, or it is a leaf of some particular
 * type given below. Each sysctl level defines a set of name/type
 * pairs to be used by sysctl(8) in manipulating the subsystem.
 */
struct ctlname {
    char* ctl_name; /* subsystem name */
    int ctl_type; /* type of name */
};

enum SysCtl {
    CTL_MAXNAME = 24,    /* largest number of components supported */

    CTLTYPE = 0xf,    /* Mask for the type */
    CTLTYPE_NODE = 1,    /* name is a node */
    CTLTYPE_INT = 2,    /* name describes an integer */
    CTLTYPE_STRING = 3,    /* name describes a string */
    CTLTYPE_QUAD = 4,    /* name describes a 64-bit number */
    CTLTYPE_OPAQUE = 5,    /* name describes a structure */
    CTLTYPE_STRUCT = CTLTYPE_OPAQUE,    /* name describes a structure */
    CTLTYPE_UINT = 6,    /* name describes an unsigned integer */
    CTLTYPE_LONG = 7,    /* name describes a long */
    CTLTYPE_ULONG = 8,    /* name describes an unsigned long */

    CTLFLAG_RD = 0x80000000,    /* Allow reads of variable */
    CTLFLAG_WR = 0x40000000,    /* Allow writes to the variable */
    CTLFLAG_RW = (CTLFLAG_RD|CTLFLAG_WR),
    CTLFLAG_NOLOCK = 0x20000000,    /* XXX Don't Lock */
    CTLFLAG_ANYBODY = 0x10000000,    /* All users can set this var */
    CTLFLAG_SECURE = 0x08000000,    /* Permit set only if securelevel<=0 */
    CTLFLAG_PRISON = 0x04000000,    /* Prisoned roots can fiddle */
    CTLFLAG_DYN = 0x02000000,    /* Dynamic oid - can be freed */
    CTLFLAG_SKIP = 0x01000000,    /* Skip this sysctl when listing */
    CTLMASK_SECURE = 0x00F00000,    /* Secure level */
    CTLFLAG_TUN = 0x00080000,    /* Tunable variable */
    CTLFLAG_MPSAFE = 0x00040000,    /* Handler is MP safe */
    CTLFLAG_RDTUN = (CTLFLAG_RD|CTLFLAG_TUN),

/*
 * Secure level.   Note that CTLFLAG_SECURE == CTLFLAG_SECURE1.  
 *
 * Secure when the securelevel is raised to at least N.
 */
    CTLSHIFT_SECURE = 20,
    CTLFLAG_SECURE1 = (CTLFLAG_SECURE | (0 << CTLSHIFT_SECURE)),
    CTLFLAG_SECURE2 = (CTLFLAG_SECURE | (1 << CTLSHIFT_SECURE)),
    CTLFLAG_SECURE3 = (CTLFLAG_SECURE | (2 << CTLSHIFT_SECURE)),

/*
 * USE THIS instead of a hardwired number from the categories below
 * to get dynamically assigned sysctl entries using the linker-set
 * technology. This is the way nearly all new sysctl variables should
 * be implemented.
 * e.g. SYSCTL_INT(_parent, OID_AUTO, name, CTLFLAG_RW, &variable, 0, "");
 */ 
    OID_AUTO = (-1),

/*
 * The starting number for dynamically-assigned entries.  WARNING!
 * ALL static sysctl entries should have numbers LESS than this!
 */
    CTL_AUTO_START = 0x100,

/*
 * Top-level identifiers
 */
    CTL_UNSPEC = 0,	 /* unused */
    CTL_KERN = 1,	 /* "high kernel": proc, limits */
    CTL_VM = 2,	 /* virtual memory */
    CTL_VFS = 3,	 /* filesystem, mount type is next */
    CTL_NET = 4,	 /* network, see socket.h */
    CTL_DEBUG = 5,	 /* debugging parameters */
    CTL_HW = 6,	 /* generic cpu/io */
    CTL_MACHDEP = 7,	 /* machine dependent */
    CTL_USER = 8,	 /* user-level */
    CTL_P1003_1B = 9,	 /* POSIX 1003.1B */
    CTL_MAXID = 10,	 /* number of valid top-level ids */


/*
 * CTL_KERN identifiers
 */
    KERN_OSTYPE = 1,    /* string: system version */
    KERN_OSRELEASE = 2,    /* string: system release */
    KERN_OSREV = 3,    /* int: system revision */
    KERN_VERSION = 4,    /* string: compile time info */
    KERN_MAXVNODES =  5,    /* int: max vnodes */
    KERN_MAXPROC = 6,    /* int: max processes */
    KERN_MAXFILES = 7,    /* int: max open files */
    KERN_ARGMAX = 8,    /* int: max arguments to exec */
    KERN_SECURELVL = 9,    /* int: system security level */
    KERN_HOSTNAME = 10,    /* string: hostname */
    KERN_HOSTID = 11,    /* int: host identifier */
    KERN_CLOCKRATE = 12,    /* struct: struct clockrate */
    KERN_VNODE = 13,    /* struct: vnode structures */
    KERN_PROC = 14,    /* struct: process entries */
    KERN_FILE = 15,    /* struct: file entries */
    KERN_PROF = 16,    /* node: kernel profiling info */
    KERN_POSIX1 = 17,    /* int: POSIX.1 version */
    KERN_NGROUPS = 18,    /* int: # of supplemental group ids */
    KERN_JOB_CONTROL = 19,    /* int: is job control available */
    KERN_SAVED_IDS = 20,    /* int: saved set-user/group-ID */
    KERN_BOOTTIME = 21,    /* struct: time kernel was booted */
    KERN_NISDOMAINNAME = 22,    /* string: YP domain name */
    KERN_UPDATEINTERVAL = 23,    /* int: update process sleep time */
    KERN_OSRELDATE = 24,    /* int: kernel release date */
    KERN_NTP_PLL = 25,    /* node: NTP PLL control */
    KERN_BOOTFILE = 26,    /* string: name of booted kernel */
    KERN_MAXFILESPERPROC = 27,    /* int: max open files per proc */
    KERN_MAXPROCPERUID = 28,    /* int: max processes per uid */
    KERN_DUMPDEV = 29,    /* struct cdev *: device to dump on */
    KERN_IPC = 30,    /* node: anything related to IPC */
    KERN_DUMMY = 31,    /* unused */
    KERN_PS_STRINGS = 32,    /* int: address of PS_STRINGS */
    KERN_USRSTACK	 = 33,    /* int: address of USRSTACK */
    KERN_LOGSIGEXIT = 34,    /* int: do we log sigexit procs? */
    KERN_IOV_MAX = 35,    /* int: value of UIO_MAXIOV */
    KERN_HOSTUUID = 36,    /* string: host UUID identifier */
    KERN_ARND = 37,    /* int: from arc4rand() */
    KERN_MAXID = 38,    /* number of valid kern ids */

/*
 * KERN_PROC subtypes
 */
    KERN_PROC_ALL = 0,    /* everything */
    KERN_PROC_PID = 1,    /* by process id */
    KERN_PROC_PGRP = 2,    /* by process group id */
    KERN_PROC_SESSION = 3,    /* by session of pid */
    KERN_PROC_TTY = 4,    /* by controlling tty */
    KERN_PROC_UID = 5,    /* by effective uid */
    KERN_PROC_RUID = 6,    /* by real uid */
    KERN_PROC_ARGS = 7,    /* get/set arguments/proctitle */
    KERN_PROC_PROC = 8,    /* only return procs */
    KERN_PROC_SV_NAME = 9,    /* get syscall vector name */
    KERN_PROC_RGID = 10,    /* by real group id */
    KERN_PROC_GID = 11,    /* by effective group id */
    KERN_PROC_PATHNAME = 12,    /* path to executable */
    KERN_PROC_OVMMAP = 13,    /* Old VM map entries for process */
    KERN_PROC_OFILEDESC = 14,    /* Old file descriptors for process */
    KERN_PROC_KSTACK = 15,    /* Kernel stacks for process */
    KERN_PROC_INC_THREAD = 0x10,    /*
					 * modifier for pid, pgrp, tty,
					 * uid, ruid, gid, rgid and proc
					 * This effectively uses 16-31
					 */
    KERN_PROC_VMMAP = 32,    /* VM map entries for process */
    KERN_PROC_FILEDESC = 33,    /* File descriptors for process */

/*
 * KERN_IPC identifiers
 */
    KIPC_MAXSOCKBUF = 1,    /* int: max size of a socket buffer */
    KIPC_SOCKBUF_WASTE = 2,    /* int: wastage factor in sockbuf */
    KIPC_SOMAXCONN = 3,    /* int: max length of connection q */
    KIPC_MAX_LINKHDR = 4,    /* int: max length of link header */
    KIPC_MAX_PROTOHDR = 5,    /* int: max length of network header */
    KIPC_MAX_HDR = 6,    /* int: max total length of headers */
    KIPC_MAX_DATALEN = 7,    /* int: max length of data? */

/*
 * CTL_HW identifiers
 */
    HW_MACHINE = 1,	 /* string: machine class */
    HW_MODEL	= 2,	 /* string: specific machine model */
    HW_NCPU = 3,	 /* int: number of cpus */
    HW_BYTEORDER = 4,	 /* int: machine byte order */
    HW_PHYSMEM	= 5,	 /* int: total memory */
    HW_USERMEM = 6,	 /* int: non-kernel memory */
    HW_PAGESIZE = 7,	 /* int: software page size */
    HW_DISKNAMES = 8,	 /* strings: disk drive names */
    HW_DISKSTATS = 9,	 /* struct: diskstats[] */
    HW_FLOATINGPT = 10,	 /* int: has HW floating point? */
    HW_MACHINE_ARCH = 11,	 /* string: machine architecture */
    HW_REALMEM = 12,	 /* int: 'real' memory */
    HW_MAXID = 13,	 /* number of valid hw ids */

/*
 * CTL_USER definitions
 */
    USER_CS_PATH = 1,    /* string: _CS_PATH */
    USER_BC_BASE_MAX	= 2,    /* int: BC_BASE_MAX */
    USER_BC_DIM_MAX = 3,    /* int: BC_DIM_MAX */
    USER_BC_SCALE_MAX = 4,    /* int: BC_SCALE_MAX */
    USER_BC_STRING_MAX = 5,    /* int: BC_STRING_MAX */
    USER_COLL_WEIGHTS_MAX = 6,    /* int: COLL_WEIGHTS_MAX */
    USER_EXPR_NEST_MAX = 7,    /* int: EXPR_NEST_MAX */
    USER_LINE_MAX = 8,    /* int: LINE_MAX */
    USER_RE_DUP_MAX = 9,    /* int: RE_DUP_MAX */
    USER_POSIX2_VERSION = 10,    /* int: POSIX2_VERSION */
    USER_POSIX2_C_BIND = 11,    /* int: POSIX2_C_BIND */
    USER_POSIX2_C_DEV = 12,    /* int: POSIX2_C_DEV */
    USER_POSIX2_CHAR_TERM = 13,    /* int: POSIX2_CHAR_TERM */
    USER_POSIX2_FORT_DEV = 14,    /* int: POSIX2_FORT_DEV */
    USER_POSIX2_FORT_RUN = 15,    /* int: POSIX2_FORT_RUN */
    USER_POSIX2_LOCALEDEF = 16,    /* int: POSIX2_LOCALEDEF */
    USER_POSIX2_SW_DEV = 17,    /* int: POSIX2_SW_DEV */
    USER_POSIX2_UPE = 18,    /* int: POSIX2_UPE */
    USER_STREAM_MAX = 19,    /* int: POSIX2_STREAM_MAX */
    USER_TZNAME_MAX = 20,    /* int: POSIX2_TZNAME_MAX */
    USER_MAXID = 21,    /* number of valid user ids */
}


int sysctl(int*, uint , void* , size_t* , void* , size_t);
int sysctlbyname(in char* , void* , size_t* , void* , size_t);
int sysctlnametomib(in char* , int* , size_t*);

module tango.sys.darwin.consts.sysctl;
enum SysCtl{
CTL_MAXNAME = 12 , /* largest number of components supported */
    /+
     + Each subsystem defined by sysctl defines a list of variables
     + for that subsystem. Each name is either a node with further
     + levels defined below it, or it is a leaf of some particular
     + type given below. Each sysctl level defines a set of name/type
     + pairs to be used by sysctl(1) in manipulating the subsystem.
     +
     + When declaring new sysctl names, please use the 0x00800000
     + flag in the type to indicate that all necessary locking will
     + be handled within the sysctl. Any sysctl defined without
     + 0x00800000 is considered legacy and will be protected by
     + both the kernel funnel and the sysctl memlock. This is not
     + optimal, so it is best to handle locking yourself.
     +/
CTLTYPE = 0xf , /* Mask for the type */
CTLTYPE_NODE = 1 , /* name is a node */
CTLTYPE_INT = 2 , /* name describes an integer */
CTLTYPE_STRING = 3, /* name describes a string */
CTLTYPE_QUAD = 4 , /* name describes a 64-bit number */
CTLTYPE_OPAQUE = 5, /* name describes a structure */
CTLTYPE_STRUCT = 5, /* name describes a structure */
CTLFLAG_RD = 0x80000000 , /* Allow reads of variable */
CTLFLAG_WR = 0x40000000 , /* Allow writes to the variable */
CTLFLAG_RW = (0x80000000|0x40000000) ,
CTLFLAG_NOLOCK = 0x20000000 , /* XXX Don't Lock */
CTLFLAG_ANYBODY = 0x10000000, /* All users can set this var */
CTLFLAG_SECURE = 0x08000000 , /* Permit set only if securelevel<=0 */
CTLFLAG_MASKED = 0x04000000 , /* deprecated variable, do not display */
CTLFLAG_NOAUTO = 0x02000000 , /* do not auto-register */
CTLFLAG_KERN = 0x01000000 , /* valid inside the kernel */
CTLFLAG_LOCKED = 0x00800000 , /* node will handle locking itself (highly encouraged) */
    /*
     * USE THIS instead of a hardwired number from the categories below
     * to get dynamically assigned sysctl entries using the linker-set
     * technology. This is the way nearly all new sysctl variables should
     * be implemented.
     *
     * e.g. SYSCTL_INT(_parent, OID_AUTO, name, CTLFLAG_RW, &variable, 0, "");
     *
     * Note that linker set technology will automatically register all nodes
     * declared like this on kernel initialization, UNLESS they are defined
     * in I/O-Kit. In this case, you have to call sysctl_register_oid()
     * manually - just like in a KEXT.
     */
OID_AUTO = (-1) ,
OID_AUTO_START = 100, /* conventional */
    /*
     * Top-level identifiers
     */
CTL_UNSPEC = 0 , /* unused */
CTL_KERN = 1 , /* "high kernel": proc, limits */
CTL_VM = 2 , /* virtual memory */
CTL_VFS = 3 , /* file system, mount type is next */
CTL_NET = 4 , /* network, see socket.h */
CTL_DEBUG = 5 , /* debugging parameters */
CTL_HW = 6 , /* generic cpu/io */
CTL_MACHDEP = 7, /* machine dependent */
CTL_USER = 8 , /* user-level */
CTL_MAXID = 9 , /* number of valid top-level ids */
    /*
     * CTL_KERN identifiers
     */
KERN_OSTYPE = 1 , /* string: system version */
KERN_OSRELEASE = 2 , /* string: system release */
KERN_OSREV = 3 , /* int: system revision */
KERN_VERSION = 4 , /* string: compile time info */
KERN_MAXVNODES = 5 , /* int: max vnodes */
KERN_MAXPROC = 6 , /* int: max processes */
KERN_MAXFILES = 7 , /* int: max open files */
KERN_ARGMAX = 8 , /* int: max arguments to exec */
KERN_SECURELVL = 9 , /* int: system security level */
KERN_HOSTNAME = 10 , /* string: hostname */
KERN_HOSTID = 11 , /* int: host identifier */
KERN_CLOCKRATE = 12 , /* struct: struct clockrate */
KERN_VNODE = 13 , /* struct: vnode structures */
KERN_PROC = 14 , /* struct: process entries */
KERN_FILE = 15 , /* struct: file entries */
KERN_PROF = 16 , /* node: kernel profiling info */
KERN_POSIX1 = 17 , /* int: POSIX.1 version */
KERN_NGROUPS = 18 , /* int: # of supplemental group ids */
KERN_JOB_CONTROL = 19 , /* int: is job control available */
KERN_SAVED_IDS = 20 , /* int: saved set-user/group-ID */
KERN_BOOTTIME = 21 , /* struct: time kernel was booted */
KERN_NISDOMAINNAME = 22 , /* string: YP domain name */
KERN_DOMAINNAME = 22 ,
KERN_MAXPARTITIONS = 23 , /* int: number of partitions/disk */
KERN_KDEBUG = 24 , /* int: kernel trace points */
KERN_UPDATEINTERVAL = 25 , /* int: update process sleep time */
KERN_OSRELDATE = 26 , /* int: OS release date */
KERN_NTP_PLL = 27 , /* node: NTP PLL control */
KERN_BOOTFILE = 28 , /* string: name of booted kernel */
KERN_MAXFILESPERPROC = 29 , /* int: max open files per proc */
KERN_MAXPROCPERUID = 30 , /* int: max processes per uid */
KERN_DUMPDEV = 31 , /* dev_t: device to dump on */
KERN_IPC = 32 , /* node: anything related to IPC */
KERN_DUMMY = 33 , /* unused */
KERN_PS_STRINGS = 34 , /* int: address of PS_STRINGS */
KERN_USRSTACK32 = 35 , /* int: address of USRSTACK */
KERN_LOGSIGEXIT = 36 , /* int: do we log sigexit procs? */
KERN_SYMFILE = 37 , /* string: kernel symbol filename */
KERN_PROCARGS = 38 , /* was KERN_PCSAMPLES... now deprecated */
KERN_NETBOOT = 40 , /* int: are we netbooted? 1=yes,0=no */
KERN_PANICINFO = 41 , /* node: panic UI information */
KERN_SYSV = 42 , /* node: System V IPC information */
KERN_AFFINITY = 43 , /* xxx */
KERN_TRANSLATE = 44 , /* xxx */
KERN_CLASSIC = 44 , /* XXX backwards compat */
KERN_EXEC = 45 , /* xxx */
KERN_CLASSICHANDLER = 45 , /* XXX backwards compatibility */
KERN_AIOMAX = 46 , /* int: max aio requests */
KERN_AIOPROCMAX = 47 , /* int: max aio requests per process */
KERN_AIOTHREADS = 48 , /* int: max aio worker threads */
KERN_COREFILE = 50 , /* string: corefile format string */
KERN_COREDUMP = 51 , /* int: whether to coredump at all */
KERN_SUGID_COREDUMP = 52 , /* int: whether to dump SUGID cores */
KERN_PROCDELAYTERM = 53 , /* int: set/reset current proc for delayed termination during shutdown */
KERN_SHREG_PRIVATIZABLE = 54, /* int: can shared regions be privatized ? */
KERN_PROC_LOW_PRI_IO = 55 , /* int: set/reset current proc for low priority I/O */
KERN_LOW_PRI_WINDOW = 56 , /* int: set/reset throttle window - milliseconds */
KERN_LOW_PRI_DELAY = 57 , /* int: set/reset throttle delay - milliseconds */
KERN_POSIX = 58 , /* node: posix tunables */
KERN_USRSTACK64 = 59 , /* LP64 user stack query */
KERN_NX_PROTECTION = 60 , /* int: whether no-execute protection is enabled */
KERN_TFP = 61 , /* Task for pid settings */
KERN_PROCNAME = 62 , /* setup process program  name(2*MAXCOMLEN) */
KERN_THALTSTACK = 63 , /* for compat with older x86 and does nothing */
KERN_SPECULATIVE_READS = 64 , /* int: whether speculative reads are disabled */
KERN_OSVERSION = 65 , /* for build number i.e. 9A127 */
KERN_SAFEBOOT = 66 , /* are we booted safe? */
KERN_LCTX = 67 , /* node: login context */
KERN_RAGEVNODE = 68 ,
KERN_TTY = 69 , /* node: tty settings */
KERN_CHECKOPENEVT = 70 , /* spi: check the VOPENEVT flag on vnodes at open time */
KERN_MAXID = 71 , /* number of valid kern ids */
    /*                                                  ,
     * Don't add any more sysctls like this.  Instead, use the SYSCTL_*() macros
     * and OID_AUTO. This will have the added benefit of not having to recompile
     * sysctl(8) to pick up your changes.
     */
    /* KERN_RAGEVNODE types */
KERN_RAGE_PROC = 1 ,
KERN_RAGE_THREAD = 2 ,
KERN_UNRAGE_PROC = 3 ,
KERN_UNRAGE_THREAD = 4 ,
    /* KERN_OPENEVT types */
KERN_OPENEVT_PROC = 1 ,
KERN_UNOPENEVT_PROC = 2 ,
    /* KERN_TFP types */
KERN_TFP_POLICY = 1 ,
    /* KERN_TFP_POLICY values . All policies allow task port for self */
KERN_TFP_POLICY_DENY = 0, /* Deny Mode: None allowed except privileged */
KERN_TFP_POLICY_DEFAULT = 2, /* Default  Mode: related ones allowed and upcall authentication */
    /* KERN_KDEBUG types */
KERN_KDEFLAGS = 1 ,
KERN_KDDFLAGS = 2 ,
KERN_KDENABLE = 3 ,
KERN_KDSETBUF = 4 ,
KERN_KDGETBUF = 5 ,
KERN_KDSETUP = 6 ,
KERN_KDREMOVE = 7 ,
KERN_KDSETREG = 8 ,
KERN_KDGETREG = 9 ,
KERN_KDREADTR = 10 ,
KERN_KDPIDTR = 11 ,
KERN_KDTHRMAP = 12 ,
KERN_KDPIDEX = 14 ,
KERN_KDSETRTCDEC = 15 ,
KERN_KDGETENTROPY = 16 ,
    /* KERN_PANICINFO types */
KERN_PANICINFO_MAXSIZE = 1 , /* quad: panic UI image size limit */
KERN_PANICINFO_IMAGE = 2 , /* panic UI in 8-bit kraw format */
    /* 
     * KERN_PROC subtypes
     */
KERN_PROC_ALL = 0 , /* everything */
KERN_PROC_PID = 1 , /* by process id */
KERN_PROC_PGRP = 2 , /* by process group id */
KERN_PROC_SESSION = 3 , /* by session of pid */
KERN_PROC_TTY = 4 , /* by controlling tty */
KERN_PROC_UID = 5 , /* by effective uid */
KERN_PROC_RUID = 6 , /* by real uid */
KERN_PROC_LCID = 7 , /* by login context id */
    /*
     * KERN_LCTX subtypes
     */
KERN_LCTX_ALL = 0 , /* everything */
KERN_LCTX_LCID = 1 , /* by login context id */
    /*
     * KERN_IPC identifiers
     */
KIPC_MAXSOCKBUF = 1 , /* int: max size of a socket buffer */
KIPC_SOCKBUF_WASTE = 2 , /* int: wastage factor in sockbuf */
KIPC_SOMAXCONN = 3 , /* int: max length of connection q */
KIPC_MAX_LINKHDR = 4 , /* int: max length of link header */
KIPC_MAX_PROTOHDR = 5 , /* int: max length of network header */
KIPC_MAX_HDR = 6 , /* int: max total length of headers */
KIPC_MAX_DATALEN = 7 , /* int: max length of data? */
KIPC_MBSTAT = 8 , /* struct: mbuf usage statistics */
KIPC_NMBCLUSTERS = 9 , /* int: maximum mbuf clusters */
KIPC_SOQLIMITCOMPAT = 10 , /* int: socket queue limit */
    /*
     * CTL_VM identifiers
     */
VM_METER = 1 , /* struct vmmeter */
VM_LOADAVG = 2 , /* struct loadavg */
    /*
     * Note: "3" was skipped sometime ago and should probably remain unused
     * to avoid any new entry from being accepted by older kernels...
     */
VM_MACHFACTOR = 4 , /* struct loadavg with mach factor*/
VM_SWAPUSAGE = 5 , /* total swap usage */
VM_MAXID = 6 , /* number of valid vm ids */
    /*
     * CTL_HW identifiers
     */
HW_MACHINE = 1 , /* string: machine class */
HW_MODEL = 2 , /* string: specific machine model */
HW_NCPU = 3 , /* int: number of cpus */
HW_BYTEORDER = 4 , /* int: machine byte order */
HW_PHYSMEM = 5 , /* int: total memory */
HW_USERMEM = 6 , /* int: non-kernel memory */
HW_PAGESIZE = 7 , /* int: software page size */
HW_DISKNAMES = 8 , /* strings: disk drive names */
HW_DISKSTATS = 9 , /* struct: diskstats[] */
HW_EPOCH = 10 , /* int: 0 for Legacy, else NewWorld */
HW_FLOATINGPT = 11 , /* int: has HW floating point? */
HW_MACHINE_ARCH = 12 , /* string: machine architecture */
HW_VECTORUNIT = 13 , /* int: has HW vector unit? */
HW_BUS_FREQ = 14 , /* int: Bus Frequency */
HW_CPU_FREQ = 15 , /* int: CPU Frequency */
HW_CACHELINE = 16 , /* int: Cache Line Size in Bytes */
HW_L1ICACHESIZE = 17 , /* int: L1 I Cache Size in Bytes */
HW_L1DCACHESIZE = 18 , /* int: L1 D Cache Size in Bytes */
HW_L2SETTINGS = 19 , /* int: L2 Cache Settings */
HW_L2CACHESIZE = 20 , /* int: L2 Cache Size in Bytes */
HW_L3SETTINGS = 21 , /* int: L3 Cache Settings */
HW_L3CACHESIZE = 22 , /* int: L3 Cache Size in Bytes */
HW_TB_FREQ = 23 , /* int: Bus Frequency */
HW_MEMSIZE = 24 , /* uint64_t: physical ram size */
HW_AVAILCPU = 25 , /* int: number of available CPUs */
HW_MAXID = 26 , /* number of valid hw ids */
    /*
     * XXX This information should be moved to the man page.
     *
     * These are the support HW selectors for sysctlbyname.  Parameters that are byte counts or frequencies are 64 bit numbers.
     * All other parameters are 32 bit numbers.
     *
     *   hw.memsize                - The number of bytes of physical memory in the system.
     *
     *   hw.ncpu                   - The maximum number of processors that could be available this boot.
     *                               Use this value for sizing of static per processor arrays; i.e. processor load statistics.
     *
     *   hw.activecpu              - The number of processors currently available for executing threads.
     *                               Use this number to determine the number threads to create in SMP aware applications.
     *                               This number can change when power management modes are changed.
     *
     *   hw.physicalcpu            - The number of physical processors available in the current power management mode.
     *   hw.physicalcpu_max        - The maximum number of physical processors that could be available this boot
     *
     *   hw.logicalcpu             - The number of logical processors available in the current power management mode.
     *   hw.logicalcpu_max         - The maximum number of logical processors that could be available this boot
     *
     *   hw.tbfrequency            - This gives the time base frequency used by the OS and is the basis of all timing services.
     *                               In general is is better to use mach's or higher level timing services, but this value
     *                               is needed to convert the PPC Time Base registers to real time.
     *
     *   hw.cpufrequency           - These values provide the current, min and max cpu frequency.  The min and max are for
     *   hw.cpufrequency_max       - all power management modes.  The current frequency is the max frequency in the current mode.
     *   hw.cpufrequency_min       - All frequencies are in Hz.
     *
     *   hw.busfrequency           - These values provide the current, min and max bus frequency.  The min and max are for
     *   hw.busfrequency_max       - all power management modes.  The current frequency is the max frequency in the current mode.
     *   hw.busfrequency_min       - All frequencies are in Hz.
     *
     *   hw.cputype                - These values provide the mach-o cpu type and subtype.  A complete list is in <mach/machine.h>
     *   hw.cpusubtype             - These values should be used to determine what processor family the running cpu is from so that
     *                               the best binary can be chosen, or the best dynamic code generated.  They should not be used
     *                               to determine if a given processor feature is available.
     *   hw.cputhreadtype          - This value will be present if the processor supports threads.  Like hw.cpusubtype this selector
     *                               should not be used to infer features, and only used to name the processors thread architecture.
     *                               The values are defined in <mach/machine.h>
     *
     *   hw.byteorder              - Gives the byte order of the processor.  4321 for big endian, 1234 for little.
     *
     *   hw.pagesize               - Gives the size in bytes of the pages used by the processor and VM system.
     *
     *   hw.cachelinesize          - Gives the size in bytes of the processor's cache lines.
     *                               This value should be use to control the strides of loops that use cache control instructions
     *                               like dcbz, dcbt or dcbst.
     *
     *   hw.l1dcachesize           - These values provide the size in bytes of the L1, L2 and L3 caches.  If a cache is not present
     *   hw.l1icachesize           - then the selector will return and error.
     *   hw.l2cachesize            -
     *   hw.l3cachesize            -
     *
     *   hw.packages               - Gives the number of processor packages.
     *
     * These are the selectors for optional processor features for specific processors.  Selectors that return errors are not support 
     * on the system.  Supported features will return 1 if they are recommended or 0 if they are supported but are not expected to help .
     * performance.  Future versions of these selectors may return larger values as necessary so it is best to test for non zero.
     *
     * For PowerPC:
     *
     *   hw.optional.floatingpoint - Floating Point Instructions
     *   hw.optional.altivec       - AltiVec Instructions
     *   hw.optional.graphicsops   - Graphics Operations
     *   hw.optional.64bitops      - 64-bit Instructions
     *   hw.optional.fsqrt         - HW Floating Point Square Root Instruction
     *   hw.optional.stfiwx        - Store Floating Point as Integer Word Indexed Instructions
     *   hw.optional.dcba          - Data Cache Block Allocate Instruction
     *   hw.optional.datastreams   - Data Streams Instructions
     *   hw.optional.dcbtstreams   - Data Cache Block Touch Steams Instruction Form
     *
     * For x86 Architecture:
     * 
     *   hw.optional.floatingpoint     - Floating Point Instructions
     *   hw.optional.mmx               - Original MMX vector instructions
     *   hw.optional.sse               - Streaming SIMD Extensions
     *   hw.optional.sse2              - Streaming SIMD Extensions 2
     *   hw.optional.sse3              - Streaming SIMD Extensions 3
     *   hw.optional.supplementalsse3  - Supplemental Streaming SIMD Extensions 3
     *   hw.optional.x86_64            - 64-bit support
     */
    /*
     * CTL_USER definitions
     */
USER_CS_PATH = 1 , /* string: _CS_PATH */
USER_BC_BASE_MAX = 2 , /* int: BC_BASE_MAX */
USER_BC_DIM_MAX = 3 , /* int: BC_DIM_MAX */
USER_BC_SCALE_MAX = 4 , /* int: BC_SCALE_MAX */
USER_BC_STRING_MAX = 5 , /* int: BC_STRING_MAX */
USER_COLL_WEIGHTS_MAX = 6 , /* int: COLL_WEIGHTS_MAX */
USER_EXPR_NEST_MAX = 7 , /* int: EXPR_NEST_MAX */
USER_LINE_MAX = 8 , /* int: LINE_MAX */
USER_RE_DUP_MAX = 9 , /* int: RE_DUP_MAX */
USER_POSIX2_VERSION = 10 , /* int: POSIX2_VERSION */
USER_POSIX2_C_BIND = 11 , /* int: POSIX2_C_BIND */
USER_POSIX2_C_DEV = 12 , /* int: POSIX2_C_DEV */
USER_POSIX2_CHAR_TERM = 13 , /* int: POSIX2_CHAR_TERM */
USER_POSIX2_FORT_DEV = 14 , /* int: POSIX2_FORT_DEV */
USER_POSIX2_FORT_RUN = 15 , /* int: POSIX2_FORT_RUN */
USER_POSIX2_LOCALEDEF = 16 , /* int: POSIX2_LOCALEDEF */
USER_POSIX2_SW_DEV = 17 , /* int: POSIX2_SW_DEV */
USER_POSIX2_UPE = 18 , /* int: POSIX2_UPE */
USER_STREAM_MAX = 19 , /* int: POSIX2_STREAM_MAX */
USER_TZNAME_MAX = 20 , /* int: POSIX2_TZNAME_MAX */
USER_MAXID = 21 , /* number of valid user ids */
    /*
     * CTL_DEBUG definitions
     *
     * Second level identifier specifies which debug variable.
     * Third level identifier specifies which stucture component.
     */
CTL_DEBUG_NAME = 0 , /* string: variable name */
CTL_DEBUG_VALUE = 1 , /* int: variable value */
CTL_DEBUG_MAXID = 20 ,
}
enum {KERN_USRSTACK=35}

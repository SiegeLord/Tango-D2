#ifdef __APPLE__
#include <sys/sysctl.h>
#else
#define SYSCTL_SKIP_ALL
// other BSD based os should also have at least part of these
#endif
#undef const
tt
xxxxxx start xxxxxx
module tango.stdc.constants.autoconf.sysctl;
#ifndef SYSCTL_SKIP_ALL
enum SysCtl{
__XYX__CTL_MAXNAME = CTL_MAXNAME , /* largest number of components supported */
    /+
     + Each subsystem defined by sysctl defines a list of variables
     + for that subsystem. Each name is either a node with further 
     + levels defined below it, or it is a leaf of some particular
     + type given below. Each sysctl level defines a set of name/type
     + pairs to be used by sysctl(1) in manipulating the subsystem.
     +
     + When declaring new sysctl names, please use the CTLFLAG_LOCKED
     + flag in the type to indicate that all necessary locking will
     + be handled within the sysctl. Any sysctl defined without
     + CTLFLAG_LOCKED is considered legacy and will be protected by
     + both the kernel funnel and the sysctl memlock. This is not
     + optimal, so it is best to handle locking yourself.
     +/

__XYX__CTLTYPE        = CTLTYPE       , /* Mask for the type */
__XYX__CTLTYPE_NODE   = CTLTYPE_NODE  , /* name is a node */
__XYX__CTLTYPE_INT    = CTLTYPE_INT   , /* name describes an integer */
__XYX__CTLTYPE_STRING = CTLTYPE_STRING, /* name describes a string */
__XYX__CTLTYPE_QUAD   = CTLTYPE_QUAD  , /* name describes a 64-bit number */
__XYX__CTLTYPE_OPAQUE = CTLTYPE_OPAQUE, /* name describes a structure */
__XYX__CTLTYPE_STRUCT = CTLTYPE_STRUCT, /* name describes a structure */

__XYX__CTLFLAG_RD      = CTLFLAG_RD     ,   /* Allow reads of variable */
__XYX__CTLFLAG_WR      = CTLFLAG_WR     ,   /* Allow writes to the variable */
__XYX__CTLFLAG_RW      = CTLFLAG_RW     ,
__XYX__CTLFLAG_NOLOCK  = CTLFLAG_NOLOCK ,    /* XXX Don't Lock */
__XYX__CTLFLAG_ANYBODY = CTLFLAG_ANYBODY,       /* All users can set this var */
__XYX__CTLFLAG_SECURE  = CTLFLAG_SECURE ,    /* Permit set only if securelevel<=0 */
__XYX__CTLFLAG_MASKED  = CTLFLAG_MASKED ,    /* deprecated variable, do not display */
__XYX__CTLFLAG_NOAUTO  = CTLFLAG_NOAUTO ,    /* do not auto-register */
__XYX__CTLFLAG_KERN    = CTLFLAG_KERN   ,    /* valid inside the kernel */
__XYX__CTLFLAG_LOCKED  = CTLFLAG_LOCKED ,    /* node will handle locking itself (highly encouraged) */

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
__XYX__OID_AUTO    = OID_AUTO      , 
__XYX__OID_AUTO_START = OID_AUTO_START, /* conventional */

    /*
     * Top-level identifiers
     */
__XYX__CTL_UNSPEC   = CTL_UNSPEC , /* unused */
__XYX__CTL_KERN     = CTL_KERN   , /* "high kernel": proc, limits */
__XYX__CTL_VM       = CTL_VM     , /* virtual memory */
__XYX__CTL_VFS      = CTL_VFS    , /* file system, mount type is next */
__XYX__CTL_NET      = CTL_NET    , /* network, see socket.h */
__XYX__CTL_DEBUG    = CTL_DEBUG  , /* debugging parameters */
__XYX__CTL_HW       = CTL_HW     , /* generic cpu/io */
__XYX__CTL_MACHDEP  = CTL_MACHDEP, /* machine dependent */
__XYX__CTL_USER     = CTL_USER   , /* user-level */
__XYX__CTL_MAXID    = CTL_MAXID  , /* number of valid top-level ids */

    /*
     * CTL_KERN identifiers
     */
__XYX__KERN_OSTYPE          = KERN_OSTYPE          , /* string: system version */
__XYX__KERN_OSRELEASE       = KERN_OSRELEASE       , /* string: system release */
__XYX__KERN_OSREV           = KERN_OSREV           , /* int: system revision */
__XYX__KERN_VERSION         = KERN_VERSION         , /* string: compile time info */
__XYX__KERN_MAXVNODES       = KERN_MAXVNODES       , /* int: max vnodes */
__XYX__KERN_MAXPROC         = KERN_MAXPROC         , /* int: max processes */
__XYX__KERN_MAXFILES        = KERN_MAXFILES        , /* int: max open files */
__XYX__KERN_ARGMAX          = KERN_ARGMAX          , /* int: max arguments to exec */
__XYX__KERN_SECURELVL       = KERN_SECURELVL       , /* int: system security level */
__XYX__KERN_HOSTNAME        = KERN_HOSTNAME        , /* string: hostname */
__XYX__KERN_HOSTID          = KERN_HOSTID          , /* int: host identifier */
__XYX__KERN_CLOCKRATE       = KERN_CLOCKRATE       , /* struct: struct clockrate */
__XYX__KERN_VNODE           = KERN_VNODE           , /* struct: vnode structures */
__XYX__KERN_PROC            = KERN_PROC            , /* struct: process entries */
__XYX__KERN_FILE            = KERN_FILE            , /* struct: file entries */
__XYX__KERN_PROF            = KERN_PROF            , /* node: kernel profiling info */
__XYX__KERN_POSIX1          = KERN_POSIX1          , /* int: POSIX.1 version */
__XYX__KERN_NGROUPS         = KERN_NGROUPS         , /* int: # of supplemental group ids */
__XYX__KERN_JOB_CONTROL     = KERN_JOB_CONTROL     , /* int: is job control available */
__XYX__KERN_SAVED_IDS       = KERN_SAVED_IDS       , /* int: saved set-user/group-ID */
__XYX__KERN_BOOTTIME        = KERN_BOOTTIME        , /* struct: time kernel was booted */
__XYX__KERN_NISDOMAINNAME   = KERN_NISDOMAINNAME   , /* string: YP domain name */
__XYX__KERN_DOMAINNAME      = KERN_DOMAINNAME      , 
__XYX__KERN_MAXPARTITIONS   = KERN_MAXPARTITIONS   , /* int: number of partitions/disk */
__XYX__KERN_KDEBUG          = KERN_KDEBUG          , /* int: kernel trace points */
__XYX__KERN_UPDATEINTERVAL  = KERN_UPDATEINTERVAL  , /* int: update process sleep time */
__XYX__KERN_OSRELDATE       = KERN_OSRELDATE       , /* int: OS release date */
__XYX__KERN_NTP_PLL         = KERN_NTP_PLL         , /* node: NTP PLL control */
__XYX__KERN_BOOTFILE        = KERN_BOOTFILE        , /* string: name of booted kernel */
__XYX__KERN_MAXFILESPERPROC = KERN_MAXFILESPERPROC , /* int: max open files per proc */
__XYX__KERN_MAXPROCPERUID   = KERN_MAXPROCPERUID   , /* int: max processes per uid */
__XYX__KERN_DUMPDEV         = KERN_DUMPDEV         , /* dev_t: device to dump on */
__XYX__KERN_IPC             = KERN_IPC             , /* node: anything related to IPC */
__XYX__KERN_DUMMY           = KERN_DUMMY           , /* unused */
__XYX__KERN_PS_STRINGS      = KERN_PS_STRINGS      , /* int: address of PS_STRINGS */
__XYX__KERN_USRSTACK32      = KERN_USRSTACK32      , /* int: address of USRSTACK */
__XYX__KERN_LOGSIGEXIT      = KERN_LOGSIGEXIT      , /* int: do we log sigexit procs? */
__XYX__KERN_SYMFILE         = KERN_SYMFILE         , /* string: kernel symbol filename */
__XYX__KERN_PROCARGS        = KERN_PROCARGS        , /* was KERN_PCSAMPLES... now deprecated */

__XYX__KERN_NETBOOT         = KERN_NETBOOT         , /* int: are we netbooted? 1=yes,0=no */
__XYX__KERN_PANICINFO       = KERN_PANICINFO       , /* node: panic UI information */
__XYX__KERN_SYSV            = KERN_SYSV            , /* node: System V IPC information */
__XYX__KERN_AFFINITY        = KERN_AFFINITY        , /* xxx */
__XYX__KERN_TRANSLATE       = KERN_TRANSLATE       , /* xxx */
__XYX__KERN_CLASSIC         = KERN_CLASSIC         , /* XXX backwards compat */
__XYX__KERN_EXEC            = KERN_EXEC            , /* xxx */
__XYX__KERN_CLASSICHANDLER  = KERN_CLASSICHANDLER  , /* XXX backwards compatibility */
__XYX__KERN_AIOMAX          = KERN_AIOMAX          , /* int: max aio requests */
__XYX__KERN_AIOPROCMAX      = KERN_AIOPROCMAX      , /* int: max aio requests per process */
__XYX__KERN_AIOTHREADS      = KERN_AIOTHREADS      , /* int: max aio worker threads */
                            
__XYX__KERN_COREFILE        = KERN_COREFILE        , /* string: corefile format string */
__XYX__KERN_COREDUMP        = KERN_COREDUMP        , /* int: whether to coredump at all */
__XYX__KERN_SUGID_COREDUMP  = KERN_SUGID_COREDUMP  , /* int: whether to dump SUGID cores */
__XYX__KERN_PROCDELAYTERM   = KERN_PROCDELAYTERM   , /* int: set/reset current proc for delayed termination during shutdown */

__XYX__KERN_SHREG_PRIVATIZABLE = KERN_SHREG_PRIVATIZABLE, /* int: can shared regions be privatized ? */
__XYX__KERN_PROC_LOW_PRI_IO    = KERN_PROC_LOW_PRI_IO   , /* int: set/reset current proc for low priority I/O */
__XYX__KERN_LOW_PRI_WINDOW     = KERN_LOW_PRI_WINDOW    , /* int: set/reset throttle window - milliseconds */
__XYX__KERN_LOW_PRI_DELAY      = KERN_LOW_PRI_DELAY     , /* int: set/reset throttle delay - milliseconds */
__XYX__KERN_POSIX              = KERN_POSIX             , /* node: posix tunables */
__XYX__KERN_USRSTACK64         = KERN_USRSTACK64        , /* LP64 user stack query */
__XYX__KERN_NX_PROTECTION      = KERN_NX_PROTECTION     , /* int: whether no-execute protection is enabled */
__XYX__KERN_TFP                = KERN_TFP               , /* Task for pid settings */
__XYX__KERN_PROCNAME           = KERN_PROCNAME          , /* setup process program  name(2*MAXCOMLEN) */
__XYX__KERN_THALTSTACK         = KERN_THALTSTACK        , /* for compat with older x86 and does nothing */
__XYX__KERN_SPECULATIVE_READS  = KERN_SPECULATIVE_READS , /* int: whether speculative reads are disabled */
__XYX__KERN_OSVERSION          = KERN_OSVERSION         , /* for build number i.e. 9A127 */
__XYX__KERN_SAFEBOOT           = KERN_SAFEBOOT          , /* are we booted safe? */
__XYX__KERN_LCTX               = KERN_LCTX              , /* node: login context */
__XYX__KERN_RAGEVNODE          = KERN_RAGEVNODE         ,
__XYX__KERN_TTY                = KERN_TTY               , /* node: tty settings */
__XYX__KERN_CHECKOPENEVT       = KERN_CHECKOPENEVT      , /* spi: check the VOPENEVT flag on vnodes at open time */
__XYX__KERN_MAXID              = KERN_MAXID             , /* number of valid kern ids */
    /*                                                  ,
     * Don't add any more sysctls like this.  Instead, use the SYSCTL_*() macros
     * and OID_AUTO. This will have the added benefit of not having to recompile
     * sysctl(8) to pick up your changes.
     */
    /* KERN_RAGEVNODE types */
__XYX__KERN_RAGE_PROC     =  KERN_RAGE_PROC     ,
__XYX__KERN_RAGE_THREAD   =  KERN_RAGE_THREAD   ,
__XYX__KERN_UNRAGE_PROC   =  KERN_UNRAGE_PROC   ,
__XYX__KERN_UNRAGE_THREAD =  KERN_UNRAGE_THREAD ,

    /* KERN_OPENEVT types */
__XYX__KERN_OPENEVT_PROC   =  KERN_OPENEVT_PROC   ,
__XYX__KERN_UNOPENEVT_PROC =  KERN_UNOPENEVT_PROC ,

    /* KERN_TFP types */
__XYX__KERN_TFP_POLICY = KERN_TFP_POLICY ,

    /* KERN_TFP_POLICY values . All policies allow task port for self */
__XYX__KERN_TFP_POLICY_DENY = KERN_TFP_POLICY_DENY, /* Deny Mode: None allowed except privileged */
__XYX__KERN_TFP_POLICY_DEFAULT = KERN_TFP_POLICY_DEFAULT, /* Default  Mode: related ones allowed and upcall authentication */

    /* KERN_KDEBUG types */
__XYX__KERN_KDEFLAGS  = KERN_KDEFLAGS  ,
__XYX__KERN_KDDFLAGS  = KERN_KDDFLAGS  ,
__XYX__KERN_KDENABLE  = KERN_KDENABLE  ,
__XYX__KERN_KDSETBUF  = KERN_KDSETBUF  ,
__XYX__KERN_KDGETBUF  = KERN_KDGETBUF  ,
__XYX__KERN_KDSETUP   = KERN_KDSETUP   ,
__XYX__KERN_KDREMOVE  = KERN_KDREMOVE  ,
__XYX__KERN_KDSETREG  = KERN_KDSETREG  ,
__XYX__KERN_KDGETREG  = KERN_KDGETREG  ,
__XYX__KERN_KDREADTR  = KERN_KDREADTR  ,
__XYX__KERN_KDPIDTR   = KERN_KDPIDTR   ,
__XYX__KERN_KDTHRMAP  = KERN_KDTHRMAP  ,
__XYX__KERN_KDPIDEX      = KERN_KDPIDEX      ,
__XYX__KERN_KDSETRTCDEC  = KERN_KDSETRTCDEC  ,
__XYX__KERN_KDGETENTROPY = KERN_KDGETENTROPY ,

    /* KERN_PANICINFO types */
__XYX__KERN_PANICINFO_MAXSIZE  = KERN_PANICINFO_MAXSIZE , /* quad: panic UI image size limit */
__XYX__KERN_PANICINFO_IMAGE    = KERN_PANICINFO_IMAGE   , /* panic UI in 8-bit kraw format */


    /* 
     * KERN_PROC subtypes
     */
__XYX__KERN_PROC_ALL      = KERN_PROC_ALL     ,  /* everything */
__XYX__KERN_PROC_PID      = KERN_PROC_PID     ,  /* by process id */
__XYX__KERN_PROC_PGRP     = KERN_PROC_PGRP    ,  /* by process group id */
__XYX__KERN_PROC_SESSION  = KERN_PROC_SESSION ,  /* by session of pid */
__XYX__KERN_PROC_TTY      = KERN_PROC_TTY     ,  /* by controlling tty */
__XYX__KERN_PROC_UID      = KERN_PROC_UID     ,  /* by effective uid */
__XYX__KERN_PROC_RUID     = KERN_PROC_RUID    ,  /* by real uid */
__XYX__KERN_PROC_LCID     = KERN_PROC_LCID    ,  /* by login context id */

    /*
     * KERN_LCTX subtypes
     */
__XYX__KERN_LCTX_ALL   = KERN_LCTX_ALL  ,  /* everything */
__XYX__KERN_LCTX_LCID  = KERN_LCTX_LCID ,  /* by login context id */

    /*
     * KERN_IPC identifiers
     */
__XYX__KIPC_MAXSOCKBUF     = KIPC_MAXSOCKBUF     ,  /* int: max size of a socket buffer */
__XYX__KIPC_SOCKBUF_WASTE  = KIPC_SOCKBUF_WASTE  ,  /* int: wastage factor in sockbuf */
__XYX__KIPC_SOMAXCONN      = KIPC_SOMAXCONN      ,  /* int: max length of connection q */
__XYX__KIPC_MAX_LINKHDR    = KIPC_MAX_LINKHDR    ,  /* int: max length of link header */
__XYX__KIPC_MAX_PROTOHDR   = KIPC_MAX_PROTOHDR   ,  /* int: max length of network header */
__XYX__KIPC_MAX_HDR        = KIPC_MAX_HDR        ,  /* int: max total length of headers */
__XYX__KIPC_MAX_DATALEN    = KIPC_MAX_DATALEN    ,  /* int: max length of data? */
__XYX__KIPC_MBSTAT         = KIPC_MBSTAT         ,  /* struct: mbuf usage statistics */
__XYX__KIPC_NMBCLUSTERS    = KIPC_NMBCLUSTERS    ,  /* int: maximum mbuf clusters */
__XYX__KIPC_SOQLIMITCOMPAT = KIPC_SOQLIMITCOMPAT ,  /* int: socket queue limit */

    /*
     * CTL_VM identifiers
     */
__XYX__VM_METER   = VM_METER   , /* struct vmmeter */
__XYX__VM_LOADAVG = VM_LOADAVG , /* struct loadavg */
    /*
     * Note: "3" was skipped sometime ago and should probably remain unused
     * to avoid any new entry from being accepted by older kernels...
     */ 
__XYX__VM_MACHFACTOR = VM_MACHFACTOR , /* struct loadavg with mach factor*/
__XYX__VM_SWAPUSAGE  = VM_SWAPUSAGE  , /* total swap usage */
__XYX__VM_MAXID      = VM_MAXID      , /* number of valid vm ids */
    /*
     * CTL_HW identifiers
     */
__XYX__HW_MACHINE      = HW_MACHINE       , /* string: machine class */
__XYX__HW_MODEL        = HW_MODEL         , /* string: specific machine model */
__XYX__HW_NCPU         = HW_NCPU          , /* int: number of cpus */
__XYX__HW_BYTEORDER    = HW_BYTEORDER     , /* int: machine byte order */
__XYX__HW_PHYSMEM      = HW_PHYSMEM       , /* int: total memory */
__XYX__HW_USERMEM      = HW_USERMEM       , /* int: non-kernel memory */
__XYX__HW_PAGESIZE     = HW_PAGESIZE      , /* int: software page size */
__XYX__HW_DISKNAMES    = HW_DISKNAMES      , /* strings: disk drive names */
__XYX__HW_DISKSTATS    = HW_DISKSTATS     , /* struct: diskstats[] */
__XYX__HW_EPOCH        = HW_EPOCH         , /* int: 0 for Legacy, else NewWorld */
__XYX__HW_FLOATINGPT   = HW_FLOATINGPT    , /* int: has HW floating point? */
__XYX__HW_MACHINE_ARCH = HW_MACHINE_ARCH  , /* string: machine architecture */
__XYX__HW_VECTORUNIT   = HW_VECTORUNIT    , /* int: has HW vector unit? */
__XYX__HW_BUS_FREQ     = HW_BUS_FREQ      , /* int: Bus Frequency */
__XYX__HW_CPU_FREQ     = HW_CPU_FREQ      , /* int: CPU Frequency */
__XYX__HW_CACHELINE    = HW_CACHELINE     , /* int: Cache Line Size in Bytes */
__XYX__HW_L1ICACHESIZE = HW_L1ICACHESIZE  , /* int: L1 I Cache Size in Bytes */
__XYX__HW_L1DCACHESIZE = HW_L1DCACHESIZE  , /* int: L1 D Cache Size in Bytes */
__XYX__HW_L2SETTINGS   = HW_L2SETTINGS    , /* int: L2 Cache Settings */
__XYX__HW_L2CACHESIZE  = HW_L2CACHESIZE   , /* int: L2 Cache Size in Bytes */
__XYX__HW_L3SETTINGS   = HW_L3SETTINGS    , /* int: L3 Cache Settings */
__XYX__HW_L3CACHESIZE  = HW_L3CACHESIZE   , /* int: L3 Cache Size in Bytes */
__XYX__HW_TB_FREQ      = HW_TB_FREQ       , /* int: Bus Frequency */
__XYX__HW_MEMSIZE      = HW_MEMSIZE       , /* uint64_t: physical ram size */
__XYX__HW_AVAILCPU     = HW_AVAILCPU      , /* int: number of available CPUs */
__XYX__HW_MAXID        = HW_MAXID         , /* number of valid hw ids */

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
__XYX__USER_CS_PATH          = USER_CS_PATH          ,  /* string: _CS_PATH */
__XYX__USER_BC_BASE_MAX      = USER_BC_BASE_MAX      ,  /* int: BC_BASE_MAX */
__XYX__USER_BC_DIM_MAX       = USER_BC_DIM_MAX       ,  /* int: BC_DIM_MAX */
__XYX__USER_BC_SCALE_MAX     = USER_BC_SCALE_MAX     ,  /* int: BC_SCALE_MAX */
__XYX__USER_BC_STRING_MAX    = USER_BC_STRING_MAX    ,  /* int: BC_STRING_MAX */
__XYX__USER_COLL_WEIGHTS_MAX = USER_COLL_WEIGHTS_MAX ,  /* int: COLL_WEIGHTS_MAX */
__XYX__USER_EXPR_NEST_MAX    = USER_EXPR_NEST_MAX    ,  /* int: EXPR_NEST_MAX */
__XYX__USER_LINE_MAX         = USER_LINE_MAX         ,  /* int: LINE_MAX */
__XYX__USER_RE_DUP_MAX       = USER_RE_DUP_MAX       ,  /* int: RE_DUP_MAX */
__XYX__USER_POSIX2_VERSION   = USER_POSIX2_VERSION   ,  /* int: POSIX2_VERSION */
__XYX__USER_POSIX2_C_BIND    = USER_POSIX2_C_BIND    ,  /* int: POSIX2_C_BIND */
__XYX__USER_POSIX2_C_DEV     = USER_POSIX2_C_DEV     ,  /* int: POSIX2_C_DEV */
__XYX__USER_POSIX2_CHAR_TERM = USER_POSIX2_CHAR_TERM ,  /* int: POSIX2_CHAR_TERM */
__XYX__USER_POSIX2_FORT_DEV  = USER_POSIX2_FORT_DEV  ,  /* int: POSIX2_FORT_DEV */
__XYX__USER_POSIX2_FORT_RUN  = USER_POSIX2_FORT_RUN  ,  /* int: POSIX2_FORT_RUN */
__XYX__USER_POSIX2_LOCALEDEF = USER_POSIX2_LOCALEDEF ,  /* int: POSIX2_LOCALEDEF */
__XYX__USER_POSIX2_SW_DEV    = USER_POSIX2_SW_DEV    ,  /* int: POSIX2_SW_DEV */
__XYX__USER_POSIX2_UPE       = USER_POSIX2_UPE       ,  /* int: POSIX2_UPE */
__XYX__USER_STREAM_MAX       = USER_STREAM_MAX       ,  /* int: POSIX2_STREAM_MAX */
__XYX__USER_TZNAME_MAX       = USER_TZNAME_MAX       ,  /* int: POSIX2_TZNAME_MAX */
__XYX__USER_MAXID            = USER_MAXID            ,  /* number of valid user ids */

    /*
     * CTL_DEBUG definitions
     *
     * Second level identifier specifies which debug variable.
     * Third level identifier specifies which stucture component.
     */
__XYX__CTL_DEBUG_NAME  = CTL_DEBUG_NAME  , /* string: variable name */
__XYX__CTL_DEBUG_VALUE = CTL_DEBUG_VALUE , /* int: variable value */
__XYX__CTL_DEBUG_MAXID = CTL_DEBUG_MAXID , 
}

enum {__XYX__KERN_USRSTACK=KERN_USRSTACK}

#endif // SYSCTL_SKIP_ALL

#if (defined(_WINDOWS)||defined(WIN32))
#define UNISTD_SKIP_ALL
#else
#include <unistd.h>
#endif
#undef const
tt
xxx start xxx
module tango.stdc.constants.autoconf.unistd;
/+ http://opengroup.org/onlinepubs/007908799/xsh/unistd.h.html +/

#ifndef UNISTD_SKIP_ALL
enum {
    __XYX__STDIN_FILENO  = STDIN_FILENO,
    __XYX__STDOUT_FILENO = STDOUT_FILENO,
    __XYX__STDERR_FILENO = STDERR_FILENO,

    __XYX__F_OK          = F_OK,
    __XYX__R_OK          = R_OK,
    __XYX__W_OK          = W_OK,
    __XYX__X_OK          = X_OK,

    __XYX__F_ULOCK       = F_ULOCK,
    __XYX__F_LOCK        = F_LOCK ,
    __XYX__F_TLOCK       = F_TLOCK,
    __XYX__F_TEST        = F_TEST ,
}
enum :long {
    __XYX___POSIX_VERSION     = _POSIX_VERSION    ,
    __XYX___POSIX2_VERSION    = _POSIX2_VERSION   ,
#ifdef _POSIX2_C_VERSION
    __XYX___POSIX2_C_VERSION  = _POSIX2_C_VERSION ,
#endif
    __XYX___XOPEN_VERSION     = _XOPEN_VERSION    ,
    __XYX___XOPEN_XCU_VERSION = _XOPEN_XCU_VERSION,
}
enum {
#ifdef _LFS64_LARGEFILE
    __XYX___LFS64_LARGEFILE=_LFS64_LARGEFILE,
#endif
#ifdef _LFS64_STDIO
    __XYX___LFS64_STDIO=_LFS64_STDIO,
#endif

    // posix.1
    __XYX___PC_LINK_MAX           = _PC_LINK_MAX,
    __XYX___PC_MAX_CANON          = _PC_MAX_CANON,
    __XYX___PC_MAX_INPUT          = _PC_MAX_INPUT,
    __XYX___PC_NAME_MAX           = _PC_NAME_MAX,
    __XYX___PC_PATH_MAX           = _PC_PATH_MAX,
    __XYX___PC_PIPE_BUF           = _PC_PIPE_BUF,
    __XYX___PC_CHOWN_RESTRICTED   = _PC_CHOWN_RESTRICTED,
    __XYX___PC_NO_TRUNC           = _PC_NO_TRUNC,
    __XYX___PC_VDISABLE           = _PC_VDISABLE,
    __XYX___PC_SYNC_IO            = _PC_SYNC_IO,
    __XYX___PC_ASYNC_IO           = _PC_ASYNC_IO,
    __XYX___PC_PRIO_IO            = _PC_PRIO_IO,
#ifdef _PC_SOCK_MAXBUF
    __XYX___PC_SOCK_MAXBUF        = _PC_SOCK_MAXBUF,
#endif
    __XYX___PC_FILESIZEBITS       = _PC_FILESIZEBITS,
    __XYX___PC_REC_INCR_XFER_SIZE = _PC_REC_INCR_XFER_SIZE,
    __XYX___PC_REC_MAX_XFER_SIZE  = _PC_REC_MAX_XFER_SIZE,
    __XYX___PC_REC_MIN_XFER_SIZE  = _PC_REC_MIN_XFER_SIZE,
    __XYX___PC_REC_XFER_ALIGN     = _PC_REC_XFER_ALIGN,
    __XYX___PC_ALLOC_SIZE_MIN     = _PC_ALLOC_SIZE_MIN,
    __XYX___PC_SYMLINK_MAX        = _PC_SYMLINK_MAX,
    __XYX___PC_2_SYMLINKS         = _PC_2_SYMLINKS,

    // posix.2
    __XYX___CS_PATH = _CS_PATH,

#ifdef _CS_GNU_LIBC_VERSION
    __XYX___CS_GNU_LIBC_VERSION = _CS_GNU_LIBC_VERSION,
#endif
#ifdef _CS_GNU_LIBPTHREAD_VERSION
    __XYX___CS_GNU_LIBPTHREAD_VERSION = _CS_GNU_LIBPTHREAD_VERSION,
#endif

#ifdef _CS_LFS_CFLAGS
    __XYX___CS_LFS_CFLAGS      = _CS_LFS_CFLAGS,
    __XYX___CS_LFS_LDFLAGS     = _CS_LFS_LDFLAGS,
    __XYX___CS_LFS_LIBS        = _CS_LFS_LIBS,
    __XYX___CS_LFS_LINTFLAGS   = _CS_LFS_LINTFLAGS,
#endif
#ifdef _CS_LFS64_CFLAGS
    __XYX___CS_LFS64_CFLAGS    = _CS_LFS64_CFLAGS,
    __XYX___CS_LFS64_LDFLAGS   = _CS_LFS64_LDFLAGS,
    __XYX___CS_LFS64_LIBS      = _CS_LFS64_LIBS,
    __XYX___CS_LFS64_LINTFLAGS = _CS_LFS64_LINTFLAGS,
#endif

#ifdef _CS_V6_WIDTH_RESTRICTED_ENVS
    __XYX___CS_V6_WIDTH_RESTRICTED_ENVS = _CS_V6_WIDTH_RESTRICTED_ENVS,
#endif

    __XYX___CS_XBS5_ILP32_OFF32_CFLAGS     = _CS_XBS5_ILP32_OFF32_CFLAGS,
    __XYX___CS_XBS5_ILP32_OFF32_LDFLAGS    = _CS_XBS5_ILP32_OFF32_LDFLAGS,
    __XYX___CS_XBS5_ILP32_OFF32_LIBS       = _CS_XBS5_ILP32_OFF32_LIBS,
    __XYX___CS_XBS5_ILP32_OFF32_LINTFLAGS  = _CS_XBS5_ILP32_OFF32_LINTFLAGS,
    __XYX___CS_XBS5_ILP32_OFFBIG_CFLAGS    = _CS_XBS5_ILP32_OFFBIG_CFLAGS,
    __XYX___CS_XBS5_ILP32_OFFBIG_LDFLAGS   = _CS_XBS5_ILP32_OFFBIG_LDFLAGS,
    __XYX___CS_XBS5_ILP32_OFFBIG_LIBS      = _CS_XBS5_ILP32_OFFBIG_LIBS,
    __XYX___CS_XBS5_ILP32_OFFBIG_LINTFLAGS = _CS_XBS5_ILP32_OFFBIG_LINTFLAGS,
    __XYX___CS_XBS5_LP64_OFF64_CFLAGS      = _CS_XBS5_LP64_OFF64_CFLAGS,
    __XYX___CS_XBS5_LP64_OFF64_LDFLAGS     = _CS_XBS5_LP64_OFF64_LDFLAGS,
    __XYX___CS_XBS5_LP64_OFF64_LIBS        = _CS_XBS5_LP64_OFF64_LIBS,
    __XYX___CS_XBS5_LP64_OFF64_LINTFLAGS   = _CS_XBS5_LP64_OFF64_LINTFLAGS,
    __XYX___CS_XBS5_LPBIG_OFFBIG_CFLAGS    = _CS_XBS5_LPBIG_OFFBIG_CFLAGS,
    __XYX___CS_XBS5_LPBIG_OFFBIG_LDFLAGS   = _CS_XBS5_LPBIG_OFFBIG_LDFLAGS,
    __XYX___CS_XBS5_LPBIG_OFFBIG_LIBS      = _CS_XBS5_LPBIG_OFFBIG_LIBS,
    __XYX___CS_XBS5_LPBIG_OFFBIG_LINTFLAGS = _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS,

#ifdef _CS_POSIX_V6_ILP32_OFF32_LINTFLAGS
    __XYX___CS_POSIX_V6_ILP32_OFF32_LINTFLAGS  = _CS_POSIX_V6_ILP32_OFF32_LINTFLAGS,
#endif
    __XYX___CS_POSIX_V6_ILP32_OFF32_CFLAGS     = _CS_POSIX_V6_ILP32_OFF32_CFLAGS,
    __XYX___CS_POSIX_V6_ILP32_OFF32_LDFLAGS    = _CS_POSIX_V6_ILP32_OFF32_LDFLAGS,
    __XYX___CS_POSIX_V6_ILP32_OFF32_LIBS       = _CS_POSIX_V6_ILP32_OFF32_LIBS,
    __XYX___CS_POSIX_V6_ILP32_OFFBIG_CFLAGS    = _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS,
    __XYX___CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS   = _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS,
    __XYX___CS_POSIX_V6_ILP32_OFFBIG_LIBS      = _CS_POSIX_V6_ILP32_OFFBIG_LIBS,
#ifdef _CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS
    __XYX___CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS = _CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS,
#endif
#ifdef _CS_POSIX_V6_LP64_OFF64_LINTFLAGS
    __XYX___CS_POSIX_V6_LP64_OFF64_LINTFLAGS   = _CS_POSIX_V6_LP64_OFF64_LINTFLAGS,
#endif
    __XYX___CS_POSIX_V6_LP64_OFF64_CFLAGS      = _CS_POSIX_V6_LP64_OFF64_CFLAGS,
    __XYX___CS_POSIX_V6_LP64_OFF64_LDFLAGS     = _CS_POSIX_V6_LP64_OFF64_LDFLAGS,
    __XYX___CS_POSIX_V6_LP64_OFF64_LIBS        = _CS_POSIX_V6_LP64_OFF64_LIBS,
#ifdef _CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS
    __XYX___CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS = _CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS,
#endif
    __XYX___CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS    = _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS,
    __XYX___CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS   = _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS,
    __XYX___CS_POSIX_V6_LPBIG_OFFBIG_LIBS      = _CS_POSIX_V6_LPBIG_OFFBIG_LIBS,


#ifdef _SC_PII
    __XYX___SC_PII                           = _SC_PII,
    __XYX___SC_PII_XTI                       = _SC_PII_XTI,
    __XYX___SC_PII_SOCKET                    = _SC_PII_SOCKET,
    __XYX___SC_PII_INTERNET                  = _SC_PII_INTERNET,
    __XYX___SC_PII_OSI                       = _SC_PII_OSI,
    __XYX___SC_POLL                          = _SC_POLL,
    __XYX___SC_PII_INTERNET_STREAM           = _SC_PII_INTERNET_STREAM,
    __XYX___SC_PII_INTERNET_DGRAM            = _SC_PII_INTERNET_DGRAM,
    __XYX___SC_PII_OSI_COTS                  = _SC_PII_OSI_COTS,
    __XYX___SC_PII_OSI_CLTS                  = _SC_PII_OSI_CLTS,
    __XYX___SC_PII_OSI_M                     = _SC_PII_OSI_M,
#endif
#ifdef _SC_SELECT
    __XYX___SC_SELECT                        = _SC_SELECT,
#endif
#ifdef _SC_UIO_MAXIOV
    __XYX___SC_UIO_MAXIOV                    = _SC_UIO_MAXIOV,
#endif
#ifdef _SC_IOV_MAX
    __XYX___SC_IOV_MAX                       = _SC_IOV_MAX,
#endif
#ifdef _SC_T_IOV_MAX
    __XYX___SC_T_IOV_MAX                     = _SC_T_IOV_MAX,
#endif

    __XYX___SC_ARG_MAX                       = _SC_ARG_MAX,
    __XYX___SC_CHILD_MAX                     = _SC_CHILD_MAX,
    __XYX___SC_CLK_TCK                       = _SC_CLK_TCK,
    __XYX___SC_NGROUPS_MAX                   = _SC_NGROUPS_MAX,
    __XYX___SC_OPEN_MAX                      = _SC_OPEN_MAX,
    __XYX___SC_STREAM_MAX                    = _SC_STREAM_MAX,
    __XYX___SC_TZNAME_MAX                    = _SC_TZNAME_MAX,
    __XYX___SC_JOB_CONTROL                   = _SC_JOB_CONTROL,
    __XYX___SC_SAVED_IDS                     = _SC_SAVED_IDS,
    __XYX___SC_REALTIME_SIGNALS              = _SC_REALTIME_SIGNALS,
    __XYX___SC_PRIORITY_SCHEDULING           = _SC_PRIORITY_SCHEDULING,
    __XYX___SC_TIMERS                        = _SC_TIMERS,
    __XYX___SC_ASYNCHRONOUS_IO               = _SC_ASYNCHRONOUS_IO,
    __XYX___SC_PRIORITIZED_IO                = _SC_PRIORITIZED_IO,
    __XYX___SC_SYNCHRONIZED_IO               = _SC_SYNCHRONIZED_IO,
    __XYX___SC_FSYNC                         = _SC_FSYNC,
    __XYX___SC_MAPPED_FILES                  = _SC_MAPPED_FILES,
    __XYX___SC_MEMLOCK                       = _SC_MEMLOCK,
    __XYX___SC_MEMLOCK_RANGE                 = _SC_MEMLOCK_RANGE,
    __XYX___SC_MEMORY_PROTECTION             = _SC_MEMORY_PROTECTION,
    __XYX___SC_MESSAGE_PASSING               = _SC_MESSAGE_PASSING,
    __XYX___SC_SEMAPHORES                    = _SC_SEMAPHORES,
    __XYX___SC_SHARED_MEMORY_OBJECTS         = _SC_SHARED_MEMORY_OBJECTS,
    __XYX___SC_AIO_LISTIO_MAX                = _SC_AIO_LISTIO_MAX,
    __XYX___SC_AIO_MAX                       = _SC_AIO_MAX,
    __XYX___SC_AIO_PRIO_DELTA_MAX            = _SC_AIO_PRIO_DELTA_MAX,
    __XYX___SC_DELAYTIMER_MAX                = _SC_DELAYTIMER_MAX,
    __XYX___SC_MQ_OPEN_MAX                   = _SC_MQ_OPEN_MAX,
    __XYX___SC_MQ_PRIO_MAX                   = _SC_MQ_PRIO_MAX,
    __XYX___SC_VERSION                       = _SC_VERSION,
    __XYX___SC_PAGESIZE                      = _SC_PAGESIZE,
    __XYX___SC_PAGE_SIZE                     = _SC_PAGE_SIZE,
    __XYX___SC_RTSIG_MAX                     = _SC_RTSIG_MAX,
    __XYX___SC_SEM_NSEMS_MAX                 = _SC_SEM_NSEMS_MAX,
    __XYX___SC_SEM_VALUE_MAX                 = _SC_SEM_VALUE_MAX,
    __XYX___SC_SIGQUEUE_MAX                  = _SC_SIGQUEUE_MAX,
    __XYX___SC_TIMER_MAX                     = _SC_TIMER_MAX,

    __XYX___SC_BC_BASE_MAX                   = _SC_BC_BASE_MAX,
    __XYX___SC_BC_DIM_MAX                    = _SC_BC_DIM_MAX,
    __XYX___SC_BC_SCALE_MAX                  = _SC_BC_SCALE_MAX,
    __XYX___SC_BC_STRING_MAX                 = _SC_BC_STRING_MAX,
    __XYX___SC_COLL_WEIGHTS_MAX              = _SC_COLL_WEIGHTS_MAX,
#ifdef _SC_EQUIV_CLASS_MAX
    __XYX___SC_EQUIV_CLASS_MAX               = _SC_EQUIV_CLASS_MAX,
#endif
    __XYX___SC_EXPR_NEST_MAX                 = _SC_EXPR_NEST_MAX,
    __XYX___SC_LINE_MAX                      = _SC_LINE_MAX,
    __XYX___SC_RE_DUP_MAX                    = _SC_RE_DUP_MAX,
#ifdef _SC_CHARCLASS_NAME_MAX
    __XYX___SC_CHARCLASS_NAME_MAX            = _SC_CHARCLASS_NAME_MAX,
#endif

    __XYX___SC_2_VERSION                     = _SC_2_VERSION,
    __XYX___SC_2_C_BIND                      = _SC_2_C_BIND,
    __XYX___SC_2_C_DEV                       = _SC_2_C_DEV,
    __XYX___SC_2_FORT_DEV                    = _SC_2_FORT_DEV,
    __XYX___SC_2_FORT_RUN                    = _SC_2_FORT_RUN,
    __XYX___SC_2_SW_DEV                      = _SC_2_SW_DEV,
    __XYX___SC_2_LOCALEDEF                   = _SC_2_LOCALEDEF,

    __XYX___SC_THREADS                       = _SC_THREADS,
    __XYX___SC_THREAD_SAFE_FUNCTIONS         = _SC_THREAD_SAFE_FUNCTIONS,
    __XYX___SC_GETGR_R_SIZE_MAX              = _SC_GETGR_R_SIZE_MAX,
    __XYX___SC_GETPW_R_SIZE_MAX              = _SC_GETPW_R_SIZE_MAX,
    __XYX___SC_LOGIN_NAME_MAX                = _SC_LOGIN_NAME_MAX,
    __XYX___SC_TTY_NAME_MAX                  = _SC_TTY_NAME_MAX,
    __XYX___SC_THREAD_DESTRUCTOR_ITERATIONS  = _SC_THREAD_DESTRUCTOR_ITERATIONS,
    __XYX___SC_THREAD_KEYS_MAX               = _SC_THREAD_KEYS_MAX,
    __XYX___SC_THREAD_STACK_MIN              = _SC_THREAD_STACK_MIN,
    __XYX___SC_THREAD_THREADS_MAX            = _SC_THREAD_THREADS_MAX,
    __XYX___SC_THREAD_ATTR_STACKADDR         = _SC_THREAD_ATTR_STACKADDR,
    __XYX___SC_THREAD_ATTR_STACKSIZE         = _SC_THREAD_ATTR_STACKSIZE,
    __XYX___SC_THREAD_PRIORITY_SCHEDULING    = _SC_THREAD_PRIORITY_SCHEDULING,
    __XYX___SC_THREAD_PRIO_INHERIT           = _SC_THREAD_PRIO_INHERIT,
    __XYX___SC_THREAD_PRIO_PROTECT           = _SC_THREAD_PRIO_PROTECT,
    __XYX___SC_THREAD_PROCESS_SHARED         = _SC_THREAD_PROCESS_SHARED,

    __XYX___SC_NPROCESSORS_CONF              = _SC_NPROCESSORS_CONF,
    __XYX___SC_NPROCESSORS_ONLN              = _SC_NPROCESSORS_ONLN,
#ifdef _SC_PHYS_PAGES
    __XYX___SC_PHYS_PAGES                    = _SC_PHYS_PAGES,
#endif
#ifdef _SC_AVPHYS_PAGES
    __XYX___SC_AVPHYS_PAGES                  = _SC_AVPHYS_PAGES,
#endif
    __XYX___SC_ATEXIT_MAX                    = _SC_ATEXIT_MAX,
    __XYX___SC_PASS_MAX                      = _SC_PASS_MAX,

    __XYX___SC_XOPEN_VERSION                 = _SC_XOPEN_VERSION,
    __XYX___SC_XOPEN_XCU_VERSION             = _SC_XOPEN_XCU_VERSION,
    __XYX___SC_XOPEN_UNIX                    = _SC_XOPEN_UNIX,
    __XYX___SC_XOPEN_CRYPT                   = _SC_XOPEN_CRYPT,
    __XYX___SC_XOPEN_ENH_I18N                = _SC_XOPEN_ENH_I18N,
    __XYX___SC_XOPEN_SHM                     = _SC_XOPEN_SHM,

    __XYX___SC_2_CHAR_TERM                   = _SC_2_CHAR_TERM,
#ifdef _SC_2_C_VERSION
    __XYX___SC_2_C_VERSION                   = _SC_2_C_VERSION,
#endif
    __XYX___SC_2_UPE                         = _SC_2_UPE,

#ifdef _SC_XOPEN_XPG2
    __XYX___SC_XOPEN_XPG2                    = _SC_XOPEN_XPG2,
    __XYX___SC_XOPEN_XPG3                    = _SC_XOPEN_XPG3,
    __XYX___SC_XOPEN_XPG4                    = _SC_XOPEN_XPG4,
#endif

#ifdef _SC_CHAR_BIT
    __XYX___SC_CHAR_BIT                      = _SC_CHAR_BIT,
    __XYX___SC_CHAR_MAX                      = _SC_CHAR_MAX,
    __XYX___SC_CHAR_MIN                      = _SC_CHAR_MIN,
    __XYX___SC_INT_MAX                       = _SC_INT_MAX,
    __XYX___SC_INT_MIN                       = _SC_INT_MIN,
    __XYX___SC_LONG_BIT                      = _SC_LONG_BIT,
    __XYX___SC_WORD_BIT                      = _SC_WORD_BIT,
    __XYX___SC_MB_LEN_MAX                    = _SC_MB_LEN_MAX,
    __XYX___SC_NZERO                         = _SC_NZERO,
    __XYX___SC_SSIZE_MAX                     = _SC_SSIZE_MAX,
    __XYX___SC_SCHAR_MAX                     = _SC_SCHAR_MAX,
    __XYX___SC_SCHAR_MIN                     = _SC_SCHAR_MIN,
    __XYX___SC_SHRT_MAX                      = _SC_SHRT_MAX,
    __XYX___SC_SHRT_MIN                      = _SC_SHRT_MIN,
    __XYX___SC_UCHAR_MAX                     = _SC_UCHAR_MAX,
    __XYX___SC_UINT_MAX                      = _SC_UINT_MAX,
    __XYX___SC_ULONG_MAX                     = _SC_ULONG_MAX,
    __XYX___SC_USHRT_MAX                     = _SC_USHRT_MAX,
#endif

#ifdef _SC_NL_ARGMAX
    __XYX___SC_NL_ARGMAX                     = _SC_NL_ARGMAX,
    __XYX___SC_NL_LANGMAX                    = _SC_NL_LANGMAX,
    __XYX___SC_NL_MSGMAX                     = _SC_NL_MSGMAX,
    __XYX___SC_NL_NMAX                       = _SC_NL_NMAX,
    __XYX___SC_NL_SETMAX                     = _SC_NL_SETMAX,
    __XYX___SC_NL_TEXTMAX                    = _SC_NL_TEXTMAX,
#endif

    __XYX___SC_XBS5_ILP32_OFF32              = _SC_XBS5_ILP32_OFF32,
    __XYX___SC_XBS5_ILP32_OFFBIG             = _SC_XBS5_ILP32_OFFBIG,
    __XYX___SC_XBS5_LP64_OFF64               = _SC_XBS5_LP64_OFF64,
    __XYX___SC_XBS5_LPBIG_OFFBIG             = _SC_XBS5_LPBIG_OFFBIG,

    __XYX___SC_XOPEN_LEGACY                  = _SC_XOPEN_LEGACY,
    __XYX___SC_XOPEN_REALTIME                = _SC_XOPEN_REALTIME,
    __XYX___SC_XOPEN_REALTIME_THREADS        = _SC_XOPEN_REALTIME_THREADS,

    __XYX___SC_ADVISORY_INFO                 = _SC_ADVISORY_INFO,
    __XYX___SC_BARRIERS                      = _SC_BARRIERS,
#ifdef _SC_BASE
    __XYX___SC_BASE                          = _SC_BASE,
#endif
#ifdef _SC_C_LANG_SUPPORT
    __XYX___SC_C_LANG_SUPPORT                = _SC_C_LANG_SUPPORT,
#endif
#ifdef _SC_C_LANG_SUPPORT_R
    __XYX___SC_C_LANG_SUPPORT_R              = _SC_C_LANG_SUPPORT_R,
#endif
    __XYX___SC_CLOCK_SELECTION               = _SC_CLOCK_SELECTION,
    __XYX___SC_CPUTIME                       = _SC_CPUTIME,
    __XYX___SC_THREAD_CPUTIME                = _SC_THREAD_CPUTIME,
#ifdef _SC_DEVICE_IO
    __XYX___SC_DEVICE_IO                     = _SC_DEVICE_IO,
#endif
#ifdef _SC_DEVICE_SPECIFIC
    __XYX___SC_DEVICE_SPECIFIC               = _SC_DEVICE_SPECIFIC,
#endif
#ifdef _SC_DEVICE_SPECIFIC_R
    __XYX___SC_DEVICE_SPECIFIC_R             = _SC_DEVICE_SPECIFIC_R,
#endif
#ifdef _SC_FD_MGMT
    __XYX___SC_FD_MGMT                       = _SC_FD_MGMT,
#endif
#ifdef _SC_FIFO
    __XYX___SC_FIFO                          = _SC_FIFO,
#endif
#ifdef _SC_PIPE
    __XYX___SC_PIPE                          = _SC_PIPE,
#endif
#ifdef _SC_PIPE
    __XYX___SC_FILE_ATTRIBUTES               = _SC_FILE_ATTRIBUTES,
#endif
#ifdef _SC_FILE_LOCKING
    __XYX___SC_FILE_LOCKING                  = _SC_FILE_LOCKING,
#endif
#ifdef _SC_FILE_SYSTEM
    __XYX___SC_FILE_SYSTEM                   = _SC_FILE_SYSTEM,
#endif
    __XYX___SC_MONOTONIC_CLOCK               = _SC_MONOTONIC_CLOCK,
#ifdef _SC_MULTI_PROCESS
    __XYX___SC_MULTI_PROCESS                 = _SC_MULTI_PROCESS,
#endif
#ifdef _SC_SINGLE_PROCESS
    __XYX___SC_SINGLE_PROCESS                = _SC_SINGLE_PROCESS,
#endif
#ifdef _SC_NETWORKING
    __XYX___SC_NETWORKING                    = _SC_NETWORKING,
#endif
    __XYX___SC_READER_WRITER_LOCKS           = _SC_READER_WRITER_LOCKS,
    __XYX___SC_SPIN_LOCKS                    = _SC_SPIN_LOCKS,
    __XYX___SC_REGEXP                        = _SC_REGEXP,
#ifdef _SC_REGEX_VERSION
    __XYX___SC_REGEX_VERSION                 = _SC_REGEX_VERSION,
#endif
    __XYX___SC_SHELL                         = _SC_SHELL,
#ifdef _SC_SIGNALS
    __XYX___SC_SIGNALS                       = _SC_SIGNALS,
#endif
    __XYX___SC_SPAWN                         = _SC_SPAWN,
    __XYX___SC_SPORADIC_SERVER               = _SC_SPORADIC_SERVER,
    __XYX___SC_THREAD_SPORADIC_SERVER        = _SC_THREAD_SPORADIC_SERVER,
#ifdef _SC_SYSTEM_DATABASE
    __XYX___SC_SYSTEM_DATABASE               = _SC_SYSTEM_DATABASE,
#endif
#ifdef _SC_SYSTEM_DATABASE_R
    __XYX___SC_SYSTEM_DATABASE_R             = _SC_SYSTEM_DATABASE_R,
#endif
    __XYX___SC_TIMEOUTS                      = _SC_TIMEOUTS,
    __XYX___SC_TYPED_MEMORY_OBJECTS          = _SC_TYPED_MEMORY_OBJECTS,
#ifdef _SC_USER_GROUPS
    __XYX___SC_USER_GROUPS                   = _SC_USER_GROUPS,
#endif
#ifdef _SC_USER_GROUPS_R
    __XYX___SC_USER_GROUPS_R                 = _SC_USER_GROUPS_R,
#endif
    __XYX___SC_2_PBS                         = _SC_2_PBS,
    __XYX___SC_2_PBS_ACCOUNTING              = _SC_2_PBS_ACCOUNTING,
    __XYX___SC_2_PBS_LOCATE                  = _SC_2_PBS_LOCATE,
    __XYX___SC_2_PBS_MESSAGE                 = _SC_2_PBS_MESSAGE,
    __XYX___SC_2_PBS_TRACK                   = _SC_2_PBS_TRACK,
    __XYX___SC_SYMLOOP_MAX                   = _SC_SYMLOOP_MAX,
#ifdef _SC_STREAMS
    __XYX___SC_STREAMS                       = _SC_STREAMS,
#endif
    __XYX___SC_2_PBS_CHECKPOINT              = _SC_2_PBS_CHECKPOINT,

    __XYX___SC_V6_ILP32_OFF32                = _SC_V6_ILP32_OFF32,
    __XYX___SC_V6_ILP32_OFFBIG               = _SC_V6_ILP32_OFFBIG,
    __XYX___SC_V6_LP64_OFF64                 = _SC_V6_LP64_OFF64,
    __XYX___SC_V6_LPBIG_OFFBIG               = _SC_V6_LPBIG_OFFBIG,

    __XYX___SC_HOST_NAME_MAX                 = _SC_HOST_NAME_MAX,
    __XYX___SC_TRACE                         = _SC_TRACE,
    __XYX___SC_TRACE_EVENT_FILTER            = _SC_TRACE_EVENT_FILTER,
    __XYX___SC_TRACE_INHERIT                 = _SC_TRACE_INHERIT,
    __XYX___SC_TRACE_LOG                     = _SC_TRACE_LOG,

#ifdef _SC_LEVEL1_ICACHE_SIZE
    __XYX___SC_LEVEL1_ICACHE_SIZE            = _SC_LEVEL1_ICACHE_SIZE,
    __XYX___SC_LEVEL1_ICACHE_ASSOC           = _SC_LEVEL1_ICACHE_ASSOC,
    __XYX___SC_LEVEL1_ICACHE_LINESIZE        = _SC_LEVEL1_ICACHE_LINESIZE,
    __XYX___SC_LEVEL1_DCACHE_SIZE            = _SC_LEVEL1_DCACHE_SIZE,
    __XYX___SC_LEVEL1_DCACHE_ASSOC           = _SC_LEVEL1_DCACHE_ASSOC,
    __XYX___SC_LEVEL1_DCACHE_LINESIZE        = _SC_LEVEL1_DCACHE_LINESIZE,
    __XYX___SC_LEVEL2_CACHE_SIZE             = _SC_LEVEL2_CACHE_SIZE,
    __XYX___SC_LEVEL2_CACHE_ASSOC            = _SC_LEVEL2_CACHE_ASSOC,
    __XYX___SC_LEVEL2_CACHE_LINESIZE         = _SC_LEVEL2_CACHE_LINESIZE,
    __XYX___SC_LEVEL3_CACHE_SIZE             = _SC_LEVEL3_CACHE_SIZE,
    __XYX___SC_LEVEL3_CACHE_ASSOC            = _SC_LEVEL3_CACHE_ASSOC,
    __XYX___SC_LEVEL3_CACHE_LINESIZE         = _SC_LEVEL3_CACHE_LINESIZE,
    __XYX___SC_LEVEL4_CACHE_SIZE             = _SC_LEVEL4_CACHE_SIZE,
    __XYX___SC_LEVEL4_CACHE_ASSOC            = _SC_LEVEL4_CACHE_ASSOC,
    __XYX___SC_LEVEL4_CACHE_LINESIZE         = _SC_LEVEL4_CACHE_LINESIZE,
#endif

    __XYX___SC_IPV6                          = _SC_IPV6,
    __XYX___SC_RAW_SOCKETS                   = _SC_RAW_SOCKETS,
}
#endif // UNISTD_SKIP_ALL

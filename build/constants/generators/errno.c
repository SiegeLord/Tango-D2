#include <errno.h>
#undef errno
#undef const
tt
xxx start xxx
module tango.stdc.constants.autoconf.errno;

enum {
#ifdef E2BIG
    __XYX__E2BIG = E2BIG, // Argument list too long
#endif
#ifdef EACCES
    __XYX__EACCES = EACCES, // Permission denied
#endif
#ifdef EADDRINUSE
    __XYX__EADDRINUSE = EADDRINUSE, // Address already in use
#endif
#ifdef EADDRNOTAVAIL
    __XYX__EADDRNOTAVAIL = EADDRNOTAVAIL, // Can't assign requested address
#endif
#ifdef EADV
    __XYX__EADV = EADV, // Advertise error
#endif
#ifdef EAFNOSUPPORT
    __XYX__EAFNOSUPPORT = EAFNOSUPPORT, // Address family not supported by protocol family
#endif
#ifdef EAGAIN
    __XYX__EAGAIN = EAGAIN, // Resource temporarily unavailable
#endif
#ifdef EALREADY
    __XYX__EALREADY = EALREADY, // Operation already in progress
#endif
#ifdef EAUTH
    __XYX__EAUTH = EAUTH, // Authentication error
#endif
#ifdef EBADE
    __XYX__EBADE = EBADE, // Invalid exchange
#endif
#ifdef EBADF
    __XYX__EBADF = EBADF, // Bad file descriptor
#endif
#ifdef EBADFD
    __XYX__EBADFD = EBADFD, // File descriptor in bad state
#endif
#ifdef EBADMSG
    __XYX__EBADMSG = EBADMSG, // Bad message
#endif
#ifdef EBADR
    __XYX__EBADR = EBADR, // Invalid request descriptor
#endif
#ifdef EBADRPC
    __XYX__EBADRPC = EBADRPC, // RPC struct is bad
#endif
#ifdef EBADRQC
    __XYX__EBADRQC = EBADRQC, // Invalid request code
#endif
#ifdef EBADSLT
    __XYX__EBADSLT = EBADSLT, // Invalid slot
#endif
#ifdef EBFONT
    __XYX__EBFONT = EBFONT, // Bad font file format
#endif
#ifdef EBUSY
    __XYX__EBUSY = EBUSY, // Device busy
#endif
#ifdef ECANCELED
    __XYX__ECANCELED = ECANCELED, // Operation canceled
#endif
#ifdef ECHILD
    __XYX__ECHILD = ECHILD, // No child processes
#endif
#ifdef ECHRNG
    __XYX__ECHRNG = ECHRNG, // Channel number out of range
#endif
#ifdef ECOMM
    __XYX__ECOMM = ECOMM, // Communication error on send
#endif
#ifdef ECONNABORTED
    __XYX__ECONNABORTED = ECONNABORTED, // Software caused connection abort
#endif
#ifdef ECONNREFUSED
    __XYX__ECONNREFUSED = ECONNREFUSED, // Connection refused
#endif
#ifdef ECONNRESET
    __XYX__ECONNRESET = ECONNRESET, // Connection reset by peer
#endif
#ifdef EDEADLK
    __XYX__EDEADLK = EDEADLK, // Resource deadlock avoided
#endif
#ifdef EDEADLOCK
    __XYX__EDEADLOCK = EDEADLOCK, 
#endif
#ifdef EDESTADDRREQ
    __XYX__EDESTADDRREQ = EDESTADDRREQ, // Destination address required
#endif
#ifdef EDOM
    __XYX__EDOM = EDOM, // Numerical argument out of domain
#endif
#ifdef EDOOFUS
    __XYX__EDOOFUS = EDOOFUS, // Programming error
#endif
#ifdef EDOTDOT
    __XYX__EDOTDOT = EDOTDOT, // RFS specific error
#endif
#ifdef EDQUOT
    __XYX__EDQUOT = EDQUOT, // Disc quota exceeded
#endif
#ifdef EEXIST
    __XYX__EEXIST = EEXIST, // File exists
#endif
#ifdef EFAULT
    __XYX__EFAULT = EFAULT, // Bad address
#endif
#ifdef EFBIG
    __XYX__EFBIG = EFBIG, // File too large
#endif
#ifdef EFTYPE
    __XYX__EFTYPE = EFTYPE, // Inappropriate file type or format
#endif
#ifdef EHOSTDOWN
    __XYX__EHOSTDOWN = EHOSTDOWN, // Host is down
#endif
#ifdef EHOSTUNREACH
    __XYX__EHOSTUNREACH = EHOSTUNREACH, // No route to host
#endif
#ifdef EIDRM
    __XYX__EIDRM = EIDRM, // Itendifier removed
#endif
#ifdef EILSEQ
    __XYX__EILSEQ = EILSEQ, // Illegal byte sequence
#endif
#ifdef EINPROGRESS
    __XYX__EINPROGRESS = EINPROGRESS, // Operation now in progress
#endif
#ifdef EINTR
    __XYX__EINTR = EINTR, // Interrupted system call
#endif
#ifdef EINVAL
    __XYX__EINVAL = EINVAL, // Invalid argument
#endif
#ifdef EIO
    __XYX__EIO = EIO, // Input/output error
#endif
#ifdef EISCONN
    __XYX__EISCONN = EISCONN, // Socket is already connected
#endif
#ifdef EISDIR
    __XYX__EISDIR = EISDIR, // Is a directory
#endif
#ifdef EISNAM
    __XYX__EISNAM = EISNAM, // Is a named type file
#endif
#ifdef EKEYEXPIRED
    __XYX__EKEYEXPIRED = EKEYEXPIRED, // Key has expired
#endif
#ifdef EKEYREJECTED
    __XYX__EKEYREJECTED = EKEYREJECTED, // Key was rejected by service
#endif
#ifdef EKEYREVOKED
    __XYX__EKEYREVOKED = EKEYREVOKED, // Key has been revoked
#endif
#ifdef EL2HLT
    __XYX__EL2HLT = EL2HLT, // Level 2 halted
#endif
#ifdef EL2NSYNC
    __XYX__EL2NSYNC = EL2NSYNC, // Level 2 not synchronized
#endif
#ifdef EL3HLT
    __XYX__EL3HLT = EL3HLT, // Level 3 halted
#endif
#ifdef EL3RST
    __XYX__EL3RST = EL3RST, // Level 3 reset
#endif
#ifdef ELAST
    __XYX__ELAST = ELAST, // Must be equal largest errno
#endif
#ifdef ELIBACC
    __XYX__ELIBACC = ELIBACC, // Can not access a needed shared library
#endif
#ifdef ELIBBAD
    __XYX__ELIBBAD = ELIBBAD, // Accessing a corrupted shared library
#endif
#ifdef ELIBEXEC
    __XYX__ELIBEXEC = ELIBEXEC, // Cannot exec a shared library directly
#endif
#ifdef ELIBMAX
    __XYX__ELIBMAX = ELIBMAX, // Attempting to link in too many shared libraries
#endif
#ifdef ELIBSCN
    __XYX__ELIBSCN = ELIBSCN, // .lib section in a.out corrupted
#endif
#ifdef ELNRNG
    __XYX__ELNRNG = ELNRNG, // Link number out of range
#endif
#ifdef ELOOP
    __XYX__ELOOP = ELOOP, // Too many levels of symbolic links
#endif
#ifdef EMEDIUMTYPE
    __XYX__EMEDIUMTYPE = EMEDIUMTYPE, // Wrong medium type
#endif
#ifdef EMFILE
    __XYX__EMFILE = EMFILE, // Too many open files
#endif
#ifdef EMLINK
    __XYX__EMLINK = EMLINK, // Too many links
#endif
#ifdef EMSGSIZE
    __XYX__EMSGSIZE = EMSGSIZE, // Message too long
#endif
#ifdef EMULTIHOP
    __XYX__EMULTIHOP = EMULTIHOP, // Multihop attempted
#endif
#ifdef ENAMETOOLONG
    __XYX__ENAMETOOLONG = ENAMETOOLONG, // File name too long
#endif
#ifdef ENAVAIL
    __XYX__ENAVAIL = ENAVAIL, // No XENIX semaphores available
#endif
#ifdef ENEEDAUTH
    __XYX__ENEEDAUTH = ENEEDAUTH, // Need authenticator
#endif
#ifdef ENETDOWN
    __XYX__ENETDOWN = ENETDOWN, // Network is down
#endif
#ifdef ENETRESET
    __XYX__ENETRESET = ENETRESET, // Network dropped connection on reset
#endif
#ifdef ENETUNREACH
    __XYX__ENETUNREACH = ENETUNREACH, // Network is unreachable
#endif
#ifdef ENFILE
    __XYX__ENFILE = ENFILE, // Too many open files in system
#endif
#ifdef ENOANO
    __XYX__ENOANO = ENOANO, // No anode
#endif
#ifdef ENOATTR
    __XYX__ENOATTR = ENOATTR, // Attribute not found
#endif
#ifdef ENOBUFS
    __XYX__ENOBUFS = ENOBUFS, // No buffer space available
#endif
#ifdef ENOCSI
    __XYX__ENOCSI = ENOCSI, // No CSI structure available
#endif
#ifdef ENODATA
    __XYX__ENODATA = ENODATA, // No message available on STREAM
#endif
#ifdef ENODEV
    __XYX__ENODEV = ENODEV, // Operation not supported by device
#endif
#ifdef ENOENT
    __XYX__ENOENT = ENOENT, // No such file or directory
#endif
#ifdef ENOEXEC
    __XYX__ENOEXEC = ENOEXEC, // Exec format error
#endif
#ifdef ENOKEY
    __XYX__ENOKEY = ENOKEY, // Required key not available
#endif
#ifdef ENOLCK
    __XYX__ENOLCK = ENOLCK, // No locks available
#endif
#ifdef ENOLINK
    __XYX__ENOLINK = ENOLINK, // Link has been severed
#endif
#ifdef ENOMEDIUM
    __XYX__ENOMEDIUM = ENOMEDIUM, // No medium found
#endif
#ifdef ENOMEM
    __XYX__ENOMEM = ENOMEM, // Cannot allocate memory
#endif
#ifdef ENOMSG
    __XYX__ENOMSG = ENOMSG, // No message of desired type
#endif
#ifdef ENONET
    __XYX__ENONET = ENONET, // Machine is not on the network
#endif
#ifdef ENOPKG
    __XYX__ENOPKG = ENOPKG, // Package not installed
#endif
#ifdef ENOPROTOOPT
    __XYX__ENOPROTOOPT = ENOPROTOOPT, // Protocol not available
#endif
#ifdef ENOSPC
    __XYX__ENOSPC = ENOSPC, // No space left on device
#endif
#ifdef ENOSR
    __XYX__ENOSR = ENOSR, // No STREAM resources
#endif
#ifdef ENOSTR
    __XYX__ENOSTR = ENOSTR, // Not a STREAM
#endif
#ifdef ENOSYS
    __XYX__ENOSYS = ENOSYS, // Function not implemented
#endif
#ifdef ENOTBLK
    __XYX__ENOTBLK = ENOTBLK, // Block device required
#endif
#ifdef ENOTCONN
    __XYX__ENOTCONN = ENOTCONN, // Socket is not connected
#endif
#ifdef ENOTDIR
    __XYX__ENOTDIR = ENOTDIR, // Not a directory
#endif
#ifdef ENOTEMPTY
    __XYX__ENOTEMPTY = ENOTEMPTY, // Directory not empty
#endif
#ifdef ENOTNAM
    __XYX__ENOTNAM = ENOTNAM, // Not a XENIX named type file
#endif
#ifdef ENOTRECOVERABLE
    __XYX__ENOTRECOVERABLE = ENOTRECOVERABLE, // State not recoverable
#endif
#ifdef ENOTSOCK
    __XYX__ENOTSOCK = ENOTSOCK, // Socket operation on non-socket
#endif
#ifdef ENOTSUP
    __XYX__ENOTSUP = ENOTSUP, // Operation not supported
#endif
#ifdef ENOTTY
    __XYX__ENOTTY = ENOTTY, // Inappropriate ioctl for device
#endif
#ifdef ENOTUNIQ
    __XYX__ENOTUNIQ = ENOTUNIQ, // Name not unique on network
#endif
#ifdef ENXIO
    __XYX__ENXIO = ENXIO, // Device not configured
#endif
#ifdef EOPNOTSUPP
    __XYX__EOPNOTSUPP = EOPNOTSUPP, // Operation not supported on socket
#endif
#ifdef EOVERFLOW
    __XYX__EOVERFLOW = EOVERFLOW, // Value too large to be stored in data type
#endif
#ifdef EOWNERDEAD
    __XYX__EOWNERDEAD = EOWNERDEAD, // Owner died
#endif
#ifdef EPERM
    __XYX__EPERM = EPERM, // Operation not permitted
#endif
#ifdef EPFNOSUPPORT
    __XYX__EPFNOSUPPORT = EPFNOSUPPORT, // Protocol family not supported
#endif
#ifdef EPIPE
    __XYX__EPIPE = EPIPE, // Broken pipe
#endif
#ifdef EPROCLIM
    __XYX__EPROCLIM = EPROCLIM, // Too many processes
#endif
#ifdef EPROCUNAVAIL
    __XYX__EPROCUNAVAIL = EPROCUNAVAIL, // Bad procedure for program
#endif
#ifdef EPROGMISMATCH
    __XYX__EPROGMISMATCH = EPROGMISMATCH, // Program version wrong
#endif
#ifdef EPROGUNAVAIL
    __XYX__EPROGUNAVAIL = EPROGUNAVAIL, // RPC prog. not avail
#endif
#ifdef EPROTO
    __XYX__EPROTO = EPROTO, // Protocol error
#endif
#ifdef EPROTONOSUPPORT
    __XYX__EPROTONOSUPPORT = EPROTONOSUPPORT, // Protocol not supported
#endif
#ifdef EPROTOTYPE
    __XYX__EPROTOTYPE = EPROTOTYPE, // Protocol wrong type for socket
#endif
#ifdef ERANGE
    __XYX__ERANGE = ERANGE, // Result too large
#endif
#ifdef EREMCHG
    __XYX__EREMCHG = EREMCHG, // Remote address changed
#endif
#ifdef EREMOTE
    __XYX__EREMOTE = EREMOTE, // Too many levels of remote in path
#endif
#ifdef EREMOTEIO
    __XYX__EREMOTEIO = EREMOTEIO, // Remote I/O error
#endif
#ifdef ERESTART
    __XYX__ERESTART = ERESTART, // Interrupted system call should be restarted
#endif
#ifdef EROFS
    __XYX__EROFS = EROFS, // Read-only file system
#endif
#ifdef ERPCMISMATCH
    __XYX__ERPCMISMATCH = ERPCMISMATCH, // RPC version wrong
#endif
#ifdef ESHUTDOWN
    __XYX__ESHUTDOWN = ESHUTDOWN, // Can't send after socket shutdown
#endif
#ifdef ESOCKTNOSUPPORT
    __XYX__ESOCKTNOSUPPORT = ESOCKTNOSUPPORT, // Socket type not supported
#endif
#ifdef ESPIPE
    __XYX__ESPIPE = ESPIPE, // Illegal seek
#endif
#ifdef ESRCH
    __XYX__ESRCH = ESRCH, // No such process
#endif
#ifdef ESRMNT
    __XYX__ESRMNT = ESRMNT, // Srmount error
#endif
#ifdef ESTALE
    __XYX__ESTALE = ESTALE, // Stale NFS file handle
#endif
#ifdef ESTRPIPE
    __XYX__ESTRPIPE = ESTRPIPE, // Streams pipe error
#endif
#ifdef ETIME
    __XYX__ETIME = ETIME, // STREAM ioctl timeout
#endif
#ifdef ETIMEDOUT
    __XYX__ETIMEDOUT = ETIMEDOUT, // Operation timed out
#endif
#ifdef ETOOMANYREFS
    __XYX__ETOOMANYREFS = ETOOMANYREFS, // Too many refrences, can't splice
#endif
#ifdef ETXTBSY
    __XYX__ETXTBSY = ETXTBSY, // Text file busy
#endif
#ifdef EUCLEAN
    __XYX__EUCLEAN = EUCLEAN, // Structure needs cleaning
#endif
#ifdef EUNATCH
    __XYX__EUNATCH = EUNATCH, // Protocol driver not attached
#endif
#ifdef EUSERS
    __XYX__EUSERS = EUSERS, // Too many users
#endif
#ifdef EWOULDBLOCK
    __XYX__EWOULDBLOCK = EWOULDBLOCK, // Operation would block
#endif
#ifdef EXDEV
    __XYX__EXDEV = EXDEV, // Cross-device link
#endif
#ifdef EXFULL
    __XYX__EXFULL = EXFULL, // Exchange full
#endif
}
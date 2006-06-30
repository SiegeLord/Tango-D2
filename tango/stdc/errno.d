/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.errno;

extern (C):

extern (C) int errno;

version( Win32 )
{
    const auto EPERM            = 1;        // Operation not permitted
    const auto ENOENT           = 2;        // No such file or directory
    const auto ESRCH            = 3;        // No such process
    const auto EINTR            = 4;        // Interrupted system call
    const auto EIO              = 5;        // I/O error
    const auto ENXIO            = 6;        // No such device or address
    const auto E2BIG            = 7;        // Argument list too long
    const auto ENOEXEC          = 8;        // Exec format error
    const auto EBADF            = 9;        // Bad file number
    const auto ECHILD           = 10;       // No child processes
    const auto EAGAIN           = 11;       // Try again
    const auto ENOMEM           = 12;       // Out of memory
    const auto EACCES           = 13;       // Permission denied
    const auto EFAULT           = 14;       // Bad address
    const auto EBUSY            = 16;       // Device or resource busy
    const auto EEXIST           = 17;       // File exists
    const auto EXDEV            = 18;       // Cross-device link
    const auto ENODEV           = 19;       // No such device
    const auto ENOTDIR          = 20;       // Not a directory
    const auto EISDIR           = 21;       // Is a directory
    const auto EINVAL           = 22;       // Invalid argument
    const auto ENFILE           = 23;       // File table overflow
    const auto EMFILE           = 24;       // Too many open files
    const auto ENOTTY           = 25;       // Not a typewriter
    const auto EFBIG            = 27;       // File too large
    const auto ENOSPC           = 28;       // No space left on device
    const auto ESPIPE           = 29;       // Illegal seek
    const auto EROFS            = 30;       // Read-only file system
    const auto EMLINK           = 31;       // Too many links
    const auto EPIPE            = 32;       // Broken pipe
    const auto EDOM             = 33;       // Math argument out of domain of func
    const auto ERANGE           = 34;       // Math result not representable
    const auto EDEADLK          = 36;       // Resource deadlock would occur
    const auto ENAMETOOLONG     = 38;       // File name too long
    const auto ENOLCK           = 39;       // No record locks available
    const auto ENOSYS           = 40;       // Function not implemented
    const auto ENOTEMPTY        = 41;       // Directory not empty
    const auto EILSEQ           = 42;       // Illegal byte sequence
    const auto EDEADLOCK        = EDEADLK;
}
else version( linux )
{
    const auto EPERM            = 1;        // Operation not permitted
    const auto ENOENT           = 2;        // No such file or directory
    const auto ESRCH            = 3;        // No such process
    const auto EINTR            = 4;        // Interrupted system call
    const auto EIO              = 5;        // I/O error
    const auto ENXIO            = 6;        // No such device or address
    const auto E2BIG            = 7;        // Argument list too long
    const auto ENOEXEC          = 8;        // Exec format error
    const auto EBADF            = 9;        // Bad file number
    const auto ECHILD           = 10;       // No child processes
    const auto EAGAIN           = 11;       // Try again
    const auto ENOMEM           = 12;       // Out of memory
    const auto EACCES           = 13;       // Permission denied
    const auto EFAULT           = 14;       // Bad address
    const auto ENOTBLK          = 15;       // Block device required
    const auto EBUSY            = 16;       // Device or resource busy
    const auto EEXIST           = 17;       // File exists
    const auto EXDEV            = 18;       // Cross-device link
    const auto ENODEV           = 19;       // No such device
    const auto ENOTDIR          = 20;       // Not a directory
    const auto EISDIR           = 21;       // Is a directory
    const auto EINVAL           = 22;       // Invalid argument
    const auto ENFILE           = 23;       // File table overflow
    const auto EMFILE           = 24;       // Too many open files
    const auto ENOTTY           = 25;       // Not a typewriter
    const auto ETXTBSY          = 26;       // Text file busy
    const auto EFBIG            = 27;       // File too large
    const auto ENOSPC           = 28;       // No space left on device
    const auto ESPIPE           = 29;       // Illegal seek
    const auto EROFS            = 30;       // Read-only file system
    const auto EMLINK           = 31;       // Too many links
    const auto EPIPE            = 32;       // Broken pipe
    const auto EDOM             = 33;       // Math argument out of domain of func
    const auto ERANGE           = 34;       // Math result not representable
    const auto EDEADLK          = 35;       // Resource deadlock would occur
    const auto ENAMETOOLONG     = 36;       // File name too long
    const auto ENOLCK           = 37;       // No record locks available
    const auto ENOSYS           = 38;       // Function not implemented
    const auto ENOTEMPTY        = 39;       // Directory not empty
    const auto ELOOP            = 40;       // Too many symbolic links encountered
    const auto EWOULDBLOCK      = EAGAIN;   // Operation would block
    const auto ENOMSG           = 42;       // No message of desired type
    const auto EIDRM            = 43;       // Identifier removed
    const auto ECHRNG           = 44;       // Channel number out of range
    const auto EL2NSYNC         = 45;       // Level 2 not synchronized
    const auto EL3HLT           = 46;       // Level 3 halted
    const auto EL3RST           = 47;       // Level 3 reset
    const auto ELNRNG           = 48;       // Link number out of range
    const auto EUNATCH          = 49;       // Protocol driver not attached
    const auto ENOCSI           = 50;       // No CSI structure available
    const auto EL2HLT           = 51;       // Level 2 halted
    const auto EBADE            = 52;       // Invalid exchange
    const auto EBADR            = 53;       // Invalid request descriptor
    const auto EXFULL           = 54;       // Exchange full
    const auto ENOANO           = 55;       // No anode
    const auto EBADRQC          = 56;       // Invalid request code
    const auto EBADSLT          = 57;       // Invalid slot
    const auto EDEADLOCK        = EDEADLK;
    const auto EBFONT           = 59;       // Bad font file format
    const auto ENOSTR           = 60;       // Device not a stream
    const auto ENODATA          = 61;       // No data available
    const auto ETIME            = 62;       // Timer expired
    const auto ENOSR            = 63;       // Out of streams resources
    const auto ENONET           = 64;       // Machine is not on the network
    const auto ENOPKG           = 65;       // Package not installed
    const auto EREMOTE          = 66;       // Object is remote
    const auto ENOLINK          = 67;       // Link has been severed
    const auto EADV             = 68;       // Advertise error
    const auto ESRMNT           = 69;       // Srmount error
    const auto ECOMM            = 70;       // Communication error on send
    const auto EPROTO           = 71;       // Protocol error
    const auto EMULTIHOP        = 72;       // Multihop attempted
    const auto EDOTDOT          = 73;       // RFS specific error
    const auto EBADMSG          = 74;       // Not a data message
    const auto EOVERFLOW        = 75;       // Value too large for defined data type
    const auto ENOTUNIQ         = 76;       // Name not unique on network
    const auto EBADFD           = 77;       // File descriptor in bad state
    const auto EREMCHG          = 78;       // Remote address changed
    const auto ELIBACC          = 79;       // Can not access a needed shared library
    const auto ELIBBAD          = 80;       // Accessing a corrupted shared library
    const auto ELIBSCN          = 81;       // .lib section in a.out corrupted
    const auto ELIBMAX          = 82;       // Attempting to link in too many shared libraries
    const auto ELIBEXEC         = 83;       // Cannot exec a shared library directly
    const auto EILSEQ           = 84;       // Illegal byte sequence
    const auto ERESTART         = 85;       // Interrupted system call should be restarted
    const auto ESTRPIPE         = 86;       // Streams pipe error
    const auto EUSERS           = 87;       // Too many users
    const auto ENOTSOCK         = 88;       // Socket operation on non-socket
    const auto EDESTADDRREQ     = 89;       // Destination address required
    const auto EMSGSIZE         = 90;       // Message too long
    const auto EPROTOTYPE       = 91;       // Protocol wrong type for socket
    const auto ENOPROTOOPT      = 92;       // Protocol not available
    const auto EPROTONOSUPPORT  = 93;       // Protocol not supported
    const auto ESOCKTNOSUPPORT  = 94;       // Socket type not supported
    const auto EOPNOTSUPP       = 95;       // Operation not supported on transport endpoint
    const auto EPFNOSUPPORT     = 96;       // Protocol family not supported
    const auto EAFNOSUPPORT     = 97;       // Address family not supported by protocol
    const auto EADDRINUSE       = 98;       // Address already in use
    const auto EADDRNOTAVAIL    = 99;       // Cannot assign requested address
    const auto ENETDOWN         = 100;      // Network is down
    const auto ENETUNREACH      = 101;      // Network is unreachable
    const auto ENETRESET        = 102;      // Network dropped connection because of reset
    const auto ECONNABORTED     = 103;      // Software caused connection abort
    const auto ECONNRESET       = 104;      // Connection reset by peer
    const auto ENOBUFS          = 105;      // No buffer space available
    const auto EISCONN          = 106;      // Transport endpoint is already connected
    const auto ENOTCONN         = 107;      // Transport endpoint is not connected
    const auto ESHUTDOWN        = 108;      // Cannot send after transport endpoint shutdown
    const auto ETOOMANYREFS     = 109;      // Too many references: cannot splice
    const auto ETIMEDOUT        = 110;      // Connection timed out
    const auto ECONNREFUSED     = 111;      // Connection refused
    const auto EHOSTDOWN        = 112;      // Host is down
    const auto EHOSTUNREACH     = 113;      // No route to host
    const auto EALREADY         = 114;      // Operation already in progress
    const auto EINPROGRESS      = 115;      // Operation now in progress
    const auto ESTALE           = 116;      // Stale NFS file handle
    const auto EUCLEAN          = 117;      // Structure needs cleaning
    const auto ENOTNAM          = 118;      // Not a XENIX named type file
    const auto ENAVAIL          = 119;      // No XENIX semaphores available
    const auto EISNAM           = 120;      // Is a named type file
    const auto EREMOTEIO        = 121;      // Remote I/O error
    const auto EDQUOT           = 122;      // Quota exceeded
    const auto ENOMEDIUM        = 123;      // No medium found
    const auto EMEDIUMTYPE      = 124;      // Wrong medium type
    const auto ECANCELED        = 125;      // Operation Canceled
    const auto ENOKEY           = 126;      // Required key not available
    const auto EKEYEXPIRED      = 127;      // Key has expired
    const auto EKEYREVOKED      = 128;      // Key has been revoked
    const auto EKEYREJECTED     = 129;      // Key was rejected by service
    const auto EOWNERDEAD       = 130;      // Owner died
    const auto ENOTRECOVERABLE  = 131;      // State not recoverable
}
module tango.sys.win32.consts.socket;

/***************************************************************


***************************************************************/

enum : int
{
        IOCPARM_MASK =  0x7f,
        IOC_IN =        0x80000000,
        FIONBIO =       (IOC_IN | ((int.sizeof & IOCPARM_MASK) << 16) | (102 << 8) | 126),
}

/***************************************************************


***************************************************************/
enum {SOCKET_ERROR = -1}

enum
{
        //consistent
        SO_DEBUG =              0x1,

        //possibly Winsock-only values
        SO_BROADCAST =          0x20,
        SO_REUSEADDR =          0x4,
        SO_LINGER =             0x80,
        SO_DONTLINGER =         ~(SO_LINGER),
        SO_OOBINLINE =          0x100,
        SO_SNDBUF =             0x1001,
        SO_RCVBUF =             0x1002,
        SO_ERROR =              0x1007,

        SO_ACCEPTCONN =         0x2, // ?
        SO_KEEPALIVE =          0x8, // ?
        SO_DONTROUTE =          0x10, // ?
        SO_TYPE =               0x1008, // ?

        // OptionLevel.IP settings
        IP_MULTICAST_TTL =      10,
        IP_MULTICAST_LOOP =     11,
        IP_ADD_MEMBERSHIP =     12,
        IP_DROP_MEMBERSHIP =    13,

        // OptionLevel.TCP settings
        TCP_NODELAY =           0x0001,
}

/***************************************************************


***************************************************************/

enum
{
        SOL_SOCKET =  0xFFFF,
}

/***************************************************************


***************************************************************/

enum
{
        AF_UNSPEC =     0,
        AF_UNIX =       1,
        AF_INET =       2,
        AF_INET6 =      23,
        AF_IPX =        6,
        AF_APPLETALK =  16,
}

/***********************************************************************

        Protocol

***********************************************************************/

enum
{
        IPPROTO_IP =    0,      /// internet protocol version 4
        IPPROTO_IPV4 =  4,      /// internet protocol version 4
        IPPROTO_IPV6 =  41,     /// internet protocol version 6
        IPPROTO_ICMP =  1,      /// internet control message protocol
        IPPROTO_IGMP =  2,      /// internet group management protocol
        IPPROTO_GGP =   3,      /// gateway to gateway protocol
        IPPROTO_TCP =   6,      /// transmission control protocol
        IPPROTO_PUP =   12,     /// PARC universal packet protocol
        IPPROTO_UDP =   17,     /// user datagram protocol
        IPPROTO_IDP =   22,     /// Xerox NS protocol
}

/***********************************************************************

         Communication semantics

***********************************************************************/

enum
{
        SOCK_STREAM =     1, /// sequenced, reliable, two-way communication-based byte streams
        SOCK_DGRAM =      2, /// connectionless, unreliable datagrams with a fixed maximum length; data may be lost or arrive out of order
        SOCK_RAW =        3, /// raw protocol access
        SOCK_RDM =        4, /// reliably-delivered message datagrams
        SOCK_SEQPACKET =  5, /// sequenced, reliable, two-way connection-based datagrams with a fixed maximum length
}
enum : uint
{
        SCM_RIGHTS = 0x01
}
enum
{
        SOMAXCONN       = 128,
}

enum : uint
{
        MSG_DONTROUTE   = 0x4,
        MSG_OOB         = 0x1,
        MSG_PEEK        = 0x2,
}

enum
{
        SHUT_RD = 0,
        SHUT_WR = 1,
        SHUT_RDWR = 2
}

enum: int
{
         AI_PASSIVE = 0x00000001,               /// Socket address will be used in bind() call
         AI_CANONNAME = 0x00000002,             /// Return canonical name in first ai_canonname
         AI_NUMERICHOST = 0x00000004 ,          /// Nodename must be a numeric address string
         AI_NUMERICSERV = 0x00000008,           /// Servicename must be a numeric port number
         AI_ALL = 0x00000100,                   /// Query both IP6 and IP4 with AI_V4MAPPED
         AI_ADDRCONFIG = 0x00000400,            /// Resolution only if global address configured
         AI_V4MAPPED = 0x00000800,              /// On v6 failure, query v4 and convert to V4MAPPED format
         AI_NON_AUTHORITATIVE = 0x00004000,     /// LUP_NON_AUTHORITATIVE
         AI_SECURE = 0x00008000,                /// LUP_SECURE
         AI_RETURN_PREFERRED_NAMES = 0x00010000,/// LUP_RETURN_PREFERRED_NAMES
         AI_FQDN = 0x00020000,                  /// Return the FQDN in ai_canonname
         AI_FILESERVER = 0x00040000,            /// Resolving fileserver name resolution 
         AI_MASK = (AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST | AI_NUMERICSERV | AI_ADDRCONFIG),
         AI_DEFAULT = (AI_V4MAPPED | AI_ADDRCONFIG),
}

enum
{
        EAI_BADFLAGS = 10022,                   /// Invalid value for `ai_flags' field.
        EAI_NONAME = 11001,                     /// NAME or SERVICE is unknown.
        EAI_AGAIN = 11002,                      /// Temporary failure in name resolution.
        EAI_FAIL = 11003,                       /// Non-recoverable failure in name res.
        EAI_NODATA = 11001,                     /// No address associated with NAME.
        EAI_FAMILY = 10047,                     /// `ai_family' not supported.
        EAI_SOCKTYPE = 10044,                   /// `ai_socktype' not supported.
        EAI_SERVICE = 10109,                    /// SERVICE not supported for `ai_socktype'.
        EAI_MEMORY = 8,                         /// Memory allocation failure.
}       

enum
{
        NI_MAXHOST = 1025,
        NI_MAXSERV = 32,
        NI_NUMERICHOST = 0x01,                  /// Don't try to look up hostname.
        NI_NUMERICSERV = 0x02,                  /// Don't convert port number to name.
        NI_NOFQDN = 0x04,                       /// Only return nodename portion.
        NI_NAMEREQD = 0x08,                     /// Don't return numeric addresses.
        NI_DGRAM = 0x10,                        /// Look up UDP service rather than TCP.
}       


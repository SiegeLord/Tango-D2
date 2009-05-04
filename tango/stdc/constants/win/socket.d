module tango.stdc.constants.win.socket;

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
        AF_INET6 =      2, // TODO: Need Windows XP ?
        AF_IPX =        6,
        AF_APPLETALK =  16,
}

/***********************************************************************

        Protocol

***********************************************************************/

enum
{
        IPPROTO_IP =    0,      /// internet protocol version 4
        IPPROTO_IPV4 =  0,      /// internet protocol version 4
        IPPROTO_IPV6 =  0,      /// TODO: internet protocol version 6
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

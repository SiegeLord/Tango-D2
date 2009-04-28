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

enum SocketOption : int
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

enum SocketOptionLevel : int
{
        SOCKET =  0xFFFF,
        IP =      0,
        TCP =     6,
        UDP =     17,
}

/***************************************************************


***************************************************************/

enum AddressFamily : int
{
        UNSPEC =     0,
        UNIX =       1,
        INET =       2,
        IPX =        6,
        APPLETALK =  16,
        //INET6 =      ? // Need Windows XP ?
}

/***********************************************************************

        Protocol

***********************************************************************/

enum ProtocolType : int
{
        IP =    0,      /// internet protocol version 4
        ICMP =  1,      /// internet control message protocol
        IGMP =  2,      /// internet group management protocol
        GGP =   3,      /// gateway to gateway protocol
        TCP =   6,      /// transmission control protocol
        PUP =   12,     /// PARC universal packet protocol
        UDP =   17,     /// user datagram protocol
        IDP =   22,     /// Xerox NS protocol
}

/***********************************************************************

         Communication semantics

***********************************************************************/

enum SocketType : int
{
        STREAM =     1, /// sequenced, reliable, two-way communication-based byte streams
        DGRAM =      2, /// connectionless, unreliable datagrams with a fixed maximum length; data may be lost or arrive out of order
        RAW =        3, /// raw protocol access
        RDM =        4, /// reliably-delivered message datagrams
        SEQPACKET =  5, /// sequenced, reliable, two-way connection-based datagrams with a fixed maximum length
}


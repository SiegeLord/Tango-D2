module tango.stdc.constants.win.socket;

private const int IOCPARM_MASK =  0x7f;
private const int IOC_IN =        cast(int)0x80000000;
private const int FIONBIO =       cast(int) (IOC_IN | ((int.sizeof & IOCPARM_MASK) << 16) | (102 << 8) | 126);

private const int WSADESCRIPTION_LEN = 256;
private const int WSASYS_STATUS_LEN = 128;
private const int WSAEWOULDBLOCK =  10035;
private const int WSAEINTR =        10004;

/***************************************************************


***************************************************************/

enum SocketOption: int
{
        //consistent
        SO_DEBUG =         0x1,

        //possibly Winsock-only values
        SO_BROADCAST =  0x20,
        SO_REUSEADDR =  0x4,
        SO_LINGER =     0x80,
        SO_DONTLINGER = ~(SO_LINGER),
        SO_OOBINLINE =  0x100,
        SO_SNDBUF =     0x1001,
        SO_RCVBUF =     0x1002,
        SO_ERROR =      0x1007,

        SO_ACCEPTCONN =    0x2, // ?
        SO_KEEPALIVE =     0x8, // ?
        SO_DONTROUTE =     0x10, // ?
        SO_TYPE =          0x1008, // ?

        // OptionLevel.IP settings
        IP_MULTICAST_TTL = 10,
        IP_MULTICAST_LOOP = 11,
        IP_ADD_MEMBERSHIP = 12,
        IP_DROP_MEMBERSHIP = 13,

        // OptionLevel.TCP settings
        TCP_NODELAY = 0x0001,
}

/***************************************************************


***************************************************************/

enum SocketOptionLevel
{
        SOCKET =  0xFFFF,
        IP =      0,
        TCP =     6,
        UDP =     17,
}

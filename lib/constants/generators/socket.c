#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#undef const
tt
xxx start xxx
module tango.stdc.constants.autoconf.socket;

#if (defined(_WINDOWS)||defined(WIN32))
enum {
    __XYX__IOCPARM_MASK = IOCPARM_MASK,
    __XYX__IOC_IN       = IOC_IN      ,
    __XYX__FIONBIO      = FIONBIO     ,
    
    __XYX__WSADESCRIPTION_LEN = WSADESCRIPTION_LEN,
    __XYX__WSASYS_STATUS_LEN  = WSASYS_STATUS_LEN ,
    __XYX__WSAEWOULDBLOCK     = WSAEWOULDBLOCK    ,
    __XYX__WSAEINTR           = WSAEINTR          ,
}
#else
    import tango.stdc.constants.fcntl: __XYX__F_GETFL, __XYX__F_SETFL,__XYX__O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
#endif

    enum SocketOption: int
    {
        __XYX__SO_DEBUG        =   SO_DEBUG     ,       /* turn on debugging info recording */
        __XYX__SO_BROADCAST    =   SO_BROADCAST ,       /* permit sending of broadcast msgs */
        __XYX__SO_REUSEADDR    =   SO_REUSEADDR ,       /* allow local address reuse */
        __XYX__SO_LINGER       =   SO_LINGER    ,       /* linger on close if data present */
        __XYX__SO_DONTLINGER   = ~(SO_LINGER),

        __XYX__SO_OOBINLINE    =   SO_OOBINLINE ,       /* leave received OOB data in line */
        __XYX__SO_ACCEPTCONN   =   SO_ACCEPTCONN,       /* socket has had listen() */
        __XYX__SO_KEEPALIVE    =   SO_KEEPALIVE ,       /* keep connections alive */
        __XYX__SO_DONTROUTE    =   SO_DONTROUTE ,       /* just use interface addresses */
        __XYX__SO_TYPE         =   SO_TYPE      ,       /* get socket type */
    
        /*
         * Additional options, not kept in so_options.
         */
        __XYX__SO_SNDBUF       = SO_SNDBUF,               /* send buffer size */
        __XYX__SO_RCVBUF       = SO_RCVBUF,               /* receive buffer size */
        __XYX__SO_ERROR        = SO_ERROR ,               /* get error status and clear */
    
        // OptionLevel.IP settings
        __XYX__IP_MULTICAST_TTL   = IP_MULTICAST_TTL  ,
        __XYX__IP_MULTICAST_LOOP  = IP_MULTICAST_LOOP ,
        __XYX__IP_ADD_MEMBERSHIP  = IP_ADD_MEMBERSHIP ,
        __XYX__IP_DROP_MEMBERSHIP = IP_DROP_MEMBERSHIP,
    
        // OptionLevel.TCP settings
        __XYX__TCP_NODELAY        = TCP_NODELAY ,
    }
    
    enum SocketOptionLevel
    {
        __XYX__SOCKET = SOL_SOCKET    ,
        __XYX__IP     = IPPROTO_IP    ,   
        __XYX__TCP    = IPPROTO_TCP   ,   
        __XYX__UDP    = IPPROTO_UDP   ,   
    }
    
    enum SocketType{
        __XYX__SOCK_STREAM    = SOCK_STREAM   , /++ sequential, reliable +/
        __XYX__SOCK_DGRAM     = SOCK_DGRAM    , /++ connectionless unreliable, max length +/
        __XYX__SOCK_SEQPACKET = SOCK_SEQPACKET, /++ sequential, reliable, max length +/
#ifdef SOCK_RAW
        __XYX__SOCK_RAW       = SOCK_RAW      , /++ raw protocol +/
#endif
#ifdef SOCK_RDM
        __XYX__SOCK_RDM       = SOCK_RDM      , /++ reliable messages +/
#endif
#ifdef SOCK_PACKET
        __XYX__SOCK_PACKET    = SOCK_PACKET   , /++ linux specific packets at dev level +/
#endif
    }
    /***********************************************************************

            Protocol

    ***********************************************************************/

    enum ProtocolType: int
    {
        IP   = IPPROTO_IP   ,     /// default internet protocol (probably 4 for compatibility)
#ifdef IPPROTO_IPV4
        IPV4 = IPPROTO_IPV4 ,     /// internet protocol version 4
#endif
#ifdef IPPROTO_IPV6
        IPV6 = IPPROTO_IPV6 ,     /// internet protocol version 6
#endif
        ICMP = IPPROTO_ICMP ,     /// internet control message protocol
        IGMP = IPPROTO_IGMP ,     /// internet group management protocol
        GGP  = IPPROTO_GGP  ,     /// gateway to gateway protocol
        TCP  = IPPROTO_TCP  ,     /// transmission control protocol
        PUP  = IPPROTO_PUP  ,     /// PARC universal packet protocol
        UDP  = IPPROTO_UDP  ,     /// user datagram protocol
        IDP  = IPPROTO_IDP  ,     /// Xerox NS protocol
    }
    
    /***********************************************************************
    
    
        ***********************************************************************/
    
    enum AddressFamily: int
    {
        __XYX__UNSPEC    = AF_UNSPEC   ,
        __XYX__UNIX      = AF_UNIX     ,
        __XYX__INET      = AF_INET     ,
        __XYX__IPX       = AF_IPX      ,
        __XYX__APPLETALK = AF_APPLETALK,
#ifdef AF_INET6
        __XYX__INET6     = AF_INET6    ,
#endif
    }

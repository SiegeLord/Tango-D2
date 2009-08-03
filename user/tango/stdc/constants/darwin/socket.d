module tango.stdc.constants.darwin.socket;
    import tango.stdc.constants.darwin.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum
    {
        SO_DEBUG = 0x0001 , /* turn on debugging info recording */
        SO_BROADCAST = 0x0020 , /* permit sending of broadcast msgs */
        SO_REUSEADDR = 0x0004 , /* allow local address reuse */
        SO_LINGER = 0x0080 , /* linger on close if data present */
        SO_DONTLINGER = ~(0x0080),
        SO_OOBINLINE = 0x0100 , /* leave received OOB data in line */
        SO_ACCEPTCONN = 0x0002, /* socket has had listen() */
        SO_KEEPALIVE = 0x0008 , /* keep connections alive */
        SO_DONTROUTE = 0x0010 , /* just use interface addresses */
        SO_TYPE = 0x1008 , /* get socket type */
        /*
         * Additional options, not kept in so_options.
         */
        SO_SNDBUF = 0x1001, /* send buffer size */
        SO_RCVBUF = 0x1002, /* receive buffer size */
        SO_ERROR = 0x1007 , /* get error status and clear */
        // OptionLevel.IP settings
        IP_MULTICAST_TTL = 10 ,
        IP_MULTICAST_LOOP = 11 ,
        IP_ADD_MEMBERSHIP = 12 ,
        IP_DROP_MEMBERSHIP = 13,
        // OptionLevel.TCP settings
        TCP_NODELAY = 0x01 ,
    }
    enum
    {
        SOL_SOCKET = 0xffff ,
    }
    enum {
        SOCK_STREAM = 1 , /++ sequential, reliable +/
        SOCK_DGRAM = 2 , /++ connectionless unreliable, max length +/
        SOCK_SEQPACKET = 5, /++ sequential, reliable, max length +/
        SOCK_RAW = 3 , /++ raw protocol +/
        SOCK_RDM = 4 , /++ reliable messages +/
    }
    enum
    {
        IPPROTO_IP = 0 , /// default internet protocol (probably 4 for compatibility)
        IPPROTO_IPV4 = 4 , /// internet protocol version 4
        IPPROTO_IPV6 = 41 , /// internet protocol version 6
        IPPROTO_ICMP = 1 , /// internet control message protocol
        IPPROTO_IGMP = 2 , /// internet group management protocol
        //IPPROTO_GGP = 3 , /// gateway to gateway protocol
        IPPROTO_TCP = 6 , /// transmission control protocol
        IPPROTO_PUP = 12 , /// PARC universal packet protocol
        IPPROTO_UDP = 17 , /// user datagram protocol
        IPPROTO_IDP = 22 , /// Xerox NS protocol
    }
    enum
    {
        AF_UNSPEC = 0 ,
        AF_UNIX = 1 ,
        AF_INET = 2 ,
        AF_IPX = 23 ,
        AF_APPLETALK = 16,
        AF_INET6 = 30 ,
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
        MSG_CTRUNC = 0x20 ,
        MSG_DONTROUTE = 0x4 ,
        MSG_EOR = 0x8 ,
        MSG_OOB = 0x1 ,
        MSG_PEEK = 0x2 ,
        MSG_TRUNC = 0x10 ,
        MSG_WAITALL = 0x40 ,
    }
    enum
    {
        SHUT_RD = 0,
        SHUT_WR = 1,
        SHUT_RDWR = 2
    }

module tango.stdc.constants.solaris.socket;
    import tango.stdc.constants.solaris.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum
    {
        SO_DEBUG = 0x0001 , /* turn on debugging info recording */
        SO_BROADCAST = 0x0020 , /* permit sending of broadcast msgs */
        SO_REUSEADDR = 0x0004 , /* allow local address reuse */
        SO_LINGER = 0x0080 , /* linger on close if data present */
        SO_DONTLINGER = ~(SO_LINGER),
        SO_OOBINLINE = 0x0100 , /* leave received OOB data in line */
        SO_ACCEPTCONN = 0x0002, /* socket has had listen() */
        SO_KEEPALIVE = 0x0008 , /* keep connections alive */
        SO_DONTROUTE = 0x0010, /* just use interface addresses */
        SO_TYPE = 0x1008 , /* get socket type */
        /*
         * Additional options, not kept in so_options.
         */
        SO_SNDBUF = 0x1001, /* send buffer size */
        SO_RCVBUF = 0x1002, /* receive buffer size */
        SO_ERROR = 0x1007 , /* get error status and clear */
        // OptionLevel.IP settings
        IP_MULTICAST_TTL = 0x11 ,
        IP_MULTICAST_LOOP = 0x12 ,
        IP_ADD_MEMBERSHIP = 0x13 ,
        IP_DROP_MEMBERSHIP = 0x14,
        // OptionLevel.TCP settings
        TCP_NODELAY = 0x01 ,
    }
    
    enum
    {
        SOL_SOCKET = 0xffff,
    }
    enum
    {
        SOCK_STREAM = 1 , /++ sequential, reliable +/
        SOCK_DGRAM = 2, /++ connectionless unreliable, max length +/
        SOCK_SEQPACKET = 6, /++ sequential, reliable, max length +/
        SOCK_RAW = 4,
    }
    /* Standard well-defined IP protocols.  */
    enum
      {
        IPPROTO_IP = 0, /* Dummy protocol for TCP.  */
        IPPROTO_IPV4 = 0,
        IPPROTO_IPV6 = 41, /* IPv6 header.  */
        IPPROTO_ICMP = 1, /* Internet Control Message Protocol.  */
        IPPROTO_IGMP = 2, /* Internet Group Management Protocol. */
        IPPROTO_TCP = 6, /* Transmission Control Protocol.  */
        IPPROTO_PUP = 12, /* PUP protocol.  */
        IPPROTO_UDP = 17, /* User Datagram Protocol.  */
        IPPROTO_IDP = 22, /* XNS IDP protocol.  */
        /+
        // undefined for cross platform reasons, if you need them ask
        IPPROTO_IPIP = 4, /* IPIP tunnels (older KA9Q tunnels use 94).  */
        IPPROTO_HOPOPTS = 0, /* IPv6 Hop-by-Hop options.  */
        IPPROTO_EGP = 8, /* Exterior Gateway Protocol.  */
        IPPROTO_TP = 29, /* SO Transport Protocol Class 4.  */
        IPPROTO_ROUTING = 43, /* IPv6 routing header.  */
        IPPROTO_FRAGMENT = 44, /* IPv6 fragmentation header.  */
        IPPROTO_RSVP = 46, /* Reservation Protocol.  */
        IPPROTO_GRE = 47, /* General Routing Encapsulation.  */
        IPPROTO_ESP = 50, /* encapsulating security payload.  */
        IPPROTO_AH = 51, /* authentication header.  */
        IPPROTO_ICMPV6 = 58, /* ICMPv6.  */
        IPPROTO_NONE = 59, /* IPv6 no next header.  */
        IPPROTO_DSTOPTS = 60, /* IPv6 destination options.  */
        IPPROTO_MTP = 92, /* Multicast Transport Protocol.  */
        IPPROTO_ENCAP = 98, /* Encapsulation Header.  */
        IPPROTO_PIM = 103, /* Protocol Independent Multicast.  */
        IPPROTO_COMP = 108, /* Compression Header Protocol.  */
        IPPROTO_SCTP = 132, /* Stream Control Transmission Protocol.  */
        IPPROTO_RAW = 255, /* Raw IP packets.  */
        IPPROTO_MAX
        +/
      }
    enum
    {
        AF_UNSPEC = 0 ,
        AF_UNIX = 1 ,
        AF_INET = 2 ,
        AF_IPX = 4 ,
        AF_APPLETALK = 5 ,
        AF_INET6 = 26 ,
    }
    enum : uint
    {
        SCM_RIGHTS = 0x1010
    }
    enum
    {
        SOMAXCONN       = 128,
    }
    
    enum : uint
    {
        MSG_CTRUNC      = 0x20,
        MSG_DONTROUTE   = 0x4,
        MSG_EOR         = 0x8,
        MSG_OOB         = 0x1,
        MSG_PEEK        = 0x2,
        MSG_TRUNC       = 0x10,
        MSG_WAITALL     = 0x40
    }

    enum
    {
        SHUT_RD = 0,
        SHUT_WR = 1,
        SHUT_RDWR = 2
    }
        

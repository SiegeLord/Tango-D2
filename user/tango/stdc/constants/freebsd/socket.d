module tango.stdc.constants.freebsd.socket;
    import tango.stdc.constants.freebsd.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum
    {
        SO_ACCEPTCONN   = 0x0002,
        SO_BROADCAST    = 0x0020,
        SO_DEBUG        = 0x0001,
        SO_DONTROUTE    = 0x0010,
        SO_ERROR        = 0x1007,
        SO_KEEPALIVE    = 0x0008,
        SO_LINGER       = 0x1080,
        SO_OOBINLINE    = 0x0100,
        SO_RCVBUF       = 0x1002,
        SO_RCVLOWAT     = 0x1004,
        SO_RCVTIMEO     = 0x1006,
        SO_REUSEADDR    = 0x1006,
        SO_SNDBUF       = 0x1001,
        SO_SNDLOWAT     = 0x1003,
        SO_SNDTIMEO     = 0x1005,
        SO_TYPE         = 0x1008,
        SO_DONTLINGER   = ~(SO_LINGER),
        // OptionLevel.IP settings unconfirmed
        IP_MULTICAST_TTL = 33 ,
        IP_MULTICAST_LOOP = 34 ,
        IP_ADD_MEMBERSHIP = 35 ,
        IP_DROP_MEMBERSHIP = 36,
        // OptionLevel.TCP settings
        TCP_NODELAY = 1 ,
    }
    
    enum
    {
        SOCK_STREAM = 1 , /++ sequential, reliable +/
        SOCK_DGRAM = 2 , /++ connectionless unreliable, max length +/
        SOCK_RAW = 3 , /++ raw protocol +/
        SOCK_RDM = 4,
        SOCK_SEQPACKET = 5, /++ sequential, reliable, max length +/
    }

    enum
    {
        SOL_SOCKET      = 0xffff,
    }
    /* Standard well-defined IP protocols.  */
    private enum
      {
        IPPROTO_IP = 0, /* Dummy protocol for TCP.  */
        IPPROTO_IPV4 = 0, /* Dummy protocol for TCP.  */
        IPPROTO_IPV6 = 41, /* IPv6 header.  */
        IPPROTO_ICMP = 1, /* Internet Control Message Protocol.  */
        IPPROTO_IGMP = 2, /* Internet Group Management Protocol. */
        IPPROTO_TCP = 6, /* Transmission Control Protocol.  */
        IPPROTO_PUP = 12, /* PUP protocol.  */
        IPPROTO_UDP = 17, /* User Datagram Protocol.  */
        IPPROTO_IDP = 22, /* XNS IDP protocol.  */
        /+
        // undefined for cross platform reasons, if you need them ask
        IPPROTO_HOPOPTS = 0, /* IPv6 Hop-by-Hop options.  */
        IPPROTO_IPIP = 4, /* IPIP tunnels (older KA9Q tunnels use 94).  */
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
      };
    enum
    {
        AF_UNSPEC = 0 ,
        AF_UNIX = 1 ,
        AF_INET = 2 ,
        AF_IPX = 23 ,
        AF_APPLETALK = 16 ,
        AF_INET6 = 28 ,
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
        MSG_OOB         = 0x1,
        MSG_PEEK        = 0x2,
        MSG_DONTROUTE   = 0x4,
        MSG_EOR         = 0x8,
        MSG_TRUNC       = 0x10,
        MSG_CTRUNC      = 0x20,
        MSG_WAITALL     = 0x40,
	MSG_NOSIGNAL =   0x20000,
    }
    enum
    {
        SHUT_RD = 0,
        SHUT_WR = 1,
        SHUT_RDWR = 2
    }


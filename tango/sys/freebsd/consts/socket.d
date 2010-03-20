module tango.sys.freebsd.consts.socket;
    import tango.sys.freebsd.consts.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum
    {
        SO_ACCEPTCONN   = 0x0002,
        SO_BROADCAST    = 0x0020,
        SO_DEBUG        = 0x0001,
        SO_DONTROUTE    = 0x0010,
        SO_ERROR        = 0x1007,
        SO_KEEPALIVE    = 0x0008,
        SO_LINGER       = 0x0080,
        SO_OOBINLINE    = 0x0100,
        SO_RCVBUF       = 0x1002,
        SO_RCVLOWAT     = 0x1004,
        SO_RCVTIMEO     = 0x1006,
        SO_REUSEADDR    = 0x0004,
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
        SOCK_SEQPACKET = 5, /++ sequential, reliable, max length +/
        SOCK_RAW = 3 , /++ raw protocol +/
    }

    enum
    {
        SOL_SOCKET      = 0xffff,
    }
    /* Standard well-defined IP protocols.  */
    private enum
      {
        IPPROTO_IP = 0, /* Dummy protocol for TCP.  */
        IPPROTO_IPV4 = 4, /* Dummy protocol for TCP.  */
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
        AF_APPLETALK = 16,
        AF_INET6 = 28
    }
    enum : uint
    {
        SCM_RIGHTS = 0x01
    }
    enum
    {
        SOMAXCONN       = 128
    }
    enum : uint
    {
        MSG_CTRUNC      = 0x20,
        MSG_DONTROUTE   = 0x4,
        MSG_EOR         = 0x8,
        MSG_OOB         = 0x1,
        MSG_PEEK        = 0x2,
        MSG_TRUNC       = 0x10,
        MSG_WAITALL     = 0x40,
        MSG_NOSIGNAL    = 0x20000
    }
    enum
    {
        SHUT_RD = 0,
        SHUT_WR = 1,
        SHUT_RDWR = 2
    }

 enum: int
 {
        AI_PASSIVE = 0x00000001, /// get address to use bind()
        AI_CANONNAME = 0x00000002, /// fill ai_canonname
        AI_NUMERICHOST = 0x00000004, /// prevent host name resolution
        AI_NUMERICSERV = 0x00000008, /// prevent service name resolution valid flags for addrinfo (not a standard def, apps should not use it)
        AI_ALL = 0x00000100, /// IPv6 and IPv4-mapped (with AI_V4MAPPED) 
        AI_V4MAPPED_CFG = 0x00000200, /// accept IPv4-mapped if kernel supports
        AI_ADDRCONFIG = 0x00000400, /// only if any address is assigned
        AI_V4MAPPED = 0x00000800, /// accept IPv4-mapped IPv6 address special recommended flags for getipnodebyname
        AI_MASK = (AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST | AI_NUMERICSERV | AI_ADDRCONFIG),
        AI_DEFAULT = (AI_V4MAPPED_CFG | AI_ADDRCONFIG),
 }
                        

enum
{
        EAI_BADFLAGS = 3,       /// Invalid value for `ai_flags' field.
        EAI_NONAME = 8, /// NAME or SERVICE is unknown.
        EAI_AGAIN = 2,  /// Temporary failure in name resolution.
        EAI_FAIL = 4,   /// Non-recoverable failure in name res.
        EAI_NODATA = 7, /// No address associated with NAME.
        EAI_FAMILY = 5, /// `ai_family' not supported.
        EAI_SOCKTYPE = 10,      /// `ai_socktype' not supported.
        EAI_SERVICE = 9,        /// SERVICE not supported for `ai_socktype'.
        EAI_MEMORY = 6, /// Memory allocation failure.
}       

enum
{
        NI_MAXHOST = 1025,
        NI_MAXSERV = 32,
        NI_NUMERICHOST = 0x00000002,    /// Don't try to look up hostname.
        NI_NUMERICSERV = 0x00000008,    /// Don't convert port number to name.
        NI_NOFQDN = 0x00000001, /// Only return nodename portion.
        NI_NAMEREQD = 0x00000004,       /// Don't return numeric addresses.
        NI_DGRAM = 0x00000010,  /// Look up UDP service rather than TCP.
}       

                        

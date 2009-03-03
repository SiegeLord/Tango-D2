module tango.stdc.constants.linuxIntel.socket;
    import tango.stdc.constants.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum SocketOption: int
    {
        SO_DEBUG = 1 , /* turn on debugging info recording */
        SO_BROADCAST = 6 , /* permit sending of broadcast msgs */
        SO_REUSEADDR = 2 , /* allow local address reuse */
        SO_LINGER = 13 , /* linger on close if data present */
        SO_DONTLINGER = ~(13),
        SO_OOBINLINE = 10 , /* leave received OOB data in line */
        SO_ACCEPTCONN = 30, /* socket has had listen() */
        SO_KEEPALIVE = 9 , /* keep connections alive */
        SO_DONTROUTE = 5 , /* just use interface addresses */
        SO_TYPE = 3 , /* get socket type */
        /*
         * Additional options, not kept in so_options.
         */
        SO_SNDBUF = 7, /* send buffer size */
        SO_RCVBUF = 8, /* receive buffer size */
        SO_ERROR = 4 , /* get error status and clear */
        // OptionLevel.IP settings
        IP_MULTICAST_TTL = 33 ,
        IP_MULTICAST_LOOP = 34 ,
        IP_ADD_MEMBERSHIP = 35 ,
        IP_DROP_MEMBERSHIP = 36,
        // OptionLevel.TCP settings
        TCP_NODELAY = 1 ,
    }
    /* Standard well-defined IP protocols.  */
    private enum
      {
        IPPROTO_IP = 0, /* Dummy protocol for TCP.  */
        IPPROTO_HOPOPTS = 0, /* IPv6 Hop-by-Hop options.  */
        IPPROTO_ICMP = 1, /* Internet Control Message Protocol.  */
        IPPROTO_IGMP = 2, /* Internet Group Management Protocol. */
        IPPROTO_IPIP = 4, /* IPIP tunnels (older KA9Q tunnels use 94).  */
        IPPROTO_TCP = 6, /* Transmission Control Protocol.  */
        IPPROTO_EGP = 8, /* Exterior Gateway Protocol.  */
        IPPROTO_PUP = 12, /* PUP protocol.  */
        IPPROTO_UDP = 17, /* User Datagram Protocol.  */
        IPPROTO_IDP = 22, /* XNS IDP protocol.  */
        IPPROTO_TP = 29, /* SO Transport Protocol Class 4.  */
        IPPROTO_IPV6 = 41, /* IPv6 header.  */
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
      };
    
    enum SocketOptionLevel
    {
        SOCKET = 1,
        IP = IPPROTO_IP ,
        TCP = IPPROTO_TCP ,
        UDP = IPPROTO_UDP ,
    }
    enum SocketType{
        SOCK_STREAM = 1 , /++ sequential, reliable +/
        SOCK_DGRAM = 2 , /++ connectionless unreliable, max length +/
        SOCK_SEQPACKET = 5, /++ sequential, reliable, max length +/
        SOCK_RAW = 3 , /++ raw protocol +/
        SOCK_RDM = 4 , /++ reliable messages +/
        SOCK_PACKET = 10, /++ linux specific packets at dev level +/
    }
    enum ProtocolType: int
    {
        IP = IPPROTO_IP , /// default internet protocol (probably 4 for compatibility)
        IPV6 = IPPROTO_IPV6 , /// internet protocol version 6
        ICMP = IPPROTO_ICMP , /// internet control message protocol
        IGMP = IPPROTO_IGMP , /// internet group management protocol
        //GGP = IPPROTO_GGP , /// gateway to gateway protocol, deprecated
        TCP = IPPROTO_TCP , /// transmission control protocol
        PUP = IPPROTO_PUP , /// PARC universal packet protocol
        UDP = IPPROTO_UDP , /// user datagram protocol
        IDP = IPPROTO_IDP , /// Xerox NS protocol
    }
    enum AddressFamily: int
    {
        UNSPEC = 0 ,
        UNIX = 1 ,
        INET = 2 ,
        IPX = 4 ,
        APPLETALK = 5 ,
        INET6 = 10 ,
    }

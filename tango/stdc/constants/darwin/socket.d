module tango.stdc.constants.darwin.socket;
    import tango.stdc.constants.darwin.fcntl: F_GETFL, F_SETFL,O_NONBLOCK;
    enum {SOCKET_ERROR = -1}
    enum SocketOption: int
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
    enum SocketOptionLevel
    {
        SOCKET = 0xffff ,
        IP = 0 ,
        TCP = 6 ,
        UDP = 17 ,
    }
    enum SocketType{
        STREAM = 1 , /++ sequential, reliable +/
        DGRAM = 2 , /++ connectionless unreliable, max length +/
        SEQPACKET = 5, /++ sequential, reliable, max length +/
        RAW = 3 , /++ raw protocol +/
        RDM = 4 , /++ reliable messages +/
    }
    enum ProtocolType: int
    {
        IP = 0 , /// default internet protocol (probably 4 for compatibility)
        IPV4 = 4 , /// internet protocol version 4
        IPV6 = 41 , /// internet protocol version 6
        ICMP = 1 , /// internet control message protocol
        IGMP = 2 , /// internet group management protocol
        GGP = 3 , /// gateway to gateway protocol
        TCP = 6 , /// transmission control protocol
        PUP = 12 , /// PARC universal packet protocol
        UDP = 17 , /// user datagram protocol
        IDP = 22 , /// Xerox NS protocol
    }
    enum AddressFamily: int
    {
        UNSPEC = 0 ,
        UNIX = 1 ,
        INET = 2 ,
        IPX = 23 ,
        APPLETALK = 16,
        INET6 = 30 ,
    }

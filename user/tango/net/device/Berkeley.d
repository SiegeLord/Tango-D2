module tango.net.device.Berkeley;

private import  tango.sys.Common;

private import  tango.core.Exception;

import  consts=tango.stdc.constants.socket;
private import tango.stdc.config; 

/*******************************************************************************

*******************************************************************************/

private extern(C) int strlen(char*);

/*******************************************************************************

*******************************************************************************/

enum {SOCKET_ERROR = consts.SOCKET_ERROR}

/*******************************************************************************

*******************************************************************************/

enum SocketOption
{
        DEBUG        =   consts.SO_DEBUG     ,       /* turn on debugging info recording */
        BROADCAST    =   consts.SO_BROADCAST ,       /* permit sending of broadcast msgs */
        REUSEADDR    =   consts.SO_REUSEADDR ,       /* allow local address reuse */
        LINGER       =   consts.SO_LINGER    ,       /* linger on close if data present */
        DONTLINGER   = ~(consts.SO_LINGER),
        
        OOBINLINE    =   consts.SO_OOBINLINE ,       /* leave received OOB data in line */
        ACCEPTCONN   =   consts.SO_ACCEPTCONN,       /* socket has had listen() */
        KEEPALIVE    =   consts.SO_KEEPALIVE ,       /* keep connections alive */
        DONTROUTE    =   consts.SO_DONTROUTE ,       /* just use interface addresses */
        TYPE         =   consts.SO_TYPE      ,       /* get socket type */
    
        /*
         * Additional options, not kept in so_options.
         */
        SNDBUF       = consts.SO_SNDBUF,               /* send buffer size */
        RCVBUF       = consts.SO_RCVBUF,               /* receive buffer size */
        ERROR        = consts.SO_ERROR ,               /* get error status and clear */
    
        // OptionLevel.IP settings
        MULTICAST_TTL   = consts.IP_MULTICAST_TTL  ,
        MULTICAST_LOOP  = consts.IP_MULTICAST_LOOP ,
        ADD_MEMBERSHIP  = consts.IP_ADD_MEMBERSHIP ,
        DROP_MEMBERSHIP = consts.IP_DROP_MEMBERSHIP,
    
        // OptionLevel.TCP settings
        TCP_NODELAY     = consts.TCP_NODELAY ,
}
    
/*******************************************************************************

*******************************************************************************/

enum SocketOptionLevel
{
        SOCKET = consts.SOL_SOCKET    ,
        IP     = consts.IPPROTO_IP    ,   
        TCP    = consts.IPPROTO_TCP   ,   
        UDP    = consts.IPPROTO_UDP   ,   
}
    
/*******************************************************************************

*******************************************************************************/

enum SocketType
{
        STREAM    = consts.SOCK_STREAM   , /++ sequential, reliable +/
        DGRAM     = consts.SOCK_DGRAM    , /++ connectionless unreliable, max length +/
        SEQPACKET = consts.SOCK_SEQPACKET, /++ sequential, reliable, max length +/
}

/*******************************************************************************

*******************************************************************************/

enum ProtocolType
{
        IP   = consts.IPPROTO_IP   ,     /// default internet protocol (probably 4 for compatibility)
        IPV4 = consts.IPPROTO_IP   ,     /// internet protocol version 4
        IPV6 = consts.IPPROTO_IPV6 ,     /// internet protocol version 6
        ICMP = consts.IPPROTO_ICMP ,     /// internet control message protocol
        IGMP = consts.IPPROTO_IGMP ,     /// internet group management protocol
        TCP  = consts.IPPROTO_TCP  ,     /// transmission control protocol
        PUP  = consts.IPPROTO_PUP  ,     /// PARC universal packet protocol
        UDP  = consts.IPPROTO_UDP  ,     /// user datagram protocol
        IDP  = consts.IPPROTO_IDP  ,     /// Xerox NS protocol
}

/*******************************************************************************

*******************************************************************************/

enum AddressFamily
{
        UNSPEC    = consts.AF_UNSPEC   ,
        UNIX      = consts.AF_UNIX     ,
        INET      = consts.AF_INET     ,
        IPX       = consts.AF_IPX      ,
        APPLETALK = consts.AF_APPLETALK,
        INET6     = consts.AF_INET6    ,
}

/*******************************************************************************

*******************************************************************************/

enum SocketShutdown
{
        RECEIVE =  consts.SHUT_RD,
        SEND =     consts.SHUT_WR,
        BOTH =     consts.SHUT_RDWR,
}

/*******************************************************************************

*******************************************************************************/

enum SocketFlags
{
        NONE =           0,
        OOB =            consts.MSG_OOB, //out of band
        PEEK =           consts.MSG_PEEK, //only for receiving
        DONTROUTE =      consts.MSG_DONTROUTE, //only for sending
}

/*******************************************************************************

        conversions for network byte-order

*******************************************************************************/

version(BigEndian)
{
        private ushort htons (ushort x)
        {
                return x;
        }

        private uint htonl (uint x)
        {
                return x;
        }
}
else 
{
        private import tango.core.BitManip;

        private ushort htons (ushort x)
        {
                return cast(ushort) ((x >> 8) | (x << 8));
        }

        private uint htonl (uint x)
        {
                return bswap(x);
        }
}

/*******************************************************************************


*******************************************************************************/

version (Win32)
{
        pragma (lib, "ws2_32.lib");
        
        private import tango.sys.win32.WsaSock;
}
else
{
        private import tango.stdc.posix.sys.time; 
        private import tango.stdc.errno;
        private import tango.stdc.posix.sys.socket: sockaddr;
        private import tango.stdc.posix.sys.select: fd_set;
        private import tango.stdc.posix.netdb;
        private typedef int socket_t = -1;

        extern  (C)
                { // this redeclaration of tango.stdc.posix.sys.socket just to use socket_t is *very* ugly and should go
                socket_t socket(int af, int type, int protocol);
                int fcntl(socket_t s, int f, ...);
                uint inet_addr(char* cp);
                int bind(socket_t s, sockaddr* name, int namelen);
                int connect(socket_t s, sockaddr* name, int namelen);
                int listen(socket_t s, int backlog);
                socket_t accept(socket_t s, sockaddr* addr, int* addrlen);
                int close(socket_t s);
                int shutdown(socket_t s, int how);
                int getpeername(socket_t s, sockaddr* name, int* namelen);
                int getsockname(socket_t s, sockaddr* name, int* namelen);
                int send(socket_t s, void* buf, int len, int flags);
                int sendto(socket_t s, void* buf, int len, int flags, sockaddr* to, int tolen);
                int recv(socket_t s, void* buf, int len, int flags);
                int recvfrom(socket_t s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
                int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
                int getsockopt(socket_t s, int level, int optname, void* optval, int* optlen);
                int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
                int gethostname(void* namebuffer, int buflen);
                char* inet_ntoa(uint ina);
                }
}


/*******************************************************************************


*******************************************************************************/

public struct Berkeley
{
        socket_t        sock;
        SocketType      type;
        AddressFamily   family;
        ProtocolType    protocol;
version (Windows)
{
         bool           synchronous;
}

        enum : socket_t 
        {
                INVALID_SOCKET = socket_t.init
        }
        
        enum 
        {
                Error = -1
        }

        alias Error        ERROR;               // backward compatibility
        alias noDelay      setNoDelay;          // backward compatibility
        alias addressReuse setAddressReuse;     // backward compatibility
        
        /***********************************************************************

                Configure this instance

        ***********************************************************************/

        void open (AddressFamily family, SocketType type, ProtocolType protocol, bool create=true)
        {
                this.type = type;
                this.family = family;
                this.protocol = protocol;
                if (create)
                    reopen;
        }

        /***********************************************************************

                Open/reopen a native socket for this instance

        ***********************************************************************/

        void reopen (socket_t sock = sock.init)
        {
                if (this.sock != sock.init)
                    this.detach;

                if (sock is sock.init)
                   {
                   sock = cast(socket_t) socket (family, type, protocol);
                   if (sock is sock.init)
                       exception ("Unable to create socket: ");
                   }

                this.sock = sock;
        }

        /***********************************************************************

                calling shutdown() before this is recommended for connection-
                oriented sockets

        ***********************************************************************/

        void detach ()
        {
                if (sock != sock.init)
                    .close (sock);
                sock = sock.init;
        }

        /***********************************************************************

                Return the underlying OS handle of this Conduit

        ***********************************************************************/

        socket_t handle ()
        {
                return sock;
        }

        /***********************************************************************

                Return the last error

        ***********************************************************************/

        static int lastError ()
        {
                version (Win32)
                         return WSAGetLastError();
                   else
                      return errno;
        }

        /***********************************************************************

                Is this socket still alive? A closed socket is considered to
                be dead, but a shutdown socket is still alive.

        ***********************************************************************/

        bool isAlive ()
        {
                int type, typesize = type.sizeof;
                return getsockopt (sock, SocketOptionLevel.SOCKET,
                                   SocketOption.TYPE, cast(char*) &type,
                                   &typesize) != Error;
        }

        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily ()
        {
                return family;
        }

        /***********************************************************************


        ***********************************************************************/

        Berkeley* bind (Address addr)
        {
                if(Error == .bind (sock, addr.name, addr.nameLen))
                   exception ("Unable to bind socket: ");
                return this;
        }

        /***********************************************************************


        ***********************************************************************/

        Berkeley* connect (Address to)
        {
                if (Error == .connect (sock, to.name, to.nameLen))
                   {
                   if (! blocking)
                      {
                      auto err = lastError;
                      version(Windows)
                      {
                              if(err is WSAEWOULDBLOCK)
                                 return this;
                      }
                      else
                         {
                         if (err is EINPROGRESS)
                             return this;
                         }
                      }
                   exception ("Unable to connect socket: ");
                   }
                return this;
        }

        /***********************************************************************

                need to bind() first

        ***********************************************************************/

        Berkeley* listen (int backlog)
        {
                if (Error == .listen (sock, backlog))
                    exception ("Unable to listen on socket: ");
                return this;
        }

        /***********************************************************************

                need to bind() first

        ***********************************************************************/

        void accept (ref Berkeley target)
        {
                auto newsock = .accept (sock, null, null); 
                if (socket_t.init is newsock)
                    exception ("Unable to accept socket connection: ");

                target.reopen (newsock);

                target.protocol = protocol;            //same protocol
                target.family = family;                //same family
                target.type = type;                    //same type
        }

        /***********************************************************************

                The shutdown function shuts down the connection of the socket.
                Depending on the argument value, it will:

                    -   stop receiving data for this socket. If further data
                        arrives, it is rejected.

                    -   stop trying to transmit data from this socket. Also
                        discards any data waiting to be sent. Stop looking for
                        acknowledgement of data already sent; don't retransmit
                        if any data is lost.

        ***********************************************************************/

        Berkeley* shutdown (SocketShutdown how)
        {
                .shutdown (sock, how);
                return this;
        }

        /***********************************************************************

                set linger timeout

        ***********************************************************************/

        Berkeley* linger (int period)
        {
                version (Win32)
                         alias ushort attr;
                   else
                       alias uint attr;

                union linger
                {
                        struct {
                               attr l_onoff;            // option on/off
                               attr l_linger;           // linger time
                               };
                        attr[2] array;                  // combined
                }

                linger l;
                l.l_onoff = 1;                          // option on/off
                l.l_linger = cast(ushort) period;       // linger time

                return setOption (SocketOptionLevel.SOCKET, SocketOption.LINGER, l.array);
        }

        /***********************************************************************

                enable/disable address reuse

        ***********************************************************************/

        Berkeley* addressReuse (bool enabled)
        {
                int[1] x = enabled;
                return setOption (SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, x);
        }

        /***********************************************************************

                enable/disable noDelay option (nagle)

        ***********************************************************************/

        Berkeley* noDelay (bool enabled)
        {
                int[1] x = enabled;
                return setOption (SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, x);
        }

        /***********************************************************************

                Helper function to handle the adding and dropping of group
                membership.

        ***********************************************************************/

        void joinGroup (IPv4Address address, bool onOff)
        {
                assert (address, "Socket.joinGroup :: invalid null address");

                struct ip_mreq
                {
                uint  imr_multiaddr;  /* IP multicast address of group */
                uint  imr_interface;  /* local IP address of interface */
                };

                ip_mreq mrq;

                auto option = (onOff) ? SocketOption.ADD_MEMBERSHIP : SocketOption.DROP_MEMBERSHIP;
                mrq.imr_interface = 0;
                mrq.imr_multiaddr = address.sin.sin_addr;

                if (.setsockopt(sock, SocketOptionLevel.IP, option, &mrq, mrq.sizeof) == Error)
                    exception ("Unable to perform multicast join: ");
        }

        /***********************************************************************


        ***********************************************************************/

        Address newFamilyObject ()
        {
                return (family is AddressFamily.INET) ? new IPv4Address : new UnknownAddress;
        }

        /***********************************************************************

                return the hostname

        ***********************************************************************/

        static char[] hostName ()
        {
                char[64] name;

                if(Error == .gethostname (name.ptr, name.length))
                   exception ("Unable to obtain host name: ");
                return name [0 .. strlen(name.ptr)].dup;
        }

        /***********************************************************************

                return the default host address (IPv4)

        ***********************************************************************/

        static uint hostAddress ()
        {
                auto ih = new NetHost;
                ih.getHostByName (hostName);
                assert (ih.addrList.length);
                return ih.addrList[0];
        }

        /***********************************************************************

                return the remote address of the current connection (IPv4)

        ***********************************************************************/

        Address remoteAddress ()
        {
                auto addr = newFamilyObject;
                auto nameLen = addr.nameLen;
                if(Error == .getpeername (sock, addr.name, &nameLen))
                   exception ("Unable to obtain remote socket address: ");
                assert (addr.addressFamily is family);
                return addr;
        }

        /***********************************************************************

                return the local address of the current connection (IPv4)

        ***********************************************************************/

        Address localAddress ()
        {
                auto addr = newFamilyObject;
                auto nameLen = addr.nameLen();
                if(Error == .getsockname (sock, addr.name, &nameLen))
                   exception ("Unable to obtain local socket address: ");
                assert (addr.addressFamily() is family);
                return addr;
        }

        /***********************************************************************

                Send data on the connection. Returns the number of bytes 
                actually sent, or ERROR on failure. If the socket is blocking 
                and there is no buffer space left, send waits.

                Returns number of bytes actually sent, or -1 on error

        ***********************************************************************/

        int send (void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                return .send(sock, buf.ptr, buf.length, cast(int)flags);
        }

        /***********************************************************************

                Send data to a specific destination Address. If the 
                destination address is not specified, a connection 
                must have been made and that address is used. If the 
                socket is blocking and there is no buffer space left, 
                sendTo waits.

        ***********************************************************************/

        int sendTo (void[] buf, SocketFlags flags, Address to)
        {
                return .sendto(sock, buf.ptr, buf.length, cast(int)flags, to.name, to.nameLen);
        }

        /***********************************************************************

                ditto

        ***********************************************************************/

        int sendTo (void[] buf, Address to)
        {
                return sendTo(buf, SocketFlags.NONE, to);
        }

        /***********************************************************************

                ditto - assumes you connect()ed

        ***********************************************************************/

        int sendTo (void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                return .sendto(sock, buf.ptr, buf.length, cast(int)flags, null, 0);
        }

        /***********************************************************************
                Receive data on the connection. Returns the number of 
                bytes actually received, 0 if the remote side has closed 
                the connection, or ERROR on failure. If the socket is blocking, 
                receive waits until there is data to be received.
                
                Returns number of bytes actually received, 0 on connection 
                closure, or -1 on error

        ***********************************************************************/

        int receive (void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                if (!buf.length)
                     badArg ("Socket.receive :: target buffer has 0 length");

                return .recv(sock, buf.ptr, buf.length, cast(int)flags);
        }

        /***********************************************************************

                Receive data and get the remote endpoint Address. Returns 
                the number of bytes actually received, 0 if the remote side 
                has closed the connection, or ERROR on failure. If the socket 
                is blocking, receiveFrom waits until there is data to be 
                received.

        ***********************************************************************/

        int receiveFrom (void[] buf, SocketFlags flags, Address from)
        {
                if (!buf.length)
                     badArg ("Socket.receiveFrom :: target buffer has 0 length");

                assert(from.addressFamily() == family);
                int nameLen = from.nameLen();
                return .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, from.name(), &nameLen);
        }

        /***********************************************************************

                ditto

        ***********************************************************************/

        int receiveFrom (void[] buf, Address from)
        {
                return receiveFrom(buf, SocketFlags.NONE, from);
        }

        /***********************************************************************

                ditto - assumes you connect()ed

        ***********************************************************************/

        int receiveFrom (void[] buf, SocketFlags flags = SocketFlags.NONE)
        {
                if (!buf.length)
                     badArg ("Socket.receiveFrom :: target buffer has 0 length");

                return .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, null, null);
        }

        /***********************************************************************

                returns the length, in bytes, of the actual result - very
                different from getsockopt()

        ***********************************************************************/

        int getOption (SocketOptionLevel level, SocketOption option, void[] result)
        {
                int len = result.length;
                if(Error == .getsockopt (sock, cast(int)level, cast(int)option, result.ptr, &len))
                   exception ("Unable to get socket option: ");
                return len;
        }

        /***********************************************************************


        ***********************************************************************/

        Berkeley* setOption (SocketOptionLevel level, SocketOption option, void[] value)
        {
                if(Error == .setsockopt (sock, cast(int)level, cast(int)option, value.ptr, value.length))
                   exception ("Unable to set socket option: ");
                return this;
        }

        /***********************************************************************

                getter

        ***********************************************************************/

        bool blocking()
        {
                version(Windows)
                {
                        return synchronous;
                }
                else
                {
                        return !(fcntl(sock, F_GETFL, 0) & O_NONBLOCK);
                }
        }

        /***********************************************************************

                setter

        ***********************************************************************/

        void blocking(bool yes)
        {
                version(Windows)
                {
                        uint num = !yes;
                        if(ioctlsocket(sock, consts.FIONBIO, &num) is ERROR)
                           exception("Unable to set socket blocking: ");
                        synchronous = yes;
                }
                else 
                {
                        int x = fcntl(sock, F_GETFL, 0);
                        if(yes)
                           x &= ~O_NONBLOCK;
                        else
                           x |= O_NONBLOCK;
                        if(fcntl(sock, F_SETFL, x) is ERROR)
                           exception("Unable to set socket blocking: ");
                }
                return; 
        }

        /***********************************************************************

        ***********************************************************************/

        static void exception (char[] msg)
        {
                throw new SocketException (msg ~ SysError.lookup(lastError));
        }

        /***********************************************************************

        ***********************************************************************/

        protected static void badArg (char[] msg)
        {
                throw new IllegalArgumentException (msg);
        }
}



/*******************************************************************************


*******************************************************************************/

public abstract class Address
{
        abstract sockaddr*       name();
        abstract int             nameLen();
        abstract AddressFamily   addressFamily();
        abstract char[]          toString();

        /***********************************************************************

                Internal usage

        ***********************************************************************/

        private static ushort ntohs (ushort x)
        {
                return htons(x);
        }

        /***********************************************************************

                Internal usage

        ***********************************************************************/

        private static uint ntohl (uint x)
        {
                return htonl(x);
        }

        /***********************************************************************

                Internal usage

        ***********************************************************************/

        private static char[] convert2D (char* s)
        {
                return s ? s[0 .. strlen(s)] : cast(char[])null;
        }

        /***********************************************************************

                Internal usage

        ***********************************************************************/

        private static char* convert2C (char[] input, char[] output)
        {
                output [0 .. input.length] = input;
                output [input.length] = 0;
                return output.ptr;
        }

        /***********************************************************************

                Internal usage

        ***********************************************************************/

        private static char[] fromInt (char[] tmp, int i)
        {
                int j = tmp.length;
                do {
                   tmp[--j] = cast(char)(i % 10 + '0');
                   } while (i /= 10);

                return tmp [j .. $];
        }

        /***********************************************************************

                Tango: added this common function

        ***********************************************************************/

        static void exception (char[] msg)
        {
                throw new SocketException (msg);
        }
}


/*******************************************************************************


*******************************************************************************/

public class UnknownAddress : Address
{
        sockaddr sa;

        /***********************************************************************


        ***********************************************************************/

        sockaddr* name()
        {
                return &sa;
        }

        /***********************************************************************


        ***********************************************************************/

        int nameLen()
        {
                return sa.sizeof;
        }

        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily()
        {
                return cast(AddressFamily) sa.sa_family;
        }

        /***********************************************************************


        ***********************************************************************/

        char[] toString()
        {
                return "Unknown";
        }
}


/*******************************************************************************


*******************************************************************************/

public class IPv4Address : Address
{
        char[8] _port;
        sockaddr_in sin;

        /***********************************************************************


        ***********************************************************************/

        enum 
        {
                ADDR_ANY = 0, 
                ADDR_NONE = cast(uint)-1, 
                PORT_ANY = 0
        }

        /***********************************************************************


        ***********************************************************************/

        struct sockaddr_in
        {
                ushort sinfamily = AddressFamily.INET;
                ushort sin_port;
                uint sin_addr; //in_addr
                char[8] sin_zero = 0;
        }

        /***********************************************************************


        ***********************************************************************/

        sockaddr* name()
        {
                return cast(sockaddr*)&sin;
        }

        /***********************************************************************


        ***********************************************************************/

        int nameLen()
        {
                return sin.sizeof;
        }

        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily()
        {
                return AddressFamily.INET;
        }

        /***********************************************************************


        ***********************************************************************/

        ushort port()
        {
                return ntohs(sin.sin_port);
        }

        /***********************************************************************


        ***********************************************************************/

        uint addr()
        {
                return ntohl(sin.sin_addr);
        }

        /***********************************************************************

        ***********************************************************************/

        package this()
        {
        }

        /***********************************************************************

                -port- can be PORT_ANY
                -addr- is an IP address or host name

        ***********************************************************************/

        this(char[] addr, int port = PORT_ANY)
        {
                uint uiaddr = parse(addr);
                if(ADDR_NONE == uiaddr)
                {
                        auto ih = new NetHost;
                        if(!ih.getHostByName(addr))
                          {
                          char[16] tmp = void;
                          exception ("Unable to resolve "~addr~":"~fromInt(tmp, port));
                          }
                        uiaddr = ih.addrList[0];
                }
                sin.sin_addr = htonl(uiaddr);
                sin.sin_port = htons(cast(ushort) port);
        }

        /***********************************************************************


        ***********************************************************************/

        this(uint addr, ushort port)
        {
                sin.sin_addr = htonl(addr);
                sin.sin_port = htons(port);
        }

        /***********************************************************************


        ***********************************************************************/

        this(ushort port)
        {
                sin.sin_addr = 0; //any, "0.0.0.0"
                sin.sin_port = htons(port);
        }

        /***********************************************************************


        ***********************************************************************/

        synchronized char[] toAddrString()
        {
                return convert2D(inet_ntoa(sin.sin_addr)).dup;
        }

        /***********************************************************************


        ***********************************************************************/

        char[] toPortString()
        {
                return fromInt (_port, port());
        }

        /***********************************************************************


        ***********************************************************************/

        char[] toString()
        {
                return toAddrString() ~ ":" ~ toPortString();
        }

        /***********************************************************************

                -addr- is an IP address in the format "a.b.c.d"
                returns ADDR_NONE on failure

        ***********************************************************************/

        static uint parse(char[] addr)
        {
                char[64] tmp;

                synchronized (IPv4Address.classinfo)
                              return ntohl(inet_addr(convert2C (addr, tmp)));
        }
}

debug(Unittest)
{
        unittest
        {
        IPv4Address ia = new IPv4Address("63.105.9.61", 80);
        assert(ia.toString() == "63.105.9.61:80");
        }
}


/*******************************************************************************


*******************************************************************************/

public class NetHost
{
        char[] name;
        char[][] aliases;
        uint[] addrList;

        /***********************************************************************


        ***********************************************************************/

        protected void validHostent(hostent* he)
        {
                if (he.h_addrtype != AddressFamily.INET || he.h_length != 4)
                    throw new SocketException("Address family mismatch.");
        }

        /***********************************************************************


        ***********************************************************************/

        void populate(hostent* he)
        {
                int i;
                char* p;

                name = Address.convert2D (he.h_name);

                for(i = 0;; i++)
                {
                        p = he.h_aliases[i];
                        if(!p)
                                break;
                }

                if(i)
                {
                        aliases = new char[][i];
                        for(i = 0; i != aliases.length; i++)
                        {
                                aliases[i] = Address.convert2D(he.h_aliases[i]);
                        }
                }
                else
                {
                        aliases = null;
                }

                for(i = 0;; i++)
                {
                        p = he.h_addr_list[i];
                        if(!p)
                                break;
                }

                if(i)
                {
                        addrList = new uint[i];
                        for(i = 0; i != addrList.length; i++)
                        {
                                addrList[i] = Address.ntohl(*(cast(uint*)he.h_addr_list[i]));
                        }
                }
                else
                {
                        addrList = null;
                }
        }

        /***********************************************************************


        ***********************************************************************/

        bool getHostByName(char[] name)
        {
                char[1024] tmp;

                synchronized (NetHost.classinfo)
                             {
                             hostent* he = gethostbyname(Address.convert2C (name, tmp));
                             if(!he)
                                return false;
                             validHostent(he);
                             populate(he);
                             }
                return true;
        }

        /***********************************************************************


        ***********************************************************************/

        bool getHostByAddr(uint addr)
        {
                uint x = htonl(addr);
                synchronized (NetHost.classinfo)
                             {
                             hostent* he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                             if(!he)
                                 return false;
                             validHostent(he);
                             populate(he);
                             }
                return true;
        }

        /***********************************************************************


        ***********************************************************************/

        //shortcut
        bool getHostByAddr(char[] addr)
        {
                char[64] tmp;

                synchronized (NetHost.classinfo)
                             {
                             uint x = inet_addr(Address.convert2C (addr, tmp));
                             hostent* he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                             if(!he)
                                 return false;
                             validHostent(he);
                             populate(he);
                             }
                return true;
        }
}


debug (UnitText)
{
        extern (C) int printf(char*, ...);
        unittest
        {
        try
        {
        NetHost ih = new NetHost;
        ih.getHostByName(Berkeley.hostName());
        assert(ih.addrList.length > 0);
        IPv4Address ia = new IPv4Address(ih.addrList[0], IPv4Address.PORT_ANY);
        printf("IP address = %.*s\nname = %.*s\n", ia.toAddrString(), ih.name);
        foreach(int i, char[] s; ih.aliases)
        {
                printf("aliases[%d] = %.*s\n", i, s);
        }

        printf("---\n");

        assert(ih.getHostByAddr(ih.addrList[0]));
        printf("name = %.*s\n", ih.name);
        foreach(int i, char[] s; ih.aliases)
        {
                printf("aliases[%d] = %.*s\n", i, s);
                }
        }
        catch( Object o )
        {
            assert( false );
        }
        }
}


/*******************************************************************************

        a set of sockets for Berkeley.select()

*******************************************************************************/

public class SocketSet
{
        private uint  nbytes; //Win32: excludes uint.size "count"
        private byte* buf;

        version(Win32)
        {
                uint count()
                {
                        return *(cast(uint*)buf);
                }


                void count(int setter)
                {
                        *(cast(uint*)buf) = setter;
                }


                socket_t* first()
                {
                        return cast(socket_t*)(buf + uint.sizeof);
                }
        }
        else version (Posix)
        {
                import tango.core.BitManip;


                uint nfdbits;
                socket_t _maxfd = 0;

                uint fdelt(socket_t s)
                {
                        return cast(uint)s / nfdbits;
                }


                uint fdmask(socket_t s)
                {
                        return 1 << cast(uint)s % nfdbits;
                }


                uint* first()
                {
                        return cast(uint*)buf;
                }

                public socket_t maxfd()
                {
                        return _maxfd;
                }
        }


        public:

        this (uint max)
        {
                version(Win32)
                {
                        nbytes = max * socket_t.sizeof;
                        buf = (new byte[nbytes + uint.sizeof]).ptr;
                        count = 0;
                }
                else version (Posix)
                {
                        if (max <= 32)
                            nbytes = 32 * uint.sizeof;
                        else
                           nbytes = max * uint.sizeof;

                        buf = (new byte[nbytes]).ptr;
                        nfdbits = nbytes * 8;
                        //clear(); //new initializes to 0
                }
                else
                {
                        static assert(0);
                }
        }

        this (SocketSet o) 
        {
                nbytes = o.nbytes;
                auto size = nbytes;
                version (Win32) 
                         size += uint.sizeof;

                version (Posix) 
                        {
                        nfdbits = o.nfdbits;
                        _maxfd = o._maxfd;
                        }
                
                auto b = new byte[size];
                b[] = o.buf[0..size];
                buf = b.ptr;
        }

        this()
        {
                version(Win32)
                {
                        this(64);
                }
                else version (Posix)
                {
                        this(32);
                }
                else
                {
                        static assert(0);
                }
        }

        SocketSet dup() 
        {
                return new SocketSet (this);
        }
        
        SocketSet reset()
        {
                version(Win32)
                {
                        count = 0;
                }
                else version (Posix)
                {
                        buf[0 .. nbytes] = 0;
                        _maxfd = 0;
                }
                else
                {
                        static assert(0);
                }
                return this;
        }

        void add(socket_t s)
        in
        {
                version(Win32)
                {
                        assert(count < max); //added too many sockets; specify a higher max in the constructor
                }
        }
        body
        {
                version(Win32)
                {
                        uint c = count;
                        first[c] = s;
                        count = c + 1;
                }
                else version (Posix)
                {
                        if (s > _maxfd)
                                _maxfd = s;

                        bts(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                }
                else
                {
                        static assert(0);
                }
        }

version (OldSocket)
{
        void add(OldSocket s)
        {
                add(s.fileHandle);
        }
}
        void add(Berkeley* s)
        {
                add(s.handle);
        }

        void remove(socket_t s)
        {
                version(Win32)
                {
                        uint c = count;
                        socket_t* start = first;
                        socket_t* stop = start + c;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        goto found;
                        }
                        return; //not found

                        found:
                        for(++start; start != stop; start++)
                        {
                                *(start - 1) = *start;
                        }

                        count = c - 1;
                }
                else version (Posix)
                {
                        btr(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);

                        // If we're removing the biggest file descriptor we've
                        // entered so far we need to recalculate this value
                        // for the socket set.
                        if (s == _maxfd)
                        {
                                while (--_maxfd >= 0)
                                {
                                        if (isSet(_maxfd))
                                        {
                                                break;
                                        }
                                }
                        }
                }
                else
                {
                        static assert(0);
                }
        }

version (OldSocket)
{
        void remove(OldSocket s)
        {
                remove(s.fileHandle);
        }
}
        void remove(Berkeley* s)
        {
                remove(s.handle);
        }

        int isSet(socket_t s)
        {
                version(Win32)
                {
                        socket_t* start = first;
                        socket_t* stop = start + count;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        return true;
                        }
                        return false;
                }
                else version (Posix)
                {
                        //return bt(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                        int index = cast(uint)s % nfdbits;
                        return (cast(uint*)&first[fdelt(s)])[index / (uint.sizeof*8)] & (1 << (index & ((uint.sizeof*8) - 1)));
                }
                else
                {
                        static assert(0);
                }
        }

version (OldSocket)
{
        int isSet(OldSocket s)
        {
                return isSet(s.fileHandle);
        }
}
        int isSet(Berkeley* s)
        {
                return isSet(s.handle);
        }

        uint max()
        {
                return nbytes / socket_t.sizeof;
        }

        fd_set* toFd_set()
        {
                return cast(fd_set*)buf;
        }

        /***********************************************************************

                SocketSet's are updated to include only those sockets which an
                event occured.

                Returns the number of events, 0 on timeout, or -1 on error

                for a connect()ing socket, writeability means connected
                for a listen()ing socket, readability means listening

                Winsock: possibly internally limited to 64 sockets per set

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, timeval* tv)
        {
                fd_set* fr, fw, fe;

                //make sure none of the SocketSet's are the same object
                if (checkRead)
                   {
                   assert(checkRead !is checkWrite);
                   assert(checkRead !is checkError);
                   }

                if (checkWrite)
                    assert(checkWrite !is checkError);

                version(Win32)
                {
                        //Windows has a problem with empty fd_set's that aren't null
                        fr = (checkRead && checkRead.count()) ? checkRead.toFd_set() : null;
                        fw = (checkWrite && checkWrite.count()) ? checkWrite.toFd_set() : null;
                        fe = (checkError && checkError.count()) ? checkError.toFd_set() : null;
                }
                else
                {
                        fr = checkRead ? checkRead.toFd_set() : null;
                        fw = checkWrite ? checkWrite.toFd_set() : null;
                        fe = checkError ? checkError.toFd_set() : null;
                }

                int result;

                version(Win32)
                {
                        while ((result = .select (socket_t.max - 1, fr, fw, fe, tv)) == -1)
                        {
                                if(WSAGetLastError() != WSAEINTR)
                                   break;
                        }
                }
                else version (Posix)
                {
                        socket_t maxfd = 0;

                        if (checkRead)
                                maxfd = checkRead.maxfd;

                        if (checkWrite && checkWrite.maxfd > maxfd)
                                maxfd = checkWrite.maxfd;

                        if (checkError && checkError.maxfd > maxfd)
                                maxfd = checkError.maxfd;

                        while ((result = .select (maxfd + 1, fr, fw, fe, tv)) == -1)
                        {
                                if(errno() != EINTR)
                                   break;
                        }
                }
                else
                {
                        static assert(0);
                }

                return result;
        }

        /***********************************************************************

                select with specified timeout

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, long microseconds)
        {       
                timeval tv = {
                             cast(c_long)(microseconds / 1000000), 
                             cast(c_long)(microseconds % 1000000)
                             };
                return select (checkRead, checkWrite, checkError, &tv);
        }

        /***********************************************************************

                select with maximum timeout

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError)
        {
                return select (checkRead, checkWrite, checkError, null);
        }
}


/*******************************************************************************

        Old implementation ... needs to be phased out

*******************************************************************************/

version (OldSocket)
{

alias Berkeley.Flags SocketFlags;
alias Berkeley.Shutdown SocketShutdown;

class OldSocket
{
        private Berkeley native;

        /**
         * Describe a socket flavor. If a single protocol type exists to support
         * this socket type within the address family, the ProtocolType may be
         * omitted.
         */
        this(AddressFamily family, SocketType type, ProtocolType protocol, bool create=true)
        {
                native.open (family, type, protocol, create);
        }

        package this() {}
        socket_t fileHandle() {return native.handle;}
        void reopen (socket_t sock = socket_t.init) {return native.init;}
        override char[] toString() {return "<socket>";}
        bool blocking() {return native.blocking;}
        void blocking(bool yes) {native.blocking(yes);}
        AddressFamily addressFamily() {return native.addressFamily;}
        OldSocket bind(Address addr) {native.bind(addr); return this;}
        OldSocket connect(Address to) {native.connect(to); return this;}
        OldSocket listen(int backlog) {native.listen(backlog); return this;}
        OldSocket accept() {auto s=new OldSocket; native.accept(s.native); return s;}
        OldSocket accept (OldSocket t) {native.accept(t.native); return t;}
        OldSocket shutdown(SocketShutdown how) {native.shutdown(how); return this;}
        OldSocket setLingerPeriod (int period) {native.linger(period); return this;}
        OldSocket setAddressReuse (bool y) {native.addressReuse(y); return this;}
        OldSocket setNoDelay (bool y) {native.noDelay(y); return this;}
        void joinGroup (IPv4Address address, bool onOff) {native.joinGroup(address, onOff);}
        void detach() {native.detach;}
        Address newFamilyObject() {return native.newFamilyObject;}
        static char[] hostName() {return native.hostName;}
        static uint hostAddress() {return native.hostAddress;}
        Address remoteAddress() {return native.remoteAddress;}
        Address localAddress() {return native.localAddress;}
        bool isAlive() {return native.isAlive;}
        int send(void[] buf, SocketFlags flags=SocketFlags.NONE){return native.send (buf, flags);}
        int sendTo(void[] buf, SocketFlags flags, Address to) {return native.sendTo(buf, flags, to);}
        int sendTo(void[] buf, Address to) {return native.sendTo(buf, to);}
        int sendTo(void[] buf, SocketFlags flags=SocketFlags.NONE) {return native.sendTo(buf, flags);}
        int receive(void[] buf, SocketFlags flags=SocketFlags.NONE) {return native.receive(buf, flags);}
        int receiveFrom(void[] buf, SocketFlags flags, Address from) {return native.receiveFrom(buf, flags, from);}
        int receiveFrom(void[] buf, Address from) {return native.receiveFrom(buf, from);}
        int receiveFrom(void[] buf, SocketFlags flags=SocketFlags.NONE) {return native.receiveFrom(buf,flags);}
        int getOption (SocketOptionLevel level, SocketOption option, void[] result) {return native.getOption (level, option, result);}
        OldSocket setOption (SocketOptionLevel level, SocketOption option, void[] value) {native.setOption (level, option, value); return this;}
}
}



/*
        Copyright (C) 2004 Christopher E. Miller
        
        This software is provided 'as-is', without any express or implied
        warranty.  In no event will the authors be held liable for any damages
        arising from the use of this software.
        
        Permission is granted to anyone to use this software for any purpose,
        including commercial applications, and to alter it and redistribute it
        freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must not
           claim that you wrote the original software. If you use this software
           in a product, an acknowledgment in the product documentation would be
           appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must not be
           misrepresented as being the original software.

        3. This notice may not be removed or altered from any source distribution.

*/
// socket.d 1.1
// Mar 2004


/*******************************************************************************

        @file Socket.d
        
        Mango coercion of the excellent socket.d implementation written by 
        Chris Miller.

        The original code has been modified in several ways:

        1) It has been altered to fit within the Mango environment, meaning
           that certain original classes have been reorganized, and/or have
           subclassed Mango base-classes. For example, the original Socket
           class has been wrapped with three distinct subclasses, and now
           derives from class tango.io.Resource.

        2) All exception instances now subclass the Mango IOException.

        3) Construction of new Socket instances via accept() is now
           overloadable.

        4) Constants and enums have been moved within a class boundary to
           ensure explicit namespace usage.

        5) changed Socket.select() to loop if it was interrupted.


        All changes within the main body of code all marked with "MANGO:"

        For a good tutorial on socket-programming I highly recommend going 
        here: http://www.ecst.csuchico.edu/~beej/guide/net/

        
        @version        Initial version, March 2004      
        @author         Christopher Miller 
                        Kris Bell
                        Anders F Bjorklund (Darwin patches)

*******************************************************************************/

// MANGO: added all this module & import stuff ...
module tango.net.Socket;

private import  tango.text.Text;

private import  tango.convert.Integer;

private import  tango.sys.OS;

private import  tango.io.Conduit,
                tango.io.Exception;

private import  tango.io.model.IBuffer;

private import  tango.stdc.stdint;
private import  tango.stdc.errno;


/*******************************************************************************


*******************************************************************************/

version (linux)
         version = BsdSockets;

version (darwin)
         version = BsdSockets;

version (Posix)
         version = BsdSockets;


/*******************************************************************************


*******************************************************************************/

version (Win32)
        {
        private typedef int socket_t = ~0;

        private const int IOCPARM_MASK =  0x7f;
        private const int IOC_IN =        cast(int)0x80000000;
        private const int FIONBIO =       cast(int) (IOC_IN | ((int.sizeof & IOCPARM_MASK) << 16) | (102 << 8) | 126);
        private const int SOL_SOCKET =    0xFFFF;
        private const int SO_TYPE =       0x1008;

        private const int WSADESCRIPTION_LEN = 256;
        private const int WSASYS_STATUS_LEN = 128;
        private const int WSAEWOULDBLOCK =  10035;
        private const int WSAEINTR =        10004;
                
                
        struct WSADATA
        {
                        WORD wVersion;
                        WORD wHighVersion;
                        char szDescription[WSADESCRIPTION_LEN+1];
                        char szSystemStatus[WSASYS_STATUS_LEN+1];
                        ushort iMaxSockets;
                        ushort iMaxUdpDg;
                        char* lpVendorInfo;
        }
        alias WSADATA* LPWSADATA;
                
        extern  (Windows)
                {
                int WSAStartup(WORD wVersionRequested, LPWSADATA lpWSAData);
                int WSACleanup();
                socket_t socket(int af, int type, int protocol);
                int ioctlsocket(socket_t s, int cmd, uint* argp);
                int getsockopt(socket_t s, int level, int optname, char* optval, int* optlen);
                uint inet_addr(char* cp);
                int bind(socket_t s, sockaddr* name, int namelen);
                int connect(socket_t s, sockaddr* name, int namelen);
                int listen(socket_t s, int backlog);
                socket_t accept(socket_t s, sockaddr* addr, int* addrlen);
                int closesocket(socket_t s);
                int shutdown(socket_t s, int how);
                int getpeername(socket_t s, sockaddr* name, int* namelen);
                int getsockname(socket_t s, sockaddr* name, int* namelen);
                int send(socket_t s, void* buf, int len, int flags);
                int sendto(socket_t s, void* buf, int len, int flags, sockaddr* to, int tolen);
                int recv(socket_t s, void* buf, int len, int flags);
                int recvfrom(socket_t s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
                int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
                //int __WSAFDIsSet(socket_t s, fd_set* fds);
                int getsockopt(socket_t s, int level, int optname, void* optval, int* optlen);
                int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
                int gethostname(void* namebuffer, int buflen);
                char* inet_ntoa(uint ina);
                hostent* gethostbyname(char* name);
                hostent* gethostbyaddr(void* addr, int len, int type);
                int WSAGetLastError();
                }

        static this()
        {
                WSADATA wd;
                if (WSAStartup (0x0101, &wd))
                    throw new SocketException("Unable to initialize socket library.");
        }


        static ~this()
        {
                WSACleanup();
        }

        }

version (BsdSockets)
        {
        private typedef int socket_t = -1;
        
        private const int F_GETFL       = 3;
        private const int F_SETFL       = 4;
        private const int O_NONBLOCK    = 0x4000;
        private const int SOL_SOCKET_D  = 0xFFFF;
        private const int SO_TYPE       = 0x1008;

        version (Phobos)
                {
                private const int EINTR = 4;
                private const int EINPROGRESS = 115; 
                }
                
        private alias SOL_SOCKET_D SOL_SOCKET; // symbol conflict, when linking

        extern  (C)
                {
                socket_t socket(int af, int type, int protocol);
                int fcntl(socket_t s, int f, ...);
                int getsockopt(socket_t s, int level, int optname, char* optval, int* optlen);
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
                hostent* gethostbyname(char* name);
                hostent* gethostbyaddr(void* addr, int len, int type);
                }
        }


/*******************************************************************************


*******************************************************************************/

private const socket_t INVALID_SOCKET = socket_t.init;
private const int SOCKET_ERROR = -1;



/+
#ifdef INCLUDE_ALL_FOR_DOXYGEN
+/

/*******************************************************************************
        
        Internal structs: 

*******************************************************************************/

struct timeval
{
        int tv_sec; //seconds
        int tv_usec; //microseconds
}


//transparent
struct fd_set
{
}


struct sockaddr
{
        ushort sa_family;               
        char[14] sa_data = [0];             
}


struct hostent
{
        char* h_name;
        char** h_aliases;
        version(Win32)
        {
                short h_addrtype;
                short h_length;
        }
        else version(BsdSockets)
        {
                int h_addrtype;
                int h_length;
        }
        char** h_addr_list;
        
        
        char* h_addr()
        {
                return h_addr_list[0];
        }
}


/*******************************************************************************
        
        conversions for network byte-order

*******************************************************************************/

version(BigEndian)
{
        uint16_t htons(uint16_t x)
        {
                return x;
        }
        
        
        uint32_t htonl(uint32_t x)
        {
                return x;
        }
}
else version(LittleEndian)
{
        import tango.core.intrinsic;
        
        
        uint16_t htons(uint16_t x)
        {
                return cast(uint16_t) ((x >> 8) | (x << 8));
        }


        uint32_t htonl(uint32_t x)
        {
                return bswap(x);
        }
}
else
{
        static assert(0);
}


uint16_t ntohs(uint16_t x)
{
        return htons(x);
}


uint32_t ntohl(uint32_t x)
{
        return htonl(x);
}

/+
#endif
+/



/*******************************************************************************


*******************************************************************************/

private extern (C) int strlen(char*);

private static char[] toString(char* s)
{
        return s ? s[0 .. strlen(s)] : cast(char[])null;
}

private static char* convert2C (char[] input, char[] output)
{
        output [0 .. input.length] = input;
        output [input.length] = 0;
        return output.ptr;
}
        
        
/*******************************************************************************

        Public interface ...

*******************************************************************************/

public:


/*******************************************************************************


*******************************************************************************/

class HostException: IOException
{
        this(char[] msg)
        {
                super(msg);
        }
}


/*******************************************************************************


*******************************************************************************/

class SocketException: IOException
{
        this(char[] msg)
        {
                super(msg);
        }
}


/*******************************************************************************


*******************************************************************************/

class AddressException: SocketException
{
        this(char[] msg)
        {
                super(msg);
        }
}


/*******************************************************************************


*******************************************************************************/

class SocketAcceptException: SocketException
{
        this(char[] msg)
        {
                super(msg);
        }
}


/*******************************************************************************


*******************************************************************************/

static int lastError ()
{
        version (Win32)
                {       
                return WSAGetLastError();
                } 
        version (Posix)
                {
                return getErrno();
                }
}

        
/*******************************************************************************

        MANGO: socket now subclasses tango.io.Resource

*******************************************************************************/

class Socket : Conduit
{
        private socket_t sock;
        private AddressFamily _family;

        version(Win32)
                private bit _blocking = false;
        
        /***********************************************************************


        ***********************************************************************/

        /+
        #ifdef INCLUDE_ALL_FOR_DOXYGEN
        +/
        
        version (Win32)
        {
                /***************************************************************


                ***************************************************************/

                enum Option: int
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
                        IP_MULTICAST_LOOP = 0x4,
                        IP_ADD_MEMBERSHIP = 0x5,
                        IP_DROP_MEMBERSHIP = 0x6,
                }

                /***************************************************************


                ***************************************************************/

                union linger
                {
                        struct {
                               ushort l_onoff;          // option on/off
                               ushort l_linger;         // linger time
                               };
                        ushort[2]       array;          // combined 
                }

                /***************************************************************


                ***************************************************************/

                enum OptionLevel
                {
                        SOCKET =  0xFFFF, 
                        IP =      0,
                        TCP =     6,
                        UDP =     17,
                }
        }
        else version (darwin)
        {
                enum Option: int
                {
                        SO_DEBUG        = 0x0001,		/* turn on debugging info recording */
                        SO_BROADCAST    = 0x0020,		/* permit sending of broadcast msgs */
                        SO_REUSEADDR    = 0x0004,		/* allow local address reuse */
                        SO_LINGER       = 0x0080,		/* linger on close if data present */
                        SO_DONTLINGER   = ~(SO_LINGER),
                        SO_OOBINLINE    = 0x0100,		/* leave received OOB data in line */
                        SO_ACCEPTCONN   = 0x0002,		/* socket has had listen() */
                        SO_KEEPALIVE    = 0x0008,		/* keep connections alive */
                        SO_DONTROUTE    = 0x0010,		/* just use interface addresses */
                      //SO_TYPE

                        /*
                         * Additional options, not kept in so_options.
                         */
                        SO_SNDBUF       = 0x1001,		/* send buffer size */
                        SO_RCVBUF       = 0x1002,		/* receive buffer size */
                        SO_ERROR        = 0x1007,		/* get error status and clear */

                        // OptionLevel.IP settings
                        IP_MULTICAST_LOOP = 11,
                        IP_ADD_MEMBERSHIP = 12,
                        IP_DROP_MEMBERSHIP = 13,
                }

                /***************************************************************


                ***************************************************************/

                union linger
                {
                        struct {
                               int l_onoff;             // option on/off
                               int l_linger;            // linger time
                               };
                        int[2]          array;          // combined
                }

                /***************************************************************

                        Question: are these correct for Darwin?

                ***************************************************************/

                enum OptionLevel
                {
                        SOCKET =  1,  // correct for linux on x86 
                        IP =      0,  // appears to be correct
                        TCP =     6,  // appears to be correct
                        UDP =     17, // appears to be correct
                }
        }
        else version (linux)
        {
                /***************************************************************

                        these appear to be compatible with x86 platforms, 
                        but not others!

                ***************************************************************/

                enum Option: int
                {
                        //consistent
                        SO_DEBUG        = 1,
                        SO_BROADCAST    = 6,
                        SO_REUSEADDR    = 2,
                        SO_LINGER       = 13,
                        SO_DONTLINGER   = ~(SO_LINGER),
                        SO_OOBINLINE    = 10,
                        SO_SNDBUF       = 7,
                        SO_RCVBUF       = 8,
                        SO_ERROR        = 4,

                        SO_ACCEPTCONN   = 30,
                        SO_KEEPALIVE    = 9, 
                        SO_DONTROUTE    = 5, 
                        SO_TYPE         = 3, 

                        // OptionLevel.IP settings
                        IP_MULTICAST_LOOP = 34,
                        IP_ADD_MEMBERSHIP = 35,
                        IP_DROP_MEMBERSHIP = 36,
                }

                /***************************************************************


                ***************************************************************/

                union linger
                {
                        struct {
                               int l_onoff;             // option on/off
                               int l_linger;            // linger time
                               };
                        int[2]          array;          // combined
                }

                /***************************************************************


                ***************************************************************/

                enum OptionLevel
                {
                        SOCKET =  1,  // correct for linux on x86 
                        IP =      0,  // appears to be correct
                        TCP =     6,  // appears to be correct
                        UDP =     17, // appears to be correct
                }
        } // end versioning

        /***********************************************************************


        ***********************************************************************/

        enum Shutdown: int
        {
                RECEIVE =  0,
                SEND =     1,
                BOTH =     2,
        }

        /***********************************************************************


        ***********************************************************************/

        enum Flags: int
        {
                NONE =           0,
                OOB =            0x1, //out of band
                PEEK =           0x02, //only for receiving
                DONTROUTE =      0x04, //only for sending
        }

        /***********************************************************************


        ***********************************************************************/

        enum Type: int
        {
                STREAM =     1,
                DGRAM =      2,
                RAW =        3,
                RDM =        4,
                SEQPACKET =  5,
        }


        /***********************************************************************


        ***********************************************************************/

        enum Protocol: int
        {
                IP =    0,
                ICMP =  1,      // apparently a no-no for linux?
                IGMP =  2,
                GGP =   3,
                TCP =   6,
                PUP =   12,
                UDP =   17,
                IDP =   22,
                ND =    77,
                RAW =   255,
                MAX =   256,
        }


        /***********************************************************************


        ***********************************************************************/

        version(Win32)
        {
                enum AddressFamily: int
                {
                        UNSPEC =     0,
                        UNIX =       1,
                        INET =       2,
                        IPX =        6,
                        APPLETALK =  16,
                        //INET6 =      ? // Need Windows XP ?
                }
        }
        else version(BsdSockets)
        {
                version (darwin)
                {
                        enum AddressFamily: int
                        {
                                UNSPEC =     0,
                                UNIX =       1,
                                INET =       2,
                                IPX =        23,
                                APPLETALK =  16,
                                //INET6 =      10,
                        }
                }
                else version (linux)
                {
                        enum AddressFamily: int
                        {
                                UNSPEC =     0,
                                UNIX =       1,
                                INET =       2,
                                IPX =        4,
                                APPLETALK =  5,
                                //INET6 =      10,
                        }
                } // end version
        }

        /+
        #endif
        +/
        

        
        /***********************************************************************

                Construct a Socket from a handle. This is used internally
                to create new Sockets via an accept().

        ***********************************************************************/

        protected this (socket_t sock)
        {
                // MANGO: exposed the constructor functionality: see below.
                set (sock);

                super (ConduitStyle.ReadWrite, false);
        }

       /***********************************************************************
        
                Callback routine to read content from the socket. Note 
                that the operation may timeout if method setTimeout()
                has been invoked with a non-zero value.         

                Returns the number of bytes read from the socket, or
                IConduit.Eof where there's no more content available

		Note that a timeout is equivalent to Eof. Isolating
		a timeout condition can be achieved via hadTimeout() 

		Note also that a zero return value is not legitimate; 
		such a value indicates Eof

        ***********************************************************************/

        private SocketSet       ss;
        private timeval         tv;
	private bool		timeout;

        protected uint reader (void[] dst)
        {
                // ensure just one read at a time 
                synchronized (this)
                {
		// reset timeout; we assume there's no thread contention
		timeout = false;

                // did user disable timeout checks?
                if (tv.tv_usec)
                   {
                   // nope: ensure we have a SocketSet
                   if (ss is null)
                       ss = new SocketSet (1);

                   ss.reset ();
                   ss.add (this);

                   // wait until data is available, or a timeout occurs
                   int i = select (ss, null, null, &tv);
		   if (i <= 0)
                      {
		      if (i == 0)
			  timeout = true;
                      return Eof;
                      }
                   }

                int count = receive (dst);
                if (count <= 0)
                    count = Eof;
                return count;
                }
        }

        /***********************************************************************
        
                Callback routine to write the provided content to the 
                socket. This will stall until the socket responds in
                some manner. Returns the number of bytes sent to the
                output, or IConduit.Eof if the socket cannot write.

        ***********************************************************************/

        protected uint writer (void[] src)
        {
                int count = send (src);
                if (count <= 0)
                    count = Eof;
                return count;
        }

        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        uint bufferSize ()
        {
                return 1024 * 8;
        }
                     
        /***********************************************************************
        
                Return the underlying OS handle of this Conduit

        ***********************************************************************/

        final Handle getHandle ()
        {
                return cast(Handle) sock;
        }
                     
        /***********************************************************************
        
                Set the read timeout to the specified microseconds. Set a 
                value of zero to disable timeout support.

        ***********************************************************************/

        void setTimeout (uint us)
        {
                tv.tv_sec = 0;
                tv.tv_usec = us;
        }
                         
        /***********************************************************************
		
		Did the last operation result in a timeout? Note that this
		assumes there is no thread contention on this object.        

        ***********************************************************************/

        bool hadTimeout ()
        {
		return timeout;
        }
                         
        /***********************************************************************
        
                MANGO: moved this out from the above constructor so that it
                can be called from the FreeList version of SocketConduit

        ***********************************************************************/

        protected void set (socket_t sock)
        {
                this.sock = sock;
        }
                
        /***********************************************************************
        
                MANGO: added to reset socket

        ***********************************************************************/

        protected void reset ()
        {
                this.sock = INVALID_SOCKET;

                // dump all filters
                super.close();
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected this (AddressFamily af, Type type, Protocol protocol)
        {
                create (af, type, protocol);

                super (ConduitStyle.ReadWrite, false);
        }
        
        
        /***********************************************************************

                Create a new socket for binding during another join() or
                connect(), since there doesn't appear to be another means
         
        ***********************************************************************/

        protected void create ()
        {
                // can't be abstract, so throw excepion instead
                throw new SocketException ("Socket.create() must be overridden");
        }

        /***********************************************************************

                MANGO: added for multicast support

        ***********************************************************************/

        protected void create (AddressFamily af, Type type, Protocol protocol)
        {
                sock = socket (af, type, protocol);
                if(sock == sock.init)
                   exception("Unable to create socket: ");
                _family = af;
        }
        

        /***********************************************************************
        
                Re-open this socket

        ***********************************************************************/

        void reopen ()
        {
                // drop the original socket handle
                close ();

                // create a new socket for binding or connecting, since
                // there doesn't appear to be a means of unbinding
                create ();
        }
        
        /***********************************************************************

                get underlying socket handle

        ***********************************************************************/

        protected socket_t handle()
        {
                return sock;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        override char[] toString()
        {
                return "Socket";
        }
        
        
        /***********************************************************************

                getter

        ***********************************************************************/

        protected bit blocking()
        {
                version(Win32)
                {
                        return _blocking;
                }
                else version(BsdSockets)
                {
                        return !(fcntl(handle, F_GETFL, 0) & O_NONBLOCK);
                }
        }
        
        
        /***********************************************************************

                setter

        ***********************************************************************/

        protected void blocking(bit byes)
        {
                version(Win32)
                {
                        uint num = !byes;
                        if(SOCKET_ERROR == ioctlsocket(sock, FIONBIO, &num))
                                goto err;
                        _blocking = byes;
                }
                else version(BsdSockets)
                {
                        int x = fcntl(handle, F_GETFL, 0);
                        if(byes)
                                x &= ~O_NONBLOCK;
                        else
                                x |= O_NONBLOCK;
                        if(SOCKET_ERROR == fcntl(sock, F_SETFL, x))
                                goto err;
                }
                return; //success
                
                err:
                exception("Unable to set socket blocking: ");
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected AddressFamily addressFamily()
        {
                return _family;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected bit isAlive()
        {
                int type, typesize = type.sizeof;
                return cast(bool) (getsockopt (sock, SOL_SOCKET, SO_TYPE, cast(char*) &type, &typesize) != SOCKET_ERROR);
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected void bind(Address addr)
        {
                if(SOCKET_ERROR == .bind (sock, addr.name(), addr.nameLen()))
                   exception ("Unable to bind socket: ");
        }
        
        
        /***********************************************************************


        ***********************************************************************/
 
        void connect(Address to)
        {
                if(SOCKET_ERROR == .connect (sock, to.name(), to.nameLen()))
                {
                        if(!blocking)
                        {
                                version(Win32)
                                {
                                        if(WSAEWOULDBLOCK == WSAGetLastError())
                                                return;
                                }
                                else version (Posix)
                                {
                                        if(EINPROGRESS == getErrno())
                                                return;
                                }
                                else
                                {
                                        static assert(0);
                                }
                        }
                        exception ("Unable to connect socket: ");
                }
        }
        
        
        /***********************************************************************

                need to bind() first

        ***********************************************************************/

        protected void listen(int backlog)
        {
                if(SOCKET_ERROR == .listen (sock, backlog))
                   exception ("Unable to listen on socket: ");
        }
        
        /***********************************************************************

                MANGO: added

        ***********************************************************************/

        protected Socket createSocket (socket_t handle)
        {
                return new Socket (handle);
        }

        /***********************************************************************


        ***********************************************************************/

        protected Socket accept()
        {       
                socket_t newsock = .accept (sock, null, null);
                if(INVALID_SOCKET == newsock)
                   // MANGO: return null rather than throwing an exception because
                   // this is a valid condition upon thread-termination.
                  {
                  return null;
                  //exception("Unable to accept socket connection.");
                  }

                // MANGO: changed to indirect construction
                Socket newSocket = createSocket (newsock);

                version(Win32)
                        newSocket._blocking = _blocking; //inherits blocking mode
                newSocket._family = _family; //same family
                return newSocket;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        void shutdown()
        {       //printf ("shutdown\n");
                .shutdown (sock, cast(int) Shutdown.BOTH);
        }
        
        /***********************************************************************


        ***********************************************************************/

        protected void shutdown(Shutdown how)
        {
                .shutdown (sock, cast(int)how);
        }
        

        /***********************************************************************

                MANGO: added

        ***********************************************************************/

        void setLingerPeriod (int period)
        {
                linger l;

                l.l_onoff = 1;                          //option on/off
                l.l_linger = cast(ushort) period;       //linger time
        
                setOption (OptionLevel.SOCKET, Option.SO_LINGER, l.array);
        }
        

        /***********************************************************************


                MANGO: added

        ***********************************************************************/

        protected void setAddressReuse (bool enabled)
        {
                int[1] x = enabled;
                setOption (OptionLevel.SOCKET, Option.SO_REUSEADDR, x);
        }

        
        /***********************************************************************

                Helper function to handle the adding and dropping of group
                membership.

                MANGO: Added

        ***********************************************************************/

        protected bool setGroup (InternetAddress address, Option option)
        {
                struct ip_mreq 
                {
                uint  imr_multiaddr;  /* IP multicast address of group */
                uint  imr_interface;  /* local IP address of interface */
                };

                ip_mreq mrq;

                mrq.imr_interface = 0;
                mrq.imr_multiaddr = address.sin.sin_addr;
                return cast(bool) (.setsockopt(handle(), OptionLevel.IP, option, &mrq, mrq.sizeof) != SOCKET_ERROR);
        }


        /***********************************************************************

                calling shutdown() before this is recommended for connection-
                oriented sockets

        ***********************************************************************/

        override void close ()
        {
                super.close ();
                collect ();
        }       
        
        /***********************************************************************

        ***********************************************************************/

        private void collect ()
        {
                if (sock != sock.init)
                   {
                   version (TraceLinux)
                            printf ("closing socket handle ...\n");

                   version(Win32)
                           .closesocket (sock);
                   else 
                   version(BsdSockets)
                           .close (sock);

                   version (TraceLinux)
                            printf ("socket handle closed\n");

                   sock = sock.init;
                   }
        }       
        
        /***********************************************************************

        ***********************************************************************/

        ~this ()
        {
                if (! isHalting)
                       collect ();
        }

        /***********************************************************************


        ***********************************************************************/

        private Address newFamilyObject ()
        {
                Address result;
                switch(_family)
                {
                        case AddressFamily.INET:
                                result = new InternetAddress;
                                break;
                        
                        default:
                                result = new UnknownAddress;
                }
                return result;
        }
        
        
        /***********************************************************************

                Mango: added this to return the hostname

        ***********************************************************************/

        protected static char[] hostName ()
        {
                char[64] name;

                if(SOCKET_ERROR == .gethostname (name, name.length))
                   exception ("Unable to obtain host name: ");
                return name [0 .. strlen(name)].dup;
        }
        

        /***********************************************************************

                Mango: added this to return the default host address (IPv4)

        ***********************************************************************/

        protected static uint hostAddress ()
        {
                InternetHost ih = new InternetHost;

                char[] hostname = hostName();
                ih.getHostByName (hostname);
                assert (ih.addrList.length);
                return ih.addrList[0];
        }

        
        /***********************************************************************


        ***********************************************************************/

        Address remoteAddress ()
        {
                Address addr = newFamilyObject ();
                int nameLen = addr.nameLen ();
                if(SOCKET_ERROR == .getpeername (sock, addr.name(), &nameLen))
                   exception ("Unable to obtain remote socket address: ");
                assert (addr.addressFamily() == _family);
                return addr;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        Address localAddress ()
        {
                Address addr = newFamilyObject ();
                int nameLen = addr.nameLen();
                if(SOCKET_ERROR == .getsockname (sock, addr.name(), &nameLen))
                   exception ("Unable to obtain local socket address: ");
                assert (addr.addressFamily() == _family);
                return addr;
        }
        
        
        /***********************************************************************

                returns number of bytes actually sent, or -1 on error

        ***********************************************************************/

        protected int send (void[] buf, Flags flags = Flags.NONE)
        {
                int sent = .send (sock, buf, buf.length, cast(int)flags);
                return sent;
        }
        
        
        /***********************************************************************

                -to- is ignored if connected ?

        ***********************************************************************/

        protected int sendTo (void[] buf, Flags flags, Address to)
        {
                int sent = .sendto (sock, buf, buf.length, cast(int)flags, to.name(), to.nameLen());
                return sent;
        }
        
        
        /***********************************************************************

                -to- is ignored if connected ?

        ***********************************************************************/

        protected int sendTo (void[] buf, Address to)
        {
                return sendTo (buf, Flags.NONE, to);
        }
        
        
        /***********************************************************************

                assumes you connect()ed

        ***********************************************************************/

        protected int sendTo (void[] buf, Flags flags = Flags.NONE)
        {
                int sent = .sendto (sock, buf, buf.length, cast(int)flags, null, 0);
                return sent;
        }
        
        
        /***********************************************************************

                returns number of bytes actually received, 0 on connection 
                closure, or -1 on error

        ***********************************************************************/

        protected int receive (void[] buf, Flags flags = Flags.NONE)
        {
                if(!buf.length) //return 0 and don't think the connection closed
                        return 0;
                int read = .recv(sock, buf, buf.length, cast(int)flags);
                if (read == SOCKET_ERROR)
                    exception ("during socket recieve: ");
                // if(!read) //connection closed
                return read;
        }
        
        
        /***********************************************************************

                -from- is ignored if connected ?

        ***********************************************************************/

        protected int receiveFrom (void[] buf, Flags flags, out Address from)
        {
                if(!buf.length) //return 0 and don't think the connection closed
                        return 0;
                version (TraceLinux)
                        {
                        printf ("executing recvFrom() \n");
                        }
                from = newFamilyObject ();
                int nameLen = from.nameLen ();
                int read = .recvfrom (sock, buf, buf.length, cast(int)flags, from.name(), &nameLen);
                version (TraceLinux)
                        {
                        printf ("recvFrom returns %d\n", read);
                        }
                if (read == SOCKET_ERROR)
                    exception ("during socket recieve: ");

                assert (from.addressFamily() == _family);
                // if(!read) //connection closed
                return read;
        }
        
        
        /***********************************************************************

                -from- is ignored if connected ?

        ***********************************************************************/

        protected int receiveFrom (void[] buf, out Address from)
        {
                return receiveFrom (buf, Flags.NONE, from);
        }
        
        
        /***********************************************************************

                assumes you connect()ed

        ***********************************************************************/

        protected int receiveFrom (void[] buf, Flags flags)
        {
                if(!buf.length) //return 0 and don't think the connection closed
                        return 0;
                int read = .recvfrom (sock, buf, buf.length, cast(int)flags, null, null);
                if (read == SOCKET_ERROR)
                    exception ("during socket recieve: ");
                // if(!read) //connection closde
                return read;
        }
        
        
        /***********************************************************************

                assumes you connect()ed

        ***********************************************************************/

        protected int receiveFrom (void[] buf)
        {
                return receiveFrom (buf, Flags.NONE);
        }
        
        
        /***********************************************************************

                returns the length, in bytes, of the actual result - very 
                different from getsockopt()

        ***********************************************************************/

        protected int getOption (OptionLevel level, Option option, void[] result)
        {
                int len = result.length;
                if(SOCKET_ERROR == .getsockopt (sock, cast(int)level, cast(int)option, result, &len))
                   exception ("Unable to get socket option: ");
                return len;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected void setOption (OptionLevel level, Option option, void[] value)
        {
                if(SOCKET_ERROR == .setsockopt (sock, cast(int)level, cast(int)option, value, value.length))
                   exception ("Unable to set socket option: ");
        }
        
        
        /***********************************************************************

                Mango: added this common function

        ***********************************************************************/

        protected static void exception (char[] msg)
        {
                throw new SocketException (msg ~ OS.error (lastError));
        }
        

        /***********************************************************************

                SocketSet's are updated to include only those sockets which an 
                event occured.
                
                Returns the number of events, 0 on timeout, or -1 on interruption

                for a connect()ing socket, writeability means connected 
                for a listen()ing socket, readability means listening 

                Winsock: possibly internally limited to 64 sockets per set

        ***********************************************************************/

        protected static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, timeval* tv)
        in
        {
                //make sure none of the SocketSet's are the same object
                if(checkRead)
                {
                        assert(checkRead !is checkWrite);
                        assert(checkRead !is checkError);
                }
                if(checkWrite)
                {
                        assert(checkWrite !is checkError);
                }
        }
        body
        {
                fd_set* fr, fw, fe;
                
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
              
                // MANGO: if select() was interrupted, we now try again
                while ((result = .select (socket_t.max - 1, fr, fw, fe, tv)) == -1)              
                        version(Win32)
                        {
                                if(WSAGetLastError() != WSAEINTR)
                                   break;
                        }
                        else version (Posix)
                        {
                                if(getErrno() != EINTR)
                                   break;
                        }
                        else
                        {
                                static assert(0);
                        }
                
                // MANGO: don't throw an exception here ... wait until we get 
                // a bit further back along the control path
                //if(SOCKET_ERROR == result)
                //   throw new SocketException("Socket select error.");
                
                return result;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        protected static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, int microseconds)
        {
                timeval tv;
                tv.tv_sec = 0;
                tv.tv_usec = microseconds;
                return select (checkRead, checkWrite, checkError, &tv);
        }
        
        
        /***********************************************************************

                maximum timeout

        ***********************************************************************/

        protected static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError)
        {
                return select (checkRead, checkWrite, checkError, null);
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        /+
        bit poll (events)
        {
                int WSAEventSelect(socket_t s, WSAEVENT hEventObject, int lNetworkEvents); // Winsock 2 ?
                int poll(pollfd* fds, int nfds, int timeout); // Unix ?
        }
        +/


}



/*******************************************************************************


*******************************************************************************/

abstract class Address
{
        protected sockaddr* name();
        protected int nameLen();
        Socket.AddressFamily addressFamily();
        char[] toString();

        /***********************************************************************

                Mango: added this common function

        ***********************************************************************/

        protected static void exception (char[] msg)
        {
                throw new AddressException (msg);
        }
        
}


/*******************************************************************************


*******************************************************************************/

class UnknownAddress: Address
{
        protected:
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
        
        
        public:
        /***********************************************************************


        ***********************************************************************/

        Socket.AddressFamily addressFamily()
        {
                return cast(Socket.AddressFamily)sa.sa_family;
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

class InternetHost
{
        char[] name;
        char[][] aliases;
        uint[] addrList;
        
        
        /***********************************************************************


        ***********************************************************************/

        protected void validHostent(hostent* he)
        {
                if(he.h_addrtype != cast(int)Socket.AddressFamily.INET || he.h_length != 4)
                        throw new HostException("Address family mismatch.");
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        void populate(hostent* he)
        {
                int i;
                char* p;
                
                name = .toString(he.h_name);
                
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
                                aliases[i] = .toString(he.h_aliases[i]);
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
                                addrList[i] = ntohl(*(cast(uint*)he.h_addr_list[i]));
                        }
                }
                else
                {
                        addrList = null;
                }
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        bit getHostByName(char[] name)
        {
                char[1024] tmp;
                
                hostent* he = gethostbyname(convert2C (name, tmp));
                if(!he)
                        return false;
                validHostent(he);
                populate(he);
                return true;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        bit getHostByAddr(uint addr)
        {
                uint x = htonl(addr);
                hostent* he = gethostbyaddr(&x, 4, cast(int)Socket.AddressFamily.INET);
                if(!he)
                        return false;
                validHostent(he);
                populate(he);
                return true;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        //shortcut
        bit getHostByAddr(char[] addr)
        {
                char[64] tmp;
                
                uint x = inet_addr(convert2C (addr, tmp));
                hostent* he = gethostbyaddr(&x, 4, cast(int)Socket.AddressFamily.INET);
                if(!he)
                        return false;
                validHostent(he);
                populate(he);
                return true;
        }
}


unittest
{
        InternetHost ih = new InternetHost;
        assert(ih.addrList.length);
        InternetAddress ia = new InternetAddress(ih.addrList[0], InternetAddress.PORT_ANY);
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


/*******************************************************************************


*******************************************************************************/

class InternetAddress: Address
{
        /+
        #ifdef INCLUDE_ALL_FOR_DOXYGEN
        +/
        protected:
        char[8] _port;

        /***********************************************************************


        ***********************************************************************/

        struct sockaddr_in
        {
                ushort sin_family = cast(ushort)Socket.AddressFamily.INET;
                ushort sin_port;
                uint sin_addr; //in_addr
                char[8] sin_zero = [0];
        }
        /+
        #endif
        +/

        sockaddr_in sin;
        
        
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

        this()
        {
        }
        
        
        public:
        const uint ADDR_ANY = 0;
        const uint ADDR_NONE = cast(uint)-1;
        const ushort PORT_ANY = 0;
        
        
        /***********************************************************************


        ***********************************************************************/

        Socket.AddressFamily addressFamily()
        {
                return Socket.AddressFamily.INET;
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

                -port- can be PORT_ANY
                -addr- is an IP address or host name

        ***********************************************************************/

        this(char[] addr, int port = PORT_ANY)
        {
                uint uiaddr = parse(addr);
                if(ADDR_NONE == uiaddr)
                {
                        InternetHost ih = new InternetHost;
                        if(!ih.getHostByName(addr))
                                exception ("Unable to resolve '"~addr~"'");
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
        
        /**********************************************************************
        
        **********************************************************************/
		
        static InternetAddress create (char[] host)
        {
                foreach (int i, char c; host)
                         if (c is ':')
                             return new InternetAddress (host[0..i], cast(int) Integer.parse (host[i+1..$]));

                exception ("missing port specification in "~host);
                return null;
        }

        /***********************************************************************


        ***********************************************************************/

        char[] toAddrString()
        {
                return .toString(inet_ntoa(sin.sin_addr)).dup;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        char[] toPortString()
        {
                return Integer.format(_port, port());
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

                return ntohl(inet_addr(convert2C (addr, tmp)));
        }
}


unittest
{
        InternetAddress ia = new InternetAddress("63.105.9.61", 80);
        assert(ia.toString() == "63.105.9.61:80");
}


/*******************************************************************************


*******************************************************************************/

//a set of sockets for Socket.select()
class SocketSet
{
//        private:
        private uint nbytes; //Win32: excludes uint.size "count"
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
                import tango.core.intrinsic;
                
                
                uint nfdbits;
                
                
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
        }
        
        
        public:
        /***********************************************************************


        ***********************************************************************/

        this(uint max)
        {
                version(Win32)
                {
                        nbytes = max * socket_t.sizeof;
                        buf = new byte[nbytes + uint.sizeof];
                        count = 0;
                }
                else version (Posix)
                {
                        if(max <= 32)
                                nbytes = 32 * uint.sizeof;
                        else
                                nbytes = max * uint.sizeof;
                        buf = new byte[nbytes];
                        nfdbits = nbytes * 8;
                        //clear(); //new initializes to 0
                }
                else
                {
                        static assert(0);
                }
        }
        
        
        /***********************************************************************


        ***********************************************************************/

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
        
        
        /***********************************************************************


        ***********************************************************************/

        void reset()
        {
                version(Win32)
                {
                        count = 0;
                }
                else version (Posix)
                {
                        buf[0 .. nbytes] = 0;
                }
                else
                {
                        static assert(0);
                }
        }
        
        
        /***********************************************************************


        ***********************************************************************/

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
                        bts(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                }
                else
                {
                        static assert(0);
                }
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        void add(Socket s)
        {
                add(s.sock);
        }
        
        
        /***********************************************************************


        ***********************************************************************/

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
                }
                else
                {
                        static assert(0);
                }
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        void remove(Socket s)
        {
                remove(s.sock);
        }
        
        
        /***********************************************************************


        ***********************************************************************/

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
        
        
        /***********************************************************************


        ***********************************************************************/

        int isSet(Socket s)
        {
                return isSet(s.sock);
        }
        
        
        /***********************************************************************

                max sockets that can be added, like FD_SETSIZE

        ***********************************************************************/

        uint max() 
        {
                return nbytes / socket_t.sizeof;
        }
        
        
        /***********************************************************************


        ***********************************************************************/

        fd_set* toFd_set()
        {
                return cast(fd_set*)buf;
        }
}




/******************************************************************************/
/******************* additions for the tango.io package  **********************/           
/******************************************************************************/


/******************************************************************************

******************************************************************************/

interface IListener
{
        /***********************************************************************

                Stop listening; this may be delayed until after the next
                valid read operation.

        ***********************************************************************/

        void cancel ();
}


/******************************************************************************

******************************************************************************/

interface ISocketReader
{
        /***********************************************************************

                Polymorphic contract for readers handed to a listener. 
                Should return the number of bytes read, or -1 on error.

        ***********************************************************************/

        uint read (IBuffer buffer);
}




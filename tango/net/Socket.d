/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
        version:        Jan 2005: RedShodan patch for timeout query
        version:        Dec 2006: Outback release
        version:        Apr 2009: revised for asynchronous IO
        version:        Aug 2011: Druntime ready for D2

        author:         Kris, Chrono

*******************************************************************************/

module tango.net.Socket;

private import  core.sys.posix.sys.socket;
private import  core.sys.posix.netinet.in_;
private import  core.sys.posix.netinet.tcp;

private import  tango.core.Exception,
                tango.sys.Common;

private import  tango.io.device.Conduit,
                tango.io.model.ISelectable;

private import  tango.net.Address,
                tango.net.InternetAddress,
                tango.net.LocalAddress,
                tango.net.SocketSet;

/*******************************************************************************

*******************************************************************************/

version (Windows)
{
         private import tango.sys.win32.WsaSock;
}

/*******************************************************************************

*******************************************************************************/

enum
{
        SOCKET_ERROR = -1
}

/*******************************************************************************

*******************************************************************************/

private typedef int socket_t = ~0;

/*******************************************************************************

*******************************************************************************/

enum SocketOption
{
        DEBUG        =   SO_DEBUG     ,       /* turn on debugging info recording */
        BROADCAST    =   SO_BROADCAST ,       /* permit sending of broadcast msgs */
        REUSEADDR    =   SO_REUSEADDR ,       /* allow local address reuse */
        LINGER       =   SO_LINGER    ,       /* linger on close if data present */
        DONTLINGER   = ~(SO_LINGER),
        
        OOBINLINE    =   SO_OOBINLINE ,       /* leave received OOB data in line */
        ACCEPTCONN   =   SO_ACCEPTCONN,       /* socket has had listen() */
        KEEPALIVE    =   SO_KEEPALIVE ,       /* keep connections alive */
        DONTROUTE    =   SO_DONTROUTE ,       /* just use interface addresses */
        TYPE         =   SO_TYPE      ,       /* get socket type */
    
        /*
         * Additional options, not kept in so_options.
         */
        SNDBUF       =   SO_SNDBUF,               /* send buffer size */
        RCVBUF       =   SO_RCVBUF,               /* receive buffer size */
        ERROR        =   SO_ERROR ,               /* get error status and clear */

        // OptionLevel.IP settings
        //MULTICAST_TTL   = IP_MULTICAST_TTL  ,   /* not available in druntime */
        //MULTICAST_LOOP  = IP_MULTICAST_LOOP ,   /* not available in druntime */
        //ADD_MEMBERSHIP  = IP_ADD_MEMBERSHIP ,   /* not available in druntime */
        //DROP_MEMBERSHIP = IP_DROP_MEMBERSHIP,   /* not available in druntime */
    
        // OptionLevel.TCP settings
        TCP_NODELAY     = TCP_NODELAY ,

        // Windows specifics    
        WIN_UPDATE_ACCEPT_CONTEXT  = 0x700B, 
        WIN_CONNECT_TIME           = 0x700C, 
        WIN_UPDATE_CONNECT_CONTEXT = 0x7010, 
}
    
/*******************************************************************************

*******************************************************************************/

enum SocketOptionLevel
{
        SOCKET = SOL_SOCKET    ,
        IP     = IPPROTO_IP    ,   
        TCP    = IPPROTO_TCP   ,   
        UDP    = IPPROTO_UDP   ,   
}
    
/*******************************************************************************

*******************************************************************************/

enum SocketType
{
        STREAM    = SOCK_STREAM   , /++ sequential, reliable +/
        DGRAM     = SOCK_DGRAM    , /++ connectionless unreliable, max length +/
        SEQPACKET = SOCK_SEQPACKET, /++ sequential, reliable, max length +/
}

/*******************************************************************************

*******************************************************************************/

enum ProtocolType
{
        NONE = 0            ,     /// no protocol
        IP   = IPPROTO_IP   ,     /// default internet protocol (probably 4 for compatibility)
        IPV4 = IPPROTO_IP   ,     /// internet protocol version 4
        IPV6 = IPPROTO_IPV6 ,     /// internet protocol version 6
        ICMP = IPPROTO_ICMP ,     /// internet control message protocol
        TCP  = IPPROTO_TCP  ,     /// transmission control protocol
        UDP  = IPPROTO_UDP  ,     /// user datagram protocol
}

/*******************************************************************************

*******************************************************************************/

enum SocketShutdown
{
        RECEIVE =  SHUT_RD,
        SEND =     SHUT_WR,
        BOTH =     SHUT_RDWR,
}

/*******************************************************************************

*******************************************************************************/

enum SocketFlags
{
        NONE =           0,
        OOB =            MSG_OOB,               /// out of band
        PEEK =           MSG_PEEK,              /// only for receiving
        DONTROUTE =      MSG_DONTROUTE,         /// only for sending
        NOSIGNAL =       0x4000,                /// inhibit signals
}

/*******************************************************************************

        A wrapper around the Berkeley API to implement the IConduit 
        abstraction and add stream-specific functionality.

*******************************************************************************/

class Socket : Conduit, ISelectable
{
        public alias native socket;             // backward compatibility
        
        private int             scheduler;
        private socket_t        sock;
        private SocketType      type;
        private AddressFamily   family;
        private ProtocolType    protocol;
        private SocketSet       pending;        // synchronous timeouts
        

        /// see super.timeout(int)
        deprecated void setTimeout (double t) 
        {
                timeout = cast(uint) (t * 1000);
        }

        deprecated bool hadTimeout ()
        {
                return false;
        }

        /***********************************************************************
        
                Create a streaming Internet socket

        ***********************************************************************/

        this ()
        {
                this (AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        }

        /***********************************************************************
        
                Create an Internet Socket with the provided characteristics

        ***********************************************************************/

        this (Address addr) 
        { 
                this (addr.addressFamily, SocketType.STREAM, ProtocolType.TCP); 
        }
                                
        /***********************************************************************
        
                Create an Internet socket

        ***********************************************************************/
        /**
         * construct a new socket
         * 
         * params:
         *  family = the address family, example:  AddressFamily.INET
         *  type = the type of socket. example: SocketType.STREAM
         *  protocol = the protocol. example: ProtocolType.TCP, ProtocolType.NONE.
         *  sock = an internal structure or it'll be automatically created (default).
         */
        this (AddressFamily family, SocketType type, ProtocolType protocol, socket_t sock = sock.init)
        {
            this.type = type;
            this.family = family;
            this.protocol = protocol;
            this.reopen(sock);
            version (Windows) {
                if (scheduler)
                    scheduler.open(handle, toString);
            }
        }
        
        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override immutable(char)[] toString()
        {
                return "<socket>";
        }

        /***********************************************************************

                Models a handle-oriented device. 

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        Handle handle ()
        {
                return cast(Handle)(this.sock);
        }
        
        /**
         * native returns the native socket, which is usually what you know as socket_t
         * 
         * returns:
         *  socket_t
         */
        socket_t native()
        {
                return this.sock;
        }
        
        /**
         * set a native socket. use this only if you know what you're doing!
         * 
         * params:
         *  socket = a native socket handle, usually a socket_t type
         */
        void native(socket_t socket)
        {
            this.sock = socket;
        }
        
        /**
         * Open/reopen a native socket for this instance, if it was previously closed via detached
         * 
         * params:
         *  sock = a native socket, which will be set. otherwise a new one is requested
         */
        void reopen(socket_t sock = sock.init)
        {
            // detch of yet opened
            if (this.sock != sock.init)
                this.detach();

            // request a new socket
            if(sock is sock.init) {
                sock = cast(socket_t).socket(this.family, this.type, this.protocol);
                if (sock == -1)
                    throw new SocketException("Unable to create socket: ");
            }
            
            this.sock = sock;
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        override const size_t bufferSize ()
        {
                return 1024 * 8;
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        Socket connect (const(char)[] address, uint port)
        {
                assert(port < ushort.max);
                scope addr = new InternetAddress(address, cast(ushort) port);
                return connect (addr);
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        Socket connect (Address address)
        {
                // async connect via scheduler ?
                if(scheduler) {
                    asyncConnect(address);
                    return this;
                }
                
                // normal connect
                if(.connect(this.sock, address.name, address.nameLen) == -1) {
                    throw new SocketException("Unable to connect socket: ");
                }
                
                return this;
        }

        /***********************************************************************

                Inform other end of a connected socket that we're no longer
                available. In general, this should be invoked before close()
        
                The shutdown function shuts down the connection of the socket: 

                    -   stops receiving data for this socket. If further data 
                        arrives, it is rejected.

                    -   stops trying to transmit data from this socket. Also
                        discards any data waiting to be sent. Stop looking for 
                        acknowledgement of data already sent; don't retransmit 
                        if any data is lost.

        ***********************************************************************/

        Socket shutdown (SocketShutdown how = SocketShutdown.BOTH)
        {
                .shutdown (this.sock, how);
                return this;
        }

        /***********************************************************************

                Release this Socket

                Note that one should always disconnect a Socket under 
                normal conditions, and generally invoke shutdown on all 
                connected sockets beforehand

        ***********************************************************************/

        override void detach ()
        {
                if (this.sock != this.sock.init)
                    .close(this.sock);
                this.sock = this.sock.init;
        }
        
       /***********************************************************************

                Read content from the socket. Note that the operation 
                may timeout if method setTimeout() has been invoked with 
                a non-zero value.

                Returns the number of bytes read from the socket, or
                IConduit.Eof where there's no more content available.

        ***********************************************************************/

        override size_t read (void[] dst)
        {
                if (scheduler)
                    return asyncRead (dst);

                size_t x = Eof;
                if (wait (true)) {
                    x = this.receive(dst);
                    
                    // x = -1 is normally some kind of error if the socket is in BLOCKING mode!
                    // so fix this in future for non blocking sockets.
                    if(x == -1)
                        throw new SocketException("read error on socket");
                    else if (x <= 0)
                        x = Eof;
                }
                return x;                        
        }
        
        /***********************************************************************

        ***********************************************************************/

        override size_t write (const(void)[] src)
        {
                if (scheduler)
                    return asyncWrite (src);

                size_t x = Eof;
                if (wait (false))
                   {
                   x = this.send(src);
                   if (x < 0)
                       x = Eof;
                   }
                return x;                        
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                the dst OutputStream, or throws IOException on failure.

                Does optimized transfers 

        ***********************************************************************/

        override OutputStream copy (InputStream src, size_t max = -1)
        {
                auto x = cast(ISelectable) src;

                if (scheduler && x)
                    asyncCopy (x.handle);
                else
                   super.copy (src, max);
                return this;
        }
        
        
        /***********************************************************************

                Send data on the connection. Returns the number of bytes 
                actually sent, or ERROR on failure. If the socket is blocking 
                and there is no buffer space left, send waits.

                Returns number of bytes actually sent, or -1 on error

        ***********************************************************************/

        ssize_t send (const(void[]) buf, SocketFlags flags=SocketFlags.NONE)
        {       
                if (buf.length is 0)
                    return 0;

                version (Posix)
                        {
                        auto ret = .send (sock, cast(char*)buf.ptr, buf.length, 
                                          SocketFlags.NOSIGNAL + cast(int) flags);
                        if (errno is EPIPE)
                            ret = -1;
                        return ret;
                        }
                     else
                        return .send (sock, buf.ptr, buf.length, cast(int) flags);
        }

        /***********************************************************************

                Send data to a specific destination Address. If the 
                destination address is not specified, a connection 
                must have been made and that address is used. If the 
                socket is blocking and there is no buffer space left, 
                sendTo waits.

        ***********************************************************************/

        ssize_t sendTo (const(void)[] buf, SocketFlags flags, Address to)
        {
                return sendTo(buf, flags, to.name, to.nameLen);
        }

        /***********************************************************************

                ditto

        ***********************************************************************/

        ssize_t sendTo (const(void)[] buf, Address to)
        {
                return sendTo(buf, SocketFlags.NONE, to);
        }

        /***********************************************************************

                ditto - assumes you connect()ed

        ***********************************************************************/

        ssize_t sendTo (const(void)[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                return sendTo(buf, flags, null, 0);
        }

        /***********************************************************************

                Send data to a specific destination Address. If the 
                destination address is not specified, a connection 
                must have been made and that address is used. If the 
                socket is blocking and there is no buffer space left, 
                sendTo waits.

        ***********************************************************************/
        
        private ssize_t sendTo (const(void)[] buf, int flags, const(sockaddr*) to, int len)
        {
                if (buf.length is 0)
                    return 0;

                version (Posix)
                        {
                        auto ret = .sendto (sock, buf.ptr, buf.length, 
                                            flags | SocketFlags.NOSIGNAL, to, len);
                        if (errno is EPIPE)
                            ret = -1;
                        return ret;
                        }
                     else
                        return .sendto (sock, buf.ptr, buf.length, flags, to, len);
        }
        
        /***********************************************************************
                Receive data on the connection. Returns the number of 
                bytes actually received, 0 if the remote side has closed 
                the connection, or ERROR on failure. If the socket is blocking, 
                receive waits until there is data to be received.
                
                Returns number of bytes actually received, 0 on connection 
                closure, or -1 on error

        ***********************************************************************/

        ssize_t receive (void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                if (!buf.length)
                    throw new SocketException("Socket.receive :: target buffer has 0 length");

                return .recv(this.sock, buf.ptr, buf.length, flags);
        }
        
        /***********************************************************************

                Receive data and get the remote endpoint Address. Returns 
                the number of bytes actually received, 0 if the remote side 
                has closed the connection, or ERROR on failure. If the socket 
                is blocking, receiveFrom waits until there is data to be 
                received.

        ***********************************************************************/

        ssize_t receiveFrom (void[] buf, SocketFlags flags, Address from)
        {
                if (!buf.length)
                    throw new SocketException("Socket.receiveFrom :: target buffer has 0 length");

                assert(from.addressFamily() == family);
                uint nameLen = from.nameLen();
                return .recvfrom(sock, buf.ptr, buf.length, flags, from.name(), &nameLen);
        }

        /***********************************************************************

                ditto

        ***********************************************************************/

        ssize_t receiveFrom (void[] buf, Address from)
        {
                return receiveFrom(buf, SocketFlags.NONE, from);
        }

        /***********************************************************************

                ditto - assumes you connect()ed

        ***********************************************************************/

        ssize_t receiveFrom (void[] buf, SocketFlags flags = SocketFlags.NONE)
        {
                if (!buf.length)
                    throw new SocketException("Socket.receiveFrom :: target buffer has 0 length");

                return .recvfrom(sock, buf.ptr, buf.length, flags, null, null);
        }

        /***********************************************************************
 
                Manage socket IO under a timeout

        ***********************************************************************/

        package final bool wait (bool reading)
        {
                // did user enable timeout checks?
                if (timeout != -1) {
                    SocketSet read, write;

                   // yes, ensure we have a SocketSet
                   if (pending is null)
                       pending = new SocketSet (1);
                   pending.reset.add (this.sock);

                   // wait until IO is available, or a timeout occurs
                   if (reading)
                       read = pending;
                   else
                      write = pending;
                
                   int i = this.select (read, write, null, timeout * 1000);
                   
                   if(i is 0)
                       super.error ("Socket :: request timeout");
                       
                   if(i <= 0)
                       return false;
                }    
                return true;
        }

        /***********************************************************************

                Throw an IOException noting the last error
        
        ***********************************************************************/

        final void error ()
        {
                super.error (this.toString ~ " :: " ~ SysError.lastMsg);
        }
        
        /**
         * will return the name of the peer associated with this socket, that was usually specified by connect.
         * ---
         * TcpSocket socket = ...
         * Address peerAddress = localSocket.peerAddres();                      // fetch the peer address
         * Stdout.formatln("Connecting from {}", peerAddress.toString());       // prints: 218.1.234.14:44980
         * ---
         */
        public Address peerAddres()
        {
            sockaddr sa;
            socklen_t sa_len = sa.sizeof;
            
            if(.getpeername(this.sock, &sa, &sa_len) !=  0)
                throw new SocketException("Unable to call getpeername.");
            
            return Address.create(&sa);
        }
        
        /**
         * will return the local side of this connection
         * ---
         * TcpSocket socket = ...
         * Address localAddress = socket.localAddres();                          // fetch the local address
         * Stdout.formatln("Connecting from {}", localAddress.toString());       // prints: 127.0.0.1:8080
         * ---
         */
        public Address localAddress()
        {
            sockaddr sa;
            socklen_t sa_len = sa.sizeof;
            
            if(.getsockname(this.sock, &sa, &sa_len) !=  0)
                throw new SocketException("Unable to call getsockname.");
            
            return Address.create(&sa);
        }
        
        /***********************************************************************
 
        ***********************************************************************/

        version (Win32)
        {
                private OVERLAPPED overlapped;
        
                /***************************************************************
        
                        Connect to the provided endpoint
                
                ***************************************************************/
        
                private void asyncConnect (Address addr)
                {
                        IPv4Address.sockaddr_in local;
        
                        auto handle = berkeley.sock;
                        .bind (handle, cast(Address.sockaddr*)&local, local.sizeof);
        
                        ConnectEx (handle, addr.name, addr.nameLen, null, 0, null, &overlapped);
                        wait (scheduler.Type.Connect);
                        patch (handle, SO_UPDATE_CONNECT_CONTEXT);
                }
        
                /***************************************************************
        
                ***************************************************************/
        
                private void asyncCopy (Handle handle)
                {
                        TransmitFile (berkeley.sock, cast(HANDLE) handle, 
                                      0, 0, &overlapped, null, 0);
                        if (wait (scheduler.Type.Transfer) is Eof)
                            berkeley.exception ("Socket.copy :: ");
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array. Returns the number of bytes read, or Eof where 
                        there is no further data.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                private size_t asyncRead (void[] dst)
                {
                        DWORD flags;
                        DWORD bytes;
                        WSABUF buf = {dst.length, dst.ptr};

                        WSARecv (cast(HANDLE) berkeley.sock, &buf, 1, &bytes, &flags, &overlapped, null);
                        if ((bytes = wait (scheduler.Type.Read, bytes)) is Eof)
                             return Eof;

                        // read of zero means Eof
                        if (bytes is 0 && dst.length > 0)
                            return Eof;
                        return bytes;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array. Returns the number of bytes written, or Eof if 
                        the output is no longer available.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                private size_t asyncWrite (const(void[]) src)
                {
                        DWORD bytes;
                        WSABUF buf = {src.length, src.ptr};

                        WSASend (cast(HANDLE) berkeley.sock, &buf, 1, &bytes, 0, &overlapped, null);
                        if ((bytes = wait (scheduler.Type.Write, bytes)) is Eof)
                             return Eof;
                        return bytes;
                }

                /***************************************************************

                ***************************************************************/

                private size_t wait (scheduler.Type type, uint bytes=0)
                {
                        while (true)
                              {
                              auto code = WSAGetLastError;
                              if (code is ERROR_HANDLE_EOF ||
                                  code is ERROR_BROKEN_PIPE)
                                  return Eof;

                              if (scheduler)
                                 {
                                 if (code is ERROR_SUCCESS || 
                                     code is ERROR_IO_PENDING || 
                                     code is ERROR_IO_INCOMPLETE)
                                    {
                                    DWORD flags;

                                    if (code is ERROR_IO_INCOMPLETE)
                                        super.error ("timeout"); 

                                    auto handle = handle;
                                    scheduler.await (handle, type, timeout);
                                    if (WSAGetOverlappedResult (handle, &overlapped, &bytes, false, &flags))
                                        return bytes;
                                    }
                                 else
                                    error;
                                 }
                              else
                                 if (code is ERROR_SUCCESS)
                                     return bytes;
                                 else
                                    error;
                              }
                        // should never get here
                        assert (false);
                }
        
                /***************************************************************
        
                ***************************************************************/
        
                private static void patch (socket_t dst, uint how, socket_t* src=null)
                {
                        auto len = src ? src.sizeof : 0;
                        if (setsockopt (dst, SocketOptionLevel.SOCKET, how, src, len))
                            berkeley.exception ("patch :: ");
                }
        }


        /***********************************************************************
 
        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************
        
                        Connect to the provided endpoint
                
                ***************************************************************/
        
                private void asyncConnect (Address addr)
                {
                        assert (false);
                }
        
                /***************************************************************
        
                ***************************************************************/
        
                Socket asyncCopy (Handle file)
                {
                        assert (false);
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array. Returns the number of bytes read, or Eof where 
                        there is no further data.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                private size_t asyncRead (void[] dst)
                {
                        assert (false);
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array. Returns the number of bytes written, or Eof if 
                        the output is no longer available.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                private size_t asyncWrite (const(void[]) src)
                {
                        assert (false);
                }
        }
        
        /***********************************************************************

                returns the length, in bytes, of the actual result - very
                different from getsockopt()

        ***********************************************************************/

        int getOption (SocketOptionLevel level, SocketOption option, void[] result)
        {
                uint len = cast(uint) result.length;
                if(.getsockopt(sock, cast(int)level, cast(int)option, result.ptr, &len) == -1)
                    throw new SocketException("unable to get socket option: ", __FILE__, __LINE__);
                return len;
        }

        /***********************************************************************

        ***********************************************************************/

        Socket setOption (SocketOptionLevel level, SocketOption option, void[] value)
        {
                if(.setsockopt (sock, cast(int)level, cast(int)option, value.ptr, cast(int) value.length) == -1)
                    throw new SocketException("Unable to set socket option: ", __FILE__, __LINE__);
                return this;
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

                        result = .select(maxfd + 1, fr, fw, fe, tv);
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
                             cast(typeof(timeval.tv_sec)) (microseconds / 1000000), 
                             cast(typeof(timeval.tv_usec)) (microseconds % 1000000)
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
                
        /***********************************************************************

                Return the last error

        ***********************************************************************/

        static int lastError ()
        {
                version (Win32) {
                    return WSAGetLastError();
                } else {
                    return errno;
                }
        }
}

/*******************************************************************************


*******************************************************************************/

/**
 * Base class for socket exceptions.
 */
class SocketException : IOException
{
    this(immutable(char)[] msg, immutable(char)[] file = __FILE__, size_t line = __LINE__)
    {
        auto errorcode = Socket.lastError();
        auto errormsg = SysError.lookup(errorcode);
        super((msg ~ errormsg).idup, file, line);
    }
}

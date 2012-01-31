/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
        version:        Jan 2005: RedShodan patch for timeout query
        version:        Dec 2006: Outback release
        version:        Apr 2009: revised for asynchronous IO

        author:         Kris

*******************************************************************************/

module tango.net.device.Socket;

private import tango.sys.Common;

private import tango.io.device.Conduit;

package import tango.net.device.Berkeley;

/*******************************************************************************

*******************************************************************************/

version (Windows)
{
         private import tango.sys.win32.WsaSock;
}

/*******************************************************************************

        A wrapper around the Berkeley API to implement the IConduit 
        abstraction and add stream-specific functionality.

*******************************************************************************/

class Socket : Conduit, ISelectable
{
        public alias native socket;             // backward compatibility

        private SocketSet pending;              // synchronous timeouts   
        private Berkeley  berkeley;             // wrap a berkeley socket


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

        this (AddressFamily family, SocketType type, ProtocolType protocol)
        {
                berkeley.open (family, type, protocol);
                version (Windows) version(TangoRuntime)
                         if (scheduler)
                             scheduler.open (fileHandle, toString);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override string toString()
        {
                return "<socket>";
        }

        /***********************************************************************

                Models a handle-oriented device. 

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        @property Handle fileHandle ()
        {
                return cast(Handle) berkeley.sock;
        }

        /***********************************************************************

                Return the socket wrapper
                
        ***********************************************************************/

        @property Berkeley* native ()
        {
                return &berkeley;
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        @property override const size_t bufferSize ()
        {
                return 1024 * 8;
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        Socket connect (const(char)[] address, uint port)
        {
                assert(port < ushort.max);
                scope addr = new IPv4Address (address, cast(ushort) port);
                return connect (addr);
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        Socket connect (Address addr)
        {
                version (TangoRuntime)
                {
                    if (scheduler)
                        {
                        asyncConnect (addr);
                        return this;
                        }
                }
                native.connect (addr);
                
                return this;
        }

        /***********************************************************************

                Bind this socket. This is typically used to configure a
                listening socket (such as a server or multicast socket).
                The address given should describe a local adapter, or
                specify the port alone (ADDR_ANY) to have the OS assign
                a local adapter address.
        
        ***********************************************************************/

        Socket bind (Address address)
        {
                berkeley.bind (address);
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

        Socket shutdown ()
        {
                berkeley.shutdown (SocketShutdown.BOTH);
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
                berkeley.detach();
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
            version (TangoRuntime)
                if (scheduler)
                    return asyncRead (dst);
            
                auto x = Eof;
                if (wait (true))
                   {
                   x = native.receive (dst);
                   if (x <= 0)
                       x = Eof;
                   }
                return x;                        
        }
        
        /***********************************************************************

        ***********************************************************************/

        override size_t write (const(void)[] src)
        {
                version (TangoRuntime)
                    if (scheduler)
                        return asyncWrite (src);

                auto x = Eof;
                if (wait (false))
                   {
                   x = native.send (src);
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
                
                version (TangoRuntime)
                {
                    if (scheduler && x){
                        asyncCopy (x.fileHandle);
                        return this;
                    }
                }
                
                super.copy (src, max);
                return this;
        }

        /***********************************************************************
 
                Manage socket IO under a timeout

        ***********************************************************************/

        package final bool wait (bool reading)
        {
                // did user enable timeout checks?
                if (timeout != -1)
                   {
                   SocketSet read, write;

                   // yes, ensure we have a SocketSet
                   if (pending is null)
                       pending = new SocketSet (1);
                   pending.reset().add (native.sock);

                   // wait until IO is available, or a timeout occurs
                   if (reading)
                       read = pending;
                   else
                      write = pending;
                   int i = pending.select (read, write, null, timeout * 1000);
                   if (i <= 0)
                      {
                      if (i is 0)
                          super.error ("Socket :: request timeout");
                      return false;
                      }
                   }       
                return true;
        }

        /***********************************************************************

                Throw an IOException noting the last error
        
        ***********************************************************************/

        final void error ()
        {
                super.error (this.toString() ~ " :: " ~ SysError.lastMsg);
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
                        version(TangoRuntime)
                           wait (scheduler.Type.Connect);
                        patch (handle, SO_UPDATE_CONNECT_CONTEXT);
                }
        
                /***************************************************************
        
                ***************************************************************/
        
                private void asyncCopy (Handle handle)
                {
                        TransmitFile (berkeley.sock, cast(HANDLE) handle, 
                                      0, 0, &overlapped, null, 0);
                        version(TangoRuntime)
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
                        version(TangoRuntime)
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

                private size_t asyncWrite (const(void)[] src)
                {
                        DWORD bytes;
                        WSABUF buf = {src.length, cast(void*)src.ptr};

                        WSASend (cast(HANDLE) berkeley.sock, &buf, 1, &bytes, 0, &overlapped, null);
                        version(TangoRuntime)
                        if ((bytes = wait (scheduler.Type.Write, bytes)) is Eof)
                             return Eof;
                        return bytes;
                }

                /***************************************************************

                ***************************************************************/

                version(TangoRuntime)
                {
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

                                       auto handle = fileHandle;
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

                private size_t asyncWrite (const(void)[] src)
                {
                        assert (false);
                }
        }
}



/*******************************************************************************


*******************************************************************************/

class ServerSocket : Socket
{      
        /***********************************************************************

        ***********************************************************************/

        this (uint port, int backlog=32, bool reuse=false)
        {
                scope addr = new IPv4Address (cast(ushort) port);
                this (addr, backlog, reuse);
        }

        /***********************************************************************

        ***********************************************************************/

        this (Address addr, int backlog=32, bool reuse=false)
        {
                super (addr);
                berkeley.addressReuse(reuse).bind(addr).listen(backlog);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override string toString()
        {
                return "<accept>";
        }

        /***********************************************************************

        ***********************************************************************/

        Socket accept (Socket recipient = null)
        {
                if (recipient is null)
                    recipient = new Socket;
                    
                version (TangoRuntime)
                {
                    if (scheduler)
                        asyncAccept(recipient);
                    else
                        berkeley.accept(recipient.berkeley);
                }
                else
                    berkeley.accept(recipient.berkeley);
                
                recipient.timeout = timeout;
                return recipient;
        }

        /***********************************************************************

        ***********************************************************************/

        version (Windows)
        {
                /***************************************************************

                ***************************************************************/

                private void asyncAccept (Socket recipient)
                {
                        byte[128]      tmp;
                        DWORD          bytes;
                        DWORD          flags;

                        auto target = recipient.berkeley.sock;
                        AcceptEx (berkeley.sock, target, tmp.ptr, 0, 64, 64, &bytes, &overlapped);
                        version(TangoRuntime)
                           wait (scheduler.Type.Accept);
                        patch (target, SO_UPDATE_ACCEPT_CONTEXT, &berkeley.sock);
                }
        }

        /***********************************************************************

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                ***************************************************************/

                private void asyncAccept (Socket recipient)
                {
                        assert (false);
                }
        }
}


/*******************************************************************************

        copyright:      Copyright (c) 2009 Tango. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Nov 2009: Initial release
        author:         Lukas Pinkowski, Kris

*******************************************************************************/

module tango.net.LocalServer;

private import  core.exception,
                core.sys.posix.unistd,
                core.sys.posix.sys.socket;
       
private import  tango.net.Server,
                tango.net.Socket,
                tango.net.LocalSocket,
                tango.net.LocalAddress;


class LocalServer : Server
{
    private socket_t        sock;       // native socket
    
    /**
     * Construct an new LocalServer for listening on unix domain path
     * 
     * params:
     *  path = the path where to listen, example /var/run/test.sock
     *  backlog = number of maximal concurrant waiting connection
     */
    this (const(char)[] path, int backlog=32)
    {
        // ditto
        this(new LocalAddress(path), backlog);
    }
    
    /**
     * Constructs a new LocalServer by specifing a LocalAddress structure
     * 
     * params:
     *  address = the address structure usually created by tango.net.LocalAddress or null if it should not listen
     *  backlog = number of maximal concurrant waiting connection
     */
    this (Address address = null, int backlog=32)
    {
        // aquire a new socket
        this.reopen();
        
        // call bind if an address was submitted
        if(address)
        {
            this.bind(address);
            this.listen(backlog);
        }
    }
    
    /**
     * dtor
     */
    ~this()
    {
        // detch before getting destroyed
        this.detach();
    }

    /**
     * fileHandle returns the internal file handle
     */
    Handle handle()
    {
        return cast(Handle)this.sock;
    }
    
    /**
     * Bind the LocalServer to a specific path to wait for new incoming connections
     * 
     * Params:
     *  address = an address structure usually created from tango.net.LocalAddress
     * 
     * ---
     * private import tango.net.LocalAddress;
     * 
     * bind(new LocalAddress("/var/run/myapp/mysock.sock"));
     * ---
     * 
     */
    public override void bind(Address address)
    {
        // check if correct address struct
        if(address.addressFamily != AddressFamily.UNIX)
            throw new LocalServerException("Address structure must be AddressFamily.UNIX");
        
        // bind socket to address
        if(.bind(this.sock, address.name, address.nameLen) == -1)
            throw new LocalServerException("Unable to bind socket: ");
    }
    
    /**
     * Set this server into listenmode. This is typically called after bind(). 
     * 
     * Params:
     *  backlog = amount of how many clients can be in the wait queue before getting accepted. default: 32
     */
    public override void listen(uint backlog = 32)
    {
        // set into listen mode
        if(.listen(this.sock, backlog) == -1)
            throw new LocalServerException("Unable to listen on socket: ");
    }
    
    /**
     * Accept will return a new LocalSocket handle
     * 
     * recipient =  if not null, this class will be filled with the new client
     *              otherwise create a new LocalSocket.
     */
    public override LocalSocket accept(Socket recipient = null)
    {
        // accept new socket
        socket_t newsock = cast(socket_t).accept(this.sock, null, null);
        
        // failed!
        if(newsock == -1)
            return null;
        
        // create localsocket 
        if(recipient is null)
            recipient = new LocalSocket();
        
        // set native socket
        recipient.native(newsock, SocketState.Connected);
        
        // return it
        return cast(LocalSocket)recipient;
    }
    
    /**
     * detach, will close the socket and release all ressources
     */
    public void detach()
    {
        // only close if opened
        if (this.sock != this.sock.init)
            .close(this.sock);
            
        // set to original state
        this.sock = this.sock.init;
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
            sock = cast(socket_t).socket(AddressFamily.UNIX, SocketType.STREAM, 0);
            if (sock == -1)
                throw new LocalServerException("Unable to create socket: ");
        }
        
        this.sock = sock;
    }
};

/**
* Throws an exception for the local server
*/
class LocalServerException : SocketException
{
    /**
     * Standard constructor
     * 
     * params:
     *  msg = the error message provided with this exception
     *  file = the file where this exception was thrown
     *  line = the line where it was thrown
     */
    this(immutable(char)[] msg, immutable(char)[] file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

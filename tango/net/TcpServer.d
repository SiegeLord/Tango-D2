/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2011
        author:         Kris, Chrono

*******************************************************************************/

module tango.net.TcpServer;

private import  core.exception,
                core.sys.posix.unistd,
                core.sys.posix.sys.socket;
                
private import  tango.net.Server,
                tango.net.InternetAddress,
                tango.net.TcpSocket,
                tango.net.Address;

/**
 * The TcpServer provides the functionality to listen on a specific port and address
 * for incoming connections.
 * 
 * ---
 * // Blocking example
 * TcpServer server = new TcpServer("localhost", 13131);
 * TcpSocket client = server.accept();
 * ---
 * 
 * There is an example by using SocketSet which is more recommended if you use
 * multiple Sockets.
 * 
 * ---
 * private import tango.net.SocketSet,
 *                tango.net.TcpSocket,
 *                tango.net.TcpServer;
 * 
 * TcpServer        server = new TcpServer();                               // create a server instance
 * InternetAddress address = new InternetAddress("localhost", 13131);       // create an address structure
 * SocketSet           set = SocketSet(64);                                 // 64 is the maximal amount of sockets
 * 
 * server.bind(server);
 * server.listen();
 * set.add(server);
 * 
 * for(;;)
 * {
 *      // wait until something happend
 *      int events = Socket.select(set, null, null, -1);
 * 
 *      // debug printf
 *      Stdout.formatln("Hey, there are {0} events waiting.", events);
 * 
 * }
 * 
 * server.detach();
 * ---
 * 
 */
class TcpServer : Server
{
    private socket_t        sock;       // native socket
    
    /**
     * Listens on a specific port.
     * 
     * params:
     *  port = the port where to listen. Example: 13131
     *  backlog = how many waiting sockets are allowed. See TcpServer.listen();
     */
    public this(ushort port, uint backlog = 32)
    {
        // ditto
        this(new InternetAddress(port), backlog);
    }
    
    /**
     * Listens on a specific address and port
     * 
     * params:
     *  addr = the address or name to listen on. (localhost)
     *  port = the port to listen on. (13131)
     *  backlog = how many waiting sockets are allowed. See TcpServer.listen();
     */
    public this(const(char)[] addr, ushort port, uint backlog = 32)
    {
        // ditto
        this(new InternetAddress(addr, port), backlog);
    }
    
    /**
     * Default constructor, if addr is null, this socket doesn't bind. You need to bind it later
     * 
     * params:
     *  address = address structure creates from tango.net.InternetAddress
     *  backlog = how many waiting sockets are allowed. See TcpServer.listen();
     */
    public this(Address address = null, uint backlog = 32)
    {
        // aquire a new socket
        this.reopen();
        
        // call bind and listen if an address was given
        if(address) {
            this.bind(address);
            this.listen(backlog);
        }
    }
    
    /**
     * dtor
     */
    ~this()
    {
        // clean up before destroy
        this.detach();
    }
    
    /**
     * The accept function accepts a new socket. It might block until someone has connected
     * 
     * params:
     *  recipient = an existing TcpSocket. If null, it's going to be created.
     * 
     * returns:
     *  the new accepted TcpSocket or null, if timeout or an error occured.
     */
    public TcpSocket accept(TcpSocket recipient = null)
    {
        // accept new socket
        socket_t newsock = cast(socket_t).accept(this.sock, null, null);
        
        // failed!
        if(newsock == -1)
            return null;
        
        // create tcpsocket
        if(recipient is null)
            recipient = new TcpSocket();
        
        // set native socket
        recipient.native(newsock, SocketState.Connected);
        
        // return it
        return recipient;
    }

    /**
     * fileHandle returns the internal file handle which is associated with the server
     */
    public Handle handle()
    {
        return cast(Handle)this.sock;
    }
    
    /**
     * Bind this TcpServer. This will be used typically before it's going into listening mode (for a server or multicast socket).
     * The address given should describe a tcp adapter, or specify the port alone (ADDR_ANY) to have the OS assign
     * a local adapter address.
     * 
     * Params:
     *  address = InternetAddress structure to listen on
     * 
     * ---
     * private import tango.net.InternetAddress;
     * 
     * bind(new InternetAddress("192.168.0.1", 8080));    // addr and port
     * bind(new InternetAddress(8080));                   // port only
     * bind(new InternetAddress("localhost", 8080));      // hostname and port
     * ---
     */
    public override void bind(Address address)
    {
        // check if correct address struct
        if(address.addressFamily != AddressFamily.INET && address.addressFamily !=  AddressFamily.INET6)
            throw new TcpServerException("Address structure must be AddressFamily.INET or AddressFamily.INET6");
        
        // bind socket to address
        if(.bind(this.sock, address.name, address.nameLen) == -1)
            throw new TcpServerException("Unable to bind socket: ");
    }
    
    /**
     * Set this TcpServer into listen mode. You should typically call bind before you call listen
     * 
     * Params:
     *  backlog = amount of how many clients can be in the wait queue before getting accepted. default: 32
     */
    public override void listen(uint backlog = 32)
    {
        // set into listen mode
        if(.listen(this.sock, backlog) == -1)
            throw new TcpServerException("Unable to listen on socket: ");
    }
    
    /**
     * detach, will close the tcp socket and release all ressources
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
            sock = cast(socket_t).socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
            if (sock == -1)
                throw new TcpServerException("Unable to create socket: ");
        }
        
        this.sock = sock;
    }
};

/**
* Throws an exception for the tcp server. You should try to catch this exception if you're
* working with tango.net.TcpServer.
*/
class TcpServerException : SocketException
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

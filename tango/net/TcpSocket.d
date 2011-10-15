/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2011
        author:         Kris, Tim

*******************************************************************************/
module tango.net.TcpSocket;

public import tango.net.Socket;
public import tango.net.InternetAddress;

class TcpSocket : Socket
{
    /**
     * Constructor that directly trys to establish a connection
     * 
     * params:
     *  addr = the address or hostname
     *  port = the port number
     */
    public this(const(char)[] addr, ushort port = InternetAddress.PORT_ANY)
    {
        // ditto
        this(new InternetAddress(addr, port));
    }
    
    /**
     * Default constructor, if addr is null, this socket doesn't connect
     *
     * params:
     *  addr = an adress structure usually created from tango.net.InternetAddress
     */
    public this(Address addr = null)
    {
        // family, type, protocol
        super((addr ? addr.addressFamily() : AddressFamily.INET), SocketType.STREAM, ProtocolType.TCP);
        
        // connect
        if(addr !is null) {
            super.connect(addr);
        }
    }
    
    /**
     * construct a socket by an existing socket_t
     * 
     * params:
     *  sock = a native socket_t socket.
     */
    this(socket_t sock)
    {
        super(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP, sock);
    }

    /**
     * connect function with addr and host
     */
    public Socket connect(const(char)[] addr, ushort port = InternetAddress.PORT_ANY)
    {
        return super.connect(new InternetAddress(addr, port));
    }
    
    /**
     * connect with an address
     */
    public override Socket connect(Address address)
    {
        return super.connect(address);
    }
};

/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2011
        author:         Kris, Tim

*******************************************************************************/
module tango.net.LocalSocket;

public import tango.net.Socket;
public import tango.net.LocalAddress;


/*******************************************************************************
    Not available on Windows
*******************************************************************************/
version (Windows)
{
        pragma(msg, "not yet available for windows");
}

/*******************************************************************************

        A wrapper around the Berkeley API to implement the IConduit 
        abstraction and add stream-specific functionality.

*******************************************************************************/
class LocalSocket : Socket
{
    /**
     * Create a streaming local socket
     * 
     * params:
     *  path = a path to which this socket auto connects
     */
    this (const(char)[] path)
    {
            // dito
            this(new LocalAddress(path));
    }
    
    /**
     * Create a streaming local socket
     */
    this (Address addr = null)
    {
            super(AddressFamily.UNIX, SocketType.STREAM, ProtocolType.NONE);
            
            // only connect if not null
            if(addr !is null)
                super.connect(addr);
    }
    
    /**
     * construct a socket by an existing socket_t
     * 
     * params:
     *  sock = a native socket_t socket.
     */
    this(socket_t sock)
    {
        super(AddressFamily.UNIX, SocketType.STREAM, ProtocolType.NONE, sock);
    }

    /**
     * connect function with addr and host
     */
    public void connect(const(char)[] path)
    {
        return super.connect(new LocalAddress(path));
    }
};

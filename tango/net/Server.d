/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2011
        author:         Kris, Chrono

*******************************************************************************/

module tango.net.Server;

private import  tango.io.device.Device,
                tango.io.model.ISelectable;

private import  tango.net.Address,
                tango.net.Socket;

/**
 * The tango server module is an abstract class and the parent of TcpServer,
 * UdpServer and LocalServer.
 * 
 * If you are wish to operate on the network you'll basically have to choose
 * between Tcp, Udp or Unix Local Domain and use one of the subclasses that
 * were mentioned above.
 * 
 * If you're a developer you could also implement this Server class which allows
 * you to provide additional Servers for tango.
 * 
 * ---
 * private import   tango.net.Socket,
 *                  tango.net.Server,
 *                  tango.net.TcpServer,
 *                  tango.net.UdpServer,
 *                  tango.net.LocalServer,
 *                  tango.net.SocketSet;
 * 
 * // create server array
 * Servers servers[4];
 * servers[0] = TcpServer(8080);                    // listens on tcp port 8080 on every interface
 * servers[1] = TcpServer("127.0.0.1", 8081);       // listens on 127.0.0.1:8081
 * servers[2] = LocalServer("/var/run/foo.sock");   // listens on /var/run/foo.sock (works only on unix)
 * servers[3] = UdpServer(31245);                   // listens on udp port 31245 on every interface
 * 
 * // create socketset and add all servers
 * SocketSet socketset = new SocketSet(64);
 * foreach(server; servers)
 *      socketset.add(server);
 * 
 * // observate all servers
 * Socket.select(socketset, null, null);
 * 
 * // iterate all servers
 * foreach(server; servers)
 * {
 *     // is there an event for it?
 *     if(socketset.isSet(server))
 *          // okay, accept a new client
 *          Socket socket = server.accept();
 * }
 * ---
 *
 */
abstract class Server : ISelectable
{
    /**
     * bind your server to a specific address
     * 
     * params:
     *  address = instance of LocalAddress, InternetAddress or Internet6Address
     */
    public abstract void bind(Address address);
   
   /**
    * starts listening
    *  
    * params:
    *   backlog = number of maximal concurrent waiting clients
    */
    public abstract void listen(uint backlog = 32);
}

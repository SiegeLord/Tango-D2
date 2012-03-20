/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004 : Initial release 
        version:        Dec 2006 : South pacific version
        
        author:         Kris

*******************************************************************************/

module tango.net.device.Multicast;

public  import  tango.net.InternetAddress;
public  import  tango.net.device.Datagram;
private import  tango.net.device.Berkeley;

/******************************************************************************
        
        MulticastConduit sends and receives data on a multicast group, as
        described by a class-D address. To send data, the recipient group
        should be handed to the write() method. To receive, the socket is
        bound to an available local adapter/port as a listener and must
        join() the group before it becomes eligible for input from there. 

        While MulticastConduit is a flavour of datagram, it doesn't support
        being connected to a specific endpoint.

        Sending and receiving via a multicast group:
        ---
        auto group = new InternetAddress ("225.0.0.10", 8080);

        // listen for datagrams on the group address (via port 8080)
        auto multi = new MulticastConduit (group);

        // join and broadcast to the group
        multi.join.write ("hello", group);

        // we are listening also ...
        char[8] tmp;
        auto bytes = multi.read (tmp);
        ---

        Note that this example is expecting to receive its own broadcast;
        thus it may be necessary to enable loopback operation (see below)
        for successful receipt of the broadcast.

        Note that class D addresses range from 225.0.0.0 to 239.255.255.255

        see: http://www.kohala.com/start/mcast.api.txt
                
*******************************************************************************/

class Multicast : Datagram
{
        private InternetAddress group;

        enum {Host=0, Subnet=1, Site=32, Region=64, Continent=128, Unrestricted=255}

        /***********************************************************************
        
                Create a writable multicast socket

        ***********************************************************************/

        this ()
        {
                super ();
        }

        /***********************************************************************
        
                Create a read/write multicast socket

                This flavour is necessary only for a multicast receiver
                (e.g. use this ctor in conjunction with SocketListener).

                You should specify both a group address and a port to 
                listen upon. The resultant socket will be bound to the
                specified port (locally), and listening on the class-D
                address. Expect this to fail without a network adapter
                present, as bind() will not find anything to work with.

                The reuse parameter dictates how to behave when the port
                is already in use. Default behaviour is to throw an IO
                exception, and the alternate is to force usage.
                
                To become eligible for incoming group datagrams, you must
                also invoke the join() method

        ***********************************************************************/

        this (InternetAddress group, bool reuse = false)
        {
                super ();

                this.group = group;
                /* Posix also seems to require to bind to the specific group, while
                 * Windows does not allow binding to multicast groups. The most
                 * portable way seems to always bind for posix, but not for other
                 * systems.
                 * Reference; http://markmail.org/thread/co53qzbsvqivqxgc
                 */
                version (Posix) {
                    native.addressReuse(reuse).bind(group);
                } else {
                    native.addressReuse(reuse).bind(new InternetAddress(group.port));
                }
        }
        
        /***********************************************************************
                
                Enable/disable the receipt of multicast packets sent
                from the same adapter. The default state is OS specific

        ***********************************************************************/

        Multicast loopback (bool yes = true)
        {
                uint[1] onoff = yes;
                native.setOption (SocketOptionLevel.IP, SocketOption.MULTICAST_LOOP, onoff);
                return this;
        }

        /***********************************************************************
                
                Set the number of hops (time to live) of this socket. 
                Convenient values are
                ---
                Host:           packets are restricted to the same host
                Subnet:         packets are restricted to the same subnet
                Site:           packets are restricted to the same site
                Region:         packets are restricted to the same region
                Continent:      packets are restricted to the same continent
                Unrestricted:   packets are unrestricted in scope
                ---

        ***********************************************************************/

        Multicast ttl (uint value=Subnet)
        {
                uint[1] options = value;
                native.setOption (SocketOptionLevel.IP, SocketOption.MULTICAST_TTL, options);
                return this;
        }

        /***********************************************************************

                Add this socket to the listening group 

        ***********************************************************************/

        Multicast join ()
        {
                native.joinGroup (group, true);
                return this;
        }

        /***********************************************************************
        
                Remove this socket from the listening group

        ***********************************************************************/

        Multicast leave ()
        {
                native.joinGroup (group, false);
                return this;
        }
}


/******************************************************************************

*******************************************************************************/

debug (Multicast)
{
        import tango.io.Console;

        void main()
        {
                auto group = new InternetAddress ("225.0.0.10", 8080);

                // listen for datagrams on the group address
                auto multi = new Multicast (group);

                // join and broadcast to the group
                multi.join.write ("hello", group);

                // we are listening also ...
                char[8] tmp;
                auto bytes = multi.read (tmp);
                Cout (tmp[0..bytes]).newline;
        }
}

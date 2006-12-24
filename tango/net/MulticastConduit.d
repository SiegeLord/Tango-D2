/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004 : Initial release 
        version:        Dec 2006 : South pacific version
        
        author:         Kris

*******************************************************************************/

module tango.net.MulticastConduit;

private import  tango.net.DatagramConduit,
                tango.net.InternetAddress;

/******************************************************************************
        
        MulticastConduit sends and receives data on a multicast group, as
        described by a class-D address. To send data, the recipient group
        should be handed to the write() method or be provided via some
        alternate means. To receive, the socket is bound to an available
        local adapter/port as a listener and must join() the group before
        it becomes eligible for input. 

        While MulticastConduit is a flavour of datagram, it doesn't support
        being connected to a specific endpoint.

        Sending and receiving via a multicast group:
        ---
        auto group = new InternetAddress ("225.0.0.1");

        // listen for datagrams on the group address
        auto multi = new MulticastConduit (group, 8080);

        // join and broadcast to the group
        multi.join.write ("hello", group);

        // we are listening also ...
        char[8] tmp;
        auto bytes = multi.read (tmp);
        ---

        Note that this example is expecting to receive its own broadcast;
        thus it may be necessary to enable loopback operation (see below)
        for successful operation
        
*******************************************************************************/

class MulticastConduit : DatagramConduit
{
        private InternetAddress group;

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
                The 'from' address optionally exposes the address where
                incoming content originates.

                Note that the socket will be bound to the specified port, 
                and be listening on the provided class D address. Expect
                this to fail without a network adapter present, as bind()
                will not find anything to operate upon.

                You must also use join() to become eligible for incoming
                datagrams

        ***********************************************************************/

        this (InternetAddress group, ushort port, Address from = null)
        {
                this.group = group;

                if (from is null)
                    from = new IPv4Address;
                super (from);
                socket.setAddressReuse(true).bind(new InternetAddress (port));
        }
        
        /***********************************************************************
                
                Enable/disable the receipt of multicast packets sent
                from the same adapter. The default state is OS specific

        ***********************************************************************/

        MulticastConduit loopback (bool yes)
        {
                uint[1] onoff = yes;
                socket.setOption (SocketOptionLevel.IP, SocketOption.IP_MULTICAST_LOOP, onoff);
                return this;
        }

        /***********************************************************************

                Add this socket to the current group 

        ***********************************************************************/

        MulticastConduit join ()
        {
                if (group)
                    if (! socket.joinGroup (group, true))
                          exception ("Unable to join multicast group.");
                return this;
        }

        /***********************************************************************
        
                Remove this socket from the current group

        ***********************************************************************/

        MulticastConduit leave ()
        {
                if (group)
                    if (! socket.joinGroup (group, false))
                          exception ("Unable to leave multicast group.");
                return this;
        }
}



debug (Test)
{
void main()
{
        auto group = new InternetAddress ("225.0.0.10");

        // listen for datagrams on the group address
        auto multi = new MulticastConduit (group, 8080);

        // join and broadcast to the group
        multi.join.write ("hello", group);

        // we are listening also ...
        char[8] tmp;
        auto bytes = multi.read (tmp);
}
}

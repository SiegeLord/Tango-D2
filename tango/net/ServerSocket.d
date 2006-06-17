/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.ServerSocket;

public  import  tango.net.Socket;

private import  tango.net.SocketConduit;

/*******************************************************************************

        ServerSocket is a wrapper upon the basic socket functionality to
        simplify the API somewhat. You use a ServerSocket to listen for 
        inbound connection requests, and get back a SocketConduit when a
        connection is made.

*******************************************************************************/

class ServerSocket : Socket
{
        private int linger = -1;

        /***********************************************************************
        
                Construct a ServerSocket on the given address, with the
                specified number of backlog connections supported. The
                socket is bound to the given address, and set to listen
                for incoming connections. Note that the socket address 
                can be setup for reuse, so that a halted server may be 
                restarted immediately.

        ***********************************************************************/

        this (InternetAddress addr, int backlog=32, bool socketReuse=false)
        {
                super (AddressFamily.INET, Type.STREAM, Protocol.IP);
                setAddressReuse (socketReuse);
                bind (addr);
                listen (backlog);
        }

        /***********************************************************************
        
                Set the period in which dead sockets are left lying around
                by the O/S

        ***********************************************************************/

        override void setLingerPeriod (int period)
        {
                linger = period;
        }

        /***********************************************************************
        
                Wait for a client to connect to us, and return a connected
                SocketConduit.

        ***********************************************************************/

        override SocketConduit accept ()
        {
                return cast(SocketConduit) super.accept ();
        }

        /***********************************************************************
        
                Overrides the default socket behaviour to create a socket
                for an incoming connection. Here we provide a SocketConduit
                instead.

        ***********************************************************************/

        protected override Socket createSocket (socket_t handle)
        {
                auto socket = SocketConduit.create (handle);

                // force abortive closure to avoid prolonged OS scavenging?
                if (linger >= 0)
                    socket.setLingerPeriod (linger);

                return socket;
        }
}


/*******************************************************************************

        Creates a text-oriented server socket

*******************************************************************************/

class TextServerSocket : ServerSocket
{       
        /***********************************************************************
        
                Construct a ServerSocket on the given address, with the
                specified number of backlog connections supported. The
                socket is bound to the given address, and set to listen
                for incoming connections. Note that the socket address 
                can be setup for reuse, so that a halted server may be 
                restarted immediately.

        ***********************************************************************/

        this (InternetAddress addr, int backlog=32, bool socketReuse=false)
        {
                super (addr, backlog, socketReuse);
        }


        /***********************************************************************
        
                Overrides the default socket behaviour to create a socket
                for an incoming connection. Here we provide a text-based
                SocketConduit instead.

        ***********************************************************************/

        protected override Socket createSocket (socket_t handle)
        {
                auto socket = TextSocketConduit.create (handle);

                // force abortive closure to avoid prolonged OS scavenging?
                if (linger >= 0)
                    socket.setLingerPeriod (linger);

                return socket;
        }
}





/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
                        Outback release: December 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.ServerSocket;

public import tango.net.device.Socket;

public  import tango.net.InternetAddress;

pragma(msg, "revision: net.ServerSocket has been folded into net.device.Socket");

version (Old)
{
private import  tango.net.Socket,
                tango.net.SocketConduit;

private import  tango.io.model.IConduit;

public  import  tango.net.InternetAddress;

/*******************************************************************************

        ServerSocket is a wrapper upon the basic socket functionality to
        simplify the API somewhat. You use a ServerSocket to listen for 
        inbound connection requests, and get back a SocketConduit when a
        connection is made.

        Accepted SocketConduit instances are held in a free-list to help
        avoid heap activity. These instances are recycled upon invoking
        the close() method, and one should ensure that occurs

*******************************************************************************/

class ServerSocket : ISelectable
{
        private Socket   socket_;
        private float    timeout;
        private int      linger = -1;

        /***********************************************************************
        
                Construct a ServerSocket on the given address, with the
                specified number of backlog connections supported. The
                socket is bound to the given address, and set to listen
                for incoming connections. Note that the socket address 
                can be setup for reuse, so that a halted server may be 
                restarted immediately.

        ***********************************************************************/

        this (InternetAddress addr, int backlog=32, bool reuse=false)
        {
                socket_ = new Socket (AddressFamily.INET, SocketType.STREAM, ProtocolType.IP);
                socket_.setAddressReuse(reuse).bind(addr).listen(backlog);
        }

        /***********************************************************************

                Models a handle-oriented device.

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        Handle fileHandle ()
        {
                return cast(Handle) socket_.fileHandle;
        }

        /***********************************************************************
        
                Set the period in which dead sockets are left lying around
                by the O/S

        ***********************************************************************/

        ServerSocket setLingerPeriod (int period)
        {
                linger = period;
                return this;
        }

        /***********************************************************************

                Set the default read timeout to the specified interval. Set
                a value of zero to disable timeout support.

                The interval is in units of seconds, where 0.500 would
                represent 500 milliseconds. Use TimeSpan.interval to
                convert from a TimeSpan instance.

        ***********************************************************************/

        ServerSocket setTimeout (float timeout)
        {
                this.timeout = timeout;
                return this;
        }

        /***********************************************************************
        
                Return the wrapped socket

        ***********************************************************************/

        Socket socket ()
        {
                return socket_;
        }

        /***********************************************************************

                Is this server still alive?

        ***********************************************************************/

        bool isAlive ()
        {
                return socket_.isAlive;
        }

        /***********************************************************************

                Produce a SocketConduit instance. This can be overridden
                to return SocketConduit derivatives  

        ***********************************************************************/

        protected SocketConduit create ()
        {
                return SocketConduit.allocate();
        }

        /***********************************************************************
        
                Wait for a client to connect to us, and return a connected
                SocketConduit.

        ***********************************************************************/

        SocketConduit accept ()
        {
                auto wrapper = create;
                auto accepted = socket_.accept (wrapper.socket);

                // force abortive closure to avoid prolonged OS scavenging?
                if (linger >= 0)
                    accepted.setLingerPeriod (linger);

                // set default timeout for read operations on this connection
                wrapper.setTimeout (timeout);

                return wrapper;
        }
}
}

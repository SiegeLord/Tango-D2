/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004 : Initial release
        version:        Jan 2005 : RedShodan patch for timeout query
        version:        Dec 2006 : Outback release
        
        author:         Kris

*******************************************************************************/

module tango.net.SocketConduit;

public  import  tango.net.device.Socket;
public  import  tango.io.device.Conduit;

alias Socket SocketConduit;

pragma(msg, "revision: net.SocketConduit has been moved to net.device.Socket");

version (Old)
{
private import  tango.net.Socket;

/*******************************************************************************

        A wrapper around the bare Socket to implement the IConduit abstraction
        and add socket-specific functionality.

        SocketConduit data-transfer is typically performed in conjunction with
        an IBuffer, but can happily be handled directly using void array where
        preferred
        
*******************************************************************************/

class SocketConduit : Conduit, ISelectable
{
        private timeval                 tv;
        private SocketSet               ss;
        package Socket                  socket_;
        private bool                    timeout;

        // freelist support
        private SocketConduit           next;   
        private bool                    fromList;
        private static SocketConduit    freelist;

        /***********************************************************************
        
                Create a streaming Internet Socket

        ***********************************************************************/

        this ()
        {
                this (AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        }

        /***********************************************************************
        
                Create an Internet Socket with the provided characteristics

        ***********************************************************************/

        this (AddressFamily family, SocketType type, ProtocolType protocol)
        {
                this (family, type, protocol, true);
        }

        /***********************************************************************
        
                Create an Internet Socket. See method allocate() below

        ***********************************************************************/

        private this (AddressFamily family, SocketType type, ProtocolType protocol, bool create)
        {
                socket_ = new Socket (family, type, protocol, create);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString()
        {
                return socket.toString;
        }

        /***********************************************************************

                Return the socket wrapper
                
        ***********************************************************************/

        Socket socket ()
        {
                return socket_;
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        override size_t bufferSize ()
        {
                return 1024 * 8;
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

                Set the read timeout to the specified interval. Set a
                value of zero to disable timeout support.

                The interval is in units of seconds, where 0.500 would
                represent 500 milliseconds. Use TimeSpan.interval to
                convert from a TimeSpan instance.

        ***********************************************************************/

        SocketConduit setTimeout (float timeout)
        {
                tv.tv_sec = cast(uint) timeout;
                tv.tv_usec = cast(uint) ((timeout - tv.tv_sec) * 1_000_000);
                return this;
        }

        /***********************************************************************

                Did the last operation result in a timeout? 

        ***********************************************************************/

        bool hadTimeout ()
        {
                return timeout;
        }

        /***********************************************************************

                Is this socket still alive?

        ***********************************************************************/

        override bool isAlive ()
        {
                return socket_.isAlive;
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        SocketConduit connect (Address addr)
        {
                socket_.connect (addr);
                return this;
        }

        /***********************************************************************

                Bind the socket. This is typically used to configure a
                listening socket (such as a server or multicast socket).
                The address given should describe a local adapter, or
                specify the port alone (ADDR_ANY) to have the OS assign
                a local adapter address.
        
        ***********************************************************************/

        SocketConduit bind (Address address)
        {
                socket_.bind (address);
                return this;
        }

        /***********************************************************************

                Inform other end of a connected socket that we're no longer
                available. In general, this should be invoked before close()
                is invoked
        
                The shutdown function shuts down the connection of the socket: 

                    -   stops receiving data for this socket. If further data 
                        arrives, it is rejected.

                    -   stops trying to transmit data from this socket. Also
                        discards any data waiting to be sent. Stop looking for 
                        acknowledgement of data already sent; don't retransmit 
                        if any data is lost.

        ***********************************************************************/

        SocketConduit shutdown ()
        {
                socket_.shutdown (SocketShutdown.BOTH);
                return this;
        }

        /***********************************************************************

                Release this SocketConduit

                Note that one should always disconnect a SocketConduit 
                under normal conditions, and generally invoke shutdown 
                on all connected sockets beforehand

        ***********************************************************************/

        override void detach ()
        {
                socket_.detach;

                // deallocate if this came from the free-list,
                // otherwise just wait for the GC to handle it
                if (fromList)
                    deallocate (this);
        }

       /***********************************************************************

                Read content from the socket. Note that the operation 
                may timeout if method setTimeout() has been invoked with 
                a non-zero value.

                Returns the number of bytes read from the socket, or
                IConduit.Eof where there's no more content available.

                If the underlying socket is a blocking socket, Eof will 
                only be returned once the socket has closed.

                Note that a timeout is equivalent to Eof. Isolating
                a timeout condition can be achieved via hadTimeout()

                Note also that a zero return value is not legitimate;
                such a value indicates Eof

        ***********************************************************************/

        override size_t read (void[] dst)
        {
                return read (dst, (void[] dst){return cast(size_t) socket_.receive(dst);});
        }
        
        /***********************************************************************

                Callback routine to write the provided content to the
                socket. This will stall until the socket responds in
                some manner. Returns the number of bytes sent to the
                output, or IConduit.Eof if the socket cannot write.

        ***********************************************************************/

        override size_t write (void[] src)
        {
                int count = socket_.send (src);
                if (count <= 0)
                    count = Eof;
                return count;
        }

        /***********************************************************************
 
                Internal routine to handle socket read under a timeout.
                Note that this is synchronized, in order to serialize
                socket access

        ***********************************************************************/

        package final synchronized size_t read (void[] dst, size_t delegate(void[]) dg)
        {
                // reset timeout; we assume there's no thread contention
                timeout = false;

                // did user disable timeout checks?
                if (tv.tv_usec | tv.tv_sec)
                   {
                   // nope: ensure we have a SocketSet
                   if (ss is null)
                       ss = new SocketSet (1);

                   ss.reset ();
                   ss.add (socket_);

                   // wait until data is available, or a timeout occurs
                   auto copy = tv;
version (linux)
{
                   // disable blocking to deal with potential linux bug
                   auto b = socket.blocking;
                   if (b)
                       socket.blocking (false);
                   int i = socket_.select (ss, null, null, &copy);
                   if (b)
                       socket.blocking (true);                
}
else
                   int i = socket_.select (ss, null, null, &copy);
                   if (i <= 0)
                      {
                      if (i is 0)
                          timeout = true;
                      return Eof;
                      }
                   }       

                // invoke the actual read op
                auto count = dg (dst);
                if (count <= 0)
                    count = Eof;
                return count;
        }
        
        /***********************************************************************

                Allocate a SocketConduit from a list rather than creating
                a new one. Note that the socket itself is not opened; only
                the wrappers. This is because the socket is often assigned
                directly via accept()

        ***********************************************************************/

        package static synchronized SocketConduit allocate ()
        {       
                SocketConduit s;

                if (freelist)
                   {
                   s = freelist;
                   freelist = s.next;
                   }
                else
                   {
                   s = new SocketConduit (AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP, false);
                   s.fromList = true;
                   }
                return s;
        }

        /***********************************************************************

                Return this SocketConduit to the free-list

        ***********************************************************************/

        private static synchronized void deallocate (SocketConduit s)
        {
                s.next = freelist;
                freelist = s;
        }
}

}

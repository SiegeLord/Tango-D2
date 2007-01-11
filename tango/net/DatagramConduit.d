/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004 : Initial release
        version:        Dec 2006 : South Pacific release
        
        author:         Kris

*******************************************************************************/

module tango.net.DatagramConduit;

public  import  tango.io.Conduit;

package import  tango.net.Socket,
                tango.net.SocketConduit;

/*******************************************************************************
        
        Datagrams provide a low-overhead, non-reliable data transmission
        mechanism, and are described as being connected or unconnected. The
        connected flavours are bound to a specific endpoint via connect().
        Unconnected datagrams should instead have an address provided for
        read() and write() invocations.

        Note that when used as a listener, you must first bind the socket
        to a local adapter. This can be achieved by binding the socket to
        an InternetAddress constructed with a port only (ADDR_ANY), thus
        requesting the OS to assign the address of a local adapter

*******************************************************************************/

class DatagramConduit : SocketConduit
{
        private Address                 src,
                                        dst;

        alias SocketConduit.read        read;
        alias SocketConduit.write       write;
        
        /***********************************************************************
        
                Create a writable datagram socket

        ***********************************************************************/

        this ()
        {
                super (Access.Write, SocketType.DGRAM);
        }

        /***********************************************************************
        
                Create a read/write datagram socket. The 'from' address
                exposes the endpoint where incoming content originates. If
                null, we assume the socket will be connected instead.

        ***********************************************************************/

        this (Address from)
        {
                src = from;
                super (Access.ReadWrite, SocketType.DGRAM);
        }

        /***********************************************************************
        
                Address an outgoing datagram. Use this in conjunction with
                the Conduit.write mechanics, which does not support a target
                address as an argument. Ignore this if the datagram is of the
                connected variety.
                
        ***********************************************************************/

        DatagramConduit to (Address to)
        {
                dst = to;
                return this;
        }

        /***********************************************************************
        
                Read the available bytes from datagram into the given array.
                When provided, the 'from' address will be populated with the
                origin of the incoming data. Otherwise, we assume the socket
                has been connected instead.

                Returns the number of bytes read from the input, or Eof if
                the socket cannot read

        ***********************************************************************/

        uint read (void[] dst, Address from)
        {
                int count;

                if (dst.length)
                   {
                   count = (from) ? socket.receiveFrom (dst, from) : socket.receiveFrom (dst);
                   if (count <= 0)
                       count = Eof;
                   }
                return count;
        }

        /***********************************************************************
        
                Write an array to the specified address. If address 'to' is
                null, it is assumed the socket has been connected instead.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        uint write (void[] src, Address to)
        {
                int count;
                
                if (src.length)
                   {
                   count = (to) ? socket.sendTo (src, to) : socket.sendTo (src);
                   if (count <= 0)
                       count = Eof;
                   }
                return count;
        }

        /***********************************************************************

                SocketConduit override:
                
                Read available datagram bytes into a provided array. Returns
                the number of bytes read from the input, or Eof if the socket
                cannot read.

                Note that we're taking advantage of timout support within the
                superclass 

        ***********************************************************************/

        protected override uint socketReader (void[] dst)
        {
                return read (dst, src);
        }

        /***********************************************************************

                SocketConduit override:

                Write the provided content to the socket. This will stall
                until the socket responds in some manner. If there is no
                target address held by this class, we assume the datagram
                has been connected instead.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        protected override uint writer (void[] src)
        {
                return write (src, dst);
        }
}


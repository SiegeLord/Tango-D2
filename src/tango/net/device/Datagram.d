/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004 : Initial release
        version:        Dec 2006 : South Pacific release
        
        author:         Kris

*******************************************************************************/

module tango.net.device.Datagram;

package import tango.net.device.Socket;

/*******************************************************************************
        
        Datagrams provide a low-overhead, non-reliable data transmission
        mechanism.

        Datagrams are not 'connected' in the same manner as a TCP socket; you
        don't need to listen() or accept() to receive a datagram, and data
        may arrive from multiple sources. A datagram socket may, however,
        still use the connect() method like a TCP socket. When connected,
        the read() and write() methods will be restricted to a single address
        rather than being open instead. That is, applying connect() will make
        the address argument to both read() and write() irrelevant. Without
        connect(), method write() must be supplied with an address and method
        read() should be supplied with one to identify where data originated.
        
        Note that when used as a listener, you must first bind the socket
        to a local adapter. This can be achieved by binding the socket to
        an InternetAddress constructed with a port only (ADDR_ANY), thus
        requesting the OS to assign the address of a local network adapter

*******************************************************************************/

class Datagram : Socket
{
        /***********************************************************************
        
                Create a read/write datagram socket

        ***********************************************************************/

        this ()
        {
                super (AddressFamily.INET, SocketType.DGRAM, ProtocolType.IP);
        }

        /***********************************************************************

                Populate the provided array from the socket. This will stall
                until some data is available, or a timeout occurs. We assume 
                the datagram has been connected.

                Returns the number of bytes read to the output, or Eof if
                the socket cannot read

        ***********************************************************************/

        override size_t read (void[] src)
        {
                return read (src, null);
        }

        /***********************************************************************
        
                Read bytes from an available datagram into the given array.
                When provided, the 'from' address will be populated with the
                origin of the incoming data. Note that we employ the timeout
                mechanics exposed via our Socket superclass. 

                Returns the number of bytes read from the input, or Eof if
                the socket cannot read

        ***********************************************************************/

        size_t read (void[] dst, Address from)
        {
                size_t count;

                if (dst.length)
                   {
                   count = (from ? native.receiveFrom(dst, from) : native.receiveFrom(dst));
                   if (count <= 0)
                       count = Eof;
                   }

                return count;
        }

        /***********************************************************************

                Write the provided content to the socket. This will stall
                until the socket responds in some manner. We assume the 
                datagram has been connected.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        override size_t write (void[] src)
        {
                return write (src, null);
        }

        /***********************************************************************
        
                Write an array to the specified address. If address 'to' is
                null, it is assumed the socket has been connected instead.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        size_t write (void[] src, Address to)
        {
                int count = Eof;
                
                if (src.length)
                   {
                   count = (to) ? native.sendTo(src, to) : native.sendTo(src);
                   if (count <= 0)
                       count = Eof;
                   }
                return count;
        }
}



/******************************************************************************

*******************************************************************************/

debug (Datagram)
{
        import tango.io.Console;

        import tango.net.InternetAddress;

        void main()
        {
                auto addr = new InternetAddress ("127.0.0.1", 8080);

                // listen for datagrams on the local address
                auto gram = new Datagram;
                gram.bind (addr);

                // write to the local address
                gram.write ("hello", addr);

                // we are listening also ...
                char[8] tmp;
                auto x = new InternetAddress;
                auto bytes = gram.read (tmp, x);
                Cout (x) (tmp[0..bytes]).newline;
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.DatagramSocket;

private import  tango.net.Socket,
                tango.io.Exception;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

/*******************************************************************************
        
        Wrapper around datagram style of sockets, to simplify the API a
        bit, and to tie them into the IBuffer construct.

        Note that when used with a SocketListener you must first bind the
        DatagramSocket to a local adapter. This can be done by binding it
        to an InternetAddress constructed with a port only (ADDR_ANY).

*******************************************************************************/

class DatagramSocket : Socket, ISocketReader
{
        /***********************************************************************
        
                Create an internet datagram socket

        ***********************************************************************/

        this ()
        {
                super (AddressFamily.INET, Type.DGRAM, Protocol.IP);                
        }

        /***********************************************************************
        
                Read the available bytes from datagram into the given IBuffer.
                The 'from' address will be populated appropriately

        ***********************************************************************/

        uint read (IBuffer target, inout Address addr)
        in {
           assert (target);
           }
        body
        {
                uint reader (void[] src)
                {
                        int count = receiveFrom (src, addr);
                        if (count <= 0)
                            count = IConduit.Eof;
                        return count;
                }

                return target.write (&reader);
        }

        /***********************************************************************
        
                Read the available bytes from datagram into the given IBuffer.
                The 'from' address will be populated appropriately

        ***********************************************************************/

        uint read (IBuffer target)
        {
                Address addr;

                return read (target, addr);
        }

        /***********************************************************************
        
                Is this socket still valid?

        ***********************************************************************/

        bool isAlive ()
        {
                return super.isAlive();
        }

        /***********************************************************************
       
                Write content from the specified buffer to the given address.
         
        ***********************************************************************/

        uint write (IBuffer source, Address to)
        in {
           assert (to);
           assert (source);
           }
        body
        {
                uint writer (void[] src)
                {
                        int count = sendTo (src, Flags.NONE, to);
                        if (count <= 0)
                            count = IConduit.Eof;
                        return count;
                }

                int count = source.read (&writer);

                // if we didn't write everything, move remaining content
                // to front of buffer for a subsequent write
                source.compress();
                return count;
        }

        /***********************************************************************
       
                create a new socket for binding during another join(), since
                there doesn't appear to be a means of unbinding
         
        ***********************************************************************/

        protected override void create ()
        {
                super.create (AddressFamily.INET, Type.DGRAM, Protocol.IP);                
        }
}


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.MulticastSocket;

private import  tango.io.Buffer,
                tango.io.Exception;
              
private import  tango.net.InternetAddress,
                tango.net.DatagramSocket;

/******************************************************************************
        
        Wrapper around multicast style of sockets, to simplify the API a
        bit, and to tie them into the IBuffer construct. Note that when used 
        with a SocketListener you must first join the MulticastSocket to a 
        group. Do not bind() it yourself, since that is performed by the 
        join() method.

*******************************************************************************/

class MulticastSocket : DatagramSocket
{
        private InternetAddress groupAddress;

        /***********************************************************************
                
                Enable/disable the receipt of multicast packets send 
                from the same socket

        ***********************************************************************/

        void setLoopback (bool loopback)
        {
                uint[1] onoff = loopback;
                setOption (OptionLevel.IP, Option.IP_MULTICAST_LOOP, onoff);
        }

        /***********************************************************************

                Join a multicast group. This is necessary only for a 
                multicast reciever (listener). You may call this for
                a send-only socket without harm, but the operation is
                completely superfluous.

                Note that the socket will be bound to the specified port, 
                and be listening on the provided class D address. Expect
                join() to fail without a network adapter present, or the
                NIC is not plugged into a router or switch.

        ***********************************************************************/

        void join (InternetAddress groupAddress)
        {
                this.groupAddress = groupAddress;

                setAddressReuse (true);
                bind (new InternetAddress(groupAddress.port()));
                resumeGroup ();
        }

        /***********************************************************************
        
                Remove this socket from the current group. Method join()
                is expected to have been invoked previously, otherwise 
                this is a noop.

        ***********************************************************************/

        void pauseGroup ()
        {
                if (groupAddress)
                    if (! setGroup (groupAddress, Option.IP_DROP_MEMBERSHIP))
                          exception ("Unable to leave multicast group.");
        }

        /***********************************************************************

                Add this socket to the current group again. Method join()
                is expected to have been invoked previously, otherwise 
                this is a noop.

        ***********************************************************************/

        void resumeGroup ()
        {
                if (groupAddress)
                    if (! setGroup (groupAddress, Option.IP_ADD_MEMBERSHIP))
                          exception ("Unable to join multicast group.");
        }

        /***********************************************************************
        
                Leave a multicast group. This should only be invoked on
                sockets that have already joined a multicast group, and
                before said socket joins another group. 

                There does not appear to be a means to unbind the socket
                from the port specified during the original join(); thus
                we have to create a new underlying socket before join()
                will bind() cleanly.

        ***********************************************************************/

        void leave ()
        {
                if (groupAddress)
                   {
                   pauseGroup ();
                   groupAddress = null;

                   reopen();
                   }
        }
}

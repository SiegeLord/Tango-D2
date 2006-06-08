/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: March 2004      
        version:        Jan 1st 2005 - Added RedShodan patch for timeout query
        
        author:         Kris

*******************************************************************************/

module tango.net.SocketConduit;

public  import  tango.net.Socket;

private import  tango.io.Buffer;


/*******************************************************************************

        A wrapper around the bare Socket to implement the IConduit abstraction
        and add socket-specific functionality. SocketConduit data-transfer is 
        typically performed in conjunction with an IBuffer instance, but can 
        be handled directly using raw arrays if preferred. See FileConduit for 
        examples of both approaches.

*******************************************************************************/

class SocketConduit : Socket, ISocketReader
{       
        // expose Conduit read()
        alias Socket.read               read;

        // freelist support
        private SocketConduit           next;   
        private bool                    fromList;
        private static SocketConduit    freelist;

        /***********************************************************************
        
                Create a streaming Internet Socket

        ***********************************************************************/

        this ()
        {
                super (AddressFamily.INET, Type.STREAM, Protocol.IP);                
        }

        /***********************************************************************

                Override closure() to deallocate this SocketConduit 
                when it has been closed. Note that one should *not* 
                delete a SocketConduit when FreeList is enabled ...

        ***********************************************************************/

        override void close ()
        {       
                // be a nice client, and tell the server?
                //super.shutdown();

                // do this first cos' we're gonna' reset the
                // socket handle during deallocate()
                super.close ();


                // deallocate if this came from the free-list,
                // otherwise just wait for the GC to handle it
                if (fromList)
                    deallocate (this);
        }

        /***********************************************************************
        
                Read from conduit into a target buffer. Note that this 
                uses SocketSet to handle timeouts, such that the socket
                does not stall forever.
        
                (for the ISocketReader interface)

        ***********************************************************************/

        uint read (IBuffer target)
        {
                return target.fill (this);
        }

        /***********************************************************************

                Is this socket still alive?

        ***********************************************************************/

        bool isAlive()
        {
                return super.isAlive();
        }

        /***********************************************************************
        
                Construct this SocketConduit with the given socket handle;
                this is for FreeList and ServerSocket support.

        ***********************************************************************/

        protected static SocketConduit create (socket_t handle)
        {
                // allocate one from the free-list
                return allocate (handle);
        }

        /***********************************************************************
       
                Create a new socket for binding during another join() or
                connect(), since there doesn't appear to be another means
         
        ***********************************************************************/

        protected override void create ()
        {
                super.create (AddressFamily.INET, Type.STREAM, Protocol.IP);                
        }

        /***********************************************************************
        
                Construct this SocketConduit with the given socket handle;
                this is for FreeList and ServerSocket support.

        ***********************************************************************/

        private this (socket_t handle)
        {
                super (handle);                
        }
     
        /***********************************************************************

                Allocate a SocketConduit from a list rather than 
                creating a new one

        ***********************************************************************/

        private static synchronized SocketConduit allocate (socket_t sock)
        {       
                SocketConduit s;

                if (freelist)
                   {
                   s = freelist;
                   freelist = s.next;
                   s.set (sock);
                   }
                else
                   {
                   s = new SocketConduit (sock);
                   s.fromList = true;
                   }
                return s;
        }

        /***********************************************************************

                Return this SocketConduit to the free-list

        ***********************************************************************/

        private static synchronized void deallocate (SocketConduit s)
        {
                // socket handle is no longer valid
                s.reset ();
                s.next = freelist;
                freelist = s;
        }
}


/*******************************************************************************

        Creates a text-oriented socket

*******************************************************************************/

class TextSocketConduit : SocketConduit
{       
        this ()
        {
                super();
        }

        /***********************************************************************
        
                Returns true if this conduit is text-based

        ***********************************************************************/

        override bool isTextual ()
        {
                return true;
        }               
}




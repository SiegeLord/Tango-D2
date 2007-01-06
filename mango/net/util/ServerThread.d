/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.util.ServerThread;

private import  tango.core.Thread;

private import  tango.io.Exception;

private import  tango.net.ServerSocket;

private import  mango.net.util.AbstractServer;

private import  mango.net.util.model.IRunnable;

/******************************************************************************

        Subclasses Thread to provide the basic server-thread loop. This
        functionality could also be implemented as a delegate, however, 
        we also wish to subclass in order to add thread-local data (see
        HttpThread).

******************************************************************************/

class ServerThread : IRunnable
{
        private Thread          thread;
        private ServerSocket    socket;
        private AbstractServer  server;

        /**********************************************************************

                Construct a ServerThread for the given Server, upon the 
                specified socket
                 
        **********************************************************************/

        this (AbstractServer server, ServerSocket socket)
        {
                this.server = server;
                this.socket = socket;
                thread = new Thread (&run);
        }

        /**********************************************************************

        **********************************************************************/

        void execute ()
        {
                thread.start();
        }

        /**********************************************************************

                Execute this thread until the Server says to halt. Each
                thread waits in the socket.accept() state, waiting for
                a connection request to arrive. Upon selection, a thread
                dispatches the request via the request service-handler
                and, upon completion, enters the socket.accept() state
                once more.

        **********************************************************************/

        void run ()
        {
                while (true)
                       try {
                           // should we bail out?
                           if (isHalting)
                               return 0;

                           // wait for a socket connection
                           auto sc = socket.accept ();

                           // did we get a valid response?
                           if (sc)
                               // yep: process this request
                               server.service (this, sc);
                           else
                              // server may be halting ...
                              if (socket.getSocket.isAlive)
                                  server.getLogger.error ("Socket accept() failed");

                           } catch (IOException x)
                                   {
                                   server.getLogger.error ("IOException: "~x.toUtf8);
                                   }
                            catch (Object x)
                                   {
                                   server.getLogger.fatal ("Exception: "~x.toUtf8);
                                   }
        }
}

/******************************************************************************

        Sentinel for application halting

******************************************************************************/

private bool isHalting;

static ~this()
{
        isHalting = true;
}

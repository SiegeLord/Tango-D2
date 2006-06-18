/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpThread;

private import  tango.net.ServerSocket;

private import  mango.net.util.ServerThread,
                mango.net.util.AbstractServer;

private import  mango.net.http.server.ServiceBridge;

/******************************************************************************

        Extends the basic ServerThread to add thread-local data. All data
        maintained on a thread basis is stored via multiple ServiceBridge
        instances (one per thread).
 
******************************************************************************/

class HttpThread : ServerThread
{
        ServiceBridge bridge;

        /**********************************************************************

                Construct an HttpThread with the provided server and socket
                attributes.

        **********************************************************************/

        this (AbstractServer server, ServerSocket socket)
        {
                super (server, socket);
        }

        /**********************************************************************

                Attach an ServiceProvider/IServer bridge. This is where additional
                per-thread data is stored.

        **********************************************************************/

        void setBridge (ServiceBridge bridge)
        {
                this.bridge = bridge;
        }

        /**********************************************************************
        
                Return the bridge associated with this thread.

        **********************************************************************/

        ServiceBridge getBridge ()
        {
                return bridge;
        }       
}


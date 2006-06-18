/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.ServiceBridge;

private import  tango.io.model.IConduit;

private import  mango.net.util.model.IServer;

/******************************************************************************

        Bridges between an ServiceProvider and an IServer, and maintains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of ServiceBridge (there
        is one per server-thread).

        Any additional thread-specific data should probably be maintained
        via this interface.

******************************************************************************/

interface ServiceBridge
{
        /**********************************************************************

                Return the server from one side of this bridge

        **********************************************************************/

        IServer getServer ();

        /**********************************************************************

                Bridge the divide between IServer and ServiceProvider instances.
                Note that there is one instance of this class per thread.

        **********************************************************************/

        void cross (IConduit conduit);
}

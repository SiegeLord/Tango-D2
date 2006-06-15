/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.model.IProviderBridge;

private import  tango.io.model.IConduit;

private import  mango.net.util.model.IServer;

private import  mango.net.http.server.model.IProvider;

/******************************************************************************

        Bridges between an IProvider and an IServer, and maintains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of IProviderBridge (there
        is one per server-thread).

        Any additional thread-specific data should probably be maintained
        via this interface.

******************************************************************************/

interface IProviderBridge
{
        /**********************************************************************

                Return the server from one side of this bridge

        **********************************************************************/

        IServer getServer ();

        /**********************************************************************

                Return the provider from the other side of the bridge

        **********************************************************************/

        IProvider getProvider ();

        /**********************************************************************

                Bridge the divide between IServer and IProvider instances.
                Note that there is one instance of this class per thread.

        **********************************************************************/

        void cross (IConduit conduit);
}

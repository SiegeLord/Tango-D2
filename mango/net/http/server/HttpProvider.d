/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpProvider;

private import  mango.net.http.server.HttpRequest,
                mango.net.http.server.HttpResponse;

private import  mango.net.http.server.model.IProvider,
                mango.net.http.server.model.IProviderBridge;

/******************************************************************************

        Bridges between an IProvider and an IServer, and maintains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of IProviderBridge (there
        is one per server-thread).

        Any additional thread-specific data should probably be maintained
        via this interface.

******************************************************************************/

class HttpProvider : IProvider
{
        /**********************************************************************

                Concrete provider must provide the service handler

        **********************************************************************/

        abstract void service (HttpRequest request, HttpResponse response);

        /**********************************************************************

                IProvider interface to create a request instance

        **********************************************************************/

        HttpRequest createRequest (IProviderBridge bridge)
        {
                return new HttpRequest (bridge);
        }

        /**********************************************************************

                IProvider interface to create a response instance

        **********************************************************************/

        HttpResponse createResponse (IProviderBridge bridge)
        {
                return new HttpResponse (bridge);
        }

        /**********************************************************************

                Return the name of this provider for identification purposes.

        **********************************************************************/

        override char[] toString()
        {
                return "Naked";
        }
}


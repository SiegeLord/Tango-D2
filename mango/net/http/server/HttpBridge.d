/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpBridge;

private import  tango.net.Socket;

private import  tango.io.model.IConduit;

private import  mango.net.util.model.IServer;

private import  mango.net.http.server.HttpThread,
                mango.net.http.server.HttpRequest,
                mango.net.http.server.HttpResponse,
                mango.net.http.server.ServiceBridge,
                mango.net.http.server.ServiceProvider;

/******************************************************************************

        Bridges between an ServiceProvider and an IServer, and contains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of HttpBridge (one per 
        server-thread).

        Any additional thread-specific data should probably be contained
        within this class, since it is reachable from almost everywhere.

******************************************************************************/

class HttpBridge : ServiceBridge
{
        private IServer         server;
        private ServiceProvider provider;

        private HttpThread      thread;
        private HttpRequest     request;
        private HttpResponse    response;
        
        /**********************************************************************

                Construct a bridge with the requisite attributes. We create
                the per-thread request/response pair here, and maintain them 
                for the lifetime of the server.

        **********************************************************************/

        this (IServer server, ServiceProvider provider, HttpThread thread)
        {
                this.server = server;
                this.thread = thread;
                this.provider = provider;

                request = provider.createRequest (this);
                response = provider.createResponse (this);
        }

        /**********************************************************************

                Return the server from one side of this bridge

        **********************************************************************/

        IServer getServer()
        {
                return server;
        }

        /**********************************************************************

                Bridge the divide between IServer and ServiceProvider instances.
                Note that there is one instance of this class per thread.

                Note also that this is probably the right place to implement 
                keep-alive support if that were ever to happen, although the
                implementation should itself be in a subclass.

        **********************************************************************/

        void cross (IConduit conduit)
        {
                // bind our input & output instance to this conduit
                request.setConduit (conduit);
                response.setConduit (conduit);

                // close and destroy this conduit (socket)
                scope (exit)
                       conduit.close;

                // reset the (probably overridden) input and output
                request.reset();
                response.reset();

                // first, extract HTTP headers from input
                request.readHeaders ();

                // pass request off to the provider. It is the provider's 
                // responsibility to flush the output!
                provider.service (request, response);
        }
}

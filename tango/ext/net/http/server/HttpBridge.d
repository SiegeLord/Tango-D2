/*******************************************************************************

        @file HttpBridge.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, April 2004      
        @author         Kris


*******************************************************************************/

module tango.ext.net.http.server.HttpBridge;

private import  tango.net.Socket;

private import  tango.io.model.IConduit;

private import  tango.ext.net.util.model.IServer;

private import  tango.ext.net.http.server.HttpThread,
                tango.ext.net.http.server.HttpRequest,
                tango.ext.net.http.server.HttpResponse;

private import  tango.ext.net.http.server.model.IProvider,
                tango.ext.net.http.server.model.IProviderBridge;

/******************************************************************************

        Bridges between an IProvider and an IServer, and contains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of HttpBridge (one per 
        server-thread).

        Any additional thread-specific data should probably be contained
        within this class, since it is reachable from almost everywhere.

******************************************************************************/

class HttpBridge : IProviderBridge
{
        private IServer         server;
        private IProvider       provider;

        private HttpThread      thread;
        private HttpRequest     request;
        private HttpResponse    response;
        
        /**********************************************************************

                Construct a bridge with the requisite attributes. We create
                the per-thread request/response pair here, and maintain them 
                for the lifetime of the server.

        **********************************************************************/

        this (IServer server, IProvider provider, HttpThread thread)
        {
                this.thread = thread;
                this.server = server;
                this.provider = provider;

                request = provider.createRequest(this);
                response = provider.createResponse(this);
        }

        /**********************************************************************

                Return the server from one side of this bridge

        **********************************************************************/

        IServer getServer()
        {
                return server;
        }

        /**********************************************************************

                Return the provider from the other side of the bridge

        **********************************************************************/

        IProvider getProvider()
        {
                return provider;
        }

        /**********************************************************************

                Bridge the divide between IServer and IProvider instances.
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

                try {
                    // reset the (probably overridden) input and output
                    request.reset();
                    response.reset();

                    // first, extract HTTP headers from input
                    request.readHeaders ();

                    // pass request off to the provider. It is the provider's 
                    // responsibility to flush the output!
                    provider.service (request, response);
                    } finally {
                              // close and destroy this conduit (socket)
                              conduit.close();
                              }
        }
}

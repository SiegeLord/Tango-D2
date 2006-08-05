/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpServer;

public  import  tango.net.InternetAddress;

private import  tango.log.Logger;

private import  tango.io.Exception;

private import  tango.net.ServerSocket;

private import  tango.io.model.IConduit;

private import  mango.net.util.AbstractServer;

private import  mango.net.util.model.IRunnable;

private import  mango.net.http.server.HttpThread,
                mango.net.http.server.HttpBridge,
                mango.net.http.server.ServiceBridge,            
                mango.net.http.server.ServiceProvider;

/******************************************************************************
        
        Extends the AbstractServer to glue all the Http support together.
        One should subclass this to provide a secure (https) server.

******************************************************************************/

class HttpServer : AbstractServer
{
        private ServiceProvider provider;

        /**********************************************************************

                Construct this server with the requisite attribites. The
                ServiceProvider represents a service handler, the binding addr
                is the local address we'll be listening on, and 'threads'
                represents the number of thread to initiate.

        **********************************************************************/

        this (ServiceProvider provider, InternetAddress bind, int threads, Logger logger = null)
        {
                this (provider, bind, threads, 10, logger);
        }

        /**********************************************************************

                Construct this server with the requisite attribites. The
                ServiceProvider represents a service handler, the binding addr
                is the local address we'll be listening on, and 'threads'
                represents the number of thread to initiate. Backlog is
                the number of "simultaneous" connection requests that a
                socket layer will buffer on our behalf.

        **********************************************************************/

        this (ServiceProvider provider, InternetAddress bind, int threads, int backlog, Logger logger = null)
        {
                super (bind, threads, backlog, logger);
                this.provider = provider;
        }

        /**********************************************************************

                Return the protocol in use.

        **********************************************************************/

        char[] getProtocol()
        {
                return "http";
        }

        /**********************************************************************

                Return a text string identifying this server

        **********************************************************************/

        override char[] toString()
        {
                return getProtocol()~"::"~provider.toString();
        }

        /**********************************************************************

                Create a ServerSocket instance. Secure implementations
                would provide a SecureSocketServer, or something along
                those lines.

        **********************************************************************/

        override ServerSocket createSocket (InternetAddress bind, int backlog)
        {
                return new ServerSocket (bind, backlog);
        }

        /**********************************************************************

                Create a ServerThread instance. This can be overridden to 
                create other thread-types, perhaps with additional thread-
                level data attached.

        **********************************************************************/

        override IRunnable createThread (ServerSocket socket)
        {
                return new HttpThread (this, socket);
        }

        /**********************************************************************

                Factory method for servicing a request. We just toss the
                request across our bridge, for the ServiceProvider to handle.

        **********************************************************************/

        override void service (IRunnable st, IConduit conduit)
        {
                HttpThread      thread;
                ServiceBridge   bridge;

                // we know what this is because we created it (above)
                thread = cast(HttpThread) st;

                // extract thread-local HttpBridge
                if ((bridge = thread.getBridge()) is null)
                   {
                   // create a new instance if it's the first service 
                   // request on this particular thread
                   bridge = new HttpBridge (this, provider, thread);
                   thread.setBridge (bridge);
                   }

                // process request
                bridge.cross (conduit);
        }
}


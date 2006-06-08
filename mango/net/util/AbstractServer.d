/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004    
        
        author:         Kris

*******************************************************************************/

module mango.net.util.AbstractServer;

private import  tango.log.Logger;

private import  tango.io.Exception;

private import  tango.convert.Integer;

private import  tango.io.model.IConduit;

private import  tango.net.ServerSocket,
                tango.net.SocketConduit;

private import  mango.net.util.ServerThread;

private import  mango.net.util.model.IServer;


/******************************************************************************

        Exposes the foundation of a multi-threaded Socket server. This is 
        subclassed by  mango.net.http.server.HttpServer, which itself would
        likely be subclassed by a SecureHttpServer. 

******************************************************************************/

class AbstractServer : IServer
{
        private InternetAddress bind;
        private int             threads;
        private int             backlog;
        private ServerSocket    socket;
        private ILogger         logger;

        /**********************************************************************

                Setup this server with the requisite attributes. The number
                of threads specified dictate exactly that. You might have 
                anything between 1 thread and several hundred, dependent
                upon the underlying O/S and hardware.

                Parameter 'backlog' specifies the max number of"simultaneous" 
                connection requests to be handled by an underlying socket 
                implementation.

        **********************************************************************/

        this (InternetAddress bind, int threads, int backlog, ILogger logger = null)
        in {
           assert (bind);
           assert (backlog >= 0);
           assert (threads > 0 && threads < 1025);
           }
        body
        {
                this.bind = bind;
                this.threads = threads;
                this.backlog = backlog;

                // save our logger for later reference
                if (logger is null)
                    logger = Logger.getLogger ("mango.net.util.AbstractServer");
                this.logger = logger;

        }

        /**********************************************************************

                Concrete server must expose a name 

        **********************************************************************/

        protected abstract char[] toString();

        /**********************************************************************

                Concrete server must expose a ServerSocket factory

        **********************************************************************/

        protected abstract ServerSocket createSocket (InternetAddress bind, int backlog);

        /**********************************************************************

                Concrete server must expose a ServerThread factory

        **********************************************************************/

        protected abstract ServerThread createThread (ServerSocket socket);

        /**********************************************************************

                Concrete server must expose a service handler

        **********************************************************************/

        abstract void service (ServerThread thread, IConduit conduit);

        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        char[] getRemoteAddress (IConduit conduit)
        {
                SocketConduit socket = cast(SocketConduit) conduit;
                InternetAddress addr = cast(InternetAddress) socket.remoteAddress();

                if (addr)
                    return addr.toAddrString();
                return "127.0.0.1";
        }

        /**********************************************************************

                Provide support for figuring out the remote host. Not
                currently implemented.
                
        **********************************************************************/

        char[] getRemoteHost (IConduit conduit)
        {
                return null;
        }

        /**********************************************************************

                Return the local port we're attached to

        **********************************************************************/

        int getPort ()
        {
                InternetAddress addr = cast(InternetAddress) socket.localAddress();
                return addr.port();
        }

        /**********************************************************************

                Return the local address we're attached to

        **********************************************************************/

        char[] getHost ()
        {
                InternetAddress addr = cast(InternetAddress) socket.localAddress();
                return addr.toAddrString();
        }

        /**********************************************************************

                Return the logger associated with this server

        **********************************************************************/

        ILogger getLogger ()
        {
                return logger;
        }

        /**********************************************************************

                Start this server

        **********************************************************************/

        void start ()
        {
                // have the subclass create a ServerSocket for us 
                socket = createSocket (bind, backlog);
                
                // instantiate and start all threads
                for (int i=threads; --i >= 0;)
                     createThread (socket).start();

                char[] info = "Server "~toString()~" started on "~
                               socket.localAddress().toString()~
                               " with "~Integer.format(new char[5], threads)~" accept threads, "~
                               Integer.format(new char[5], backlog)~" backlogs";

                // indicate what's going on 
                logger.info (info);
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        May 2008: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.SocketPool;

private import  tango.time.Clock;

private import  tango.core.Runtime,
                tango.core.Exception;

private import  tango.net.SocketConduit,
                tango.net.InternetAddress;

/*******************************************************************************
        
        A pool of socket connections for accessing cluster nodes. Note 
        that the entries will timeout after a period of inactivity, and
        will subsequently cause a connected host to drop the supporting
        session.

        The connections are expected to be reasonably long-lived on the 
        hosting server, since we try to reuse existing sockets

*******************************************************************************/

private class SocketPool
{ 
        private alias void delegate (IConduit) Handler;
        private alias void delegate (char[] msg, ...) Error;

        private int                     size, 
                                        count;
        private bool                    online,
                                        noDelay;

        private Error                   error;
        private InternetAddress         address;
        private Connection              freelist;
        private TimeSpan                timeout = TimeSpan.seconds(60);

        /***********************************************************************

                Create a connection-pool for the specified address

        ***********************************************************************/

        this (InternetAddress address, Error error=null, bool noDelay=true)
        {      
                this.online = true;
                this.error = error;
                this.address = address;
                this.noDelay = noDelay;
        }

        /***********************************************************************

                Allocate a Connection from a list rather than creating a 
                new one. Reap old entries as we go.

        ***********************************************************************/

        final synchronized Connection borrow (Time time)
        {  
                if (freelist)
                    do {
                       auto c = freelist;

                       freelist = c.next;
                       if (freelist && (time - c.time > timeout))
                           c.close;
                       else
                          return c;
                       } while (true);

                return new Connection (this);
        }

        /***********************************************************************

                Close this pool and drop all existing connections.

        ***********************************************************************/

        final synchronized void close ()
        {     
                online = false;

                auto c = freelist;
                freelist = null;
                while (c)
                      {
                      c.close;
                      c = c.next;
                      }
        }

        /***********************************************************************
        
                Is the server still online?

                This is set false once we fail to connect, and enabled again
                once a connection has been re-established

        ***********************************************************************/

        final bool isOnline ()
        {       
                return online;
        }

        /***********************************************************************

                request data; fail this pool if we can't connect. Note
                that we make several attempts to connect before writing
                the node off as a failure. We use a delegate to perform 
                the request output since it may be invoked on more than
                one iteration, where the current attempt fails.

                We return true if the cluster node responds, and false
                otherwise. Exceptions are thrown if they occured on the 
                server. 
                
        ***********************************************************************/
        
        final bool request (Handler send, Handler recv)
        {       
                Time time;

                // get a connection to the server
                auto connect = borrow (time = Clock.now);

                // talk to the server (try a few times if necessary)
                for (int attempts=3; attempts--;)
                     try {
                         send (connect.conduit); 

                         // load the reply. Don't retry on
                         // failed reads, since the server is either
                         // really really busy, or near death. We must
                         // assume it is offline until it tells us 
                         // otherwise 
                         attempts = 0;
                         recv (connect.conduit);

                         // return borrowed connection
                         connect.done (time);

                         } catch (IOException x)
                                 {
                                 if (error)
                                     error ("IOException on request to server {} - {}", address, x);

                                 // attempt to reconnect?
                                 if (attempts is 0 || !connect.reset)
                                    {
                                    // that server is offline
                                    if (error)
                                        error ("disabling connection for server {}", address);
                                    close;
  
                                    // state that we failed
                                    return false;
                                    }
                                }
                    
                // ok, our server responded
                return true;
        }


        /***********************************************************************
        
                Utility class to provide the basic connection facilities
                provided by the connection pool.

        ***********************************************************************/

        static class Connection
        {
                Connection      next;   
                Time            time;
                SocketPool      parent;   
                SocketConduit   socket;

                /***************************************************************
                
                        Construct a new connection and set its parent

                ***************************************************************/
        
                this (SocketPool pool)
                {
                        parent = pool;
                        reset;
                }
                  
                /***************************************************************

                        Create a new socket and connect it to the specified 
                        server. This should cause a dedicated handler to start 
                        on the server. Said handler should remain connected
                        until a timout or error occurs.

                ***************************************************************/
        
                final bool reset ()
                {
                        try {
                            socket = new SocketConduit;

                            // apply Nagle settings
                            socket.socket.setNoDelay (parent.noDelay);

                            // set a 500ms timeout for read operations
                            socket.setTimeout (0.500);

                            // open a connection to this server
                            socket.connect (parent.address);

                            return parent.online = true;

                            } catch (Object o)
                                     if (! Runtime.isHalting && parent.error)
                                           parent.error ("server {} is unavailable - {}", parent.address, o);
                        return false;
                }
                  
                /***************************************************************

                        Return the socket belonging to this connection

                ***************************************************************/
        
                final SocketConduit conduit ()
                {
                        return socket;
                }
                  
                /***************************************************************

                        Close the socket. This will cause any host session
                        to be terminated.

                ***************************************************************/
        
                final void close ()
                {
                        socket.detach;
                }

                /***************************************************************

                        Return this connection to the free-list. Note that
                        we have to synchronize on the parent-pool itself.

                ***************************************************************/

                final void done (Time time)
                {
                        synchronized (parent)
                                     {
                                     next = parent.freelist;
                                     parent.freelist = this;
                                     this.time = time;
                                     }
                }
        }
}


/*******************************************************************************
        
*******************************************************************************/

debug (SocketPool)
{
        import tango.io.Stdout;
        import tango.core.Thread;

        void main()
        {

                auto pool = new SocketPool (new InternetAddress("localhost:1111"), &Stdout.formatln);

                void send (Connection c)
                {
                        Stdout ("sending").newline;
                        int x = 5;
                        c.write ((&x)[0..1]);
                        if (c.write ("hello") is c.Eof)
                            throw new IOException ("failed to write");
                }

                void recv (IConduit c)
                {
                }

                while (true)
                      {
                      if (! pool.request (&send, &recv))
                            Stdout (">>> request failed").newline;
                      Thread.sleep (1);
                      }
        }
}
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

private import  tango.io.stream.DataStream;

/*******************************************************************************
        
        A pool of socket connections for accessing remote servers. Note 
        that the entries will timeout after a period of inactivity, and
        will subsequently cause a connected host to drop the supporting
        session.

        The connections are expected to be reasonably long-lived on the 
        hosting server, since we try to reuse existing sockets

*******************************************************************************/

class SocketPool(T)
{ 
        public alias void delegate (T) Handler;
        public alias T delegate (IConduit) Factory;
        public alias void delegate (char[] msg, ...) Log;

        private bool                    nagle,
                                        online;

        private Factory                 factory;
        private InternetAddress         address;
        private Connection              freelist;
        private TimeSpan                timeout = TimeSpan.seconds(60);


        /***********************************************************************

                Create a connection-pool for the specified address

        ***********************************************************************/

        this (InternetAddress address, Factory factory, bool nagle=true)
        {      
                this.nagle = nagle;
                this.online = true;
                this.factory = factory;
                this.address = address;
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

                Returns true on success, false otherwise
                
        ***********************************************************************/
        
        final bool request (Handler send, Handler recv, Log log)
        {       
                Time time;

                // get a connection to the server
                auto connection = borrow (time = Clock.now);

                // talk to the server (try a few times if necessary)
                for (int attempts=3; attempts--;)
                     try {
                         if (send)
                             send (connection.bound); 

                         // load the reply. Don't retry on
                         // failed reads, since the server is either
                         // really really busy, or near death. We must
                         // assume it is offline until it tells us 
                         // otherwise 
                         attempts = 0;
                         if (recv)
                             recv (connection.bound);

                         // return borrowed connection
                         connection.done (time);

                         } catch (IOException x)
                                 {
                                 if (log)
                                     log ("IOException on request to server {} - {}", address, x);

                                 // attempt to reconnect?
                                 if (attempts is 0 || !connection.reset)
                                    {
                                    // that server is offline
                                    close;

                                    if (log)
                                        log ("disabling connection for server {}", address);
  
                                    // state that we failed
                                    return false;
                                    }
                                }
                    
                // ok, our server responded
                return true;
        }

        /***********************************************************************

                Allocate a Connection from a list rather than creating a 
                new one. Reap old entries as we go.

        ***********************************************************************/

        private final synchronized Connection borrow (Time time)
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
        
                Utility class to provide the basic connection facilities
                provided by the connection pool.

        ***********************************************************************/

        private static class Connection
        {
                Connection      next;   
                Time            time;
                SocketPool      parent;   
                SocketConduit   socket;
                T               bound;

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
                        // new connection to host
                        socket = new SocketConduit;

                        // have callee create the binding
                        bound = parent.factory (socket);

                        try {
                            // apply Nagle settings
                            socket.socket.setNoDelay (parent.nagle is false);

                            // set a 500ms timeout for read operations
                            socket.setTimeout (0.500);

                            // open a connection to this server
                            socket.connect (parent.address);

                            return parent.online = true;
                            } catch (Object o) {}
                                     
                        return false;
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
        
        A pool of connected DataOuptut instances, each of which are thread-
        safe (each connection has its own private output buffer).
        
        Note that the connections will timeout after a period of inactivity, 
        and will subsequently cause a connected host to drop the supporting
        session.

        The connections are expected to be reasonably long-lived on the 
        hosting server, since we try to reuse existing sockets

*******************************************************************************/

class DataOutputPool : SocketPool!(DataOutput)
{ 
        private bool flip;
        private int  bufferSize;

        /***********************************************************************

                Create a connection-pool for the specified address

        ***********************************************************************/

        this (InternetAddress addr, int bufferSize=8192, bool flip=false, bool nagle=true)
        {
                this.flip = flip;
                this.bufferSize = bufferSize;
                super (addr, &factory, nagle);
        }

        /***********************************************************************

                Wrap the socket with a DataOutput instance

        ***********************************************************************/

        private DataOutput factory (IConduit c)
        {       
                return new DataOutput (c, bufferSize, flip);
        }
}


/*******************************************************************************
        
*******************************************************************************/

debug (SocketPool)
{
        import tango.io.Stdout;
        import tango.core.Thread;
        
        alias SocketPool!(IConduit) Pool;

        void main()
        {
                IConduit create (IConduit c)
                {       
                        return c;
                }

                void send (IConduit c)
                {
                        Stdout ("sending").newline;
                        int x = 5;
                        c.write ((&x)[0..1]);
                        if (c.write ("hello") is c.Eof)
                            throw new IOException ("failed to write");
                }
        
                auto pool = new Pool (new InternetAddress("localhost:1111"), &create);
                while (true)
                      {
                      if (! pool.request (&send, null, cast(Pool.Log) &Stdout.formatln))
                            Stdout (">>> request failed").newline;
                      Thread.sleep (1);
                      }
        }
}
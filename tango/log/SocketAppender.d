/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.SocketAppender;

private import  tango.log.Appender;

version (Isolated)
        {
        private import  std.stream,
                        std.Socket,
                        std.SocketStream;
        }
     else
        {
        private import  tango.io.Buffer,
                        tango.io.Console,
                        tango.net.SocketConduit;
        }

/*******************************************************************************

        Appender for sending formatted output to a Socket.

*******************************************************************************/

public class SocketAppender : Appender
{
        private Mask mask;

        version (Isolated)
                 private SocketStream stream;
              else
                 private IBuffer buffer;

        /***********************************************************************
                
                Create with the given Layout and address

        ***********************************************************************/

        this (InternetAddress address, Layout layout = null)
        {
                setAddress (address);
                setLayout (layout);
        }

        /***********************************************************************
               
               Set the destination address and port for this socket

        ***********************************************************************/

        private void setAddress (InternetAddress address)
        {
                close ();
                
                version (Isolated)
                        {
                        try {
                            //throw new Exception ("SocketAppender fails with dmd v0.115");
                            Socket s = new Socket (AddressFamily.INET, SocketType.STREAM, ProtocolType.IP);
                            s.connect (address);
                            stream = new SocketStream (s, FileMode.Out);
                            } catch (Object x)
                                     printf ("SocketAppender: failed to connect\n");
                        }
                     else
                        {
                        try {
                            SocketConduit socket = new TextSocketConduit;
                            socket.connect (address);
                            buffer = new Buffer (socket);
                            } catch (Object x)
                                     Cerr ("SocketAppender: failed to connect\n"c);
                        }

                // Get a unique fingerprint for this class
                mask = register (address.toString);
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        Mask getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
                
                Append an event to the output.
                 
        ***********************************************************************/

        void append (Event event)
        {
                version (Isolated)
                        {
                        if (stream)
                           {
                           Layout layout = getLayout;
                           stream.writeString (layout.header  (event));
                           stream.writeString (layout.content (event));
                           stream.writeString (layout.footer  (event));
                           stream.flush ();
                           }    
                        }
                     else
                        {
                        if (buffer)
                           {
                           Layout layout = getLayout;
                           buffer.append (layout.header  (event));
                           buffer.append (layout.content (event));
                           buffer.append (layout.footer  (event)).flush();
                           }    
                        }
        }

        /***********************************************************************
            
                Close the socket associated with this Appender
                    
        ***********************************************************************/

        void close ()
        {
                version (Isolated)
                        {
                        if (stream)
                            stream.close ();
                        stream = null;
                        }
                     else
                        {
                        if (buffer)
                            buffer.getConduit.close();
                        buffer = null;
                        }
        }
}

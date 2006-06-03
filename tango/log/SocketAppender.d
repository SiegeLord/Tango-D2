/*******************************************************************************

        @file SocketAppender.d

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

      
        @version        Initial version, May 2004
        @author         Kris


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
        private static uint mask;

        version (Isolated)
                 private SocketStream stream;
              else
                 private IBuffer buffer;

        /***********************************************************************
                
                Get a unique fingerprint for this class

        ***********************************************************************/

        static this()
        {
                mask = nextMask();
        }

        /***********************************************************************
                
                Create with the given Layout and address

        ***********************************************************************/

        this (Layout layout, InternetAddress address)
        {
                setLayout (layout);
                setAddress (address);
        }

        /***********************************************************************
               
               Set the destination address and port for this socket

        ***********************************************************************/

        void setAddress (InternetAddress address)
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
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        uint getMask ()
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

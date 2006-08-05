/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.SocketAppender;

private import  tango.log.Appender;

private import  tango.io.Buffer,
                tango.io.Console;

private import  tango.net.SocketConduit,
                tango.net.InternetAddress;

/*******************************************************************************

        Appender for sending formatted output to a Socket.

*******************************************************************************/

public class SocketAppender : Appender
{
        private Mask    mask;
        private IBuffer buffer;

        /***********************************************************************
                
                Create with the given Layout and address

        ***********************************************************************/

        this (InternetAddress address, Layout layout = null)
        {
                setAddress (address);
                setLayout  (layout);
        }

        /***********************************************************************
               
               Set the destination address and port for this socket

        ***********************************************************************/

        private void setAddress (InternetAddress address)
        {
                close;
                
                try {
                    version (IOTextTest)
                             auto conduit = new TextSocketConduit;
                         else
                            auto conduit = new SocketConduit;

                    buffer = new Buffer (conduit);
                    conduit.connect (address);

                    } catch (Object x)
                             Cerr ("SocketAppender: failed to connect\n"c);

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
                if (buffer)
                   {
                   Layout layout = getLayout;
                   buffer.append (layout.header  (event));
                   buffer.append (layout.content (event));
                   buffer.append (layout.footer  (event)).flush();
                   }    
        }

        /***********************************************************************
            
                Close the socket associated with this Appender
                    
        ***********************************************************************/

        void close ()
        {
                if (buffer)
                    buffer.getConduit.close();
                buffer = null;
        }
}

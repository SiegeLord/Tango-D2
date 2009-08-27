/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.AppendSocket;

private import  tango.util.log.Log;

private import  tango.io.Console;

private import  tango.io.stream.Buffered;
                
private import  tango.net.SocketConduit,
                tango.net.InternetAddress;

/*******************************************************************************

        Appender for sending formatted output to a Socket.

*******************************************************************************/

public class AppendSocket : Appender
{
        private Mask            mask_;
        private Bout            buffer;
        private SocketConduit   conduit;
        private InternetAddress address;
        private bool            connected;

        /***********************************************************************
                
                Create with the given Layout and address

        ***********************************************************************/

        this (InternetAddress address, Appender.Layout how = null)
        {
                layout (how);

                this.address = address;
                this.conduit = new SocketConduit;
                this.buffer  = new Bout (conduit);

                // Get a unique fingerprint for this class
                mask_ = register (address.toString);
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        Mask mask ()
        {
                return mask_;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] name ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
                
                Append an event to the output. If the operations fails
                we have to revert to an alternative logging strategy, 
                which will probably require a backup Appender specified
                during construction. For now we simply echo to Cerr if
                the socket has become unavailable.               
                 
        ***********************************************************************/

        void append (LogEvent event)
        {
                auto layout = layout();

                if (buffer)
                   {
                   try {
                       if (! connected)
                          {
                          conduit.connect (address);
                          connected = true;
                          }

                       layout.format (event, &buffer.write);
                       buffer.flush;
                       return;
                       } catch (Exception e)
                               {
                               connected = false;
                               Cerr ("SocketAppender.append :: "~e.toString).newline;
                               }
                   }

                Cerr (event.toString).newline;
        }

        /***********************************************************************
            
                Close the socket associated with this Appender
                    
        ***********************************************************************/

        void close ()
        {
                if (conduit)
                    conduit.detach;
                conduit = null;
        }
}

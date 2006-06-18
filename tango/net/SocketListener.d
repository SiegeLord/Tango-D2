/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.SocketListener;

private import  tango.core.Thread;

private import  tango.net.Socket;

private import  tango.io.model.IBuffer;

/******************************************************************************

        Abstract class to asynchronously listen for incoming data on a 
        socket. This can be used with DatagramSocket & MulticastSocket, 
        and might possibly be useful with a basic SocketConduit also.
        Note that DatagramSocket must first be bound to a local network
        address via bind(), and MulticastSocket should first be made a 
        member of a multicast group via its join() method. Note also
        that the underlying thread is not started by the constructor;
        you should do that manually via the start() method.

******************************************************************************/

class SocketListener : Thread, IListener
{
        private bool                    quit;
        private IBuffer                 buffer;
        private ISocketReader           reader;
        private int                     limit = 3;

        /**********************************************************************
               
                Construct a listener with the requisite arguments. The
                specified buffer is populated via the provided instance
                of ISocketReader before being passed to the notify()
                method. All arguments are required.

        **********************************************************************/

        this (ISocketReader reader, IBuffer buffer)
        in {
           assert (reader);
           assert (buffer);
           }
        body
        {
                this.buffer = buffer;
                this.reader = reader;
        }

        /***********************************************************************
                
                Notification callback invoked whenever the listener has
                anything to report. The buffer will have whatever content
                was available from the read() operation

        ***********************************************************************/

        abstract void notify (IBuffer buffer);

        /***********************************************************************

                Handle error conditions from the listener thread.

        ***********************************************************************/

        abstract void exception (char[] msg);

        /**********************************************************************
             
                Cancel this listener. The thread will quit only after the 
                current read() request responds, or is interrrupted.

        **********************************************************************/

        void cancel ()
        {
                quit = true;
        }

        /**********************************************************************
             
                Set the maximum contiguous number of exceptions this 
                listener will survive. Setting a limit of zero will 
                not survive any errors at all, whereas a limit of two
                will survive as long as two consecutive errors don't 
                arrive back to back.

        **********************************************************************/

        void setErrorLimit (ushort limit)
        {
                this.limit = limit + 1;
        }

        /**********************************************************************

                Execution of this thread is typically stalled on the
                read() method belonging to the ISocketReader specified
                during construction. You can invoke cancel() to indicate
                execution should not proceed further, but that will not
                actually interrupt a blocked read() operation.

                Note that exceptions are all directed towards the handler
                implemented by the class instance. 

        **********************************************************************/

        void run ()
        {
                int lives = limit;

                while (lives > 0)
                       try {
                           // start with a clean slate
                           buffer.clear ();

                           // wait for incoming content
                           auto result = reader.read (buffer);

                           // time to quit? Note that a v0.95 compiler bug 
                           // prohibits 'break' from exiting the try{} block
//                         if (quit || Socket.isHalting ())
                           if (quit || 
                              (result is Socket.Eof && !reader.isAlive))
                               lives = 0;
                           else
                              {
                              // invoke callback                        
                              notify (buffer);
                              lives = limit;
                              }
                           } catch (Object x)
                                    // time to quit?
//                                    if (quit || Socket.isHalting ())
                                    if (quit || !reader.isAlive)
                                        break;
                                    else
                                       {
                                       exception (x.toString);
                                       if (--lives is 0)
                                           exception ("listener thread aborting");
                                       }
        }
}




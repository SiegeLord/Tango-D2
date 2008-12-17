/*******************************************************************************
                                                                                
        copyright:      Copyright (c) 2006 UWB. All rights reserved             
                                                                                
        license:        BSD style: $(LICENSE)                                   
                                                                                
        version:        Initial release: June 2006                              
                        Tango Mods by Lester L Martin: August 2008
                                                                                
        author:         UWB                                                     
                                                                                
*******************************************************************************/

module tango.net.ftp.Telnet;

private {
        import tango.net.SocketConduit;
        import tango.net.Socket;
        import tango.net.InternetAddress;
        import tango.core.Exception;
        import tango.io.stream.Lines;
}

class Telnet {

        /// The Socket Conduit that is used to send commands.
        SocketConduit socket_;
        Lines!(char) iterator;
        char[8 * 1024] dst; //for reading from the socket_

        abstract void exception(char[] message);

        /// Send a line over the Socket Conduit.
        ///
        ///    buf =             the bytes to send
        void sendline(void[] buf) {
                sendData(buf);
                sendData("\r\n");
        }

        /// Send a line over the Socket Conduit.
        ///
        ///    buf =             the bytes to send
        void sendData(void[] buf) {
                socket_.write(buf);
        }

        /// Read a CRLF terminated line from the socket.
        ///
        /// Returns:             the line read
        char[] readLine() {
        char[] to_return; 
        iterator.readln(to_return); 
        return to_return; 
        }

        /************************************************************************
         * Find a server which is listening on the specified port.
         *
         *      Params:
         *          hostname = the hostname to lookup and connect to
         *          port = the port to connect on
         *      Returns:
                the SocketConduit instance used
         *      Since: 0.99.8
         */
        SocketConduit findAvailableServer(char[] hostname, int port) {
                socket_ = new SocketConduit();
                socket_.connect(new InternetAddress(hostname, port));
                iterator = new Lines!(char)(socket_); 
                return socket_;
        }

}

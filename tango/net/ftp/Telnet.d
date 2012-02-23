/*******************************************************************************

        copyright:      Copyright (c) 2006 UWB. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2006
                        Tango Mods by Lester L Martin: August 2008

        author:         UWB

*******************************************************************************/

module tango.net.ftp.Telnet;

private
{
        import tango.core.Exception;
        import tango.io.stream.Lines;
        import tango.net.device.Socket;
}

class Telnet
{
        /// The Socket that is used to send commands.
        Socket socket_;
        Lines!(char) iterator;

        abstract void exception(string message);

        /// Send a line over the Socket Conduit.
        ///
        /// buf = the bytes to send
        void sendline(const(void)[] buf)
        {
                sendData(buf);
                sendData("\r\n");
        }

        /// Send a line over the Socket Conduit.
        ///
        /// buf = the bytes to send
        void sendData(const(void)[] buf)
        {
                socket_.write(buf);
        }

        /// Read a CRLF terminated line from the socket.
        ///
        /// Returns: the line read
        const(char)[] readLine()
        {
                const(char)[] to_return;
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
                the Socket instance used
         *      Since: 0.99.8
         */
        Socket findAvailableServer(const(char)[] hostname, int port)
        {
                socket_ = new Socket;
                socket_.connect(hostname, port);
                iterator = new Lines!(char)(socket_);
                return socket_;
        }

}

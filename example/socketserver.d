/*******************************************************************************

        Shows how to create a basic socket server, and how to talk to
        it from a socket client. Note that both the server and client
        are entirely simplistic, and therefore this is for illustration
        purposes only. See HttpServer for something more robust.

*******************************************************************************/

private import  tango.core.Thread;

private import  tango.io.Console;

private import  tango.net.ServerSocket,
                tango.net.SocketConduit;

/*******************************************************************************

        Create a socket server, and have it respond to a request

*******************************************************************************/

void main()
{
        // thread body for socket listener
        void run()
        {       
                // instantiate a server socket
                auto server = new ServerSocket (new InternetAddress("localhost", 8080));
                while (true)
                      { 
                      // wait for requests
                      auto request = server.accept();

                      // write a response 
                      request.write ("server replies 'hello'");
                      }
        }

        // start server in a seperate thread
        (new Thread (&run)).start;

        // make a connection request to the server
        auto request = new SocketConduit;
        request.connect (new InternetAddress("localhost", 8080));

        // wait for response (there is an optional timeout supported)
        char[64] response;
        request.read (response);

        // close socket
        request.close();

        // display server response
        Cout (response).newline;
}

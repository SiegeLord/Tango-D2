/*******************************************************************************

        Shows how to create a basic socket server, and how to copy a file
        to it from a socket client. Note that both the server and client
        are entirely simplistic, and hence this is for illustrative
        purposes only. 

*******************************************************************************/

private import  tango.core.Thread;

private import  tango.io.Console,
                tango.io.device.File;

private import  tango.net.device.Socket;
            

/*******************************************************************************

        Create a socket server, and have it respond to a request

*******************************************************************************/

void main(char[][] args)
{
        // thread body for socket listener
        void run()
        {       
                // instantiate a server socket
                auto server = new ServerSocket (8080);

                // wait for requests
                auto stream = server.accept;

                // copy incoming stream to a local file
                auto file = new File ("dumpster.log", File.WriteCreate);
                file.copy(stream).flush.close;
        }

        if (args.length is 2)
           { 
           // start server in a separate thread and wait for it to start
           auto server = new Thread (&run);
           server.start;   

           // wait for server to start
           Thread.sleep (0.1);

           // make a connection request to the server
           auto send = new Socket;
           send.connect ("localhost", 8080);

           // send the specified file
           send.copy (new File(args[1])).flush.close;
           } 
        else
           Cout ("usage is netcopy filename").newline;
}

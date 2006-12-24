import  tango.core.Thread;

import  tango.net.http.HttpResponses;

import  mango.net.http.server.HttpServer,
        mango.net.http.server.HttpRequest,
        mango.net.http.server.HttpResponse,
        mango.net.http.server.HttpProvider;

/*******************************************************************************

        Create a simple HttpServer, that responds with a trivial HTML page.
        The server listens on localhost:8080

*******************************************************************************/

void main ()
{
        // our simple http hander
        class Provider : HttpProvider
        {
                override void service (HttpRequest request, HttpResponse response)
                {
                        // return an HTML page saying "HTTP Error: 200 OK"
                        response.sendError (HttpResponses.OK);
                }
        }

        // bind server to port 8080 on a local address
        auto addr = new InternetAddress (8080);

        // create a (1 thread) server using the ServiceProvider to service requests
        auto server = new HttpServer (new Provider, addr, 1, 100);

        // start listening for requests (but this thread does not listen)
        server.start;

        // send main thread to sleep
        Thread.sleep;
}
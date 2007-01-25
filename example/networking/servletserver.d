import  tango.core.Thread;

import  tango.net.Socket;
        
import  mango.net.servlet.Servlet;
import  mango.net.servlet.ServletProvider;

import  mango.net.http.server.HttpServer,
        mango.net.http.server.HttpProvider;

/*******************************************************************************

        Create a simple Servlet engine to respond to file requests. The server 
        listens on localhost:8080

*******************************************************************************/

void main()
{
        // a trivial servlet to return files. NOte that there are a number
        // of servlet types available (see mango.net.servlet.Servlet)
        class FileServlet : MethodServlet
        {
                void doGet (IServletRequest request, IServletResponse response)
                {
                        response.copyFile (request.getContext(), request.getPathInfo());
                }
        }

        // construct a servlet-provider
        auto sp = new ServletProvider;

        // map all html requests to our file servlet
        auto files = sp.addServlet (new FileServlet(), "files");
        sp.addMapping ("*.html", files);
        sp.addMapping ("*.htm", files);

        // create a (1 thread) http-server using the ServletProvider 
        auto server = new HttpServer (sp, new InternetAddress (8080), 1, 100);

        // start listening for requests (but this thread does not listen)
        server.start;

        // send main thread to sleep
        Thread.sleep;
}
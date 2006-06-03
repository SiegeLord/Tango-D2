/******************************************************************************

        @file servlets.d

        Here's some contrived servlets to give you an idea what Mango does.

        Point your Browser at http://127.0.0.1 and try the following paths:

        1) /example/echo should return a bunch of diagnostic stuff back to
           the browser

        2) /example/ping maintains a count of how many times a particular
           ip-address has made a request, and check to see if Google News
           page has been updated since the last visit (per address). This 
           is a hideously contrived example of VirtualCache and HttpClient. 
           That is, it illustrates how to maintain lightweight server-side 
           state (when necessary), and how to make client-side requests to 
           a remote server. One might handle state management using cookies 
           or url-rewrites instead.

        3) /admin/logger allows you to modify current Loggers and Levels, 
           as well as the ability to create new Logger/Level combinations.

        4) all other paths are mapped to a file-request handler. Requesting
           /index.html should return the doxygen page for Mango; all other
           links should operate correctly. Be sure to start the executable 
           from the mango/obj directory, otherwise you'll probably run into
           404-Not-Found errors. 

        
        Kris, May 2nd 2004
        Scott Sanders, June 1, 2004

*******************************************************************************/

        // for a variety of servlet IO
import  tango.io.Uri,
        tango.io.Exception,
        tango.io.DisplayWriter;

        // for sleep()
import  tango.core.System;

        // for InternetAddress
import  tango.net.Socket;

        //for logging
import  tango.log.Admin,
        tango.log.Logger,
        tango.log.Configurator;

        // for testing the http server
import  tango.net.http.server.HttpServer;

        // for testing the servlet-engine
import  tango.net.servlet.Servlet,
        tango.net.servlet.ServletContext,
        tango.net.servlet.ServletProvider;

        // setup a logger for module scope
private Logger mainLogger;


/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");


/*******************************************************************************

        an HTML wrapper built upon a DisplayWriter

*******************************************************************************/

class HtmlWriter : DisplayWriter
{       
        /***********************************************************************
        
        ***********************************************************************/

        this (IWriter writer)
        {
                super (writer.getBuffer);
        }

        /***********************************************************************
        
        ***********************************************************************/

        override IWriter newline()
        {
                return super.put ("<br>\r\n"c);
        }
}


/*******************************************************************************

        Servlet to return a file. 

*******************************************************************************/

class FileServlet : MethodServlet
{
        private static Logger logger;

        /***********************************************************************
        
                get a Logger for this class

        ***********************************************************************/

        static this ()
        {
                logger = Logger.getLogger ("tango.servlets.File");
        }

        /***********************************************************************
        
                support GET requests only! All other method requests will
                return an error to the user-agent

        ***********************************************************************/

        void doGet (IServletRequest request, IServletResponse response)
        {   
                logger.info ("request for file: " ~ request.getUri.getPath);

                response.copyFile (request.getContext, request.getPathInfo);
        }
}


/*******************************************************************************

        Servlet to return a page echoing request-details sent to the server

*******************************************************************************/

class Echo : Servlet
{
        private static Logger logger;

        /***********************************************************************
        
                get a Logger for this class

        ***********************************************************************/

        static this ()
        {
                logger = Logger.getLogger ("tango.servlets.Echo");
        }

        /***********************************************************************

                Handle all the different request methods ...
        
        ***********************************************************************/

        void service (IServletRequest request, IServletResponse response)
        {   
                Uri uri = request.getUri;

                logger.info ("request for echo");

                // say we're writing html
                response.setContentType ("text/html");

                // wrap an HtmlWriter around the response output ...
                HtmlWriter output = new HtmlWriter(response.getWriter);

                // write HTML preamble ...
                output ("<HTML><HEAD><TITLE>Echo</TITLE></HEAD><BODY>"c);

                // log everything to the output
                output ("------------------------"c).cr()
                       ("Uri: "c) (uri).cr()
                       ("------------------------"c).cr()
                       ("Headers:"c).cr()
                       (request.getHeaders)
                       ("------------------------"c).cr()
                       ("Cookies:"c).cr()
                       (request.getCookies)
                       ("------------------------"c).cr()
                       ("Parameters:"c).cr()
                       (request.getParameters)
                       ("------------------------"c).cr();

                // display the Servlet environment
                output ("encoding: "c) (request.getCharacterEncoding).cr()
                       ("content length: "c) (request.getContentLength).cr()
                       ("content type: "c) (request.getContentType).cr()                   
                       ("protocol: "c) (request.getProtocol).cr()                   
                       ("scheme: "c) (uri.getScheme).cr()                   
                       ("method: "c) (request.getMethod).cr()                   
                       ("host name: "c) (request.getServerName).cr()                   
                       ("host port: "c) (request.getServerPort).cr()                   
                       ("remote address: "c) (request.getRemoteAddress).cr()                   
                       ("remote host: "c) (request.getRemoteHost).cr()                   
                       ("path info: "c) (request.getPathInfo).cr()                   
                       ("query: "c) (uri.getQuery).cr()                   
                       ("path: "c) (uri.getPath).cr()                   
                       ("context path: "c) (request.getContextPath).cr().cr().cr();  

                // write HTML closure
                output("</BODY></HTML>"c);
        }
}


/*******************************************************************************

        Create an http server with the given IProvider. Wait for console
        input, then quit.

*******************************************************************************/

void testServer (IProvider provider)
{       
        mainLogger.info ("starting server");

        // bind to port 80 on a local address
        InternetAddress addr = new InternetAddress (80);

        // create a (1 thread) server using the IProvider to service requests
        HttpServer server = new HttpServer (provider, addr, 1, mainLogger);
        
        // start listening for requests (but this thread does not listen)
        server.start ();

        // send this thread to sleep for ever ...
        System.sleep ();

        // should never get here
        mainLogger.info ("halting server");
}


/*******************************************************************************

        Test the servlet wrapper. We have three servlets that we map to
        various request paths. We take advantage of a 'default' context
        to serve up pages from the Mango help files.

*******************************************************************************/

void testServletEngine ()
{       
        mainLogger.info ("registering servlets");

        // construct a servlet-provider
        ServletProvider sp = new ServletProvider();

        // create a context for example servlets
        ServletContext example = sp.addContext (new ServletContext ("/example"));

        // create a context for admin servlets
        ServletContext admin = sp.addContext (new AdminContext (sp, "/admin"));

        // map echo requests to our echo servlet
        sp.addMapping ("/echo", sp.addServlet (new Echo, "echo", example));

        // point the default context to the mango help files
        sp.addContext (new ServletContext ("", "../doc/html"));

        // map all other requests to our file servlet
        sp.addMapping ("/", sp.addServlet (new FileServlet, "files"));
        
        // fire up a server
        testServer (sp);
}

/*******************************************************************************


*******************************************************************************/

int main ()
{   
        BasicConfigurator.configure ();
        mainLogger = Logger.getLogger ("tango.servlets");
        mainLogger.setLevel (mainLogger.Level.Info);

        try {
            testServletEngine();

            mainLogger.info ("Done");
            } catch (Exception x)
                    {
                    mainLogger.error (x.msg);
                    }
        return 0;
}

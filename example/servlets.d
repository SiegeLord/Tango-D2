/******************************************************************************

        @file servlets.d

        Here's some contrived servlets to give you an idea what Tango plus
        Mango does.

        Point your Browser at http://127.0.0.1 and try the following paths:

        1) /example/echo should return a bunch of diagnostic stuff back to
           the browser

        2) /admin/logger allows you to modify current Loggers and Levels,
           as well as the ability to create new Logger/Level combinations.

        3) all other paths are mapped to a file-request handler. Requesting
           /index.html should return the doxygen page for Tango; all other
           links should operate correctly. Be sure to start the executable
           from the example directory, otherwise you'll probably run into
           404-Not-Found errors.


        Kris, May 2nd 2004
        Scott Sanders, June 1, 2004

*******************************************************************************/

        // for sleep()
import  tango.core.Thread;

        //for logging
import  tango.util.log.Log,
        tango.util.log.Configurator;

        // for html responses
import  tango.io.protocol.Writer;
import  tango.io.protocol.PrintProtocol;

        // for testing the http server
import  mango.net.http.server.HttpServer;

        // for testing the servlet-engine
import  mango.net.servlet.Servlet,
        mango.net.servlet.ServletContext,
        mango.net.servlet.ServletProvider;

        // hook up the log Administrator
import  mango.net.servlet.tools.AdminServlet;


        // setup a logger for module scope
private Logger mainLogger;


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
                logger = Log.getLogger ("tango.servlets.File");
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
                logger = Log.getLogger ("tango.servlets.Echo");
        }

        /***********************************************************************

                Handle all the different request methods ...

        ***********************************************************************/

        void service (IServletRequest request, IServletResponse response)
        {
                auto uri = request.getUri();

                logger.info ("request for echo");

                // say we're writing html
                response.setContentType ("text/html");

                // wrap a Writer around the response output ...
                auto output = new Writer(new PrintProtocol (response.getWriter.buffer));
                output.newline ("<br>\r\n");

                // write HTML preamble ...
                output ("<HTML><HEAD><TITLE>Echo</TITLE></HEAD><BODY>"c);

                // log everything to the output
                output ("------------------------"c).newline()
                       ("Uri: "c) (uri.toUtf8).newline()
                       ("------------------------"c).newline()
                       ("Headers:"c).newline()
                       (request.getHeaders)
                       ("------------------------"c).newline()
                       ("Cookies:"c).newline()
                       (request.getCookies)
                       ("------------------------"c).newline()
                       ("Parameters:"c).newline()
                       (request.getParameters)
                       ("------------------------"c).newline();

                // display the Servlet environment
                output ("encoding: "c) (request.getCharacterEncoding).newline()
                       ("content length: "c) (request.getContentLength).newline()
                       ("content type: "c) (request.getContentType).newline()
                       ("protocol: "c) (request.getProtocol).newline()
                       ("scheme: "c) (uri.getScheme).newline()
                       ("method: "c) (request.getMethod).newline()
                       ("host name: "c) (request.getServerName).newline()
                       ("host port: "c) (request.getServerPort).newline()
                       ("remote address: "c) (request.getRemoteAddress).newline()
                       ("remote host: "c) (request.getRemoteHost).newline()
                       ("path info: "c) (request.getPathInfo).newline()
                       ("query: "c) (uri.getQuery).newline()
                       ("path: "c) (uri.getPath).newline()
                       ("context path: "c) (request.getContextPath).newline().newline().newline();

                // write HTML closure
                output("</BODY></HTML>"c);
        }
}


/*******************************************************************************

        Create an http server with the given ServiceProvider. Wait for console
        input, then quit.

*******************************************************************************/

void testServer (ServletProvider provider)
{
        mainLogger.info ("starting server");

        // bind to port 80 on a local address
        auto addr = new InternetAddress (8080);

        // create a (1 thread) server using the ServiceProvider to service requests
        auto server = new HttpServer (provider, addr, 1, mainLogger);

        // start listening for requests (but this thread does not listen)
        server.start;

        // send this thread to sleep for ever ...
        Thread.sleep;

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
        auto sp = new ServletProvider;

        // create a context for example servlets
        auto example = sp.addContext (new ServletContext ("/example"));

        // create a context for admin servlets
        auto admin = sp.addContext (new AdminContext (sp, "/admin"));

        // map echo requests to our echo servlet
        sp.addMapping ("/echo", sp.addServlet (new Echo, "echo", example));

        // point the default context to the tango help files
        sp.addContext (new ServletContext ("", "../doc/html"));

        // map all other requests to our file servlet
        sp.addMapping ("/", sp.addServlet (new FileServlet, "files"));

        // fire up a server
        testServer (sp);
}

/*******************************************************************************


*******************************************************************************/

void main ()
{
        Configurator ();
        mainLogger = Log.getLogger ("tango.servlets");
        mainLogger.setLevel (mainLogger.Level.Info);
            testServletEngine();

        try {
            testServletEngine();

            mainLogger.info ("Done");
            } catch (Exception x)
                     mainLogger.error (x.toUtf8);
}

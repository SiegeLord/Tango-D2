
private import  tango.net.Socket;

private import  tango.sys.System;

private import  tango.log.Admin,
                tango.log.Logger,
                tango.log.Configurator;

private import  tango.servlet.Servlet,
                tango.servlet.ServletContext,
                tango.servlet.ServletProvider;

private import  tango.net.http.server.HttpServer;

private import  tango.cluster.qos.socket.ClusterServer;

/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");


/*******************************************************************************

        How to instantiate a cluster server. There's an optional section
        that also fires up a servlet-server with the Logger Administrator
        hooked in. From a browser you'd use http://127.0.0.1/admin/logger
        to reach the adminstrator.

*******************************************************************************/

void main()
{
        // configure the main logger
        BasicConfigurator.configure ();
        Logger logger = Logger.getLogger ("example.cserver");

        // fire up a cluster server on the specified port
        ClusterServer cs = new ClusterServer (new InternetAddress(4567), 1, logger);
        cs.start ();

        /**************** optional admin servlet support **********************/
        version (UseLoggerAdministrator)
                {
                // construct a servlet-provider
                ServletProvider sp = new ServletProvider();

                // create a context for admin servlets
                ServletContext admin = sp.addContext (new AdminContext (sp, "/admin"));

                // create a (1 thread) server using the IProvider to service requests
                // and start listening for requests (but this thread does not listen)
                HttpServer server = new HttpServer (sp, new InternetAddress (80), 1, logger);
                server.start ();
                }

        logger.info  ("awaiting requests: press <ctrl-c> to quit");
        System.sleep ();
}

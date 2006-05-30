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
        tango.io.Socket,
        tango.io.Exception,
        tango.io.FileBucket,
        tango.io.DisplayWriter,
        tango.io.PickleRegistry;

        // for numeric conversion
import  tango.convert.Integer;

        // for threads
import  tango.sys.System;

        //for logging
import  tango.log.Admin,
        tango.log.Logger,
        tango.log.Configurator;

        // for testing the http server
import  tango.http.server.HttpServer;

        // for testing the http client
import  tango.http.client.HttpClient;

        // for testing the servlet-engine
import  tango.servlet.Servlet,
        tango.servlet.ServletContext,
        tango.servlet.ServletProvider;

        // for working with cache entries
import  tango.cache.Payload,
        tango.cache.VirtualCache;

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

        A truly contrived example of server-side state management, and 
        client-side http requests.

*******************************************************************************/

class Ping : Servlet
{
        private static VirtualCache cache;
        private static FileBucket   bucket;
        private static PingThread   thread;
        private static int          ping_id;

        /***********************************************************************

                A Thread subclass to monitor external web-pages

        ***********************************************************************/

        static class PingThread
        {       
                bool                    halt;
                ulong                   time;
                int                     delta;
                int                     pause,
                                        content;

                HttpClient              client;
                Logger                  logger;


                /**************************************************************

                **************************************************************/

                this (MutableUri uri, int pause)
                {
                        // get a Logger for this class
                        logger = Logger.getLogger ("tango.servlets.PingThread");

                        this.pause = pause;
                        client = new HttpClient (HttpClient.Head, uri);
                }

                /**************************************************************

                        Check the provided URL now and then to see if it
                        has changed ...
        
                **************************************************************/

                version (Ares) 
                         alias void ThreadReturn;
                      else
                         alias int ThreadReturn;

                ThreadReturn run()
                {
                        while (true)
                               try {

                                   // should we bail out?
                                   if (halt)
                                       return 0;

                                   // reset, and set up a Host header
                                   client.reset ();
                                   client.getRequestHeaders.add (HttpHeader.Host, client.getUri.getHost);

                                   // make request
                                   client.open ();

                                   // close connection
                                   client.close ();

                                   // check return status for validity
                                   if (client.isResponseOK)
                                      {
                                      // extract modifed date (be aware of -1 return, for no header)
                                      ulong time = client.getResponseHeaders.getDate (HttpHeader.LastModified);
                                      if (time != -1)
                                         { 
                                         if (time > this.time)
                                            {
                                            this.time = time;
                                            ++delta;
                                            }
                                         }
                                      else
                                         {
                                         int content = client.getResponseHeaders.getInt (HttpHeader.ContentLength);
                                         if (content != this.content)
                                            {
                                            this.content = content;
                                            ++delta;
                                            }
                                         }
                                      }

                                   // see if tracing is enabled before doing a bunch of work
                                   if (logger.isEnabled (logger.Level.Trace))
                                      {
                                      char[16] tmp;
                                      logger.trace (Integer.format (tmp, delta));

                                      foreach (HeaderElement header; client.getResponseHeaders())
                                              {
                                              logger.trace (header.name.value ~ header.value);
                                              }
                                      }

                                   // sleep for a few seconds 
                                   System.sleep (pause);

                                   } catch (IOException x)
                                            logger.error ("IOException: " ~ x.toString);

                                     catch (Object x)
                                            logger.fatal ("Fatal: " ~ x.toString);
                        return 0;
                }
        }


        /***********************************************************************

                Each unique requesting IP address has one of these 
                maintained on the server in a cache. When the cache 
                fills up, LRU entries are spooled out to disk. The
                next request for an 'old' entry will cause it to be
                resurrected from disk storage, with state intact.

        ***********************************************************************/

        private static class PingEntry : Payload
        {
                // these are serialized
                long            delta;
                int             count;

                /***************************************************************

                        Reset our state via the provided reader

                ***************************************************************/

                override void read (IReader input)
                {
                        input (count) (delta);
                }

                /***************************************************************

                        Save our state via the provided writer

                ***************************************************************/

                override void write (IWriter output)
                {
                        output (count) (delta);
                }

                /***************************************************************

                        ISerializable factory; used for creating new 
                        class instances, which are then primed with
                        previously saved state.

                ***************************************************************/

                override Object create (IReader reader)
                {
                        PingEntry p = new PingEntry;
                        p.read (reader);
                        return p;
                }

                /***************************************************************

                        Return a network identifier for serializing this 
                        class. 

                ***************************************************************/

                override char[] getGuid()
                {
                        return this.classinfo.name;
                }
        }


        /***********************************************************************

                Initialize the Ping environment 

        ***********************************************************************/

        static this()
        {
                // create a file bucket for serialized PingEntry instances
                bucket = new FileBucket (new FilePath("bucket.bin"), FileBucket.HalfK);

                // create a VirtualCache to host popular PingEntry instances.
                // When the cache fills, LRU entries get flushed out to disk, 
                // and then retrieved and resurrected as necessary.
                cache = new VirtualCache (bucket, 101);

                // enroll the PingEntry for serialization
                PickleRegistry.enroll (new PingEntry);

                // create a thread to poll Google News for changes ...
                thread = new PingThread (new MutableUri ("http", "news.google.com", "/", null), 
                                                          System.Interval.Second * 30);
                System.createThread (&thread.run, true);
        }

        /***********************************************************************

                clean up when we're done

        ***********************************************************************/

        static ~this()
        {
                thread.halt = true;
                bucket.close ();
        }

        /***********************************************************************

                handle all service requests

        ***********************************************************************/

        void service (IServletRequest request, IServletResponse response)
        {   
                PingEntry ping;

                // log an info message
                Logger.getLogger ("tango.servlets.Ping").info ("request for ping");

                // get the remote ip-address
                char[] ua = request.getRemoteAddress;

                // protect against thread collisions ...
                synchronized (cache)
                             {
                             // seen this address before?
                             ping = cast(PingEntry) cache.get (ua);
                             if (ping is null)
                                 // nope; create new one
                                 cache.put (ua, ping = new PingEntry);
                             }

                // bump ping count
                ++ping.count;

                // has Google news been updated?
                long changes = thread.delta - ping.delta;
                ping.delta = thread.delta;

                // say we're writing html
                response.setContentType ("text/html");

                // grab the response writer ...
                IWriter output = response.getWriter;

                // write HTML page ...
                output ("<HTML><HEAD><TITLE>Ping</TITLE></HEAD><BODY>"c)
                       ("You've visited this page "c)
                       (ping.count)
                       (" times. Google News has had "c)
                       (changes)
                       (" update(s) since your last visit."c)
                       ("</BODY></HTML>"c);
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

        // map ping requests to our ping servlet
        sp.addMapping ("/ping", sp.addServlet (new Ping, "ping", example));

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

/*******************************************************************************

        @file HttpClient.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, April 2004      

        @author         Kris    - original module
                        h3r3tic - fixed a number of Post issues and
                                  bugs in the 'params' construction

        Redirection handling guided via 
                    http://ppewww.ph.gla.ac.uk/~flavell/www/post-redirect.html

*******************************************************************************/

module tango.net.http.HttpClient;

private import  tango.core.System;

private import  tango.io.Uri,
                tango.io.Buffer,
                tango.io.Writer,
                tango.io.Exception;

private import  tango.convert.Atoi;

private import  tango.net.SocketConduit;

private import  tango.text.LineIterator;

private import  tango.net.http.HttpParams,  
                tango.net.http.HttpWriter,
                tango.net.http.HttpHeaders,
                tango.net.http.HttpTriplet,
                tango.net.http.HttpCookies,                
                tango.net.http.HttpResponses;
              
/*******************************************************************************

        Supports the basic needs of a client making requests of an HTTP
        server. The following is an example of how this might be used:

        @code
        // callback for client reader
        void sink (char[] content)
        {
                Stdout.put (content);
        }

        // create client for a GET request
        auto client = new HttpClient (HttpClient.Get, "http://www.yahoo.com");

        // make request
        client.open ();

        // check return status for validity
        if (client.isResponseOK)
           {
           // extract content length
           int length = client.getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);
        
           // display all returned headers
           Stdout.put (client.getResponseHeaders);
        
           // display remaining content
           client.read (&sink, length);
           }
        else
           Stderr.put (client.getResponse);

        client.close ();
        @endcode

*******************************************************************************/

class HttpClient
{       
        // this is struct rather than typedef to avoid compiler bugs
        private struct RequestMethod
        {
                final char[]            name;
        }    
                        
        // class members; there's a surprising amount of stuff here!
        private MutableUri              uri;
        private IBuffer                 tmp,
                                        input,
                                        output;
        private SocketConduit           socket;
        private RequestMethod           method;
        private InternetAddress         address;
        private HttpMutableParams       paramsOut;
        private HttpHeaders             headersIn;
        private HttpMutableHeaders      headersOut;
        private HttpMutableCookies      cookiesOut;
        private ResponseLine            responseLine;

        // should we perform internal redirection?
        private bool                    doRedirect = true;

        // default to three second timeout on read operations ...
        protected const DefaultReadTimeout = System.Interval.Second * 3;

        // use HTTP v1.0 ?
        private static const char[] DefaultHttpVersion = "HTTP/1.0";

        // standard set of request methods ...
        static const RequestMethod      Get = {"GET"},
                                        Put = {"PUT"},
                                        Head = {"HEAD"},
                                        Post = {"POST"},
                                        Trace = {"TRACE"},
                                        Delete = {"DELETE"},
                                        Options = {"OPTIONS"},
                                        Connect = {"CONNECT"};

        /***********************************************************************
        
                Create a client for the given URL. The argument should be
                fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided.

        ***********************************************************************/

        this (RequestMethod method, char[] url)
        {
                this (method, new MutableUri(url));
        }

        /***********************************************************************
        
                Create a client with the provided Uri instance. The Uri should 
                be fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided. 

        ***********************************************************************/

        this (RequestMethod method, MutableUri uri)
        {
                this.uri = uri;
                this.method = method;

                responseLine = new ResponseLine ();
                headersIn    = new HttpHeaders  ();

                tmp          = new Buffer (1024 * 1);
                paramsOut    = new HttpMutableParams  (new Buffer (1024 * 1));
                headersOut   = new HttpMutableHeaders (new Buffer (1024 * 4));
                cookiesOut   = new HttpMutableCookies (headersOut);

                // decode the host name (may take a second or two)
                auto host = uri.getHost ();
                if (host)
                    address = new InternetAddress (host, uri.getValidPort());
                else
                   responseLine.error ("invalid url provided to HttpClient ctor");
        }

        /***********************************************************************
        
                Get the current input headers, as returned by the host request.

        ***********************************************************************/

        HttpHeaders getResponseHeaders()
        {
                return headersIn;
        }

        /***********************************************************************
        
                Gain access to the request headers. Use this to add whatever
                headers are required for a request. 

        ***********************************************************************/

        HttpMutableHeaders getRequestHeaders()
        {
                return headersOut;
        }

        /***********************************************************************
        
                Gain access to the request parameters. Use this to add x=y
                style parameters to the request. These will be appended to
                the request assuming the original Uri does not contain any
                of its own.

        ***********************************************************************/

        HttpMutableParams getRequestParams()
        {
                return paramsOut;
        }

        /***********************************************************************
        
                Return the Uri associated with this client

        ***********************************************************************/

        Uri getUri()
        {
                return uri;
        }

        /***********************************************************************
        
                Return the response-line for the latest request. This takes 
                the form of "version status reason" as defined in the HTTP
                RFC.

        ***********************************************************************/

        ResponseLine getResponse()
        {
                return responseLine;
        }

        /***********************************************************************
        
                Return the HTTP status code set by the remote server

        ***********************************************************************/

        int getStatus()
        {
                return responseLine.getStatus();
        }

        /***********************************************************************
        
                Return whether the response was OK or not

        ***********************************************************************/

        bool isResponseOK()
        {
                return cast(bool) (getStatus() is HttpResponseCode.OK);
        }

        /***********************************************************************
        
                Add a cookie to the outgoing headers

        ***********************************************************************/

        void addCookie (Cookie cookie)
        {
                cookiesOut.add (cookie);
        }

        /***********************************************************************
        
                Close all resources used by a request. You must invoke this 
                between successive open() calls.

        ***********************************************************************/

        void close ()
        {
                if (socket)
                   {
                   socket.shutdown ();
                   socket.close ();
                   socket = null;
                   }
        }

        /***********************************************************************

                Reset the client such that it is ready for a new request.
        
        ***********************************************************************/

        void reset ()
        {
                headersIn.reset();
                headersOut.reset();
                paramsOut.reset();
        }

        /***********************************************************************

                enable/disable the internal redirection suppport
        
        ***********************************************************************/

        void enableRedirect (bool yes)
        {
                doRedirect = yes;
        }

        /***********************************************************************

                Overridable method to create a Socket. You may find a need 
                to override this for some purpose; perhaps to add input or 
                output filters.
                 
        ***********************************************************************/

        protected SocketConduit createSocket ()
        {
                return new TextSocketConduit;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected IBuffer inputBuffer (IConduit conduit)
        {
                return new Buffer (conduit);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected IBuffer outputBuffer (IConduit conduit)
        {
                return new Buffer (conduit);
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor,
                using a callback for pumping additional data to the host. This 
                defaults to a three-second timeout period. The return value 
                represents the input buffer, from which all returned headers 
                and content may be accessed.
                
        ***********************************************************************/

        IBuffer open (IWritable pump)
        {
                return open (DefaultReadTimeout, pump);
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor,
                using the specified timeout period (in milli-seconds).The 
                return value represents the input buffer, from which all
                returned headers and content may be accessed.
                
        ***********************************************************************/

        IBuffer open (uint timeout = DefaultReadTimeout)
        {
                return open (timeout, null);
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor
                using the specified timeout period (in micro-seconds), and a
                user-defined callback for pumping additional data to the host.
                The callback would be used when uploading data during a 'put'
                operation (or equivalent). The return value represents the 
                input buffer, from which all returned headers and content may 
                be accessed.
                
        ***********************************************************************/

        IBuffer open (uint timeout, IWritable pump)
        {
                return open (timeout, pump, method);
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor
                using the specified timeout period (in micro-seconds), and a
                user-defined callback for pumping additional data to the host.
                The callback would be used when uploading data during a 'put'
                operation (or equivalent). The return value represents the 
                input buffer, from which all returned headers and content may 
                be accessed.

                Note that certain request-headers may generated automatically
                if they are not present. These include a Host header and, in
                the case of Post, both ContentType & ContentLength for a query
                type of request. The latter two are *not* produced for Post
                requests with 'pump' specified ~ when using 'pump' to output
                additional content, you must explicitly set your own headers.
                
        ***********************************************************************/
//import tango.io.Stdout;

        private IBuffer open (uint timeout, IWritable pump, RequestMethod method)
        {
                // create socket, and connect it 
                socket = createSocket;
                try {
                    socket.setTimeout (timeout);
                    socket.connect (address);

                    // create buffers for input and output
                    input  = inputBuffer  (socket);
                    output = outputBuffer (socket);

                    // bind a writer to the output
                    auto emit = new HttpWriter (output);

                    // setup a Host header
                    if (headersOut.get (HttpHeader.Host, null) is null)
                        headersOut.add (HttpHeader.Host, uri.getHost);

                    // http/1.0 needs connection:close
                    headersOut.add (HttpHeader.Connection, "close");

                    // attach/extend query parameters if user has added some
                    tmp.clear();
                    char[] query = uri.extendQuery (paramsOut.formatTokens(tmp, "&"));

                    // patch request path?
                    char[] path = uri.getPath;
                    if (path.length is 0)
                        path = "/";

                    // format request 
                    emit (method.name)
                         (' ')
                         (path);

                    // should we emit query as part of request line?
                    if (query.length)
                        if (method is Get)
                            emit ('?') (query);
                        else 
                           if (method is Post && pump is null)
                              {
                              if (headersOut.get (HttpHeader.ContentType, null) is null)
                                  headersOut.add (HttpHeader.ContentType, "application/x-www-form-urlencoded");

                              if (headersOut.get   (HttpHeader.ContentLength, null) is null)
                                 headersOut.addInt (HttpHeader.ContentLength, query.length);
                              }
                    
                    // complete the request line, and emit headers too
                    emit (' ')
                         (DefaultHttpVersion)
                         (emit.eol)
                         (headersOut)
                         (emit.eol);

                    // user has additional data to send?
                    if (pump)
                        pump.write (emit);
                    else
                       // send POST data?
                       if (method is Post && query.length)
                           emit (query);

                    // send entire request
                    emit.flush ();

                    // Token for initial parsing of input header lines
                    auto line = new LineIterator (input);

                    // skip any blank lines
                    while (line.next && line.get.length is 0) 
                          {}

                    // throw if we experienced a timeout
                    if (socket.hadTimeout)
                        responseLine.error ("response timeout");

                    // is this a bogus request?
                    if (line.get.length is 0)
                        responseLine.error ("truncated response");

                    // read response line
                    responseLine.parse (line.get);

                    // parse headers
                    headersIn.reset ();
                    headersIn.parse (input);

                    // check for redirection
                    if (doRedirect)
                        switch (responseLine.getStatus)
                               {
                               case HttpResponseCode.SeeOther:
                               case HttpResponseCode.MovedPermanently:
                               case HttpResponseCode.MovedTemporarily:
                               case HttpResponseCode.TemporaryRedirect:
                                    // drop this connection
                                    close();

                                    // reset the uri because parse() won't do it
                                    //uri.reset();

                                    // remove any existing Host header
                                    headersOut.remove (HttpHeader.Host);

                                    // parse redirected uri
                                    auto redirect = headersIn.get (HttpHeader.Location, "[missing url]");
                                    uri.relParse (redirect);

                                    //Stdout ("redirecting to "c) (uri) (CR) ();

                                    // decode the host name (may take a second or two)
                                    auto host = uri.getHost();
                                    if (host)
                                        address = new InternetAddress (uri.getHost(), uri.getValidPort());
                                    else
                                       responseLine.error ("redirect has invalid url: "~redirect);

                                    // figure out what to do
                                    if (method is Get || method is Head)
                                        return open (timeout, pump, method);
                                    else
                                       if (method is Post)
                                           return redirectPost (timeout, pump, responseLine.getStatus);
                                       else
                                          responseLine.error ("unexpected redirect for method "~method.name);
                               default:
                                    break;
                               }

                    // return the input buffer
                    return input;
                    } catch (Exception e)
                            {
                            // close *only* when we get an exception
                            close();
                            throw e;
                            }
        }

        /***********************************************************************
        
        ***********************************************************************/

        void read (void delegate (char[]) sink, long length = long.max)
        {
                do {
                   length -= input.readable;
                   sink (input.toString);
                   input.clear ();
                   } while (length > 0 && input.fill() != socket.Eof);
        }

        /***********************************************************************
        
                Handle redirection of Post
                
                Guidance for the default behaviour came from this page: 
                http://ppewww.ph.gla.ac.uk/~flavell/www/post-redirect.html

        ***********************************************************************/

        IBuffer redirectPost (uint timeout, IWritable pump, int status)
        {
                switch (status)
                       {
                            // use Get method to complete the Post
                       case HttpResponseCode.SeeOther:
                       case HttpResponseCode.MovedTemporarily:

                            // remove POST headers first!
                            headersOut.remove (HttpHeader.ContentLength);
                            headersOut.remove (HttpHeader.ContentType);
                            paramsOut.reset ();
                            return open (timeout, null, Get);

                            // try entire Post again, if user say OK
                       case HttpResponseCode.MovedPermanently:
                       case HttpResponseCode.TemporaryRedirect:
                            if (canRepost (status))
                                return open (timeout, pump, this.method);
                            // fall through!

                       default:
                            responseLine.error ("Illegal redirection of Post");
                       }
                return null;
        }

        /***********************************************************************
        
                Handle user-notification of Post redirection. This should
                be overridden appropriately.

                Guidance for the default behaviour came from this page: 
                http://ppewww.ph.gla.ac.uk/~flavell/www/post-redirect.html

        ***********************************************************************/

        bool canRepost (uint status)
        {
                return false;
        }
}


/******************************************************************************

        Class to represent an HTTP response-line

******************************************************************************/

private class ResponseLine : HttpTriplet
{
        private char[]          vers,
                                reason;
        private int             status;

        /**********************************************************************

                test the validity of these tokens

        **********************************************************************/

        void test ()
        {
                vers = tokens[0];
                reason = tokens[2];
                status = cast(int) Atoi.convert (tokens[1]);
                if (status is 0)
                   {
                   status = cast(int) Atoi.convert (tokens[2]);
                   if (status is 0)
                       error ("Invalid HTTP response: '"~tokens[0]~"' '"~tokens[1]~"' '" ~tokens[2] ~"'");
                   }
        }

        /**********************************************************************

                Return HTTP version

        **********************************************************************/

        char[] getVersion ()
        {
                return vers;
        }

        /**********************************************************************

                Return reason text

        **********************************************************************/

        char[] getReason ()
        {
                return reason;
        }

        /**********************************************************************

                Return status integer

        **********************************************************************/

        int getStatus ()
        {
                return status;
        }
}

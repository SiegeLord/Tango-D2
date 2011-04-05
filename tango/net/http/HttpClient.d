/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
                        Outback release: December 2006
        
        author:         Kris    - original module
        author:         h3r3tic - fixed a number of Post issues and
                                  bugs in the 'params' construction

        Redirection handling guided via 
                    http://ppewww.ph.gla.ac.uk/~flavell/www/post-redirect.html

*******************************************************************************/

module tango.net.http.HttpClient;

private import  tango.time.Time;
                
private import  tango.net.Uri,
                tango.net.device.Socket,
                tango.net.InternetAddress;

private import  tango.io.device.Array;

private import  tango.io.stream.Lines;
private import  tango.io.stream.Buffered;

private import  tango.net.http.HttpConst,
                tango.net.http.HttpParams,  
                tango.net.http.HttpHeaders,
                tango.net.http.HttpTriplet,
                tango.net.http.HttpCookies;

private import  tango.core.Exception : IOException;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        Supports the basic needs of a client making requests of an HTTP
        server. The following is an example of how this might be used:

        ---
        // callback for client reader
        void sink (void[] content)
        {
                Stdout (cast(char[]) content);
        }

        // create client for a GET request
        auto client = new HttpClient (HttpClient.Get, "http://www.yahoo.com");

        // make request
        client.open;

        // check return status for validity
        if (client.isResponseOK)
           {
           // extract content length
           auto length = client.getResponseHeaders.getInt (HttpHeader.ContentLength);
        
           // display all returned headers
           Stdout (client.getResponseHeaders);
        
           // display remaining content
           client.read (&sink, length);
           }
        else
           Stderr (client.getResponse);

        client.close;
        ---

        See modules HttpGet and HttpPost for simple wrappers instead.

*******************************************************************************/

class HttpClient
{       
        /// callback for sending PUT content
        alias void delegate (OutputBuffer) Pump;
        
        // this is struct rather than typedef to avoid compiler bugs
        private struct RequestMethod
        {
                final char[]            name;
        }    
                        
        // class members; there's a surprising amount of stuff here!
        private Uri                     uri;
        private BufferedInput           input;
        private BufferedOutput          output;
        private Array                   tokens;
        private Lines!(char)            line;
        private Socket                  socket;
        private RequestMethod           method;
        private InternetAddress         address;
        private HttpParams              paramsOut;
        private HttpHeadersView         headersIn;
        private HttpHeaders             headersOut;
        private HttpCookies             cookiesOut;
        private ResponseLine            responseLine;

        // default to three second timeout on read operations ...
        private float                   timeout = 3.0;

        // enable uri encoding?
        private bool                    encode = true;

        // should we perform internal redirection?
        private bool                    doRedirect = true;

        // attempt keepalive? 
        private bool                    keepalive = false;

        // limit the number of redirects, or catch circular redirects
        private uint                    redirections, 
                                        redirectionLimit = 5;

        // the http version being sent with requests
        private char[]                  httpVersion;

        // http version id
        public enum Version {OnePointZero, OnePointOne};

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
                this (method, new Uri(url));
        }

        /***********************************************************************
        
                Create a client with the provided Uri instance. The Uri should 
                be fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided. 

        ***********************************************************************/

        this (RequestMethod method, Uri uri)
        {
                this.uri = uri;
                this.method = method;

                responseLine = new ResponseLine;
                headersIn    = new HttpHeadersView;
                tokens       = new Array (1024 * 4);

                input        = new BufferedInput  (null, 1024 * 16);
                output       = new BufferedOutput (null, 1024 * 16);

                paramsOut    = new HttpParams;
                headersOut   = new HttpHeaders;
                cookiesOut   = new HttpCookies (headersOut, HttpHeader.Cookie);

                // decode the host name (may take a second or two)
                auto host = uri.getHost;
                if (host)
                    address = new InternetAddress (host, uri.getValidPort);
                else
                   error ("invalid url provided to HttpClient ctor");

                paramsOut.parse(new Array(uri.query)); 
                
                // default the http version to 1.0
                setVersion (Version.OnePointZero);
        }

        /***********************************************************************
        
                Get the current input headers, as returned by the host request.

        ***********************************************************************/

        HttpHeadersView getResponseHeaders()
        {
                return headersIn;
        }

        /***********************************************************************
        
                Gain access to the request headers. Use this to add whatever
                headers are required for a request. 

        ***********************************************************************/

        HttpHeaders getRequestHeaders()
        {
                return headersOut;
        }

        /***********************************************************************
        
                Gain access to the request parameters. Use this to add x=y
                style parameters to the request. These will be appended to
                the request assuming the original Uri does not contain any
                of its own.

        ***********************************************************************/

        HttpParams getRequestParams()
        {
                return paramsOut;
        }

        /***********************************************************************
        
                Return the Uri associated with this client

        ***********************************************************************/

        UriView getUri()
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
                return responseLine.getStatus;
        }

        /***********************************************************************
        
                Return whether the response was OK or not

        ***********************************************************************/

        bool isResponseOK()
        {
                return getStatus is HttpResponseCode.OK;
        }

        /***********************************************************************
        
                Add a cookie to the outgoing headers

        ***********************************************************************/

        HttpClient addCookie (Cookie cookie)
        {
                cookiesOut.add (cookie);
                return this;
        }

        /***********************************************************************
        
                Close all resources used by a request. You must invoke this 
                between successive open() calls.

        ***********************************************************************/

        void close ()
        {
                if (socket)
                   {
                   socket.shutdown;
                   socket.detach;
                   socket = null;
                   }
        }

        /***********************************************************************

                Reset the client such that it is ready for a new request.
        
        ***********************************************************************/

        HttpClient reset ()
        {
                headersIn.reset;
                headersOut.reset;
                paramsOut.reset;
                redirections = 0;
                return this;
        }

        /***********************************************************************
        
                Set the request method

        ***********************************************************************/

        HttpClient setRequest (RequestMethod method)
        {
                this.method = method;
                return this;
        }

        /***********************************************************************
        
                Set the request version

        ***********************************************************************/

        HttpClient setVersion (Version v)
        {
                static const char[][] versions = ["HTTP/1.0", "HTTP/1.1"];

                httpVersion = versions[v];
                return this;
        }

        /***********************************************************************

                enable/disable the internal redirection suppport
        
        ***********************************************************************/

        HttpClient enableRedirect (bool yes = true)
        {
                doRedirect = yes;
                return this;
        }

        /***********************************************************************

                set timeout period for read operation
        
        ***********************************************************************/

        HttpClient setTimeout (float interval)
        {
                timeout = interval;
                return this;
        }

        /***********************************************************************

                Control keepalive option 

        ***********************************************************************/

        HttpClient keepAlive (bool yes = true)
        {
                keepalive = yes;
                return this;
        }

        /***********************************************************************

                Control Uri output encoding 

        ***********************************************************************/

        HttpClient encodeUri (bool yes = true)
        {
                encode = yes;
                return this;
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor,
                using the specified timeout period (in milli-seconds).The 
                return value represents the input buffer, from which all
                returned headers and content may be accessed.
                
        ***********************************************************************/

        InputBuffer open ()
        {
                return open (method, null);
        }

        /***********************************************************************
        
                Make a request for the resource specified via the constructor,
                using a callback for pumping additional data to the host. This 
                defaults to a three-second timeout period. The return value 
                represents the input buffer, from which all returned headers 
                and content may be accessed.
                
        ***********************************************************************/

        InputBuffer open (Pump pump)
        {
                return open (method, pump);
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

                Note also that IOException instances may be thrown. These 
                should be caught by the client to ensure a close() operation
                is always performed
                
        ***********************************************************************/

        InputBuffer open (RequestMethod method, Pump pump)
        {
            try {
                this.method = method;
                if (++redirections > redirectionLimit)
                    error ("too many redirections, or a circular redirection");

                // new socket for each request?
                if (keepalive is false)
                    close;

                // create socket and connect it. Retain prior socket if
                // not closed between calls
                if (socket is null)
                   {
                   socket = createSocket;
                   socket.timeout = cast(int)(timeout * 1000);
                   socket.connect (address);
                   }

                // setup buffers for input and output
                output.output (socket);
                input.input (socket);
                input.clear;

                // setup a Host header
                if (headersOut.get (HttpHeader.Host, null) is null)
                    headersOut.add (HttpHeader.Host, uri.getHost);

                // http/1.0 needs connection:close
                if (keepalive is false)
                    headersOut.add (HttpHeader.Connection, "close");

                // format encoded request 
                output.append (method.name)
                      .append (" ");

                // patch request path?
                auto path = uri.getPath;
                if (path.length is 0)
                    path = "/";

                // emit path
                if (encode)
                    uri.encode (&output.write, path, uri.IncPath);
                else
                   output.append (path);

                // attach/extend query parameters if user has added some
                tokens.clear;
                paramsOut.produce ((void[] p){if (tokens.readable) tokens.write("&"); 
                                    return uri.encode(&tokens.write, cast(char[]) p, uri.IncQuery);});
                auto query = cast(char[]) tokens.slice;

                // emit query?
                if (query.length)
                   {
                   output.append ("?").append(query);
                            
                   if (method is Post && pump.funcptr is null)
                      {
                      // we're POSTing query text - add default info
                      if (headersOut.get (HttpHeader.ContentType, null) is null)
                          headersOut.add (HttpHeader.ContentType, "application/x-www-form-urlencoded");

                      if (headersOut.get (HttpHeader.ContentLength, null) is null)
                         {
                         headersOut.addInt (HttpHeader.ContentLength, query.length);
                         pump = (OutputBuffer o){o.append(query);};
                         }
                      }
                   }
                
                // complete the request line, and emit headers too
                output.append (" ")
                      .append (httpVersion)
                      .append (HttpConst.Eol);

                headersOut.produce (&output.write, HttpConst.Eol);
                output.append (HttpConst.Eol);
                
                if (pump.funcptr)
                    pump (output);

                // send entire request
                output.flush;

                // Token for initial parsing of input header lines
                if (line is null)
                    line = new Lines!(char) (input);
                else
                   line.set(input);

                // skip any blank lines
                while (line.next && line.get.length is 0) 
                      {}

                // is this a bogus request?
                if (line.get.length is 0)
                    error ("truncated response");

                // read response line
                if (! responseLine.parse (line.get))
                      error (responseLine.error);

                // parse incoming headers
                headersIn.reset.parse (this.input);

                // check for redirection
                if (doRedirect)
                    switch (responseLine.getStatus)
                           {
                           case HttpResponseCode.Found:
                           case HttpResponseCode.SeeOther:
                           case HttpResponseCode.MovedPermanently:
                           case HttpResponseCode.TemporaryRedirect:
                                // drop this connection
                                close;

                                // remove any existing Host header
                                headersOut.remove (HttpHeader.Host);

                                // parse redirected uri
                                auto redirect = headersIn.get (HttpHeader.Location, "[missing Location header]");
                                uri.relParse (redirect.dup);

                                // decode the host name (may take a second or two)
                                auto host = uri.getHost;
                                if (host)
                                    address = new InternetAddress (uri.getHost, uri.getValidPort);
                                else
                                    error ("redirect has invalid url: "~redirect);

                                // figure out what to do
                                if (method is Get || method is Head)
                                    return open (method, pump);
                                else
                                   if (method is Post)
                                       return redirectPost (pump, responseLine.getStatus);
                                   else
                                      error ("unexpected redirect for method "~method.name);
                           default:
                                break;
                           }

                // return the input buffer
                return input;
                } finally {redirections = 0;}
        }

        /***********************************************************************
        
                Read the content from the returning input stream, up to a
                maximum length, and pass content to the given sink delegate
                as it arrives. 

                Exits when length bytes have been processed, or an Eof is
                seen on the stream.

        ***********************************************************************/

        void read (void delegate(void[]) sink, size_t len = size_t.max)
        {
                while (true)
                      {
                      auto content = input.slice;
                      if (content.length > len)
                         {
                         sink (content [0 .. len]);
                         input.skip (len);
                         break;
                         }
                      else
                         {
                         len -= content.length;
                         sink (content);
                         input.clear;
                         if (input.populate is input.Eof)
                             break;
                         }
                      }
        }

        /***********************************************************************
        
                Handle redirection of Post
                
                Guidance for the default behaviour came from this page: 
                http://ppewww.ph.gla.ac.uk/~flavell/www/post-redirect.html

        ***********************************************************************/

        InputBuffer redirectPost (Pump pump, int status)
        {
                switch (status)
                       {
                            // use Get method to complete the Post
                       case HttpResponseCode.Found:
                       case HttpResponseCode.SeeOther:

                            // remove POST headers first!
                            headersOut.remove (HttpHeader.ContentLength);
                            headersOut.remove (HttpHeader.ContentType);
                            paramsOut.reset;
                            return open (Get, null);

                            // try entire Post again, if user say OK
                       case HttpResponseCode.MovedPermanently:
                       case HttpResponseCode.TemporaryRedirect:
                            if (canRepost (status))
                                return open (this.method, pump);
                            // fall through!

                       default:
                            error ("Illegal redirection of Post");
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

        /***********************************************************************
        
                Overridable socket factory, for use with HTTPS and so on

        ***********************************************************************/

        protected Socket createSocket ()
        {
                return new Socket;
        }

        /**********************************************************************

                throw an exception, after closing the socket

        **********************************************************************/

        private void error (char[] msg)
        {
                close;
                throw new IOException (msg);
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

        override bool test ()
        {
                vers = tokens[0];
                reason = tokens[2];
                status = cast(int) Integer.convert (tokens[1]);
                if (status is 0)
                   {
                   status = cast(int) Integer.convert (tokens[2]);
                   if (status is 0)
                      {
                      failed = "Invalid HTTP response: '"~tokens[0]~"' '"~tokens[1]~"' '" ~tokens[2] ~"'";
                      return false;
                      }
                   }
                return true;
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


/******************************************************************************

******************************************************************************/

debug (HttpClient)
{
        import tango.io.Stdout;

        void main()
        {
        // callback for client reader
        void sink (void[] content)
        {
                Stdout (cast(char[]) content);
        }

        // create client for a GET request
        auto client = new HttpClient (HttpClient.Get, "http://www.microsoft.com");

        // make request
        client.open;

        // check return status for validity
        if (client.isResponseOK)
           {
           // display all returned headers
           foreach (header; client.getResponseHeaders)
                    Stdout.formatln ("{} {}", header.name.value, header.value);
        
           // extract content length
           auto length = client.getResponseHeaders.getInt (HttpHeader.ContentLength);
        
           // display remaining content
           client.read (&sink, length);
           }
        else
           Stderr (client.getResponse);

        client.close;
        }
}

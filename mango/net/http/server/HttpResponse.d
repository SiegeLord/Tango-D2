/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpResponse;

private import  tango.io.Buffer;

private import  tango.net.http.HttpWriter,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders,
                tango.net.http.HttpResponses;

private import  mango.net.http.server.HttpMessage,
                mango.net.http.server.ServiceBridge;

private import  tango.io.protocol.model.IWriter;

//version = ShowHeaders;

/*******************************************************************************

        Some constants for output buffer sizes

*******************************************************************************/

private static const int ParamsBufferSize = 1 * 1024;
private static const int HeaderBufferSize = 4 * 1024;

/******************************************************************************

        Define an http response to a user-agent (client). Note that all
        data is managed on a thread-by-thread basis.

******************************************************************************/

class HttpResponse : HttpMessage
{
        private HttpMutableParams       params;
        private HttpMutableCookies      cookies;
        private HttpStatus              status;
        private HttpWriter              writer;
        private bool                    commited;

        static private InvalidStateException InvalidState;

        /**********************************************************************

                Construct static instances of exceptions etc. 

        **********************************************************************/

        static this()
        {
                InvalidState = new InvalidStateException("Invalid response state");
        }

        /**********************************************************************

                Create a Response instance. Note that we create a bunch of
                internal support objects on a per-thread basis. This is so
                we don't have to create them on demand; however, we should
                be careful about resetting them all before each new usage.

        **********************************************************************/

        this (ServiceBridge bridge)
        {
                // create a seperate output buffer for headers to reside
                super (bridge, new Buffer(HeaderBufferSize));

                // create a default output writer
                writer = new HttpWriter (super.getBuffer());
        
                // create a cached query-parameter processor. We
                // support a maximum output parameter list of 1K bytes
                params = new HttpMutableParams (new Buffer(ParamsBufferSize));
        
                // create a wrapper for output cookies. This is more akin 
                // to a specialized writer, since it just adds additional
                // content to the output headers.
                cookies = new HttpMutableCookies (super.getHeader());
        }

        /**********************************************************************

                Reset this response, ready for the next connection

        **********************************************************************/

        void reset()
        {
                // response is "OK" by default
                commited = false;
                setStatus (HttpResponses.OK);

                // reset the headers
                super.reset();

                // reset output parameters
                params.reset();
        }

        /**********************************************************************

                Send an error status to the user-agent

        **********************************************************************/

        void sendError (inout HttpStatus status)
        {
                sendError (status, "");
        }

        /**********************************************************************

                Send an error status to the user-agent, along with the
                provided message

        **********************************************************************/

        void sendError (inout HttpStatus status, char[] msg)
        {       
                sendError (status, status.name, msg);
        }

        /**********************************************************************

                Send an error status to the user-agent, along with the
                provided exception text

        **********************************************************************/

        void sendError (inout HttpStatus status, Exception ex)
        {
                sendError (status, status.name, ex.toString());
        }

        /**********************************************************************

                Set the current response status.

        **********************************************************************/

        void setStatus (inout HttpStatus status)
        {
                this.status = status;
        }

        /**********************************************************************

                Return the current response status

        **********************************************************************/

        HttpStatus getStatus ()
        {
                return status;
        }

        /**********************************************************************

                Return the output writer. This set a sentinel indicating
                that we cannot add any more headers (since they have to
                be flushed before any additional output is sent).

        **********************************************************************/

        HttpWriter getWriter()
        {
                // write headers, and cause InvalidState on next call
                // to getOutputHeaders()
                commit (writer);               
                return writer;
        }

        /**********************************************************************

                Return the wrapper for adding output parameters

        **********************************************************************/

        HttpMutableParams getOutputParams()
        {
                return params;
        }

        /**********************************************************************

                Return the wrapper for output cookies

        **********************************************************************/

        HttpMutableCookies getOutputCookies()
        {
                return cookies;
        }

        /**********************************************************************

                Return the wrapper for output headers.

        **********************************************************************/

        HttpMutableHeaders getOutputHeaders()
        {
                // can't access headers after commiting
                if (commited)
                    throw InvalidState;
                return super.getHeader();
        }

        /**********************************************************************

                Return the buffer attached to the output conduit. Note that
                further additions to the output headers is disabled from
                this point forward. 

        **********************************************************************/

        IBuffer getOutputBuffer()
        {
                // write headers, and cause InvalidState on next call
                // to getOutputHeaders()
                commit (writer);
                return super.getBuffer();
        }

        /**********************************************************************

                Send a redirect response to the user-agent

        **********************************************************************/

        void sendRedirect (char[] location)
        {
                setStatus (HttpResponses.MovedTemporarily);
                getHeader().add (HttpHeader.Location, location);
                flush (writer);
        }

        /**********************************************************************

                Write the response and the output headers 

        **********************************************************************/

        void write (IWriter writer)
        {
                commit (writer);
        }

        /**********************************************************************

                Ensure the output is flushed

        **********************************************************************/

        void flush (IWriter writer)
        {
                commit (writer);

                version (ShowHeaders)
                        {
                        Stdout.put ("###############").newline();
                        Stdout.put (super.getBuffer.toString).newline();
                        Stdout.put ("###############").newline();
                        }
                writer.flush();
        }

        /**********************************************************************

                Private method to send the response status, and the
                output headers, back to the user-agent

        **********************************************************************/

        private void commit (IWriter writer)
        {
                if (! commited)
                   {
                   // say we've send headers on this response
                   commited = true;

                   char[]               header;
                   HttpMutableHeaders   headers = getHeader();

                   // write the response header
                   writer.put (HttpHeader.Version.value)
                         .put (' ')
                         .put (status.code)
                         .put (' ')
                         .put (status.name)
                         .newline  ();

                   // tell client we don't support keep-alive
                   if (! headers.get (HttpHeader.Connection))
                         headers.add (HttpHeader.Connection, "close");
                  
                   // write the header tokens, followed by a blank line
                   super.write (writer);
                   writer.newline ();

                   // send it back to the UA (and empty the buffer)
                   writer.flush();
                        
                   version (ShowHeaders)
                           {
                           Stdout.put (">>>> output headers"c).newline();
                           Stdout.put (HttpHeader.Version.value)
                                 .put (' ')
                                 .put (status.code)
                                 .put (' ')
                                 .put (status.name)
                                 .newline  ();
                           super.write (Stdout);
                           }
                   }
        }

        /**********************************************************************

                Send an error back to the user-agent. We have to be careful
                about which errors actually have content returned and those
                that don't.

        **********************************************************************/

        private void sendError (inout HttpStatus status, char[] reason, char[] message)
        {
                setStatus (status);

                if (status.code != HttpResponses.NoContent.code && 
                    status.code != HttpResponses.NotModified.code && 
                    status.code != HttpResponses.PartialContent.code && 
                    status.code >= HttpResponses.OK.code)
                   {
                   // error-page is html
                   setContentType (HttpHeader.TextHtml.value);

                   // output the headers
                   commit (writer);

                   // output an error-page
                   writer.put ("<HTML>\n<HEAD>\n<TITLE>Error "c)
                         .put (status.code)
                         .put (' ')
                         .put (reason)
                         .put ("</TITLE>\n<BODY>\n<H2>HTTP Error: "c)
                         .put (status.code)
                         .put (' ')
                         .put (reason)                       
                         .put ("</H2>\n"c)
                         .put (message ? message : ""c)
                         .put ("\n</BODY>\n</HTML>\n"c);

                   flush (writer);
                   }
        }
}




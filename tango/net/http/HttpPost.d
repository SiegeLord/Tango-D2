/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpPost;

public import   tango.net.Uri;

public import   tango.core.Interval;

private import  tango.io.GrowBuffer;

private import  tango.io.model.IConduit;

private import  tango.net.http.HttpClient,
                tango.net.http.HttpHeaders;

/*******************************************************************************

        Supports the basic needs of a client making file requests of an 
        HTTP server. The following is a usage example:

        ---
        ---

*******************************************************************************/

class HttpPost : HttpClient
{      
        private uint pageChunk;

        /***********************************************************************
        
                Create a client for the given URL. The argument should be
                fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided.

        ***********************************************************************/

        this (char[] url, uint pageChunk = 16 * 1024)
        {
                this (new Uri(url), pageChunk);
        }

        /***********************************************************************
        
                Create a client with the provided Uri instance. The Uri should 
                be fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided. 

        ***********************************************************************/

        this (Uri uri, uint pageChunk = 16 * 1024)
        {
                super (HttpClient.Post, uri);
                this.pageChunk = pageChunk;
        }

        /***********************************************************************
        
                Provide an input buffer for HttpClient

        ***********************************************************************/

        protected IBuffer inputBuffer (IConduit conduit)
        {
                return new GrowBuffer (conduit, pageChunk);
        }

        /***********************************************************************
        
                Send query params only

        ***********************************************************************/

        void[] write (Interval timeout = DefaultReadTimeout)
        {
                return write (cast(Pump) null, timeout);
        }

        /***********************************************************************
        
                Send content and no query params. The contentLength header
                will be set to match the provided content, and contentType
                set to the given type.

        ***********************************************************************/

        void[] write (void[] content, char[] type, Interval timeout = DefaultReadTimeout)
        {
                auto headers = getRequestHeaders();

                headers.add    (HttpHeader.ContentType, type);
                headers.addInt (HttpHeader.ContentLength, content.length);
                
                return write (delegate void (IBuffer b){b.append(content);}, timeout);
        }

        /***********************************************************************
        
                Send raw data via the provided pump, and no query 
                params. You have full control over headers and so 
                on via this method.

        ***********************************************************************/

        void[] write (Pump pump, Interval timeout = DefaultReadTimeout)
        {
                auto input = open (timeout, pump);
                scope (exit)
                       close;

                // check return status for validity
                auto status = getStatus();
                if (status is HttpResponseCode.OK || 
                    status is HttpResponseCode.Created || 
                    status is HttpResponseCode.Accepted
                   ) 
                   {
                   // extract content length
                   int length = getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);
                   while (input.readable() < length && input.fill() != IConduit.Eof) {}
                   }

                return input.slice;
        }
}


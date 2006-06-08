/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: January 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpGet;

private import  tango.net.Uri,
                tango.io.Conduit,
                tango.io.GrowBuffer;

private import  tango.core.Interval;

private import  tango.net.http.HttpClient;

private import  tango.net.http.HttpHeaders;


/*******************************************************************************

        Supports the basic needs of a client making file requests of an 
        HTTP server. The following is a usage example:

        @code
        @endcode

*******************************************************************************/

class HttpGet : HttpClient
{      
        private uint pageChunk;

        /***********************************************************************
        
                Create a client for the given URL. The argument should be
                fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided.

        ***********************************************************************/

        this (char[] url, uint pageChunk = 16 * 1024)
        {
                this (new MutableUri (url), pageChunk);
        }

        /***********************************************************************
        
                Create a client with the provided Uri instance. The Uri should 
                be fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided. 

        ***********************************************************************/

        this (MutableUri uri, uint pageChunk = 16 * 1024)
        {
                super (HttpClient.Get, uri);
                this.pageChunk = pageChunk;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected IBuffer inputBuffer (IConduit conduit)
        {
                return new GrowBuffer (conduit, pageChunk);
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] read (Interval timeout = DefaultReadTimeout)
        {
                auto input = open (timeout);

                // check return status for validity
                if (isResponseOK)
                   {
                   // extract content length
                   int length = getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);
                   while (input.readable() < length && input.fill() != Conduit.Eof) {}
                   }

                close ();
                return input.toString;
        }
}


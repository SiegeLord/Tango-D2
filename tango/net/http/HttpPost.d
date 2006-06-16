/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpPost;

private import  tango.net.Uri,
                tango.io.Conduit,
                tango.io.GrowBuffer;

private import  tango.io.protocol.model.IWriter;

private import  tango.net.http.HttpClient;

private import  tango.net.http.HttpHeaders;

/*******************************************************************************

        Supports the basic needs of a client making file requests of an 
        HTTP server. The following is a usage example:

        ---
        ---

*******************************************************************************/

class HttpPost : HttpClient, IWritable
{      
        private void[]  content;
        private uint    pageChunk;

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
                super (HttpClient.Post, uri);
                this.pageChunk = pageChunk;
        }

        /***********************************************************************
        
        ***********************************************************************/

        void write (IWriter output)
        {
                output (cast(byte[]) content);   
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected IBuffer inputBuffer (IConduit conduit)
        {
                return new GrowBuffer (conduit, pageChunk);
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] write (void[] content, uint timeout = DefaultReadTimeout)
        {
                this.content = content;
                return write (this, timeout);
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] write (IWritable pump, uint timeout = DefaultReadTimeout)
        {
                auto input = open (timeout, pump);

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


/*******************************************************************************

        @file HttpGet.d
        
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


        @version        Initial version, January 2006

        @author         Kris


*******************************************************************************/

module tango.net.http.HttpGet;

private import  tango.io.Uri,
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


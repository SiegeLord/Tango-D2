/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.model.IProvider;

private import  mango.net.http.server.HttpRequest,
                mango.net.http.server.HttpResponse;

private import  mango.net.http.server.model.IProviderBridge;

/******************************************************************************

        Contract to be fulfilled by all HTTP provider instances.

******************************************************************************/

interface IProvider
{
        /**********************************************************************

                Concrete provider must provide the service handler

        **********************************************************************/

        void service (HttpRequest request, HttpResponse response);

        /**********************************************************************

                Concrete provider must provide a request factory

        **********************************************************************/

        HttpRequest createRequest (IProviderBridge bridge);

        /**********************************************************************

                Concrete provider must provide a response factory

        **********************************************************************/

        HttpResponse createResponse (IProviderBridge bridge);

        /**********************************************************************

                Concrete provider must provide an identifying text string
              
        **********************************************************************/

        char[] toString ();
}


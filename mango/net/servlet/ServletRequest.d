/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.ServletRequest;

private import  tango.net.model.UriView;

private import  tango.io.model.IBuffer;
               
private import  tango.io.protocol.model.IReader;

private import  tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders;

private import  mango.net.servlet.ServletContext;

private import  mango.net.servlet.model.IServletRequest;

private import  mango.net.http.server.HttpRequest,
                mango.net.http.server.ServiceBridge;

/******************************************************************************

******************************************************************************/

class ServletRequest : HttpRequest, IServletRequest
{
        private ServletContext  context;                                
        private char[]          servlet;

        /**********************************************************************

        **********************************************************************/

        this (ServiceBridge bridge)
        {
                // initialize the HttpRequest
                super (bridge);
        }

        /**********************************************************************

        **********************************************************************/

        void set (char[] servlet, ServletContext context)
        {
                this.servlet = servlet;
                this.context = context;
        }

        /**********************************************************************

        **********************************************************************/

        void reset ()
        {
                // reset HttpRequest
                super.reset();
        }

        /***********************************************************************
        
        ***********************************************************************/

        UriView getUri()
        {
                return super.getExplicitUri();
        }

        /**********************************************************************

        **********************************************************************/

        IServletContext getContext ()
        {
                return context;
        }

        /**********************************************************************

        **********************************************************************/

        HttpParamsView getParameters ()
        {
                return super.getInputParameters();
        }

        /**********************************************************************

        **********************************************************************/

        HttpHeadersView getHeaders ()
        {
                return super.getInputHeaders();
        }

        /**********************************************************************

        **********************************************************************/

        HttpCookiesView getCookies ()
        {
                return super.getInputCookies();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getCharacterEncoding()
        {
                return super.getEncoding();
        }

        /***********************************************************************
        
        ***********************************************************************/

        int getContentLength()
        {
                return super.getHeader().getInt (HttpHeader.ContentLength);
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getContentType()
        {
                return super.getMimeType();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getProtocol()
        {
                return super.getStartLine().getProtocol();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getMethod()
        {
                return super.getStartLine().getMethod();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getServerName()
        {
                return super.getHost();
        }

        /***********************************************************************
        
        ***********************************************************************/

        int getServerPort()
        {
                return super.getPort();
        }

        /***********************************************************************
        
        ***********************************************************************/

        IReader getReader ()
        {
                return super.getReader();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getRemoteAddress()
        {
                return super.getRemoteAddr();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getRemoteHost()
        {
                return super.getRemoteHost();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getPathInfo()
        {
                char[] path = super.getRequestUri().getPath();
                
                return path [context.getName.length..path.length];
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getContextPath()
        {
                return context.getName();
        }

        /***********************************************************************
        
        ***********************************************************************/

        char[] getServletPath()
        {
                return servlet;
        }
}



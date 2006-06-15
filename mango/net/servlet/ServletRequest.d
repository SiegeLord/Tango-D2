/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.ServletRequest;

private import  tango.net.Uri;

private import  tango.io.model.IBuffer;
               
private import  mango.net.servlet.ServletContext;

private import  mango.net.servlet.model.IServletRequest;

private import  tango.net.http.HttpReader,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders;

private import  mango.net.http.server.HttpRequest;

private import  mango.net.http.server.model.IProviderBridge;

/******************************************************************************

******************************************************************************/

class ServletRequest : HttpRequest, IServletRequest
{
        private ServletContext  context;                                
        private char[]          servlet;

        /**********************************************************************

        **********************************************************************/

        this (IProviderBridge bridge)
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

        Uri getUri()
        {
                return super.getExplicitUri();
        }

        /**********************************************************************

        **********************************************************************/

        ServletContext getContext ()
        {
                return context;
        }

        /**********************************************************************

        **********************************************************************/

        HttpParams getParameters ()
        {
                return super.getInputParameters();
        }

        /**********************************************************************

        **********************************************************************/

        HttpHeaders getHeaders ()
        {
                return super.getInputHeaders();
        }

        /**********************************************************************

        **********************************************************************/

        HttpCookies getCookies ()
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

        HttpReader getReader ()
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



/*******************************************************************************

        @file ServletRequest.d
        
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
        @author         Kris


*******************************************************************************/

module tango.ext.net.servlet.ServletRequest;

private import  tango.io.Uri;

private import  tango.io.model.IBuffer;
               
private import  tango.ext.net.servlet.ServletContext;

private import  tango.ext.net.servlet.model.IServletRequest;

private import  tango.net.http.HttpReader,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders;

private import  tango.ext.net.http.server.HttpRequest;

private import  tango.ext.net.http.server.model.IProviderBridge;

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



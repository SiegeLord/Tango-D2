/*******************************************************************************

        @file IServletRequest.d
        
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

module tango.net.servlet.model.IServletRequest;

private import  tango.io.Uri;

private import  tango.io.model.IBuffer,
                tango.io.model.IReader;

private import  tango.net.http.HttpReader,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders;

private import  tango.net.servlet.ServletContext;

/******************************************************************************

******************************************************************************/

interface IServletRequest
{
        /***********************************************************************
        
        ***********************************************************************/

        Uri getUri();

        /**********************************************************************

        **********************************************************************/

        ServletContext getContext ();

        /**********************************************************************

        **********************************************************************/

        HttpParams getParameters ();

        /**********************************************************************

        **********************************************************************/

        HttpHeaders getHeaders ();

        /**********************************************************************

        **********************************************************************/

        HttpCookies getCookies ();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getCharacterEncoding();

        /***********************************************************************
        
        ***********************************************************************/

        int getContentLength();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getContentType();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getProtocol();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getMethod();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getServerName();

        /***********************************************************************
        
        ***********************************************************************/

        int getServerPort();

        /***********************************************************************
        
        ***********************************************************************/

        HttpReader getReader ();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getRemoteAddress();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getRemoteHost();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getPathInfo();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getContextPath();

        /***********************************************************************
        
        ***********************************************************************/

        char[] getServletPath();
}

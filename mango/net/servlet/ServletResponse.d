/*******************************************************************************

        @file ServletResponse.d
        
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

module mango.net.servlet.ServletResponse;

private import  tango.net.Uri,
                tango.io.Buffer,
                tango.io.Exception,
                tango.io.FileConduit;

private import  tango.io.model.IBuffer;

private import  mango.net.servlet.ServletContext;

private import  mango.net.servlet.model.IServletResponse;

private import  tango.net.http.HttpWriter,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders,
                tango.net.http.HttpResponses;

private import  mango.net.http.server.HttpResponse;

private import  mango.net.http.server.model.IProviderBridge;

/******************************************************************************

******************************************************************************/

class ServletResponse : HttpResponse, IServletResponse
{
        /**********************************************************************

        **********************************************************************/

        this (IProviderBridge bridge)
        {
                // initialize the HttpRequest
                super (bridge);
        }

        /**********************************************************************

        **********************************************************************/

        void reset ()
        {
                // reset HttpRequest
                super.reset();
        }

        /**********************************************************************

        **********************************************************************/

        HttpMutableParams getParameters ()
        {
                return super.getOutputParams();
        }

        /**********************************************************************

        **********************************************************************/

        HttpMutableCookies getCookies ()
        {
                return super.getOutputCookies();
        }

        /**********************************************************************

        **********************************************************************/

        HttpMutableHeaders getHeaders ()
        {
                return super.getOutputHeaders();
        }

        /***********************************************************************
        
        ***********************************************************************/

        HttpWriter getWriter()
        {
                return super.getWriter();
        }

        /***********************************************************************
        
        ***********************************************************************/

        void setContentLength (int len)
        {
               getHeader().addInt (HttpHeader.ContentLength, len);
        }


        /***********************************************************************
        
        ***********************************************************************/

        void setContentType (char[] type)
        {
               super.setContentType (type);
        }

        /***********************************************************************
        
        ***********************************************************************/

        void flushBuffer()
        {
                super.flush (getWriter ());
        }

        /***********************************************************************
        
                The argument 'status' should be "inout" instead so as to 
                enforce pass-by-reference semantics. However, one cannot
                do that with a const struct. D apparently still requires
                further development in this area.

        ***********************************************************************/

        void sendError (inout HttpStatus status, char[] msg)
        {
                super.sendError (status, msg);
        }


        /***********************************************************************
        
                The argument 'status' should be "inout" instead so as to 
                enforce pass-by-reference semantics. However, one cannot
                do that with a const struct. D apparently still requires
                further development in this area.

        ***********************************************************************/

        void sendError (inout HttpStatus status)
        {
                super.sendError (status);
        }


        /***********************************************************************
        
        ***********************************************************************/

        void sendRedirect(char[] location)
        {
                super.sendRedirect (location);
        }

        /***********************************************************************
        
                The argument 'status' should be "inout" instead so as to 
                enforce pass-by-reference semantics. However, one cannot
                do that with a const struct. D apparently still requires
                further development in this area.

        ***********************************************************************/

        void setStatus (inout HttpStatus status)
        {
                super.setStatus (status);
        }

        /***********************************************************************
        
        ***********************************************************************/

        bool copyFile (ServletContext context, char[] path)
        {
                FileConduit conduit;

                try {
                    // does the file exist?
                    conduit = context.getResourceAsFile (path);

                    // set expected output size
                    setContentLength (cast(int) conduit.length());

                    // set content-type if not already set
                    if (super.getContentType() is null)
                       {
                       char[] mime = context.getMimeType (conduit.getPath.getExtension());
                       if (mime is null)
                           mime = "text/plain";        
                       
                       super.setContentType (mime);
                       }

                    // copy file to output conduit
                    getWriter.getBuffer.getConduit.copy (conduit);
                    return true;

                    } catch (IOException x)
                            {
                            sendError (HttpResponses.NotFound);
                            }
                      finally 
                            {
                            if (conduit)
                                conduit.close();
                            }
                return false;
        }
}



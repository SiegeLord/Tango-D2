/*******************************************************************************

        @file Servlet.d
        
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

module mango.net.servlet.Servlet;

public import  tango.net.http.HttpHeaders,
               tango.net.http.HttpResponses;

public import  mango.net.servlet.ServletConfig,
               mango.net.servlet.ServletException;

public import  mango.net.servlet.model.IServletRequest,
               mango.net.servlet.model.IServletResponse;
                

/******************************************************************************

        The basic servlet class. This is a bit different from the Java
        style servlets, as the class hierarchy is effectively inverted.

        Servlet, by itself, does not break out each request-method. It
        provides only the most basic functionality. See MethodServlet
        for additional functionalty.

******************************************************************************/

class Servlet
{
        /**********************************************************************

                Service is the main entry point for all servlets.

        **********************************************************************/

        abstract void service (IServletRequest request, IServletResponse response);

        /**********************************************************************

                Init is called when the servlet is first registered.

        **********************************************************************/

        void init (ServletConfig config)
        {
        }
}


/******************************************************************************

        Extends the basic servlet with individual signatures for handling 
        each request method.

******************************************************************************/

class MethodServlet : Servlet
{

        /**********************************************************************
        
                Default response for unimplemented requests.

        **********************************************************************/

        static private void error (IServletResponse response)
        {
                response.sendError (HttpResponses.MethodNotAllowed);
        }

        /**********************************************************************

                Handle a GET request

        **********************************************************************/

        void doGet (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle a HEAD request

        **********************************************************************/

        void doHead (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle a POST request

        **********************************************************************/

        void doPost (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle a DELETE request

        **********************************************************************/

        void doDelete (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle a PUT request

        **********************************************************************/

        void doPut (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle an OPTIONS request

        **********************************************************************/

        void doOptions (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                Handle a TRACE request

        **********************************************************************/

        void doTrace (IServletRequest request, IServletResponse response)
        {
                error (response);
        }

        /**********************************************************************

                overridable implementation of getLastModified() returns
                -1 to say it doesn't know.

        **********************************************************************/

        ulong getLastModified (IServletRequest request)
        {
                return -1;
        }

        /**********************************************************************

                Preamble for GET requests that tries to figure out if
                we can simply return a NotModified status to the UA.

                Servlets supporting such notions should override the
                getLastModified() method above, and have it do the
                appropriate thing.

        **********************************************************************/

        void get (IServletRequest request, IServletResponse response)
        {
                ulong lastModified = getLastModified (request);
                if (lastModified == -1) 
                    doGet (request, response);
                else
                   {    
                   ulong ifModifiedSince = request.getHeaders.getDate (HttpHeader.IfModifiedSince);
                   if (ifModifiedSince < (lastModified / 1000 * 1000)) 
                      {
                      response.getHeaders.addDate (HttpHeader.LastModified, lastModified);
                      doGet (request, response);
                      } 
                   else 
                      response.setStatus (HttpResponses.NotModified);
                   }
        }

        /**********************************************************************

                Service implementation for method specific isolation.

        **********************************************************************/

        void service (IServletRequest request, IServletResponse response)
        {
                char[] method = request.getMethod();

                switch (method[0])
                       {
                       case 'G':
                            get (request, response);
                            break;

                       case 'H':
                            doHead (request, response);
                            break;

                       case 'O':
                            doOptions (request, response);
                            break;

                       case 'T':
                            doTrace (request, response);
                            break;

                       case 'D':
                            doDelete (request, response);
                            break;

                       case 'P':
                            if (method[1] == 'O')
                                doPost (request, response);
                            else
                               doPut (request, response);
                            break;

                       default:
                            response.sendError (HttpResponses.NotImplemented);
                            break;
                       }
        }
}


/******************************************************************************

        This class is intended to be compatible with a Java GenericServlet.
        Note that the ServletContext is available from the ServletRequest
        class, so this error-prone approach of accessing context via the
        configuration is rendered totally redundant.

******************************************************************************/

class CompatibleServlet : MethodServlet
{
        private ServletConfig config;

        /**********************************************************************

                Servlet must implement the init() method

        **********************************************************************/

        abstract void init ();

        /**********************************************************************

                Optional init() with ServletConfig passed to it.

        **********************************************************************/

        void init (ServletConfig config)
        {
                this.config = config;
                init ();
        }

        /**********************************************************************

                Return the configuration passed with init()

        **********************************************************************/

        ServletConfig getConfig ()
        {
                return config;
        }
}



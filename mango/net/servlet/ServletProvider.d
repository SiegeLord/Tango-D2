/*******************************************************************************

        @file ServletProvider.d
        
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

module mango.net.servlet.ServletProvider;

private import  tango.text.Regex;
 
private import  tango.text.Text;
   
private import  tango.io.Uri,
                tango.io.Exception;

private import  mango.net.servlet.Servlet,
                mango.net.servlet.ServletConfig,
                mango.net.servlet.ServletContext,
                mango.net.servlet.ServletRequest,
                mango.net.servlet.ServletResponse;

private import  mango.net.servlet.cache.HashMap,
                mango.net.servlet.cache.Payload,
                mango.net.servlet.cache.QueuedCache;

private import  mango.net.http.server.HttpRequest,
                mango.net.http.server.HttpResponse;

private import  mango.net.http.server.model.IProvider,
                mango.net.http.server.model.IProviderBridge;


/******************************************************************************

        ServletProvider is a servlet-host implementation; you bind one of
        these to an HttpServer instance and you're up and running. This 
        particular implementation has a few quirks worth noting:

        @li each http request is mapped to a servlet instance via a set of
           regex patterns. That is far too expensive to figure out upon 
           each request, so a cache of Uri request versus mapped servlets 
           is maintained. Subsequent requests go straight to the cached 
           servlet mapping. The cache size should be specified as large 
           enough to contain the vast majority of valid path requests.

        @li the mapping of a servlet to a request does not follow the spec
           to the letter. Specifically, the namespace is not seperated out 
           into isolated sections for each of the four mapping types, so 
           it's a case of "first found wins" regarding the matching of 
           patterns to URL paths. This should not cause any problem in the
           general case, since it's very rare to have such a servlet-naming
           conflict. The tradeoff is one runtime lookup versus four; we 
           chose the former.

        @li the "default context" implemented here has an empty name, as
           opposed to a name of "/". This simplifies the code but might 
           look alien; there's a getDefaultContext() method to alleviate
           such concerns.

        Overall this should be pretty fast, since it doesn't cause any
        memory allocation whatsoever (once operationally primed).

******************************************************************************/

class ServletProvider : IProvider
{
        private QueuedCache             cache;
        private HashMap                 proxies;
        private HashMap                 contexts;
        private ServletMapping[]        mappings;

        /**********************************************************************

                Construct a ServletProvider with a default path-mapping
                cache of 2048 entries. We also create the default context
                here.

        **********************************************************************/

        this (uint urls = 2048)
        {
                // small, low contention hashmap for proxies and contexts
                proxies = new HashMap (128, 0.75, 1);
                contexts = new HashMap (128, 0.75, 1);

                // medium concurrency hashmap for the url cache
                cache = new QueuedCache (urls, 16);

                // create the default context. Note that this is not 
                // named '/', permitting usage of context.getName() 
                // to be greatly simplified
                addContext (new ServletContext ("")); 
        }

        /**********************************************************************

                IProvider interface method

        **********************************************************************/

        HttpRequest createRequest (IProviderBridge bridge)
        {
                return new ServletRequest (bridge);
        }

        /**********************************************************************

                IProvider interface method

        **********************************************************************/

        HttpResponse createResponse (IProviderBridge bridge)
        {
                return new ServletResponse (bridge);
        }

        /**********************************************************************

                Return the name of this provider

        **********************************************************************/

        override char[] toString()
        {
                return "Servlet";
        }

        /**********************************************************************

                Return the default context. This is used for those 
                servlets which don't have a context of their own, and
                is effectively a backwards-compatability hack.

        **********************************************************************/

        ServletContext getDefaultContext ()
        {
                return getContext ("");
        }

        /**********************************************************************

                Return the named context, or null if the name is unregistered

        **********************************************************************/

        ServletContext getContext (char[] name)
        in {
           assert (name !is null);
           }
        body
        {
                return cast(ServletContext) contexts.get (name);
        }

        /**********************************************************************

                Register a servlet context. The name is provided by the 
                context itself.

        **********************************************************************/

        ServletContext addContext (ServletContext context)
        in {
           assert (context);
           }
        body
        {
                contexts.put (context.getName, context);
                return context;
        }

        /**********************************************************************

                lookup and cast HashMap entry

        **********************************************************************/

        private final ServletProxy lookupProxy (char[] name)
        {
                return cast(ServletProxy) proxies.get (name);
        }

        /**********************************************************************

                Add a uri-mapping for the named servlet. The servlet should
                have been registered previously.

        **********************************************************************/

        void addMapping (char[] pattern, char[] servlet)
        in {
           assert (servlet.length);
           }
        body
        {
                ServletProxy proxy = lookupProxy (servlet);
                if (proxy)
                    addMapping (pattern, proxy);
                else
                   throw new ServletException ("Invalid servlet mapping argument");
        }
                
        /**********************************************************************

                Add a uri-mapping for the specified servlet. We follow the
                Java spec in terms of pattern support, but the namespace is
                not seperated for the four different pattern types. That is,
                all the mappings are placed into a single namespace.

        **********************************************************************/

        void addMapping (char[] pattern, IRegisteredServlet servlet)
        in {
           assert (servlet);
           }
        body
        {
                // context is always used, even when it's "" for the default context
                char[] context = "^" ~ servlet.getContext.getName();

                // check for default context specifier
                if (pattern is null || pattern == "/")
                    pattern = "";

                int i = Text.indexOf (pattern, '*');
                if (i == 0)
                    // file extension 
                    pattern = "/.+\\" ~ pattern[1..pattern.length] ~ "$";
                else
                   if (i > 0)
                       // path extension
                       pattern = pattern[0..i] ~ ".*";
                   else
                      if (pattern.length == 0)
                          // default
                          pattern = "/.*";
                      else
                         // explicit filename
                         pattern = pattern ~ "$";
                
                // prepend the context ...
                pattern = context ~ pattern;

                // add to list of mappings
                mappings ~= new ServletMapping (servlet, new Regex(pattern, null));
                
                version (Debug)
                         printf ("Pattern '%.*s'\n", pattern);
        }

        /**********************************************************************

                Return the servlet registered with the specified name, or
                null if there is no such servlet.

        **********************************************************************/

        IRegisteredServlet getServlet (char[] name)
        in {
           assert (name.length);
           }
        body
        {
                return lookupProxy (name);
        }

        /**********************************************************************

                Register a servlet with the specified name. The servlet 
                is associated with the default context.

        **********************************************************************/

        IRegisteredServlet addServlet (Servlet servlet, char[] name)
        {
                return addServlet (servlet, name, getDefaultContext());
        }

        /**********************************************************************

                Register a servlet with the specified name and context 

        **********************************************************************/

        IRegisteredServlet addServlet (Servlet servlet, char[] name, char[] context)
        in {
           assert (context !is null);
           }
        body
        {
                // backward compatability for default context ...
                if (context == "/")
                    context = "";

                return addServlet (servlet, name, getContext (context));
        }

        /**********************************************************************

                Register a servlet with the specified name and context 

        **********************************************************************/

        IRegisteredServlet addServlet (Servlet servlet, char[] name, ServletContext context)
        in {
           assert (context !is null);
           }
        body
        {
                return addServlet (servlet, name, new ServletConfig (context));
        }

        /**********************************************************************

                Register a servlet with the specified name and configuration 

        **********************************************************************/

        IRegisteredServlet addServlet (Servlet servlet, char[] name, ServletConfig config)
        in {
           assert (name.length);
           assert (config !is null);
           assert (servlet !is null);
           assert (config.getServletContext() !is null);
           }
        body
        {
                ServletProxy proxy = new ServletProxy (servlet, name, config.getServletContext());
                proxies.put (name, proxy);

                // initialize this servlet
                servlet.init (config);

                return proxy;
        }

        /**********************************************************************

                Scan the servlet mappings, looking for one that matches
                the specified path. The first match found is returned.

        **********************************************************************/

        private PathMapping constructPathMapping (char[] path)
        {
                foreach (ServletMapping m; mappings)
                         if (m.regex.test (path))
                             return new PathMapping (m, path);
                return null;
        }

        /**********************************************************************

                IProvider interface method. This is where the real work 
                is done, and where optimization efforts should be focused.
                The process itself is straightforward:

                @li we lookup the mapping cache to see if we've processed
                    the request before. If not, we create a new mapping

                @li we then setup the input parameters to the servlet, and
                    invoke the latter.

                @li lastly, we flush the response

                All exceptions are caught and logged.

        **********************************************************************/

        void service (HttpRequest req, HttpResponse res)
        {
                PathMapping             pm;
                char[]                  path;
                ServletRequest          request;
                ServletResponse         response;
                bool                    addToCache;

                // we know what these are since we created them (above)
                request = cast(ServletRequest) req;
                response = cast(ServletResponse) res;

                // retrieve the requested uri
                path = request.getUri.getPath();
                
                // lookup servlet for this path
                pm = cast (PathMapping) cache.get (path);

                // construct a new cache entry if not found
                if (pm is null)
                   {
                   // take a copy of the path since we're gonna' hold onto it
                   pm = constructPathMapping (path.dup);

                   // did we find a matching servlet?                
                   if (pm is null)
                       // nope; go home ...
                       return response.sendError (HttpResponses.NotFound);

                   // add this new URI path to the cache
                   addToCache = true;
                   }

                // ready to go ...
                try {
                    // initialize the servlet environment
                    request.set (pm.mapping.proxy.getName, pm.mapping.proxy.getContext);

                    // execute servlet
                    pm.mapping.proxy.getServlet.service (request, response);

                    // flush output on behalf of servlet ...
                    response.flush (response.getWriter);

                    // processed successfully? add new URI path to cache ...
                    if (addToCache && (response.getStatus.code == HttpResponseCode.OK))
                        cache.put (pm.path, pm);

                    } catch (UnavailableException ux)
                             response.sendError (HttpResponses.ServiceUnavailable, ux.toString);

                      catch (ServletException sx)
                             error (response, sx);

                      catch (Object ex)
                             error (response, ex);
        }

        /**********************************************************************

                handle internal errors

        **********************************************************************/

        private void error (ServletResponse response, Object x)
        {
                response.sendError (HttpResponses.InternalServerError, x.toString);
                getDefaultContext().log ("Internal error:", x);
        }
}


/******************************************************************************

        Models a servlet that has been registered.

******************************************************************************/

interface IRegisteredServlet
{    
        /**********************************************************************

                Return the servlet name

        **********************************************************************/

        char[] getName ();

        /**********************************************************************

                Return the servlet instance

        **********************************************************************/

        Servlet getServlet ();
        
        /**********************************************************************

                Return the servlet context

        **********************************************************************/

        ServletContext getContext ();           
}
   

/******************************************************************************

        ServletProxy is a wrapper that combines the servlet along with 
        its context and name. This is what's created when a servlet is 
        registered.

******************************************************************************/

private class ServletProxy : IRegisteredServlet
{       
        private char[]          name;
        private Servlet         servlet;
        private ServletContext  context;
        
        /**********************************************************************

                Construct the wrapper with all necessary attributes

        **********************************************************************/

        this (Servlet servlet, char[] name, ServletContext context)
        {
                this.name = name;
                this.servlet = servlet;
                this.context = context;
        }

        /**********************************************************************

                Return the servlet name

        **********************************************************************/

        char[] getName ()
        {
                return name;
        }

        /**********************************************************************

                Return the servlet instance

        **********************************************************************/

        Servlet getServlet ()
        {
                return servlet;
        }
        
        /**********************************************************************

                Return the servlet context

        **********************************************************************/

        ServletContext getContext ()
        {
                return context;
        }          
}

        
/******************************************************************************

        PathMapping instances are held in the mapping cache, and relate
        a servlet to a given uri request. Method constructPathMapping()
        produces these.

******************************************************************************/

private class PathMapping : Payload
{       
        private char[]          path;
        private ServletMapping  mapping;
/*
        private short           end,
                                start;
*/        
        /**********************************************************************

                Construct the mapping with all necessary attributes

        **********************************************************************/

        this (ServletMapping mapping, char[] path)
        {
                this.path = path;
                this.mapping = mapping;

                //start = mapping.regex.pmatch[0].rm_so;
                //end   = mapping.regex.pmatch[0].rm_eo;
        }
}

        
/******************************************************************************

        Relate a servlet to a regular expression. These are constructed 
        via the addMapping() methods, and there may be more than one for
        any particular servlet. 

******************************************************************************/

private class ServletMapping
{       
        private Regex                  regex;
        private IRegisteredServlet      proxy;

        /**********************************************************************

                Construct the mapping with all necessary attributes

        **********************************************************************/

        this (IRegisteredServlet proxy, Regex regex)
        {
                this.regex = regex; 
                this.proxy = proxy;       
        }
}


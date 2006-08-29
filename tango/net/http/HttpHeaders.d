/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpHeaders;

private import  tango.text.LineIterator;

private import  tango.io.model.IBuffer,
                tango.io.protocol.model.IWriter;

private import  tango.net.http.HttpStack;

private import  tango.net.http.HttpTokens;

/*******************************************************************************

        Headers are distinct types in their own right. This is because they
        are somewhat optimized via a trailing ':' character.

*******************************************************************************/

struct HttpHeaderName
{
        char[]     value;  
}

/*******************************************************************************

        Define the traditional set of HTTP header names
        
*******************************************************************************/

struct HttpHeader
{   
        // size of both the request & response buffer (per thread)
        static const int IOBufferSize                 = 16 * 1024;

        // maximum length for POST parameters (to avoid DOS ...)
        static const int MaxPostParamSize             = 4 * 1024;

        static const HttpHeaderName Version           = {"HTTP/1.0"};
        static const HttpHeaderName TextHtml          = {"text/html"};

        static const HttpHeaderName Accept            = {"Accept:"};
        static const HttpHeaderName AcceptCharset     = {"Accept-Charset:"};
        static const HttpHeaderName AcceptEncoding    = {"Accept-Encoding:"};
        static const HttpHeaderName AcceptLanguage    = {"Accept-Language:"};
        static const HttpHeaderName AcceptRanges      = {"Accept-Ranges:"};
        static const HttpHeaderName Age               = {"Age:"};
        static const HttpHeaderName Allow             = {"Allow:"};
        static const HttpHeaderName Authorization     = {"Authorization:"};
        static const HttpHeaderName CacheControl      = {"Cache-Control:"};
        static const HttpHeaderName Connection        = {"Connection:"};
        static const HttpHeaderName ContentEncoding   = {"Content-Encoding:"};
        static const HttpHeaderName ContentLanguage   = {"Content-Language:"};
        static const HttpHeaderName ContentLength     = {"Content-Length:"};
        static const HttpHeaderName ContentLocation   = {"Content-Location:"};
        static const HttpHeaderName ContentRange      = {"Content-Range:"};
        static const HttpHeaderName ContentType       = {"Content-Type:"};
        static const HttpHeaderName Cookie            = {"Cookie:"};
        static const HttpHeaderName Date              = {"Date:"};
        static const HttpHeaderName ETag              = {"ETag:"};
        static const HttpHeaderName Expect            = {"Expect:"};
        static const HttpHeaderName Expires           = {"Expires:"};
        static const HttpHeaderName From              = {"From:"};
        static const HttpHeaderName Host              = {"Host:"};
        static const HttpHeaderName Identity          = {"identity:"};
        static const HttpHeaderName IfMatch           = {"If-Match:"};
        static const HttpHeaderName IfModifiedSince   = {"If-Modified-Since:"};
        static const HttpHeaderName IfNoneMatch       = {"If-None-Match:"};
        static const HttpHeaderName IfRange           = {"If-Range:"};
        static const HttpHeaderName IfUnmodifiedSince = {"If-Unmodified-Since:"};
        static const HttpHeaderName LastModified      = {"Last-Modified:"};
        static const HttpHeaderName Location          = {"Location:"};
        static const HttpHeaderName MaxForwards       = {"Max-Forwards:"};
        static const HttpHeaderName MimeVersion       = {"MIME-Version:"};
        static const HttpHeaderName Pragma            = {"Pragma:"};
        static const HttpHeaderName ProxyAuthenticate = {"Proxy-Authenticate:"};
        static const HttpHeaderName ProxyConnection   = {"Proxy-Connection:"};
        static const HttpHeaderName Range             = {"Range:"};
        static const HttpHeaderName Referrer          = {"Referer:"};
        static const HttpHeaderName RetryAfter        = {"Retry-After:"};
        static const HttpHeaderName Server            = {"Server:"};
        static const HttpHeaderName ServletEngine     = {"Servlet-Engine:"};
        static const HttpHeaderName SetCookie         = {"Set-Cookie:"};
        static const HttpHeaderName SetCookie2        = {"Set-Cookie2:"};
        static const HttpHeaderName TE                = {"TE:"};
        static const HttpHeaderName Trailer           = {"Trailer:"};
        static const HttpHeaderName TransferEncoding  = {"Transfer-Encoding:"};
        static const HttpHeaderName Upgrade           = {"Upgrade:"};
        static const HttpHeaderName UserAgent         = {"User-Agent:"};
        static const HttpHeaderName Vary              = {"Vary:"};
        static const HttpHeaderName Warning           = {"Warning:"};
        static const HttpHeaderName WwwAuthenticate   = {"WWW-Authenticate:"};
}


/******************************************************************************

        Exposes freachable HttpHeader instances 

******************************************************************************/

struct HeaderElement
{
        HttpHeaderName  name;
        char[]          value;
}

/******************************************************************************

        Maintains a set of input headers. These are placed into an input
        buffer and indexed via a HttpStack. 

******************************************************************************/

class HttpHeadersView : HttpTokens
{
        // tell compiler to used super.parse() also
        alias HttpTokens.parse parse;

        private LineIterator line;

        /**********************************************************************
                
                Construct this set of headers, using a HttpStack based
                upon a ':' delimeter   
              
        **********************************************************************/

        this ()
        {
                // separator is a ':', and specify we want it included as
                // part of the name whilst iterating
                super (':', true);

                // construct a line tokenizer for later usage
                line = new LineIterator;
        }

        /**********************************************************************
                
                Clone a source set of HttpHeaders

        **********************************************************************/

        this (HttpHeadersView source)
        {
                super (source);
        }

        /**********************************************************************
                
                Clone this set of HttpHeadersView

        **********************************************************************/

        HttpHeadersView clone ()
        {
                return new HttpHeadersView (this);
        }

        /**********************************************************************
                
                Read all header lines. Everything is mapped rather 
                than being allocated & copied

        **********************************************************************/

        void parse (IBuffer input)
        {
                setParsed (true);
                line.set (input);

                while (line.next && line.get.length)
                       stack.push (line.get);
        }

        /**********************************************************************
                
                Return the value of the provided header, or null if the
                header does not exist

        **********************************************************************/

        char[] get (HttpHeaderName name, char[] def = null)
        {
                return super.get (name.value, def);
        }

        /**********************************************************************
                
                Return the integer value of the provided header, or -1 
                if the header does not exist

        **********************************************************************/

        int getInt (HttpHeaderName name, int def = -1)
        {
                return super.getInt (name.value, def);
        }

        /**********************************************************************
                
                Return the date value of the provided header, or -1 
                if the header does not exist

        **********************************************************************/

        ulong getDate (HttpHeaderName name, ulong def = -1)
        {
                return super.getDate (name.value, def);
        }

        /**********************************************************************

                Iterate over the set of headers. This is a shell around
                the superclass, where we can convert the HttpToken into 
                a HeaderElement instead.

        **********************************************************************/

        int opApply (int delegate(inout HeaderElement) dg)
        {
                HeaderElement   element;
                int             result = 0;

                foreach (HttpToken token; super)
                        {
                        element.name.value = token.name;
                        element.value = token.value;
                        result = dg (element);
                        if (result)
                            break;
                        }
                return result;
        }

        /**********************************************************************

                Create a filter for iterating of a set of named headers.
                We have to create a filter since we can't pass additional
                arguments directly to an opApply() method.

        **********************************************************************/

        FilteredHeaders createFilter (HttpHeaderName header)
        {
                return new FilteredHeaders (this, header);
        }

        /**********************************************************************

                Filter class for isolating a set of named headers.

        **********************************************************************/

        private static class FilteredHeaders : FilteredTokens
        {       
                /**************************************************************

                        Construct a filter upon the specified headers, for
                        the given header name.

                **************************************************************/

                this (HttpHeadersView headers, HttpHeaderName header)
                {
                        super (headers, header.value);
                }

                /**************************************************************

                        Iterate over all headers matching the given name. 
                        This wraps the HttpToken iterator to convert the 
                        output into a HeaderElement instead.

                **************************************************************/

                int opApply (int delegate(inout HeaderElement) dg)
                {
                        HeaderElement   element;
                        int             result = 0;
                        
                        foreach (HttpToken token; super)
                                {
                                element.name.value = token.name;
                                element.value = token.value;
                                result = dg (element);
                                if (result)
                                    break;
                                }
                        return result;
                }

        }
}


/******************************************************************************

        Maintains a set of output headers. These are held in an output
        buffer, and indexed via a HttpStack. Deleting a header could be 
        supported by setting the HttpStack entry to null, and ignoring
        such values when it's time to write the headers.

******************************************************************************/

class HttpHeaders : HttpHeadersView
{
        /**********************************************************************
                
                Construct output headers, using the provided buffer as
                a place to stash the header content.

        **********************************************************************/

        this (IBuffer output)
        {
                super ();
                super.setOutputBuffer (output);
        }

        /**********************************************************************
                
                Clone a source set of HttpHeaders

        **********************************************************************/

        this (HttpHeaders source)
        {
                super (source);
        }

        /**********************************************************************
                
                Clone this set of HttpHeaders

        **********************************************************************/

        HttpHeaders clone ()
        {
                return new HttpHeaders (this);
        }

        /**********************************************************************
                
                Add the specified header, and use a callback to provide
                the content.

        **********************************************************************/

        void add (HttpHeaderName name, void delegate (IBuffer) dg)
        {
                super.add (name.value, dg);
        }

        /**********************************************************************
                
                Add the specified header and text 

        **********************************************************************/

        void add (HttpHeaderName name, char[] value)
        {
                super.add (name.value, value);
        }

        /**********************************************************************
                
                Add the specified header and integer value

        **********************************************************************/

        void addInt (HttpHeaderName name, int value)
        {
                super.addInt (name.value, value);
        }

        /**********************************************************************
                
                Add the specified header and long/date value

        **********************************************************************/

        void addDate (HttpHeaderName name, ulong value)
        {
                super.addDate (name.value, value);
        }

        /**********************************************************************
                
                Remove the specified header header. Returns false if not 
                found.

        **********************************************************************/

        bool remove (HttpHeaderName name)
        {
                return super.remove (name.value);
        }

        /**********************************************************************
                
                Return the output buffer provided during construction.

        **********************************************************************/

        IBuffer getOutputBuffer ()
        {
                return super.getOutputBuffer ();
        }
}

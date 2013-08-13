/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpCookies;

private import  tango.stdc.ctype;

private import  tango.io.device.Array;

private import  tango.io.model.IConduit;

private import  tango.io.stream.Iterator;

private import  tango.net.http.HttpHeaders;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        Defines the Cookie class, and the means for reading & writing them.
        Cookie implementation conforms with RFC 2109, but supports parsing 
        of server-side cookies only. Client-side cookies are supported in
        terms of output, but response parsing is not yet implemented ...

        See over <A HREF="http://www.faqs.org/rfcs/rfc2109.html">here</A>
        for the RFC document.        

*******************************************************************************/

class Cookie //: IWritable
{
        const(char)[]   name,
                        path,
                        value,
                        domain,
                        comment;
        uint            vrsn=1;              // 'version' is a reserved word
        bool            secure=false;
        long            maxAge=long.min;

        /***********************************************************************
                
                Construct an empty client-side cookie. You add these
                to an output request using HttpClient.addCookie(), or
                the equivalent.

        ***********************************************************************/

        this () {}

        /***********************************************************************
        
                Construct a cookie with the provided attributes. You add 
                these to an output request using HttpClient.addCookie(), 
                or the equivalent.

        ***********************************************************************/

        this (const(char)[] name, const(char)[] value)
        {
                setName (name);
                setValue (value);
        }

        /***********************************************************************
        
                Set the name of this cookie

        ***********************************************************************/

        Cookie setName (const(char)[] name)
        {
                this.name = name;
                return this;
        }

        /***********************************************************************
        
                Set the value of this cookie

        ***********************************************************************/

        Cookie setValue (const(char)[] value)
        {
                this.value = value;
                return this;
        }

        /***********************************************************************
                
                Set the version of this cookie

        ***********************************************************************/

        Cookie setVersion (uint vrsn)
        {
                this.vrsn = vrsn;
                return this;
        }

        /***********************************************************************
        
                Set the path of this cookie

        ***********************************************************************/

        Cookie setPath (const(char)[] path)
        {
                this.path = path;
                return this;
        }

        /***********************************************************************
        
                Set the domain of this cookie

        ***********************************************************************/

        Cookie setDomain (const(char)[] domain)
        {
                this.domain = domain;
                return this;
        }

        /***********************************************************************
        
                Set the comment associated with this cookie

        ***********************************************************************/

        Cookie setComment (const(char)[] comment)
        {
                this.comment = comment;
                return this;
        }

        /***********************************************************************
        
                Set the maximum duration of this cookie

        ***********************************************************************/

        Cookie setMaxAge (long maxAge)
        {
                this.maxAge = maxAge;
                return this;
        }

        /***********************************************************************
        
                Indicate whether this cookie should be considered secure or not

        ***********************************************************************/

        Cookie setSecure (bool secure)
        {
                this.secure = secure;
                return this;
        }
/+
        /***********************************************************************
        
                Output the cookie as a text stream, via the provided IWriter

        ***********************************************************************/

        void write (IWriter writer)
        {
                produce (&writer.buffer.consume);
        }
+/
        /***********************************************************************
        
                Output the cookie as a text stream, via the provided consumer

        ***********************************************************************/

        void produce (scope size_t delegate(const(void)[]) consume)
        {
                consume (name);

                if (value.length)
                    consume ("="), consume (value);

                if (path.length)
                    consume (";Path="), consume (path);

                if (domain.length)
                    consume (";Domain="), consume (domain);

                if (vrsn)
                   {
                   char[16] tmp = void;

                   consume (";Version=");
                   consume (Integer.format (tmp, vrsn));

                   if (comment.length)
                       consume (";Comment=\""), consume(comment), consume("\"");

                   if (secure)
                       consume (";Secure");

                   if (maxAge != maxAge.min)
                       consume (";Max-Age="c), consume (Integer.format (tmp, maxAge));
                   }
        }

        /***********************************************************************
        
                Reset this cookie

        ***********************************************************************/

        Cookie clear ()
        {
                vrsn = 1;
                secure = false;
                maxAge = maxAge.min;
                name = path = domain = comment = null;
                return this;
        }
}



/*******************************************************************************

        Implements a stack of cookies. Each cookie is pushed onto the
        stack by a parser, which takes its input from HttpHeaders. The
        stack can be populated for both client and server side cookies.

*******************************************************************************/

class CookieStack
{
        private int             depth;
        private Cookie[]        cookies;

        /**********************************************************************

                Construct a cookie stack with the specified initial extent.
                The stack will grow as necessary over time.

        **********************************************************************/

        this (int size)
        {
                cookies = new Cookie[0];
                resize (cookies, size);
        }

        /**********************************************************************

                Pop the stack all the way to zero

        **********************************************************************/

        final void reset ()
        {
                depth = 0;
        }

        /**********************************************************************

                Return a fresh cookie from the stack

        **********************************************************************/

        final Cookie push ()
        {
                if (depth == cookies.length)
                    resize (cookies, depth * 2);
                return cookies [depth++];
        }
        
        /**********************************************************************

                Resize the stack such that it has more room.

        **********************************************************************/

        private final static void resize (ref Cookie[] cookies, size_t size)
        {
                size_t i = cookies.length;
                
                for (cookies.length=size; i < cookies.length; ++i)
                     cookies[i] = new Cookie();
        }

        /**********************************************************************

                Iterate over all cookies in stack

        **********************************************************************/

        int opApply (scope int delegate(ref Cookie) dg)
        {
                int result = 0;

                for (int i=0; i < depth; ++i)
                     if ((result = dg (cookies[i])) != 0)
                          break;
                return result;
        }
}



/*******************************************************************************

        This is the support point for server-side cookies. It wraps a
        CookieStack together with a set of HttpHeaders, along with the
        appropriate cookie parser. One would do something very similar
        for client side cookie parsing also.

*******************************************************************************/

class HttpCookiesView //: IWritable
{
        private bool                    parsed;
        private CookieStack             stack;
        private CookieParser            parser;
        private HttpHeadersView         headers;

        /**********************************************************************

                Construct cookie wrapper with the provided headers.

        **********************************************************************/

        this (HttpHeadersView headers)
        {
                this.headers = headers;

                // create a stack for parsed cookies
                stack = new CookieStack (10);

                // create a parser
                parser = new CookieParser (stack);
        }
/+
        /**********************************************************************

                Output each of the cookies parsed to the provided IWriter.

        **********************************************************************/

        void write (IWriter writer)
        {
                produce (&writer.buffer.consume, HttpConst.Eol);
        }
+/
        /**********************************************************************

                Output the token list to the provided consumer

        **********************************************************************/

        void produce (scope size_t delegate(const(void)[]) consume, const(char)[] eol = HttpConst.Eol)
        {
                foreach (cookie; parse())
                         cookie.produce (consume), consume (eol);
        }

        /**********************************************************************

                Reset these cookies for another parse

        **********************************************************************/

        void reset ()
        {
                stack.reset();
                parsed = false;
        }

        /**********************************************************************

                Parse all cookies from our HttpHeaders, pushing each onto
                the CookieStack as we go.

        **********************************************************************/

        CookieStack parse ()
        {
                if (! parsed)
                   {
                   parsed = true;

                   foreach (HeaderElement header; headers)
                            if (header.name.value == HttpHeader.Cookie.value)
                                parser.parse (header.value);
                   }
                return stack;
        }
}



/*******************************************************************************

        Handles a set of output cookies by writing them into the list of
        output headers.

*******************************************************************************/

class HttpCookies
{
        private HttpHeaderName  name;
        private HttpHeaders     headers;

        /**********************************************************************

                Construct an output cookie wrapper upon the provided 
                output headers. Each cookie added is converted to an
                addition to those headers.

        **********************************************************************/

        this (HttpHeaders headers, const(HttpHeaderName) name = HttpHeader.SetCookie)
        {
                this.headers = headers;
                this.name = name;
        }

        /**********************************************************************

                Add a cookie to our output headers.

        **********************************************************************/

        void add (Cookie cookie)
        {
                // add the cookie header via our callback
                headers.add (name, (OutputBuffer buf){cookie.produce (&buf.write);});        
        }
}



/*******************************************************************************

        Server-side cookie parser. See RFC 2109 for details.

*******************************************************************************/

class CookieParser : Iterator!(char)
{
        private enum State {Begin, LValue, Equals, RValue, Token, SQuote, DQuote};

        private CookieStack       stack;
        private Array             array;
        private static __gshared bool[128]  charMap;

        /***********************************************************************

                populate a map of token separators

        ***********************************************************************/

        shared static this ()
        {
                charMap['('] = true;
                charMap[')'] = true;
                charMap['<'] = true;
                charMap['>'] = true;
                charMap['@'] = true;
                charMap[','] = true;
                charMap[';'] = true;
                charMap[':'] = true;
                charMap['\\'] = true;
                charMap['"'] = true;
                charMap['/'] = true;
                charMap['['] = true;
                charMap[']'] = true;
                charMap['?'] = true;
                charMap['='] = true;
                charMap['{'] = true;
                charMap['}'] = true;
        }
        
        /***********************************************************************

        ***********************************************************************/

        this (CookieStack stack)
        {
                super();
                this.stack = stack;
                array = new Array(0);
        }

        /***********************************************************************

                Callback for iterator.next(). We scan for name-value
                pairs, populating Cookie instances along the way.

        ***********************************************************************/

        protected override size_t scan (const(void)[] data)
        {      
                char           c;
                int            mark,
                               vrsn;
                const(char)[]  name,
                               token;
                Cookie         cookie;

                State          state = State.Begin;
                const(char)[]  content = cast(const(char)[]) data;

                /***************************************************************

                        Found a value; set that also

                ***************************************************************/

                void setValue (size_t i)
                {   
                        token = content [mark..i];
                        //Print ("::name '%.*s'\n", name);
                        //Print ("::value '%.*s'\n", token);

                        if (name[0] != '$')
                           {
                           cookie = stack.push();
                           cookie.setName (name);
                           cookie.setValue (token);
                           cookie.setVersion (vrsn);
                           }
                        else
                           {
                           if(name.length < 9)
                              {
                              char[8] temp;
                              temp[0..name.length] = name[];
                              switch (toLower (temp[0..name.length]))
                                     {
                                     case "$path":
                                           if (cookie)
                                               cookie.setPath (token); 
                                           break;

                                     case "$domain":
                                           if (cookie)
                                               cookie.setDomain (token); 
                                           break;

                                     case "$version":
                                           vrsn = cast(int) Integer.parse (token); 
                                           break;

                                     default:
                                          break;
                                     }
                               }
                           }
                        state = State.Begin;
                }

                /***************************************************************

                        Scan content looking for cookie fields

                ***************************************************************/

                for (int i; i < content.length; ++i)
                    {
                    c = content [i];
                    switch (state)
                           {
                           // look for an lValue
                           case State.Begin:
                                mark = i;
                                if (isToken(c))
                                    state = State.LValue;
                                continue;

                           // scan until we have all lValue chars
                           case State.LValue:
                                if (! isToken(c))
                                   {
                                   state = State.Equals;
                                   name = content [mark..i];
                                   --i;
                                   }
                                continue;

                           // should now have either a '=', ';', or ','
                           case State.Equals:
                                if (c is '=')
                                    state = State.RValue;
                                else
                                   if (c is ',' || c is ';')
                                       // get next NVPair
                                       state = State.Begin;
                                continue;

                           // look for a quoted token, or a plain one
                           case State.RValue:
                                mark = i;
                                if (c is '\'')
                                    state = State.SQuote;
                                else
                                   if (c is '"')
                                       state = State.DQuote;
                                   else
                                      if (isToken(c))
                                          state = State.Token;
                                continue;

                           // scan for all plain token chars
                           case State.Token:
                                if (! isToken(c))
                                   {
                                   setValue (i);
                                   --i;
                                   }
                                continue;

                           // scan until the next '
                           case State.SQuote:
                                if (c is '\'')
                                    ++mark, setValue (i);
                                continue;

                           // scan until the next "
                           case State.DQuote:
                                if (c is '"')
                                    ++mark, setValue (i);
                                continue;

                           default:
                                continue;
                           }
                    }

                // we ran out of content; patch partial cookie values 
                if (state is State.Token)
                    setValue (content.length);

                // go home
                return IConduit.Eof;
        }
                                
        /***********************************************************************
        
                Locate the next token from the provided buffer, and map a
                buffer reference into token. Returns true if a token was 
                located, false otherwise. 

                Note that the buffer content is not duplicated. Instead, a
                slice of the buffer is referenced by the token. You can use
                Token.clone() or Token.toString().dup() to copy content per
                your application needs.

                Note also that there may still be one token left in a buffer 
                that was not terminated correctly (as in eof conditions). In 
                such cases, tokens are mapped onto remaining content and the 
                buffer will have no more readable content.

        ***********************************************************************/

        bool parse (const(char)[] header)
        {
                super.set (array.assign (cast(void[]) header));
                return next.ptr > null;
        }

        /**********************************************************************

                in-place conversion to lowercase 

        **********************************************************************/

        final static char[] toLower (char[] src)
        {
                foreach (int i, char c; src)
                         if (c >= 'A' && c <= 'Z')
                             src[i] = cast(char)(c + ('a' - 'A'));
                return src;
        }

        /***********************************************************************

                Is 'c' a valid token character?

        ***********************************************************************/

        private static bool isToken (char c)
        {
                return (c > 32 && c < 127 && !charMap[c]);
        }
}
   
     

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.Uri;

private import  tango.io.Exception;

private import  tango.text.convert.Integer;

/*******************************************************************************

*******************************************************************************/

extern (C) char* memchr (char *, char, uint);

/*******************************************************************************

        Implements an RFC 2396 compliant URI specification. See 
        <A HREF="http://ftp.ics.uci.edu/pub/ietf/uri/rfc2396.txt">this page</A>
        for more information. 

        The implementation fails the spec on two counts: it doesn't insist
        on a scheme being present in the UriView, and it doesn't implement the
        "Relative References" support noted in section 5.2. 
        
        Note that IRI support can be implied by assuming each of userinfo, path, 
        query, and fragment are UTF-8 encoded 
        (see <A HREF="http://www.w3.org/2001/Talks/0912-IUC-IRI/paper.html">
        this page</A> for further details).

        Use the Uri derivative where you need to alter specific uri
        attributes. 

*******************************************************************************/

class UriView
{
        public const int        InvalidPort = -1;

        private int             port;
        private char[]          host,
                                path,
                                query,
                                scheme,
                                userinfo,
                                fragment;
        private HeapSlice       decoded;

        private static ubyte    map[256];

                    
        private static short[char[]] genericSchemes;

        private static const char[] hexDigits = "0123456789abcdef";

        private static IOException error;

        private enum    {
                        ExcScheme       = 0x01, 
                        ExcAuthority    = 0x02, 
                        ExcPath         = 0x04, 
                        ExcQuery        = 0x08, 
                        IncUser         = 0x10, 
                        IncPath         = 0x20,
                        IncQuery        = 0x40,
                        IncScheme       = 0x80,
                        IncGeneric      = IncScheme | IncUser | IncPath | IncQuery
                        };

        private struct SchemePort
        {
                        char[]  name;
                        short   port;
        }

        private static  const SchemePort[] schemePorts =
                        [
                        {"coffee",      80},
                        {"file",        InvalidPort},
                        {"ftp",         21},
                        {"gopher",      70},
                        {"hnews",       80},
                        {"http",        80},
                        {"http-ng",     80},
                        {"https",       443},
                        {"imap",        143},
                        {"irc",         194}, 
                        {"ldap",        389},
                        {"news",        119},
                        {"nfs",         2049}, 
                        {"nntp",        119},
                        {"pop",         110}, 
                        {"prospero",    1525},
                        {"rwhois",      4321},
                        {"sip",         InvalidPort},
                        {"sips",        InvalidPort},
                        {"sipt",        InvalidPort},
                        {"sipu",        InvalidPort},
                        {"shttp",       80},
                        {"smtp",        25},
                        {"snews",       563},
                        {"telnet",      23},
                        {"vemmi",       575},
                        {"videotex",    516},
                        {"wais",        210},
                        {"whois",       43},
                        {"whois++",     43},
                        ];


        private alias void delegate (void[]) Consumer;  // simplistic string appender


        /***********************************************************************
        
                Initialize the UriView character maps and so on

        ***********************************************************************/

        static this ()
        {
                error = new IOException ("Invalid URI specification");

                // Map known generic schemes to their default port. Specify
                // InvalidPort for those schemes that don't use ports. Note
                // that a port value of zero is not supported ...
                foreach (SchemePort sp; schemePorts)
                         genericSchemes[sp.name] = sp.port;
                genericSchemes.rehash;

                // load the character map with valid symbols
                for (int i='a'; i <= 'z'; ++i)  
                     map[i] = IncGeneric;

                for (int i='A'; i <= 'Z'; ++i)  
                     map[i] = IncGeneric;

                for (int i='0'; i<='9'; ++i)  
                     map[i] = IncGeneric;

                // exclude these from parsing elements
                map[':'] |= ExcScheme;
                map['/'] |= ExcScheme | ExcAuthority;
                map['?'] |= ExcScheme | ExcAuthority | ExcPath;
                map['#'] |= ExcScheme | ExcAuthority | ExcPath | ExcQuery;

                // include these as common symbols
                map['-'] |= IncUser | IncQuery;
                map['_'] |= IncUser | IncQuery;
                map['.'] |= IncUser | IncQuery;
                map['!'] |= IncUser | IncQuery;
                map['~'] |= IncUser | IncQuery;
                map['*'] |= IncUser | IncQuery;
                map['\''] |= IncUser | IncQuery;
                map['('] |= IncUser | IncQuery;
                map[')'] |= IncUser | IncQuery;

                // include these as scheme symbols
                map['+'] |= IncScheme;
                map['-'] |= IncScheme;
                map['.'] |= IncScheme;

                // include these as userinfo symbols
                map[';'] |= IncUser;
                map[':'] |= IncUser;
                map['&'] |= IncUser;
                map['='] |= IncUser;
                map['+'] |= IncUser;
                map['$'] |= IncUser;
                map[','] |= IncUser;

                // include these as path symbols
                map['/'] |= IncPath;
                map[';'] |= IncPath;
                map[':'] |= IncPath;
                map['@'] |= IncPath;
                map['&'] |= IncPath;
                map['='] |= IncPath;
                map['+'] |= IncPath;
                map['$'] |= IncPath;
                map[','] |= IncPath;

                // include these as query symbols
                map[';'] |= IncQuery;
                map['/'] |= IncQuery;
                map['?'] |= IncQuery;
                map[':'] |= IncQuery;
                map['@'] |= IncQuery;
                map['&'] |= IncQuery;
                map['='] |= IncQuery;
                map['+'] |= IncQuery;
                map['$'] |= IncQuery;
                map[','] |= IncQuery;
        }
        
        /***********************************************************************
        
                Construct a UriView from the provided character string

        ***********************************************************************/

        this (char[] uri)
        {
                this();
                parse (uri);
        }

        /***********************************************************************
        
                Return the default port for the given scheme. InvalidPort
                is returned if the scheme is unknown, or does not accept
                a port.

        ***********************************************************************/

        final static int getDefaultPort (char[] scheme)
        {
                short* port = scheme in genericSchemes; 
                if (port is null)
                    return InvalidPort;
                return *port;
        }

        /***********************************************************************
        
                Return the parsed scheme, or null if the scheme was not
                specified

        ***********************************************************************/

        char[] getScheme()
        {
                return scheme;
        }

        /***********************************************************************
        
                Return the parsed host, or null if the host was not
                specified

        ***********************************************************************/

        char[] getHost()
        {
                return host;
        }

        /***********************************************************************
        
                Return the parsed port number, or InvalidPort if the port
                was not provided.

        ***********************************************************************/

        int getPort()
        {
                return port;
        }

        /***********************************************************************
        
                Return a valid port number by performing a lookup on the 
                known schemes if the port was not explicitly specified.

        ***********************************************************************/

        int getValidPort()
        {
                if (port is InvalidPort)
                    return getDefaultPort (scheme);
                return port;
        }

        /***********************************************************************
        
                Return the parsed userinfo, or null if userinfo was not 
                provided.

        ***********************************************************************/

        char[] getUserInfo()
        {
                return userinfo;
        }

        /***********************************************************************
        
                Return the parsed path, or null if the path was not 
                provided.

        ***********************************************************************/

        char[] getPath()
        {
                return path;
        }

        /***********************************************************************
        
                Return the parsed query, or null if a query was not 
                provided.

        ***********************************************************************/

        char[] getQuery()
        {
                return query;
        }

        /***********************************************************************
        
                Return the parsed fragment, or null if a fragment was not 
                provided.

        ***********************************************************************/

        char[] getFragment()
        {
                return fragment;
        }

        /***********************************************************************
        
                Return whether or not the UriView scheme is considered generic.

        ***********************************************************************/

        bool isGeneric ()
        {
                return cast(bool) ((scheme in genericSchemes) !is null);
        }

        /***********************************************************************
        
                Emit the content of this UriView via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        Consumer produce (Consumer consume)
        {
                if (scheme.length)
                    consume (scheme), consume (":");


                if (userinfo.length || host.length || port != InvalidPort)
                   {
                   consume ("//");

                   if (userinfo.length)
                       encode (consume, userinfo, IncUser) ("@");

                   if (host.length)
                       consume (host);

                   if (port != InvalidPort && port != getDefaultPort(scheme))
                      {
                      char[4] tmp;
                      consume (":"), consume (Integer.format (tmp, port));
                      }
                   }

                if (path.length)
                    encode (consume, path, IncPath);

                if (query.length)
                   {
                   consume ("?");
                   encode (consume, query, IncQuery);
                   }

                if (fragment.length)
                   {
                   consume ("#");
                   encode (consume, fragment, IncQuery);
                   }

                return consume;
        }

        /***********************************************************************
        
                Emit the content of this UriView via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        override char[] toUtf8 ()
        {
                char[] s;

                s.length = 256, s.length = 0;
                produce ((void[] v) {s ~= cast(char[]) v;});
                return s;
        }

        /***********************************************************************
        
                Encode uri characters into a Consumer, such that
                reserved chars are converted into their %hex version.

        ***********************************************************************/

        static Consumer encode (Consumer consume, char[] s, int flags)
        {
                char[3] hex;
                int     mark;

                hex[0] = '%';
                foreach (int i, char c; s)
                        {
                        if (! (map[c] & flags))
                           {
                           consume (s[mark..i]);
                           mark = i+1;
                                
                           hex[1] = hexDigits [(c >> 4) & 0x0f];
                           hex[2] = hexDigits [c & 0x0f];
                           consume (hex);
                           }
                        }

                // add trailing section
                if (mark < s.length)
                    consume (s[mark..s.length]);

                return consume;
        }

        /***********************************************************************
        
                Decode a character string with potential %hex values in it.
                The decoded strings are placed into a thread-safe expanding
                buffer, and a slice of it is returned to the requestor.

        ***********************************************************************/

        char[] decode (char[] s)
        {
                static int toInt (char c)
                {
                        if (c >= '0' && c <= '9')
                            c -= '0';
                        else
                        if (c >= 'a' && c <= 'f')
                            c -= ('a' - 10);
                        else
                        if (c >= 'A' && c <= 'F')
                            c -= ('A' - 10);
                        return c;
                }
                
                int length = s.length;

                // take a peek first, to see if there's work to do
                if (length && memchr (s, '%', length))
                   {
                   char* p;
                   int   j;
                        
                   // ensure we have enough decoding space available
                   p = cast(char*) decoded.expand (length);

                   // scan string, stripping % encodings as we go
                   for (int i; i < length; ++i, ++j, ++p)
                       {
                       int c = s[i];
                       if (c is '%' && (i+2) < length)
                          {
                          c = toInt(s[i+1]) * 16 + toInt(s[i+2]);
                          i += 2;
                          }

                       *p = c;
                       }
                   // return a slice from the decoded input
                   return cast(char[]) decoded.slice (j);
                   }

                // return original content
                return s;
        }   

        /***********************************************************************
        
                This should not be exposed outside of this module!

        ***********************************************************************/

        private this ()
        {
                port = InvalidPort;
                decoded = new HeapSlice (256);
        }

        /***********************************************************************
        
                Parsing is performed according to RFC 2396
                
                ---
                  ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
                   12            3  4          5       6  7        8 9
                    
                2 isolates scheme
                4 isolates authority
                5 isolates path
                7 isolates query
                9 isolates fragment
                ---

                This was originally a state-machine; it turned out to be a 
                lot faster (~40%) when unwound like this instead.
                
        ***********************************************************************/

        private void parse (char[] uri, bool relative = false)
        {
                char    c;
                int     i, 
                        mark, 
                        len = uri.length;

                // isolate scheme (note that it's OK to not specify a scheme)
                for (i=0; i < len && !(map[c = uri[i]] & ExcScheme); ++i) {}
                if (c is ':')
                   {
                   scheme = uri [mark..i];
                   toLower (scheme);
                   mark = i + 1;
                   }

                // isolate authority
                if (mark < len-1  &&  uri[mark] is '/'  &&  uri[mark+1] is '/')
                   {
                   for (mark+=2, i=mark; i < len && !(map[uri[i]] & ExcAuthority); ++i) {}
                   parseAuthority (uri[mark..i]); 
                   mark = i;
                   }
                else
                   if (relative && uri[0] != '/')
                      {
                      uri = toLastSlash(path) ~ uri;
                      query = fragment = null;
                      len = uri.length;
                      }

                // isolate path
                for (i=mark; i < len && !(map[uri[i]] & ExcPath); ++i) {}
                path = decode (uri[mark..i]);
                mark = i;

                // isolate query
                if (mark < len && uri[mark] is '?')
                   {
                   for (++mark, i=mark; i < len && uri[i] != '#'; ++i) {}
                   query = decode (uri[mark..i]);
                   mark = i;
                   }

                // isolate fragment
                if (mark < len && uri[mark] is '#')
                    fragment = decode (uri[mark+1..len]);
        }

        /***********************************************************************
        
                Authority is the section after the scheme, but before the 
                path, query or fragment; it typically represents a host.
               
                ---
                    ^(([^@]*)@?)([^:]*)?(:(.*))?
                     12         3       4 5
                  
                2 isolates userinfo
                3 isolates host
                5 isolates port
                ---

        ***********************************************************************/

        private void parseAuthority (char[] auth)
        {
                int     mark,
                        len = auth.length;

                // get userinfo: (([^@]*)@?)
                foreach (int i, char c; auth)
                         if (c is '@')
                            {
                            userinfo = decode (auth[0..i]);
                            mark = i + 1;
                            break;
                            }

                // get port: (:(.*))?
                for (int i=mark; i < len; ++i)
                     if (auth [i] is ':')
                        {
                        port = cast(int) Integer.parse (auth [i+1..len]);
                        len = i;
                        break;
                        }

                // get host: ([^:]*)?
                host = auth [mark..len];
        }

        /**********************************************************************

        **********************************************************************/

        private char[] toLastSlash (char[] path)
        {
                for (char*p = path.ptr+path.length; --p >= path.ptr;)
                     if (*p is '/')
                         return path [0 .. (p-path.ptr)+1];
                return path;
        }

        /**********************************************************************

                in-place conversion to lowercase 

        **********************************************************************/

        final static char[] toLower (inout char[] src)
        {
                foreach (inout char c; src)
                         if (c >= 'A' && c <= 'Z')
                             c = c + ('a' - 'A');
                return src;
        }
}



/*******************************************************************************

        Mutable version of UriView

*******************************************************************************/

class Uri : UriView
{
        /***********************************************************************
        
                Create an empty UriView

        ***********************************************************************/

        this ()
        {
                super();
        }

        /***********************************************************************
        
                Create a UriView from the provided text string.

        ***********************************************************************/

        this (char[] uri)
        {
                super (uri);
        }

        /***********************************************************************
        
                Construct a UriView from the given components. The query is
                optional.
                
        ***********************************************************************/

        this (char[] scheme, char[] host, char[] path, char[] query = null)
        {
                super();

                this.scheme = scheme;
                this.query = query;
                this.host = host;
                this.path = path;
        }

        /***********************************************************************
        
                Clone another UriView. This can be used to make a Uri
                from an immutable UriView.

        ***********************************************************************/

        static Uri clone (UriView uri)
        {
                with (uri)
                     {
                     Uri ret = new Uri (scheme, host, path, query);
                     ret.userinfo = userinfo;
                     ret.fragment = fragment;
                     ret.port = port;
                     return ret;
                     }
        }

        /***********************************************************************
        
                Clear everything to null.

        ***********************************************************************/

        void reset()
        {
                decoded.reset();
                port = InvalidPort;
                host = path = query = scheme = userinfo = fragment = null;
        }

        /***********************************************************************
        
                Parse the given uri string

        ***********************************************************************/

        Uri parse (char[] uri)
        {       
                super.parse (uri);
                return this;
        }

        /***********************************************************************
        
                Parse the given uri, with support for relative URLs

        ***********************************************************************/

        Uri relParse (char[] uri)
        {
                super.parse (uri, true);
                return this;
        }
        
        /***********************************************************************
                
                Set the UriView scheme

        ***********************************************************************/

        Uri setScheme (char[] scheme)
        {
                this.scheme = scheme;
                return this;
        }

        /***********************************************************************
        
                Set the UriView host

        ***********************************************************************/

        Uri setHost (char[] host)
        {
                this.host = host;
                return this;
        }

        /***********************************************************************
        
                Set the UriView port

        ***********************************************************************/

        Uri setPort (int port)
        {
                this.port = port;
                return this;
        }

        /***********************************************************************
        
                Set the UriView userinfo

        ***********************************************************************/

        Uri setUserInfo(char[] userinfo)
        {
                this.userinfo = userinfo;
                return this;
        }

        /***********************************************************************
        
                Set the UriView query

        ***********************************************************************/

        Uri setQuery (char[] query)
        {
                this.query = query;
                return this;
        }

        /***********************************************************************
        
                Extend the UriView query

        ***********************************************************************/

        char[] extendQuery (char[] tail)
        {
                if (tail.length)
                    if (query.length)
                        query = query ~ "&" ~ tail;
                    else
                       query = tail;
                return query;
        }

        /***********************************************************************
        
                Set the UriView path

        ***********************************************************************/

        Uri setPath (char[] path)
        {
                this.path = path;
                return this;
        }

        /***********************************************************************
        
                Set the UriView fragment

        ***********************************************************************/

        Uri setFragment (char[] fragment)
        {
                this.fragment = fragment;
                return this;
        }
}


/*******************************************************************************
        
*******************************************************************************/

private class HeapSlice
{
        private uint    used;
        private void[]  buffer;

        /***********************************************************************
        
                Create with the specified starting size

        ***********************************************************************/

        this (uint size)
        {
                buffer = new void[size];
        }

        /***********************************************************************
        
                Reset content length to zero

        ***********************************************************************/

        void reset ()
        {
                used = 0;
        }

        /***********************************************************************
        
                Potentially expand the content space, and return a pointer
                to the start of the empty section.

        ***********************************************************************/

        void* expand (uint size)
        {
                if ((used + size) > buffer.length)
                     buffer.length = (used + size) * 2;
                return &buffer [used];
        }

        /***********************************************************************
        
                Return a slice of the content from the current position 
                with the specified size. Adjusts the current position to 
                point at an empty zone.

        ***********************************************************************/

        void[] slice (int size)
        {
                uint i = used;
                used += size;
                return buffer [i..used];
        }
}



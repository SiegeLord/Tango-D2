/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.Uri;

public  import  tango.net.model.UriView;

//public alias Uri UriView;

private import  tango.core.Exception;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        external links
        
*******************************************************************************/

extern (C) char* memchr (char *, int, size_t);


/*******************************************************************************

        Implements an RFC 2396 compliant URI specification. See 
        <A HREF="http://ftp.ics.uci.edu/pub/ietf/uri/rfc2396.txt">this page</A>
        for more information. 

        The implementation fails the spec on two counts: it doesn't insist
        on a scheme being present in the Uri, and it doesn't implement the
        "Relative References" support noted in section 5.2. The latter can
        be found in tango.util.PathUtil instead.
        
        Note that IRI support can be implied by assuming each of userinfo,
        path, query, and fragment are UTF-8 encoded 
        (see <A HREF="http://www.w3.org/2001/Talks/0912-IUC-IRI/paper.html">
        this page</A> for further details).

*******************************************************************************/

class Uri : UriView
{
        // simplistic string appender
        private alias size_t delegate(void[]) Consumer;  
        
        /// old method names
        public alias port        getPort;
        public alias defaultPort getDefaultPort;
        public alias scheme      getScheme;
        public alias host        getHost;
        public alias validPort   getValidPort;
        public alias userinfo    getUserInfo;
        public alias path        getPath;
        public alias query       getQuery;
        public alias fragment    getFragment;
        public alias port        setPort;
        public alias scheme      setScheme;
        public alias host        setHost;
        public alias userinfo    setUserInfo;
        public alias query       setQuery;
        public alias path        setPath;
        public alias fragment    setFragment;

        public enum {InvalidPort = -1}

        private int             port_;
        private char[]          host_,
                                path_,
                                query_,
                                scheme_,
                                userinfo_,
                                fragment_;
        private HeapSlice       decoded;

        private static ubyte    map[];

        private static short[char[]] genericSchemes;

        private static const char[] hexDigits = "0123456789abcdef";

        private static const SchemePort[] schemePorts =
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
                {"rwhois",      4321},
                {"shttp",       80},
                {"smtp",        25},
                {"snews",       563},
                {"telnet",      23},
                {"wais",        210},
                {"whois",       43},
                {"whois++",     43},
                ];

        public enum    
        {       
                ExcScheme       = 0x01,         
                ExcAuthority    = 0x02, 
                ExcPath         = 0x04, 
                IncUser         = 0x80,         // encode spec for User
                IncPath         = 0x10,         // encode spec for Path
                IncQuery        = 0x20,         // encode spec for Query
                IncQueryAll     = 0x40,
                IncScheme       = 0x80,         // encode spec for Scheme
                IncGeneric      = IncScheme | 
                                  IncUser   | 
                                  IncPath   | 
                                  IncQuery  | 
                                  IncQueryAll
        }

        // scheme and port pairs
        private struct SchemePort
        {
                char[]  name;
                short   port;
        }

        /***********************************************************************
        
                Initialize the Uri character maps and so on

        ***********************************************************************/

        static this ()
        {
                // Map known generic schemes to their default port. Specify
                // InvalidPort for those schemes that don't use ports. Note
                // that a port value of zero is not supported ...
                foreach (SchemePort sp; schemePorts)
                         genericSchemes[sp.name] = sp.port;
                genericSchemes.rehash;

                map = new ubyte[256];

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
                map['#'] |= ExcScheme | ExcAuthority | ExcPath;

                // include these as common (unreserved) symbols
                map['-'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['_'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['.'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['!'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['~'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['*'] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['\''] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map['('] |= IncUser | IncQuery | IncQueryAll | IncPath;
                map[')'] |= IncUser | IncQuery | IncQueryAll | IncPath;

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
                map[';'] |= IncQuery | IncQueryAll;
                map['/'] |= IncQuery | IncQueryAll;
                map[':'] |= IncQuery | IncQueryAll;
                map['@'] |= IncQuery | IncQueryAll;
                map['='] |= IncQuery | IncQueryAll;
                map['$'] |= IncQuery | IncQueryAll;
                map[','] |= IncQuery | IncQueryAll;

                // '%' are permitted inside queries when constructing output
                map['%'] |= IncQueryAll;
                map['?'] |= IncQueryAll;
                map['&'] |= IncQueryAll;
        }
        
        /***********************************************************************
        
                Create an empty Uri

        ***********************************************************************/

        this ()
        {
                port_ = InvalidPort;
                decoded.expand (512);
        }

        /***********************************************************************
        
                Construct a Uri from the provided character string

        ***********************************************************************/

        this (char[] uri)
        {
                this ();
                parse (uri);
        }

        /***********************************************************************
        
                Construct a Uri from the given components. The query is
                optional.
                
        ***********************************************************************/

        this (char[] scheme, char[] host, char[] path, char[] query = null)
        {
                this ();

                this.scheme_ = scheme;
                this.query_ = query;
                this.host_ = host;
                this.path_ = path;
        }

        /***********************************************************************
        
                Clone another Uri. This can be used to make a mutable Uri
                from an immutable UriView.

        ***********************************************************************/

        this (UriView other)
        {
                with (other)
                     {
                     this (getScheme, getHost, getPath, getQuery);
                     this.userinfo_ = getUserInfo;
                     this.fragment_ = getFragment;
                     this.port_ = getPort;
                     }
        }

        /***********************************************************************
        
                Return the default port for the given scheme. InvalidPort
                is returned if the scheme is unknown, or does not accept
                a port.

        ***********************************************************************/

        final int defaultPort (char[] scheme)
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

        final char[] scheme()
        {
                return scheme_;
        }

        /***********************************************************************
        
                Return the parsed host, or null if the host was not
                specified

        ***********************************************************************/

        final char[] host()
        {
                return host_;
        }

        /***********************************************************************
        
                Return the parsed port number, or InvalidPort if the port
                was not provided.

        ***********************************************************************/

        final int port()
        {
                return port_;
        }

        /***********************************************************************
        
                Return a valid port number by performing a lookup on the 
                known schemes if the port was not explicitly specified.

        ***********************************************************************/

        final int validPort()
        {
                if (port_ is InvalidPort)
                    return defaultPort (scheme_);
                return port_;
        }

        /***********************************************************************
        
                Return the parsed userinfo, or null if userinfo was not 
                provided.

        ***********************************************************************/

        final char[] userinfo()
        {
                return userinfo_;
        }

        /***********************************************************************
        
                Return the parsed path, or null if the path was not 
                provided.

        ***********************************************************************/

        final char[] path()
        {
                return path_;
        }

        /***********************************************************************
        
                Return the parsed query, or null if a query was not 
                provided.

        ***********************************************************************/

        final char[] query()
        {
                return query_;
        }

        /***********************************************************************
        
                Return the parsed fragment, or null if a fragment was not 
                provided.

        ***********************************************************************/

        final char[] fragment()
        {
                return fragment_;
        }

        /***********************************************************************
        
                Return whether or not the Uri scheme is considered generic.

        ***********************************************************************/

        final bool isGeneric ()
        {
                return (scheme_ in genericSchemes) !is null;
        }

        /***********************************************************************
        
                Emit the content of this Uri via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        final size_t produce (Consumer consume)
        {
                size_t ret;

                if (scheme_.length)
                    ret += consume (scheme_), ret += consume (":");


                if (userinfo_.length || host_.length || port_ != InvalidPort)
                   {
                   ret += consume ("//");

                   if (userinfo_.length)
                       ret += encode (consume, userinfo_, IncUser), ret +=consume ("@");

                   if (host_.length)
                       ret += consume (host_);

                   if (port_ != InvalidPort && port_ != getDefaultPort(scheme_))
                      {
                      char[8] tmp;
                      ret += consume (":"), ret += consume (Integer.itoa (tmp, cast(uint) port_));
                      }
                   }

                if (path_.length)
                    ret += encode (consume, path_, IncPath);

                if (query_.length)
                   {
                   ret += consume ("?");
                   ret += encode (consume, query_, IncQueryAll);
                   }

                if (fragment_.length)
                   {
                   ret += consume ("#");
                   ret += encode (consume, fragment_, IncQuery);
                   }

                return ret;
        }

        /***********************************************************************
        
                Emit the content of this Uri via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        final char[] toString ()
        {
                void[] s;

                s.length = 256, s.length = 0;
                produce ((void[] v) {return s ~= v, v.length;});
                return cast(char[]) s;
        }

        /***********************************************************************
        
                Encode uri characters into a Consumer, such that
                reserved chars are converted into their %hex version.

        ***********************************************************************/

        static size_t encode (Consumer consume, char[] s, int flags)
        {
                size_t  ret;
                char[3] hex;
                int     mark;

                hex[0] = '%';
                foreach (int i, char c; s)
                        {
                        if (! (map[c] & flags))
                           {
                           ret += consume (s[mark..i]);
                           mark = i+1;
                                
                           hex[1] = hexDigits [(c >> 4) & 0x0f];
                           hex[2] = hexDigits [c & 0x0f];
                           ret += consume (hex);
                           }
                        }

                // add trailing section
                if (mark < s.length)
                    ret += consume (s[mark..s.length]);

                return ret;
        }

        /***********************************************************************
        
                Encode uri characters into a string, such that reserved 
                chars are converted into their %hex version.

                Returns a dup'd string

        ***********************************************************************/

        static char[] encode (char[] text, int flags)
        {
                void[] s;
                encode ((void[] v) {return s ~= v, v.length;}, text, flags);
                return cast(char[]) s;
        }

        /***********************************************************************
        
                Decode a character string with potential %hex values in it.
                The decoded strings are placed into a thread-safe expanding
                buffer, and a slice of it is returned to the caller.

        ***********************************************************************/

        private char[] decoder (char[] s, char ignore=0)
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
                
                auto length = s.length;

                // take a peek first, to see if there's work to do
                if (length && memchr (s.ptr, '%', length))
                   {
                   char* p;
                   int   j;
                        
                   // ensure we have enough decoding space available
                   p = cast(char*) decoded.expand (length);

                   // scan string, stripping % encodings as we go
                   for (auto i = 0; i < length; ++i, ++j, ++p)
                       {
                       int c = s[i];

                       if (c is '%' && (i+2) < length)
                          {
                          c = toInt(s[i+1]) * 16 + toInt(s[i+2]);

                          // leave ignored escapes in the stream, 
                          // permitting escaped '&' to remain in
                          // the query string
                          if (c && (c is ignore))
                              c = '%';
                          else
                             i += 2;
                          }

                       *p = cast(char)c;
                       }

                   // return a slice from the decoded input
                   return cast(char[]) decoded.slice (j);
                   }

                // return original content
                return s;
        }   

        /***********************************************************************
        
                Decode a duplicated string with potential %hex values in it

        ***********************************************************************/

        final char[] decode (char[] s)
        {
                return decoder(s).dup;
        }

        /***********************************************************************
        
                Parsing is performed according to RFC 2396
                
                <pre>
                  ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
                   12            3  4          5       6  7        8 9
                    
                2 isolates scheme
                4 isolates authority
                5 isolates path
                7 isolates query
                9 isolates fragment
                </pre>

                This was originally a state-machine; it turned out to be a 
                lot faster (~40%) when unwound like this instead.
                
        ***********************************************************************/

        final Uri parse (char[] uri, bool relative = false)
        {
                char    c;
                int     i, 
                        mark;
                auto    prefix = path_;
                auto    len = uri.length;

                if (! relative)
                      reset;

                // isolate scheme (note that it's OK to not specify a scheme)
                for (i=0; i < len && !(map[c = uri[i]] & ExcScheme); ++i) {}
                if (c is ':')
                   {
                   scheme_ = uri [mark .. i];   
                   toLower (scheme_);
                   mark = i + 1;
                   }

                // isolate authority
                if (mark < len-1 && uri[mark] is '/' && uri[mark+1] is '/')
                   {
                   for (mark+=2, i=mark; i < len && !(map[uri[i]] & ExcAuthority); ++i) {}
                   parseAuthority (uri[mark .. i]); 
                   mark = i;
                   }
                else
                   if (relative)
                      {
                      auto head = (uri[0] is '/') ? host_ : toLastSlash(prefix);
                      query_ = fragment_ = null;
                      uri = head ~ uri;
                      len = uri.length;
                      mark = head.length;
                      }

                // isolate path
                for (i=mark; i < len && !(map[uri[i]] & ExcPath); ++i) {}
                path_ = decoder (uri[mark .. i]);
                mark = i;

                // isolate query
                if (mark < len && uri[mark] is '?')
                   {
                   for (++mark, i=mark; i < len && uri[i] != '#'; ++i) {}
                   query_ = decoder (uri[mark .. i], '&');
                   mark = i;
                   }

                // isolate fragment
                if (mark < len && uri[mark] is '#')
                    fragment_ = decoder (uri[mark+1 .. len]);

                return this;
        }

        /***********************************************************************
        
                Clear everything to null.

        ***********************************************************************/

        final void reset()
        {
                decoded.reset;
                port_ = InvalidPort;
                host_ = path_ = query_ = scheme_ = userinfo_ = fragment_ = null;
        }

        /***********************************************************************
        
                Parse the given uri, with support for relative URLs

        ***********************************************************************/

        final Uri relParse (char[] uri)
        {
                return parse (uri, true);
        }
        
        /***********************************************************************
                
                Set the Uri scheme

        ***********************************************************************/

        final Uri scheme (char[] scheme)
        {
                this.scheme_ = scheme;
                return this;
        }

        /***********************************************************************
        
                Set the Uri host

        ***********************************************************************/

        final Uri host (char[] host)
        {
                this.host_ = host;
                return this;
        }

        /***********************************************************************
        
                Set the Uri port

        ***********************************************************************/

        final Uri port (int port)
        {
                this.port_ = port;
                return this;
        }

        /***********************************************************************
        
                Set the Uri userinfo

        ***********************************************************************/

        final Uri userinfo (char[] userinfo)
        {
                this.userinfo_ = userinfo;
                return this;
        }

        /***********************************************************************
        
                Set the Uri query

        ***********************************************************************/

        final Uri query (char[] query)
        {
                this.query_ = query;
                return this;
        }

        /***********************************************************************
        
                Extend the Uri query

        ***********************************************************************/

        final char[] extendQuery (char[] tail)
        {
                if (tail.length)
                    if (query_.length)
                        query_ = query_ ~ "&" ~ tail;
                    else
                       query_ = tail;
                return query_;
        }

        /***********************************************************************
        
                Set the Uri path

        ***********************************************************************/
        
        final Uri path (char[] path)
        {
                this.path_ = path;
                return this;
        }

        /***********************************************************************
        
                Set the Uri fragment

        ***********************************************************************/

        final Uri fragment (char[] fragment)
        {
                this.fragment_ = fragment;
                return this;
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
                            userinfo_ = decoder (auth[0 .. i]);
                            mark = i + 1;
                            break;
                            }

                // get port: (:(.*))?
                for (int i=mark; i < len; ++i)
                     if (auth [i] is ':')
                        {
                        port_ = Integer.atoi (auth [i+1 .. len]);
                        len = i;
                        break;
                        }

                // get host: ([^:]*)?
                host_ = auth [mark..len];
        }

        /**********************************************************************

        **********************************************************************/

        private final char[] toLastSlash (char[] path)
        {
                if (path.ptr)
                    for (auto p = path.ptr+path.length; --p >= path.ptr;)
                         if (*p is '/')
                             return path [0 .. (p-path.ptr)+1];
                return path;
        }

        /**********************************************************************

                in-place conversion to lowercase 

        **********************************************************************/

        private final static char[] toLower (ref char[] src)
        {
                foreach (ref char c; src)
                         if (c >= 'A' && c <= 'Z')
                             c = cast(char)(c + ('a' - 'A'));
                return src;
        }
}


/*******************************************************************************
        
*******************************************************************************/

private struct HeapSlice
{
        private uint    used;
        private void[]  buffer;

        /***********************************************************************
        
                Reset content length to zero

        ***********************************************************************/

        final void reset ()
        {
                used = 0;
        }

        /***********************************************************************
        
                Potentially expand the content space, and return a pointer
                to the start of the empty section.

        ***********************************************************************/

        final void* expand (uint size)
        {
                auto len = used + size;
                if (len > buffer.length)
                    buffer.length = len + len/2;

                return &buffer [used];
        }

        /***********************************************************************
        
                Return a slice of the content from the current position 
                with the specified size. Adjusts the current position to 
                point at an empty zone.

        ***********************************************************************/

        final void[] slice (int size)
        {
                uint i = used;
                used += size;
                return buffer [i..used];
        }
}

/*******************************************************************************
      
    Unittest
        
*******************************************************************************/

debug (UnitTest)
{ 
    import tango.util.log.Trace;

unittest
{
    auto uri = new Uri;
    auto uristring = "http://www.example.com/click.html/c=37571:RoS_Intern_search-link3_LB_Sky_Rec/b=98983:news-time-search-link_leader_neu/l=68%7C%7C%7C%7Cde/url=http://ads.ad4max.com/adclick.aspx?id=cf722624-efd5-4b10-ad53-88a5872a8873&pubad=b9c8acc4-e396-4b0b-b665-8bb3078128e6&avid=963171985&adcpc=xrH%2f%2bxVeFaPVkbVCMufB5A%3d%3d&a1v=6972657882&a1lang=de&a1ou=http%3a%2f%2fad.search.ch%2fiframe_ad.html%3fcampaignname%3dRoS_Intern_search-link3_LB_Sky_Rec%26bannername%3dnews-time-search-link_leader_neu%26iframeid%3dsl_if1%26content%3dvZLLbsIwEEX3%2bQo3aqUW1XEgkAckSJRuKqEuoDuELD%2bmiSEJyDEE%2fr7h0cKm6q6SF9bVjH3uzI3vMOaVYdpgPIwrodXGIHPYQGIb2BuyZDt2Vu2hRUh8Nx%2b%2fjj5Gc4u0UNAJ95H7jCbAJGi%2bZlqix3eoqyfUIhaT3YLtabpVEiXI5pEImRBdDF7k4y53Oea%2b38Mh554bhO1OCL49%2bO6qlTTZsa3546pmoNLMHOXIvaoapNIgTnpmzKZPCJNOBUyLzBEZEbkSKyczRU5E4gW9oN2frmf0rTSgS3quw7kqVx6dvNDZ6kCnIAhPojAKvX7Z%2bMFGFYBvKml%2bskxL2JI88cOHYPxzJJCtzpP79pXQaCZWqkxppcVvlDsF9b9CqiJNLiB1Xd%2bQqIKlUBHXSdWnjQbN1heLoRWTcwz%2bCAlqLCZXg5VzHoEj1gW5XJeVffOcFR8TCKVs8vcF%26crc%3dac8cc2fa9ec2e2de9d242345c2d40c25";
    
    
    uri.parse(uristring);
    
    with(uri)
    {
        assert(scheme == "http");
        assert(host == "www.example.com");
        assert(port == InvalidPort);
        assert(userinfo == null);
        assert(fragment == null);
        assert(path == "/click.html/c=37571:RoS_Intern_search-link3_LB_Sky_Rec/b=98983:news-time-search-link_leader_neu/l=68||||de/url=http://ads.ad4max.com/adclick.aspx");
        assert(query == "id=cf722624-efd5-4b10-ad53-88a5872a8873&pubad=b9c8acc4-e396-4b0b-b665-8bb3078128e6&avid=963171985&adcpc=xrH/+xVeFaPVkbVCMufB5A==&a1v=6972657882&a1lang=de&a1ou=http://ad.search.ch/iframe_ad.html?campaignname=RoS_Intern_search-link3_LB_Sky_Rec%26bannername=news-time-search-link_leader_neu%26iframeid=sl_if1%26content=vZLLbsIwEEX3+Qo3aqUW1XEgkAckSJRuKqEuoDuELD+miSEJyDEE/r7h0cKm6q6SF9bVjH3uzI3vMOaVYdpgPIwrodXGIHPYQGIb2BuyZDt2Vu2hRUh8Nx+/jj5Gc4u0UNAJ95H7jCbAJGi+Zlqix3eoqyfUIhaT3YLtabpVEiXI5pEImRBdDF7k4y53Oea+38Mh554bhO1OCL49+O6qlTTZsa3546pmoNLMHOXIvaoapNIgTnpmzKZPCJNOBUyLzBEZEbkSKyczRU5E4gW9oN2frmf0rTSgS3quw7kqVx6dvNDZ6kCnIAhPojAKvX7Z+MFGFYBvKml+skxL2JI88cOHYPxzJJCtzpP79pXQaCZWqkxppcVvlDsF9b9CqiJNLiB1Xd+QqIKlUBHXSdWnjQbN1heLoRWTcwz+CAlqLCZXg5VzHoEj1gW5XJeVffOcFR8TCKVs8vcF%26crc=ac8cc2fa9ec2e2de9d242345c2d40c25");
    
    
        parse("psyc://example.net/~marenz?what#_presence");
        
        assert(scheme == "psyc");
        assert(host == "example.net");
        assert(port == InvalidPort);
        assert(fragment == "_presence");
        assert(path == "/~marenz");
        assert(query == "what");
   
    }
   
    //Cout (uri).newline;
    //Cout (uri.encode ("&#$%", uri.IncQuery)).newline;
        
}

}

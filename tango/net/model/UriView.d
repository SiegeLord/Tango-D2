/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.model.UriView;

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

        Use a Uri instead where you need to alter specific uri attributes. 

*******************************************************************************/

abstract class UriView
{
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

        /***********************************************************************
        
                Return the default port for the given scheme. InvalidPort
                is returned if the scheme is unknown, or does not accept
                a port.

        ***********************************************************************/

        abstract const int defaultPort (const(char)[] scheme);

        /***********************************************************************
        
                Return the parsed scheme, or null if the scheme was not
                specified

        ***********************************************************************/

        abstract const const(char)[] scheme();

        /***********************************************************************
        
                Return the parsed host, or null if the host was not
                specified

        ***********************************************************************/

        abstract const const(char)[] host();

        /***********************************************************************
        
                Return the parsed port number, or InvalidPort if the port
                was not provided.

        ***********************************************************************/

        abstract const int port();

        /***********************************************************************
        
                Return a valid port number by performing a lookup on the 
                known schemes if the port was not explicitly specified.

        ***********************************************************************/

        abstract const int validPort();

        /***********************************************************************
        
                Return the parsed userinfo, or null if userinfo was not 
                provided.

        ***********************************************************************/

        abstract const const(char)[] userinfo();

        /***********************************************************************
        
                Return the parsed path, or null if the path was not 
                provided.

        ***********************************************************************/

        abstract const const(char)[] path();

        /***********************************************************************
        
                Return the parsed query, or null if a query was not 
                provided.

        ***********************************************************************/

        abstract const const(char)[] query();

        /***********************************************************************
        
                Return the parsed fragment, or null if a fragment was not 
                provided.

        ***********************************************************************/

        abstract const const(char)[] fragment();

        /***********************************************************************
        
                Return whether or not the UriView scheme is considered generic.

        ***********************************************************************/

        abstract const bool isGeneric ();

        /***********************************************************************
        
                Emit the content of this UriView. Output is constructed per
                RFC 2396.

        ***********************************************************************/

        //abstract immutable(char)[] toString ();
}


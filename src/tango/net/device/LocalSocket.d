/*******************************************************************************

        copyright:      Copyright (c) 2009 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2009: Initial release

        author:         Lukas Pinkowski, Kris

*******************************************************************************/

module tango.net.device.LocalSocket;

private import tango.net.device.Socket;

/*******************************************************************************


*******************************************************************************/

version (Windows)
{
        pragma(msg, "not yet available for windows");
}

/*******************************************************************************

        A wrapper around the Berkeley API to implement the IConduit 
        abstraction and add stream-specific functionality.

*******************************************************************************/

class LocalSocket : Socket
{
        /***********************************************************************
        
                Create a streaming local socket

        ***********************************************************************/

        private this ()
        {
                super (AddressFamily.UNIX, SocketType.STREAM, ProtocolType.IP);
        }

        /***********************************************************************
        
                Create a streaming local socket

        ***********************************************************************/

        this (char[] path)
        {
                this (new LocalAddress (path));
        }

        /***********************************************************************
        
                Create a streaming local socket

        ***********************************************************************/

        this (LocalAddress addr)
        {       
                this();
                super.connect (addr);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString()
        {
                return "<localsocket>";
        }
}

/*******************************************************************************


*******************************************************************************/

class LocalServerSocket : LocalSocket
{      
        /***********************************************************************

        ***********************************************************************/

        this (char[] path, int backlog=32, bool reuse=false)
        {
                auto addr = new LocalAddress (path);
                native.addressReuse(reuse).bind(addr).listen(backlog);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString()
        {
                return "<localaccept>";
        }

        /***********************************************************************

        ***********************************************************************/

        Socket accept (Socket recipient = null)
        {
                if (recipient is null)
                    recipient = new LocalSocket;

                native.accept (*recipient.native);
                recipient.timeout = timeout;
                return recipient;
        }
}

/*******************************************************************************

*******************************************************************************/

class LocalAddress : Address
{
        align(1) struct sockaddr_un
        {
                ushort sun_family = AddressFamily.UNIX;
                char[108] sun_path;
        }
                        
        protected
        {
                sockaddr_un sun;
                char[] _path;
                int _pathLength;
        }

        /***********************************************************************

            -path- path to a unix domain socket (which is a filename)

        ***********************************************************************/

        this (char[] path)
        {
                assert (path.length < 108);
                
                sun.sun_path [0 .. path.length] = path;
                sun.sun_path [path.length .. $] = 0;
                
                _pathLength = path.length;
                _path = sun.sun_path [0 .. path.length];
        }

        /***********************************************************************

        ***********************************************************************/

        final sockaddr* name () 
        { 
                return cast(sockaddr*) &sun; 
        }
        
        /***********************************************************************

        ***********************************************************************/

        final int nameLen () 
        { 
                return _pathLength + ushort.sizeof; 
        }
        
        /***********************************************************************

        ***********************************************************************/

        final AddressFamily addressFamily () 
        { 
                return AddressFamily.UNIX; 
        }
        
        /***********************************************************************

        ***********************************************************************/

        final char[] toString ()
        {
                if (isAbstract)
                    return "unix:abstract=" ~ _path[1..$];
                else
                   return "unix:path=" ~ _path;
        }
        
        /***********************************************************************

        ***********************************************************************/

        final char[] path ()
        {
                return _path;
        }
        
        /***********************************************************************

        ***********************************************************************/

        final bool isAbstract ()
        {
                return _path[0] == 0;
        }
}

/******************************************************************************

******************************************************************************/

debug (LocalSocket)
{
        import tango.io.Stdout;

        void main()
        {
                auto y = new LocalSocket ("foo");
                auto x = new LocalServerSocket ("foo");   
        }
}        
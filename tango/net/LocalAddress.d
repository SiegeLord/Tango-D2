/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2006
        version:        Changed for D2
        author:         Kris

*******************************************************************************/

module tango.net.LocalAddress;

private import core.sys.posix.sys.un;
public import  tango.net.Address;

/**
 * LocalAddress represents the Unix Domain Socket.
 */
class LocalAddress : Address
{
        private sockaddr_un sun;
        private immutable(char)[] _path;
        
        /**
         * constructs a LocalAddress (unix domain socket) which is a filename in most cases. 
         * 
         * params:
         *  path = the path where to create the unix local domain socket.
         * 
         * ---
         * private import tango.net.LocalAddress;
         * 
         * LocalAddress address = new LocalAddress("/var/run/myapp/mysock.sock");
         * ---
         * 
         */
        this (const(char)[] path)
        {
                assert (path.length < 108);
                
                // save idup version of path
                this._path = path.idup;
                
                // setup sun_path
                this.sun.sun_family = AF_UNIX;
                this.sun.sun_path[0..$] = 0;
                this.sun.sun_path[0..this._path.length] = cast(const(byte[]))this._path[0..$];
        }
        
        /**
         * returns the sockaddr of this strucure
         */
        final override sockaddr* name () 
        { 
                return cast(sockaddr*)&this.sun; 
        }
        
        /**
         * returns the length of this structure
         */
        final override uint nameLen () 
        { 
                return cast(uint)this.sun.sizeof;
        }
        
        /**
         * returns AddressFamily.UNIX for all instance of LocalAddress. This is usefull if you cast it to the parent class.
         * 
         * ---
         * LocalAddress localAddress = new LocalAddress("/foo/bar");
         * InternetAddress inetAddress = new InternetAddress();
         * 
         * void some_function(Address address)
         * {
         *      Stdout(address.toString());
         *      if(address.addressFamily == AddressFamily.UNIX)
         *          // UNIX...
         *      else
         *          // OTHER...
         * }
         * 
         * some_function(localAddress);
         * inetAddress(localAddress);
         * ---
         */
        final override AddressFamily addressFamily () 
        { 
                return AddressFamily.UNIX; 
        }
        
        /**
         * returns the localaddress in a readable manner. if you prefer to get just the path
         * than you should rather take the path method of this class.
         * 
         * ---
         * // example using abstract identifier
         * LocalAddress address = new LocalAddress(" just_an_identifier");
         * Stdout(address.toString()); // unix:abstract=just_an_identifier
         * ---
         * 
         * ---
         * // example using some kind of path
         * LocalAddress address = new LocalAddress("/var/run/myapp/mysock.sock");
         * Stdout(address.toString()); // unix:path=/var/run/myapp/mysock.sock
         * ---
         */
        override immutable(char)[] toString ()
        {
                if (isAbstract)
                    return ("unix:abstract=" ~ _path[1..$]).idup;
                else
                    return ("unix:path=" ~ _path).idup;
        }
        
        /**
         * returns the path that was provided by the constructor
         */
        final immutable(char)[] path ()
        {
                return this._path;
        }
        
        /**
         * a localaddress can be an abstract identifier, in this case isAbstract returns true otherwise false
         */
        final bool isAbstract ()
        {
                return this._path[0] == 0;
        }
}

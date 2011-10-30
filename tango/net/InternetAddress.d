/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2006      
        author:         Kris

*******************************************************************************/

module tango.net.InternetAddress;

private import core.sys.posix.arpa.inet;
private import core.sys.posix.netinet.in_;

private import tango.net.NetHost;
public import  tango.net.Address;

/**
 * InternetAddress represents an Endpoint in the Internet (IP Version 4).
 * You'll basically need it for establishing connections or for listening on a
 * specific location.
 */

public class InternetAddress : Address
{
        private sockaddr_in sin;
        
        /**
         * constructs an address by port. the host will be set to ANY!
         * in most cases this is useful for listening on this sport
         * 
         * params:
         *  port = port number, example: 8080, PORT_ANY
         */
        this (ushort port = PORT_ANY)
        {
                sin.sin_family = AF_INET;
                sin.sin_addr.s_addr = htonl(INADDR_ANY); //any, "0.0.0.0"
                sin.sin_port = htons(port);
        }

        /**
         * constructs an adress by an addr and port in integral form
         * 
         * params:
         *  addr = uint of ip address
         *  port = port number
         */
        this (uint addr, ushort port)
        {
                sin.sin_family = AF_INET;
                sin.sin_addr.s_addr = htonl(addr);
                sin.sin_port = htons(port);
        }
        
        /**
         * constructs address by a given host and port. host can be an hostname or an ip address.
         * 
         * ---
         * new InternetAddress("localhost:12345");
         * new InternetAddress("localhost", 12345);
         * new InternetAddress("hostname", PORT_ANY);
         * ---
         * 
         * params:
         *  host = hostname or ip address
         *  port = port number
         */
        this (const(char)[] host, ushort port = PORT_ANY)
        {
            // split host and port
            foreach (int i, char c; host)
            {
                if (c is ':') {
                    port = cast(ushort)Integer.parse(host [i+1 .. $]);
                    host = host[0 .. i];
                    break;
                }
            }
            
            // try to parse directly into uiaddr
            uint uiaddr = this.parse(host);
            
            // it wasn't parse, need Host Lookup
            if(ADDR_NONE == uiaddr) {
                auto ih = new NetHost();
                if(!ih.getHostByName(host))
                    throw new AddressException(("Unable to resolve " ~ host ~ ":" ~ Integer.toString(port)).idup);
                
                uiaddr = ntohl(ih.addrList[0]);
            }
            
            // fill in the internal structure
            sin.sin_family = AF_INET;
            sin.sin_addr.s_addr = htonl(uiaddr);
            sin.sin_port = htons(port);
        }
        
        /**
         * construct an InternetAddress by some sockaddr_in* structure.
         * 
         * params:
         *  sin = pointer to sockaddr_in. the structure will be copied
         */
        this (sockaddr_in* sin) 
        {
                // this line copies the structure
                this.sin = *sin;
        }
        
        /**
         * returns a pointer to the internal structur
         */
        override sockaddr* name()
        {
                return cast(sockaddr*)&sin;
        }
        
        /**
         * the length of the internal structure
         */
        override int nameLen()
        {
                return sin.sizeof;
        }
        
        /**
         * returns AddressFamily.INET for all InternetAddress's.
         */
        override AddressFamily addressFamily()
        {
                return AddressFamily.INET;
        }
        
        /**
         * returns the port of this address struct
         */
        public ushort port()
        {
                return ntohs(this.sin.sin_port);
        }
        
        /**
         * uint version of address struct
         */
        public uint addr()
        {
                return ntohl(this.sin.sin_addr.s_addr);
        }
        
        /**
         * returns you a printable version of this address
         * ---
         * Stdout(new InternetAddress("localhost", 12345)); // 127.0.0.1:12345
         * ---
         */
        override immutable(char)[] toString()
        {
                version (Windows) {
                    const(char)* addr = inet_ntoa(sin.sin_addr);
                } else {
                    char buff[16] = 0;
                    const(char)* addr = inet_ntop(AddressFamily.INET, &sin.sin_addr, buff.ptr, buff.length);
                }
                
                return (Utf.fromStringz(addr) ~ ":" ~ Integer.toString(this.port())).idup;
        }
        
        /**
         * returns uint version of addr or ADDR_NONE on failure
         * 
         * params:
         *  addr = is an IP address in the format "a.b.c.d"
         */
        static uint parse(const(char)[] addr)
        {
                synchronized (InternetAddress.classinfo)
                {
                    return ntohl(inet_addr(Utf.toStringz(addr)));
                }
        }
}

/*******************************************************************************

*******************************************************************************/

debug(UnitTest)
{
    unittest
    {
        InternetAddress addr;
        
        addr = new InternetAddress("localhost", 80);
        assert(addr.toString() == "127.0.0.1:80");
        
        addr = new InternetAddress(12345);
        assert(addr.toString() == "0.0.0.0:12345");
        
        addr = new InternetAddress("63.105.9.61", 80);
        assert(addr.toString() == "63.105.9.61:80");
    }
}

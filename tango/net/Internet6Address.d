/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2006      
        author:         Kris

*******************************************************************************/

module tango.net.Internet6Address;

private import  core.sys.posix.netdb,
                core.sys.posix.arpa.inet,
                core.sys.posix.netinet.in_;

private import  tango.net.NetHost;
public import   tango.net.Address;


/******************************************************************************* 
        
        IPv6 is the next-generation Internet Protocol version
        designated as the successor to IPv4, the first
        implementation used in the Internet that is still in
        dominant use currently.
	        			
        More information: http://ipv6.com/
				
        IPv6 supports 128-bit address space as opposed to 32-bit
        address space of IPv4.
				
        IPv6 is written as 8 blocks of 4 octal digits (16 bit)
        separated by a colon (":"). Zero block can be replaced by "::".
	        			
        For example:
        
        ---
        0000:0000:0000:0000:0000:0000:0000:0001
        is equal
        ::0001
        is equal
        ::1
        is analogue IPv4 127.0.0.1
				
        0000:0000:0000:0000:0000:0000:0000:0000
        is equal
        ::
        is analogue IPv4 0.0.0.0
				
        2001:cdba:0000:0000:0000:0000:3257:9652 
        is equal
        2001:cdba::3257:9652
				
        IPv4 address can be submitted through IPv6 as ::ffff:xx.xx.xx.xx,
        where xx.xx.xx.xx 32-bit IPv4 addresses.
				
        ::ffff:51b0:ec6d
        is equal
        ::ffff:81.176.236.109
        is analogue IPv4 81.176.236.109
				
        The URL for the IPv6 address will be of the form:
        http://[2001:cdba:0000:0000:0000:0000:3257:9652]/
				
        If needed to specify a port, it will be listed after the
        closing square bracket followed by a colon.
				
        http://[2001:cdba:0000:0000:0000:0000:3257:9652]:8080/
        address: "2001:cdba:0000:0000:0000:0000:3257:9652"
        port: 8080
				
        IPv6Address can be used as well as IPv4Address.
				
        scope addr = new Internet6Address(8080); 
        address: "::"
        port: 8080
				
        scope addr_2 = new Internet6Address("::1", 8081); 
        address: "::1"
        port: 8081
				
        scope addr_3 = new Internet6Address("::1"); 
        address: "::1"
        port: PORT_ANY
				
        Also in the IPv6Address constructor can specify the service name
        or port as string
        
        scope addr_3 = new Internet6Address("::", "ssh"); 
        address: "::"
        port: 22 (ssh service port)
        
        scope addr_4 = new Internet6Address("::", "8080"); 
        address: "::"
        port: 8080
        ---

*******************************************************************************/ 

class Internet6Address : Address 
{
        protected sockaddr_in6 sin;
        
        /*********************************************************************** 
 
        ***********************************************************************/ 
 
        override sockaddr* name() 
        { 
                return cast(sockaddr*)&sin; 
        } 
 
        /*********************************************************************** 
 
        ***********************************************************************/ 
 
        override int nameLen() 
        { 
                return sin.sizeof; 
        } 
 
public: 

        /***********************************************************************

        ***********************************************************************/

        override AddressFamily addressFamily()
        {
                return AddressFamily.INET6;
        }

 
        const ushort PORT_ANY = 0; 
  
        /*********************************************************************** 
 
         ***********************************************************************/ 
 
        ushort port() 
        { 
                return ntohs(this.sin.sin6_port); 
        }
        
        /*********************************************************************** 
 
                Create IPv6Address with zero address

        ***********************************************************************/ 

        this (int port) 
        { 
            this ("::", port);
        } 

        /*********************************************************************** 
 
                -port- can be PORT_ANY 
                -addr- is an IP address or host name 
 
        ***********************************************************************/ 
				
        this (const(char)[] addr, int port = PORT_ANY) 
        { 
                version (Win32) 
                        { 
                        if (!getaddrinfo) 
                             exception ("This platform does not support IPv6."); 
                        } 
                addrinfo* info; 
                addrinfo hints; 
                hints.ai_family = AddressFamily.INET6; 
                int error = getaddrinfo((addr ~ '\0').ptr, null, &hints, &info); 
                if (error != 0)  
                    throw new AddressException("failed to create IPv6Address: "); 
                 
                this.sin = *cast(sockaddr_in6*)(info.ai_addr); 
                this.sin.sin6_port = htons(cast(ushort) port); 
        }
               
        /*********************************************************************** 
 
                -service- can be a port number or service name 
                -addr- is an IP address or host name 
 
        ***********************************************************************/ 
 
        this (char[] addr, char[] service) 
        { 
                version (Win32) 
                        { 
                        if(! getaddrinfo) 
                             exception ("This platform does not support IPv6."); 
                        } 
                addrinfo* info; 
                addrinfo hints; 
                hints.ai_family = AddressFamily.INET6; 
                int error = getaddrinfo((addr ~ '\0').ptr, (service ~ '\0').ptr, &hints, &info); 
                if (error != 0)  
                    throw new AddressException("failed to create IPv6Address: "); 
                sin = *cast(sockaddr_in6*)(info.ai_addr); 
        }
        
        /***********************************************************************

        ***********************************************************************/

        this(sockaddr_in6* sin) 
        {
                // copy structure
                this.sin = *sin; 
        }
 
        /*********************************************************************** 
  
        ***********************************************************************/ 
 
        ubyte[] addr() 
        { 
                return cast(ubyte[this.sin.sin6_addr.sizeof])this.sin.sin6_addr; 
        } 
 
        /*********************************************************************** 
  
        ***********************************************************************/ 
 
        version (Posix)
        override char[] toAddrString()
        {
                char[100] buff = 0;
                return Utf.fromStringz(inet_ntop(AddressFamily.INET6, &sin.sin6_addr, buff.ptr, 100)).dup;
        }

        /***********************************************************************

        ***********************************************************************/

        override char[] toPortString()
        {
                return Integer.toString(this.port());
        }
 
        /***********************************************************************

        ***********************************************************************/

        override immutable(char)[] toString() 
        { 
                return ("[" ~ toAddrString ~ "]:" ~ toPortString).idup; 
        } 
}

/*******************************************************************************

*******************************************************************************/

debug(UnitTest)
{
    unittest
    {
        IPv6Address ia = new IPv6Address("7628:0d18:11a3:09d7:1f34:8a2e:07a0:765d", 8080);
        assert(ia.toString() == "[7628:d18:11a3:9d7:1f34:8a2e:7a0:765d]:8080");
        //assert(ia.toString() == "[7628:0d18:11a3:09d7:1f34:8a2e:07a0:765d]:8080");
    }
}

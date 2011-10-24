/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
        version:        Jan 2005: RedShodan patch for timeout query
        version:        Dec 2006: Outback release
        version:        Apr 2009: revised for asynchronous IO
        version:        Aug 2011: Druntime ready for D2

        author:         Kris, Chrono

*******************************************************************************/
module tango.net.Address;

private import  core.sys.posix.netdb;
private import  core.sys.posix.sys.socket;

private import  tango.core.Exception;

private import  tango.net.Socket,
                tango.net.NetHost,
                tango.net.LocalAddress,
                tango.net.InternetAddress;

private import  Utf = tango.text.convert.Utf;
private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

*******************************************************************************/

enum AddressFamily
{
        UNSPEC    = AF_UNSPEC   ,
        UNIX      = AF_UNIX     ,
        INET      = AF_INET     ,
        INET6     = AF_INET6    ,
}


enum AIFlags: int 
{
        PASSIVE     = AI_PASSIVE,                /// get address to use bind()
        CANONNAME   = AI_CANONNAME,              /// fill ai_canonname
        NUMERICHOST = AI_NUMERICHOST,            /// prevent host name resolution
        NUMERICSERV = AI_NUMERICSERV,            /// prevent service name resolution valid 
                                                 /// flags for addrinfo (not a standard def, 
                                                 /// apps should not use it)
        ALL         = AI_ALL,                    /// IPv6 and IPv4-mapped (with AI_V4MAPPED) 
        ADDRCONFIG  = AI_ADDRCONFIG,             /// only if any address is assigned
        V4MAPPED    = AI_V4MAPPED,               /// accept IPv4-mapped IPv6 address special 
                                                 /// recommended flags for getipnodebyname
                                                 
        MASK        = (AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST | AI_NUMERICSERV | AI_ADDRCONFIG),
        DEFAULT     = (AI_V4MAPPED | AI_ADDRCONFIG),
}

enum AIError
{
        BADFLAGS    = EAI_BADFLAGS,	        /// Invalid value for `ai_flags' field.
        NONAME      = EAI_NONAME,	        /// NAME or SERVICE is unknown.
        AGAIN       = EAI_AGAIN,	        /// Temporary failure in name resolution.
        FAIL        = EAI_FAIL,	            /// Non-recoverable failure in name res.
        //NODATA      = EAI_NODATA,	        /// No address associated with NAME. /* not available in druntime */
        FAMILY      = EAI_FAMILY,	        /// `ai_family' not supported.
        SOCKTYPE    = EAI_SOCKTYPE,	        /// `ai_socktype' not supported.
        SERVICE     = EAI_SERVICE,	        /// SERVICE not supported for `ai_socktype'.
        MEMORY      = EAI_MEMORY,	        /// Memory allocation failure.
}


enum NIFlags: int 
{
        MAXHOST     = NI_MAXHOST,
        MAXSERV     = NI_MAXSERV,
        NUMERICHOST = NI_NUMERICHOST,       /// Don't try to look up hostname.
        NUMERICSERV = NI_NUMERICSERV,       /// Don't convert port number to name.
        NOFQDN      = NI_NOFQDN,            /// Only return nodename portion.
        NAMEREQD    = NI_NAMEREQD,          /// Don't return numeric addresses.
        DGRAM       = NI_DGRAM,             /// Look up UDP service rather than TCP.
}

/*******************************************************************************


*******************************************************************************/

public abstract class Address
{
        abstract sockaddr*  name();
        abstract uint       nameLen();
        
        /***********************************************************************

        ***********************************************************************/

        enum
        {
                ADDR_ANY = 0,
                ADDR_NONE = cast(uint)-1,
                PORT_ANY = 0
        }
        
        /***********************************************************************

                Address factory

        ***********************************************************************/

        static Address create (sockaddr* sa) 
        { 
                switch  (sa.sa_family) 
                { 
                        case AddressFamily.INET: 
                             return new InternetAddress(sa); 
                        case AddressFamily.INET6: 
                             return new IPv6Address(sa);
                        case AddressFamily.UNIX:
                             return new LocalAddress(sa);
                        default: 
                             return null; 
                } 
        } 

        /*********************************************************************** 
  
        ***********************************************************************/ 
         
        static Address resolve (char[] host, char[] service = null, 
                                AddressFamily af = AddressFamily.UNSPEC, 
                                AIFlags flags = cast(AIFlags)0) 
        { 
                return resolveAll (host, service, af, flags)[0]; 
        } 
         
        /*********************************************************************** 
  
        ***********************************************************************/ 
         
        static Address resolve (char[] host, ushort port, 
                                AddressFamily af = AddressFamily.UNSPEC, 
                                AIFlags flags = cast(AIFlags)0) 
        { 
                return resolveAll (host, port, af, flags)[0]; 
        } 
         
        /*********************************************************************** 
  
        ***********************************************************************/ 
         
        static Address[] resolveAll (char[] host, char[] service = null, 
                                     AddressFamily af = AddressFamily.UNSPEC, 
                                     AIFlags flags = cast(AIFlags)0) 
        { 
                Address[] retVal; 
                version (Win32) 
                        { 
                        if (!getaddrinfo) 
                           { // *old* windows, let's fall back to NetHost 
                           uint port = toInt(service); 
                           if (flags & AIFlags.PASSIVE && host is null) 
                               return [new IPv4Address(0, port)]; 

                           auto nh = new NetHost; 
                           if (!nh.getHostByName(host)) 
                                throw new AddressException("couldn't resolve " ~ host); 

                           retVal.length = nh.addrList.length; 
                           foreach (i, addr; nh.addrList)
                                    retVal[i] = new IPv4Address(addr, port); 
                           return retVal; 
                           } 
                        } 

                addrinfo* info; 
                addrinfo hints; 
                hints.ai_flags = flags; 
                hints.ai_family = (flags & AIFlags.PASSIVE && af == AddressFamily.UNSPEC) ? AddressFamily.INET6 : af; 
                hints.ai_socktype = SocketType.STREAM; 
                int error = getaddrinfo(Utf.toStringz(host), service.length == 0 ? null : Utf.toStringz(service), &hints, &info); 
                if (error != 0)  
                    throw new AddressException(("couldn't resolve " ~ host).idup); 

                retVal.length = 16; 
                retVal.length = 0; 
                while (info) 
                      { 
                      if (auto addr = create(info.ai_addr)) 
                          retVal ~= addr; 
                      info = info.ai_next; 
                      } 
                freeaddrinfo (info); 
                return retVal; 
        } 
         
        /*********************************************************************** 
  
        ***********************************************************************/ 
         
        static Address[] resolveAll (char host[], ushort port, 
                                     AddressFamily af = AddressFamily.UNSPEC, 
                                     AIFlags flags = cast(AIFlags)0) 
        { 
                return resolveAll (host, port, af, flags); 
        } 
         
        /*********************************************************************** 
  
        ***********************************************************************/ 
         
        static Address passive (char[] service, 
                                AddressFamily af = AddressFamily.UNSPEC, 
                                AIFlags flags = cast(AIFlags)0) 
        { 
                return resolve (null, service, af, flags | AIFlags.PASSIVE); 
        } 
         
        /*********************************************************************** 
 
         ***********************************************************************/ 
         
        static Address passive (ushort port, AddressFamily af = AddressFamily.UNSPEC, 
                                AIFlags flags = cast(AIFlags)0) 
        { 
                return resolve (null, port, af, flags | AIFlags.PASSIVE); 
        } 
         
        /*********************************************************************** 
  
        ***********************************************************************/ 
 
        char[] toAddrString() 
        { 
                char[1025] host = void; 
                // Getting name info. Don't look up hostname, returns 
                // numeric name. (NIFlags.NUMERICHOST)
                getnameinfo (name, cast(int)nameLen, host.ptr, host.length, null, 0, NIFlags.NUMERICHOST); 
                return Utf.fromStringz(host.ptr); 
        } 
 
        /*********************************************************************** 
 
         ***********************************************************************/ 
 
        char[] toPortString() 
        { 
                char[32] service = void; 
                // Getting name info. Returns port number, not 
                // service name. (NIFlags.NUMERICSERV)
                getnameinfo (name, cast(int)nameLen, null, 0, service.ptr, service.length, NIFlags.NUMERICSERV); 
                foreach (i, c; service)  
                         if (c == '\0')  
                             return service[0..i].dup; 
                return null;
        } 
          
        /*********************************************************************** 
  
        ***********************************************************************/ 
 
        override immutable(char)[] toString() 
        { 
                return (toAddrString ~ ":" ~ toPortString).idup; 
        } 
                  
        /*********************************************************************** 
 
         ***********************************************************************/ 
 
        AddressFamily addressFamily() 
        { 
                return cast(AddressFamily)name.sa_family; 
        } 
}


/*******************************************************************************

*******************************************************************************/

public class UnknownAddress : Address
{
        sockaddr sa;

        /***********************************************************************

        ***********************************************************************/

        override sockaddr* name()
        {
                return &sa;
        }

        /***********************************************************************

        ***********************************************************************/

        override int nameLen()
        {
                return sa.sizeof;
        }

        /***********************************************************************

        ***********************************************************************/

        override AddressFamily addressFamily()
        {
                return cast(AddressFamily) sa.sa_family;
        }

        /***********************************************************************

        ***********************************************************************/

        override immutable(char[]) toString()
        {
                return "Unknown";
        }
}

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
				
        scope addr = new IPv6Address(8080); 
        address: "::"
        port: 8080
				
        scope addr_2 = new IPv6Address("::1", 8081); 
        address: "::1"
        port: 8081
				
        scope addr_3 = new IPv6Address("::1"); 
        address: "::1"
        port: PORT_ANY
				
        Also in the IPv6Address constructor can specify the service name
        or port as string
				
        scope addr_3 = new IPv6Address("::", "ssh"); 
        address: "::"
        port: 22 (ssh service port)
				
        scope addr_4 = new IPv6Address("::", "8080"); 
        address: "::"
        port: 8080
        ---
				
*******************************************************************************/ 
				
class IPv6Address : Address 
{ 
protected:
        /*********************************************************************** 
         
        ***********************************************************************/ 
 
        struct sockaddr_in6 
        { 
                ushort sin_family; 
                ushort sin_port; 
                 
                uint sin6_flowinfo; 
                ubyte[16] sin6_addr; 
                uint sin6_scope_id; 
        } 
         
        sockaddr_in6 sin; 
 
        /*********************************************************************** 
 
         ***********************************************************************/ 
 
        this () 
        { 
        } 
 
        /***********************************************************************

        ***********************************************************************/

        this (sockaddr* sa) 
        { 
                sin = *cast(sockaddr_in6*)sa; 
        } 
         
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
                return ntohs(sin.sin_port); 
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
                 
                sin = *cast(sockaddr_in6*)(info.ai_addr); 
                sin.sin_port = htons(cast(ushort) port); 
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
 
        ubyte[] addr() 
        { 
                return sin.sin6_addr; 
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

/**
 * Base class for exceptiond thrown by an Address.
 */
class AddressException : IOException
{
    this(immutable(char)[] msg, immutable(char)[] file = __FILE__, size_t line = __LINE__)
    {
        super( msg );
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


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

private import  core.sys.posix.sys.un,
                core.sys.posix.netdb,
                core.sys.posix.sys.socket;

private import  tango.core.Exception;

private import  tango.net.Socket,
                tango.net.NetHost,
                tango.net.LocalAddress,
                tango.net.Internet6Address,
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
                
                params:
                    sa = a pointer to a sockaddr which will be copied
                    sa_len = the length of the sa structure
                
                returns:
                    cast(Address)InternetAddress
                    cast(Address)Internet6Address
                    cast(Address)LocalAddress
                    null

        ***********************************************************************/

        static Address create (sockaddr* sa, socklen_t sa_len = sockaddr.sizeof) 
        {
                switch  (sa.sa_family) 
                { 
                        // INET
                        case AddressFamily.INET:
                            assert(sa_len >= sockaddr_in.sizeof, "Address.create: sa is to small for converting to an InternetAddress.");
                        return new InternetAddress(cast(sockaddr_in*)sa);
                        
                        // INET
                        case AddressFamily.INET6: 
                            assert(sa_len >= sockaddr_in6.sizeof, "Address.create: sa is to small for converting to an Internet6Address");
                        return new Internet6Address(cast(sockaddr_in6*)sa);
                        
                        // UNIX
                        case AddressFamily.UNIX:
                             assert(sa_len >= sockaddr_un.sizeof, "Address.create: sa is to small for converting to LocalAddress");
                        return new LocalAddress(cast(sockaddr_un*)sa);
                        
                        // default
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

*******************************************************************************/

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

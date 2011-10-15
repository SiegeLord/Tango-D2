/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        author:         Kris

*******************************************************************************/
module tango.net.NetHost;

private import core.sys.posix.netdb;
private import core.sys.posix.unistd;

private import tango.net.Socket,
               tango.net.Address,
               tango.net.InternetAddress;

private import Integer = tango.text.convert.Integer;
private import Utf = tango.text.convert.Utf;

/*******************************************************************************


*******************************************************************************/

public class NetHost
{
        char[]          name;
        char[][]        aliases;
        uint[]          addrList;

        /***********************************************************************

        ***********************************************************************/

        protected void validHostent(hostent* he)
        {
                if (he.h_addrtype != AddressFamily.INET || he.h_length != 4)
                    throw new SocketException("Address family mismatch.");
        }

        /***********************************************************************

        ***********************************************************************/

        void populate (hostent* he)
        {
                int i;
                char* p;

                name = Utf.fromStringz(he.h_name);

                for (i = 0;; i++)
                    {
                    p = he.h_aliases[i];
                    if(!p)
                        break;
                    }

                if (i)
                   {
                   aliases = new char[][i];
                   for (i = 0; i != aliases.length; i++)
                        aliases[i] = Utf.fromStringz(he.h_aliases[i]);
                   }
                else
                   aliases = null;

                for (i = 0;; i++)
                    {
                    p = he.h_addr_list[i];
                    if(!p)
                        break;
                    }

                if (i)
                   {
                   addrList = new uint[i];
                   for (i = 0; i != addrList.length; i++)
                        //addrList[i] = Address.ntohl(*(cast(uint*)he.h_addr_list[i])); ??
                        addrList[i] = *cast(uint*)he.h_addr_list[i];
                   }
                else
                   addrList = null;
        }

        /***********************************************************************

        ***********************************************************************/

        bool getHostByName(const(char)[] name)
        {
                char[1024] tmp;

                synchronized (NetHost.classinfo)
                {
                    auto he = gethostbyname(Utf.toStringz(name));
                    if(!he)
                        return false;
                        
                    validHostent(he);
                    populate(he);
                }
                return true;
        }

        /***********************************************************************

        ***********************************************************************/

        bool getHostByAddr(uint addr)
        {
                uint x = htonl(addr);
                synchronized (NetHost.classinfo)
                {
                    auto he = .gethostbyaddr(&x, 4, AddressFamily.INET);
                    if(!he)
                        return false;
                        
                    validHostent(he);
                    populate(he);
                }
                return true;
        }

        /***********************************************************************

        ***********************************************************************/

        //shortcut
        bool getHostByAddr(char[] addr)
        {
                synchronized (NetHost.classinfo)
                {
                    uint x = inet_addr(Utf.toStringz(addr));
                    return getHostByAddr(x);
                }
        }
        
        /**
         * returns the hostname of this host see: /etc/hostname
         */
        static char[] hostName()
        {
            char[64] name;
            if(.gethostname(name.ptr, name.length) == -1)
                   throw new SocketException("Unable to obtain host name: ");
            
            return Utf.fromStringz(name.ptr).dup;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
	unittest
	{
        import core.stdc.stdio;
		import tango.io.Stdout;
        
        // hostname
        char[] hostname = NetHost.hostName();
        Stdout.formatln("hostname: {}", hostname);
        Stdout("---").newline;
        
        // lookup by name
        NetHost hostent = new NetHost();
        hostent.getHostByName(hostname);
        assert(hostent.addrList.length > 0);
        foreach(int i, char[] s; hostent.aliases)
            Stdout.formatln("aliases[{0}] = {1}", i, s); 
        Stdout("---").newline;
        
        // reverse lookup
        InternetAddress address = new InternetAddress(ntohl(hostent.addrList[0]), InternetAddress.PORT_ANY);
        Stdout.formatln("IP-Address = {0}", address.toAddrString());
        Stdout.formatln("Name = {0}", hostent.name);
        Stdout("---").newline;
        
        // lookup by addr
        assert(hostent.getHostByAddr(ntohl(hostent.addrList[0])));
        Stdout.formatln("name = {}", hostent.name);
        foreach(int i, char[] s; hostent.aliases)
            Stdout.formatln("aliases[{0}] = {1}", i, s);
        Stdout("---").newline;
    }
}

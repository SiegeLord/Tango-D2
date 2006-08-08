/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Aug 2006      
        
        author:         Kris

*******************************************************************************/

module tango.net.InternetAddress;

private import tango.net.Socket;

/*******************************************************************************


*******************************************************************************/

class InternetAddress : IPv4Address
{
        /***********************************************************************

                -port- can be PORT_ANY
                -addr- is an IP address or host name

        ***********************************************************************/

        this (char[] addr, int port = PORT_ANY)
        {
                foreach (int i, char c; addr)
                         if (c is ':')
                            {
                            addr = addr [0 .. i];
                            port = parse (addr [i+1 .. $]);
                            break;
                            }

                super (addr, port);
        }

        /***********************************************************************


        ***********************************************************************/

        this (uint addr, ushort port)
        {
                super (addr, port);
        }


        /***********************************************************************


        ***********************************************************************/

        this (ushort port)
        {
                super (port);
        }

        /**********************************************************************

        **********************************************************************/

        static InternetAddress create (char[] host)
        {       
                return new InternetAddress (host);
        }

        /**********************************************************************

        **********************************************************************/

        private static int parse (char[] s)
        {       
                int number;

                foreach (c; s)
                         number = number * 10 + (c - '0');

                return number;
        }
}

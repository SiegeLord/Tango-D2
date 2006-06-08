/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.ServletException;

private import tango.io.Exception;

/******************************************************************************

        The fundamental Servlet exception

******************************************************************************/

class ServletException : IOException
{
        /**********************************************************************

                Construct this exception with the provided message
                
        **********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}


/******************************************************************************

        Exception to indicate a service is unavailable

******************************************************************************/

class UnavailableException : ServletException
{
        /**********************************************************************

                Construct this exception with the provided message
                
        **********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}

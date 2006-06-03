/*******************************************************************************

        @file IServer.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version, April 2004      
        @author         Kris


*******************************************************************************/

module tango.ext.net.util.model.IServer;

private import  tango.net.Socket;

private import  tango.io.model.IConduit;

/******************************************************************************

        Contract to be fulfilled by all Mango servers.

******************************************************************************/

interface IServer
{
        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        char[] getRemoteAddress (IConduit conduit);

        /**********************************************************************

                Provide support for figuring out the remote host. 

        **********************************************************************/

        char[] getRemoteHost (IConduit conduit);

        /**********************************************************************

                Return the protocol in use.

        **********************************************************************/

        char[] getProtocol();

        /**********************************************************************

                Return the local port we're attached to

        **********************************************************************/

        int getPort();

        /**********************************************************************

                Return the local address we're attached to

        **********************************************************************/

        char[] getHost();
}



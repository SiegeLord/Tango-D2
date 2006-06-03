/*******************************************************************************

        @file HttpThread.d
        
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

module tango.ext.net.http.server.HttpThread;

private import  tango.net.ServerSocket;

private import  tango.ext.net.util.ServerThread,
                tango.ext.net.util.AbstractServer;

private import  tango.ext.net.http.server.model.IProviderBridge;

/******************************************************************************

        Extends the basic ServerThread to add thread-local data. All data
        maintained on a thread basis is stored via multiple IProviderBridge
        instances (one per thread).
 
******************************************************************************/

class HttpThread : ServerThread
{
        IProviderBridge bridge;

        /**********************************************************************

                Construct an HttpThread with the provided server and socket
                attributes.

        **********************************************************************/

        this (AbstractServer server, ServerSocket socket)
        {
                super (server, socket);
        }

        /**********************************************************************

                Attach an IProvider/IServer bridge. This is where additional
                per-thread data is stored.

        **********************************************************************/

        void setBridge (IProviderBridge bridge)
        {
                this.bridge = bridge;
        }

        /**********************************************************************
        
                Return the bridge associated with this thread.

        **********************************************************************/

        IProviderBridge getBridge ()
        {
                return bridge;
        }       
}


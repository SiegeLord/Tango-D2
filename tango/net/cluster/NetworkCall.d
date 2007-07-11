/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkCall;

protected import tango.io.protocol.model.IReader,
                 tango.io.protocol.model.IWriter;

protected import tango.net.cluster.model.IChannel;

private   import tango.net.cluster.NetworkMessage;

/*******************************************************************************

*******************************************************************************/

class NetworkCall : NetworkMessage
{
        /***********************************************************************

        ***********************************************************************/

        void send (IChannel channel = null)
        {
                if (channel)
                    channel.execute (this);
                else
                   execute;
        }
}
/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.cache.model.IPayload;

public import tango.io.protocol.model.IPickle;

/******************************************************************************

        IPayload objects are held within an ICache. Each entry can
        be serialized in the standard fashion, via the IReader/IWriter
        mechanisms and the IPickle object resurrection facilities.

        IPayload objects are expected to extend out across a cluster.

******************************************************************************/

interface IPayload : IPickle, IPickleFactory
{
        /***********************************************************************

        ***********************************************************************/

        ulong getTime ();

        /***********************************************************************

        ***********************************************************************/

        void setTime (ulong time);

        /**********************************************************************

                Perform whatever cleanup is necessary. Could use ~this()
                instead, but I prefer it to be truly explicit.

        **********************************************************************/

        void destroy ();
}

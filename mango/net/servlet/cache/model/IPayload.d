/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.cache.model.IPayload;

public import tango.io.protocol.model.IReader,
              tango.io.protocol.model.IWriter;

/******************************************************************************

        IPayload objects are held within an ICache. Each entry can
        be serialized in the standard fashion, via the IReader/IWriter
        mechanisms and the IPickle object resurrection facilities.

        IPayload objects are expected to extend out across a cluster.

******************************************************************************/

interface IPayload : IReadable, IWritable
{
        /***********************************************************************
        
                Identify this serializable class via a char[]. This should
                be (per class) unique within the domain. Use version numbers 
                or similar mechanism to isolate different implementations of
                the same class.

        ***********************************************************************/

        char[] getGuid ();
        
        /***********************************************************************

        ***********************************************************************/

        ulong getTime ();

        /***********************************************************************

        ***********************************************************************/

        void setTime (ulong time);

        /**********************************************************************

                Perform whatever cleanup is necessary. Could use ~this()
                instead, but we prefer it to be explicit.

        **********************************************************************/

        void destroy ();
}

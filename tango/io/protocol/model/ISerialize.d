/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2007: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.io.protocol.model.ISerialize;

public import tango.io.protocol.model.IReader,
              tango.io.protocol.model.IWriter;

/*******************************************************************************

        Interface for all serializable classes. Such classes are intended
        to be transported over a network, or be frozen in a file for later
        reconstruction. 

*******************************************************************************/

interface ISerialize : IReadable, IWritable
{
        /***********************************************************************

                return the guid of this class -- typically classinfo.name
                                
        ***********************************************************************/

        char[] toUtf8 ();

        /***********************************************************************

                return a shallow, bitwise, copy of the object
                                 
        ***********************************************************************/

        ISerialize clone ();
}

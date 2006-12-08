/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.protocol.model.IPickle;

public import tango.io.protocol.model.IReader,
              tango.io.protocol.model.IWriter;

/*******************************************************************************

        Interface for all serializable classes. Such classes are intended
        to be transported over a network, or be frozen in a file for later
        reconstruction. 

*******************************************************************************/

interface IPickle : IWritable, IReadable
{
        /***********************************************************************
        
                Identify this serializable class via a char[]. This should
                be (per class) unique within the domain. Use version numbers 
                or similar mechanism to isolate different implementations of
                the same class.

        ***********************************************************************/

        char[] getGuid ();
}
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


/*******************************************************************************

        Interface for all deserializable classes. Such classes either
        implement the full concrete class instance or they act as a
        proxy of sorts, creating the true instance only when called
        upon to do so. An IPickleProxy could perhaps take alternative
        action when called upon to create an "old" or "unsupported"
        class guid. The default behaviour is to throw an exception
        when an unknown guid is seen.

*******************************************************************************/

interface IPickleFactory
{
        /***********************************************************************

                Identify this serializable class via a char[]. This should
                be (per class) unique within the domain. Use version numbers
                or similar mechanism to isolate different implementations of
                the same class.

        ***********************************************************************/

        char[] getGuid ();

        /***********************************************************************

                This defines the factory method. Each IPickleProxy object
                provides a factory for creating a deserialized instance.
                The factory is registered along with the appropriate guid.

        ***********************************************************************/

        Object create (IReader reader);
}
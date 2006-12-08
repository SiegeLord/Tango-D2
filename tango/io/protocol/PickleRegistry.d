/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004     
                        Outback version: December 2006
         
        author:         Kris

*******************************************************************************/

module tango.io.protocol.PickleRegistry;

private import  tango.io.Exception;
        
public  import  tango.io.protocol.model.IReader,
                tango.io.protocol.model.IPickle;

/*******************************************************************************

        Bare framework for registering and creating serializable objects.
        Such objects are intended to be transported across a local network
        and re-instantiated at some destination node. 

        Each IPickle exposes the means to write, or freeze, its content. An
        IPickleFactory provides the means to create a new instance of itself
        populated with thawed data. Frozen objects are uniquely identified 
        by a guid exposed via the interface. Responsibility of maintaining
        uniqueness across said identifiers lies in the hands of the developer.

        See PickleReader for an example of how this is expected to operate

*******************************************************************************/

class PickleRegistry
{
        private alias Object function (IReader reader)  Factory;
        
        private static Factory[char[]]                  registry;


        /***********************************************************************
        
                This is a singleton: the constructor should not be exposed

        ***********************************************************************/

        private this () {}

        /***********************************************************************
        
                Add the provided Factory to the registry. Note that one
                cannot change a registration once it is placed. Neither
                can one remove registered item. This is done to avoid 
                issues when trying to synchronize servers across
                a farm, which may still have live instances of "old"
                objects waiting to be passed around the cluster. New
                versions of an object should be given a distinct guid
                from the prior version; appending an incremental number 
                may well be sufficient for your needs.

        ***********************************************************************/

        static synchronized void enroll (Factory factory, char[] guid)
        {
                if (guid in registry)
                    throw new PickleException ("PickleRegistry.enroll :: attempt to re-register a guid");
        
                registry[guid] = factory;
        }

        /***********************************************************************
        
                Synchronized Factory lookup of the guid

        ***********************************************************************/

        static synchronized Factory lookup (char[] guid)
        {
                auto factory = guid in registry;
                return (factory ? *factory : null);
        }

        /***********************************************************************
        
                Create a new instance of a registered class from the content
                made available via the given reader. The factory is located
                using the provided guid, which must match an enrolled Factory.

                Note that only the factory lookup is synchronized, and not 
                the instance construction itself. This is intentional, and
                limits how long the calling thread is stalled

        ***********************************************************************/

        static Object create (IReader reader, char[] guid)
        {
                // locate the appropriate Proxy. 
                auto factory = lookup (guid);
                if (factory)
                    return factory (reader);

                throw new PickleException ("PickleRegistry.create :: attempt to unpickle via unregistered guid '"~guid~"'");
        }
}


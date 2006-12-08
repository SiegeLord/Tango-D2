/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004     
                        Outback version: December 2006
         
        author:         Kris

*******************************************************************************/

module tango.io.protocol.PickleReader;

private import  tango.io.protocol.EndianReader,
                tango.io.protocol.PickleRegistry;

/*******************************************************************************
        
        Reads serialized content from the bound Buffer, and reconstructs
        the 'original' object from the data therein. 

        All content must be in Network byte-order, so as to span machine
        boundaries. Here's an example of how this class is expected to be 
        used in conjunction with PickleWriter & PickleRegistry: 

        ---
        class Wumpus : IPickle
        {
                private int x = 11;
                private int y = 112;

                char[] getGuid ()
                {
                        return this.classinfo.toUtf8;
                }

                void write (IWriter output)
                {
                        output (x) (y);
                }

                void read (IReader input)
                {
                        input (x) (y);
                }

                static Object create (IReader reader)
                {
                        auto wumpus = new Wumpus;
                        wumpus.read (reader);
                        assert (wumpus.x == 11 && wumpus.y == 112);
                        return wumpus;
                }
        }

        // setup for serialization
        auto buf = new Buffer (256);
        auto read = new PickleReader (buf);
        auto write = new PickleWriter (buf);

        // tell registry about this object
        PickleRegistry.enroll (&Wumpus.create, Wumpus.classinfo.toUtf8);

        // construct a Wumpus and serialize it
        write.freeze (new Wumpus);
        
        // create a new instance and populate. This just shows the basic
        // concept, not a fully operational implementation
        auto object = read.thaw ();
        ---

*******************************************************************************/

version (BigEndian)
         private alias Reader SuperClass;
      else
         private alias EndianReader SuperClass;

class PickleReader : SuperClass
{       
        /***********************************************************************
        
                Construct a PickleReader with the given buffer, and
                an appropriate EndianReader.

                Note that serialized data is always in Network order.

        ***********************************************************************/

        this (IBuffer buffer)
        {
                super (buffer);
        }

        /***********************************************************************
        
                Reconstruct an Object from the current buffer content. It
                is considered optimal to configure the underlying IReader
                with an allocator that slices array-references, rather than 
                copying them into the heap (the default configuration). 

        ***********************************************************************/

        Object thaw ()
        {
                char[] name;

                get (name);
                return PickleRegistry.create (this, name);                                 
        }
}

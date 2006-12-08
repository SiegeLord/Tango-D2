/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004     
                        Outback version: December 2006
         
        author:         Kris

*******************************************************************************/

module tango.io.PickleWriter;

private import  tango.io.protocol.EndianWriter;

private import  tango.io.protocol.model.IPickle;


/*******************************************************************************

        Serialize Objects via an EndianWriter. All Objects are written in
        Network-order such that they may cross machine boundaries.

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
         private alias Writer SuperClass;
      else
         private alias EndianWriter SuperClass;

class PickleWriter : SuperClass
{
        /***********************************************************************
        
                Construct a PickleWriter upon the given buffer. As
                Objects are serialized, their content is written to this
                buffer. The buffer content is then typically flushed to 
                some external conduit, such as a file or socket.

                Note that serialized data is always in Network order.

        ***********************************************************************/
        
        this (IBuffer buffer)
        {
                super (buffer);
        }

        /***********************************************************************
        
                Serialize an Object. Objects are written in Network-order, 
                and are prefixed by the guid exposed via the IPickle
                interface. This guid is used to identify the appropriate
                factory when reconstructing the instance. 

        ***********************************************************************/

        PickleWriter freeze (IPickle object)
        {
                put (object.getGuid);
                object.write (this);
                return this;
        }
}


/*******************************************************************************

        copyright:      Copyright (c) 2006 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Dec 2006

        author:         Kris

*******************************************************************************/

module tango.io.MemoryConduit;

public import tango.io.Conduit,
              tango.io.GrowBuffer;

/*******************************************************************************

        Implements reading and writing of memory as a Conduit. Conduits
        are the primary means of accessing external data

        Use GrowBuffer directly in place of this class

*******************************************************************************/

class MemoryConduit : GrowBuffer
{
        // Use GrowBuffer directly in place of this class

        deprecated this() {}
}


/******************************************************************************

******************************************************************************/

debug (MemoryConduit)
{
        import tango.io.protocol.Reader;
        import tango.io.protocol.Writer;

        void main() {}

        unittest
        {
                auto c = new MemoryConduit;
                auto r = new Reader (c);
                auto w = new Writer (c);

                w ("one two three"c) ();
                char[] x;
                r (x);
                assert (x == "one two three");
        }        
}

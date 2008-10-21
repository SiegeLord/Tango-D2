/*******************************************************************************

        A Conduit that ignores all that is written to it
        
        copyright:      Copyright (c) 2008. Fawzi Mohamed
        
        license:        BSD style: $(LICENSE)
        
        version:        Initial release: July 2008
        
        author:         Fawzi Mohamed

*******************************************************************************/

module tango.io.device.NullConduit;

private import tango.io.device.Conduit;

/*******************************************************************************

        A Conduit that ignores all that is written to it and returns Eof
        when read from. Note that write() returns the length of what was
        handed to it, acting as a pure bit-bucket. Returning zero or Eof
        instead would not be appropriate in this context.

*******************************************************************************/

class NullConduit : Conduit
{
        override char[] toString () {return "<null conduit>";} 

        override uint bufferSize () { return 0;}

        override uint read (void[] dst) { return Eof; }

        override uint write (void[] src) { return src.length; }

        override void detach () { }
}



debug(UnitTest)
{
    unittest{
        auto a=new NullConduit();
        a.write("bla");
        a.flush();
        a.detach();
        a.write("b"); // at the moment it works, disallow?
        uint[4] b=0;
        a.read(b);
        foreach (el;b)
            assert(el==0);
    }
}

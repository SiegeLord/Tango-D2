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
        when read from

*******************************************************************************/

class NullConduit : Conduit
{
        override char[] toString () {return "NullConduit";} 

        override uint bufferSize () { return 256u;}

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

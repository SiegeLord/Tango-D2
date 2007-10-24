/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.GreedyStream;

private import tango.io.Conduit;

/*******************************************************************************

        A conduit filter that ensures its output is written in full  

*******************************************************************************/

class GreedyOutput : OutputFilter
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Consume everything we were given. Returns the number of
                bytes written which will be less than src.length only
                when an Eof condition is reached, and IConduit.Eof from
                that point forward

        ***********************************************************************/

        override uint write (void[] src)
        {
                uint len = 0;

                while (len < src.length)
                      {
                      auto i = host.write (src [len .. $]);
                      if (i is IConduit.Eof)
                          return (len ? len : i);
                      len += i;
                      } 
                return len;
        }
}


/*******************************************************************************

        A conduit filter that ensures its input is read in full         

*******************************************************************************/

class GreedyInput : InputFilter
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Fill the provided array. Returns the number of bytes
                actually read, which will be less that dst.length when
                Eof has been reached and IConduit.Eof thereafter

        ***********************************************************************/

        override uint read (void[] dst)
        {
                uint len = 0;

                while (len < dst.length)
                      {
                      auto i = host.read (dst [len .. $]);
                      if (i is IConduit.Eof)
                          return (len ? len : i);
                      len += i;
                      } 
                return len;
        }
}

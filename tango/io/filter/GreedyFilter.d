/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.GreedyFilter;

private import tango.io.Conduit;

private import tango.io.model.IConduit;

/*******************************************************************************

        A conduit filter that ensures its output is written in full. Note
        that the filter attaches itself to the associated conduit    

*******************************************************************************/

class GreedyOutput : OutputFilter
{
        /***********************************************************************

                Propogate ctor to superclass

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
                uint len;

                do {
                   auto i = next.write (src [len .. $]);
                   if (i is IConduit.Eof)
                       return (len ? len : i);
                   len += i;
                   } while (len < src.length);

                return len;
        }
}


/*******************************************************************************

        A conduit filter that ensures its input is read in full. Note
        that the filter attaches itself to the associated conduit          

*******************************************************************************/

class GreedyInput : InputFilter
{
        /***********************************************************************

                Propogate ctor to superclass

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
                uint len;

                do {
                   auto i = next.read (dst [len .. $]);
                   if (i is IConduit.Eof)
                       return (len ? len : i);
                   len += i;
                   } while (len < dst.length);

                return len;
        }
}

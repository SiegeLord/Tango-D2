/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.BufferedStream;

private import tango.io.Buffer;

/*******************************************************************************

        Buffers the flow of data from a downstream input. An upstream 
        neighbour can locate and use this instead of creating another.

*******************************************************************************/

class BufferedInput : Buffer
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, uint size = 16 * 1024)
        {
                super (size);
                super.input = stream;
        }
}


/*******************************************************************************
        
        Buffers the flow of data to a downstream output. An upstream 
        neighbour can locate and use this instead of creating another.

*******************************************************************************/

class BufferedOutput : Buffer
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, uint size = 16 * 1024)
        {
                super (size);
                super.output = stream;
        }
}



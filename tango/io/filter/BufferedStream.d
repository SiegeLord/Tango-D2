/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.BufferedStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import  tango.io.model.IConduit;

/*******************************************************************************

        A conduit filter that ensures its output is written in full. Note
        that the filter attaches itself to the associated conduit    

*******************************************************************************/

class BufferedOutput : OutputFilter, Buffered
{
        private IBuffer output;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream)
        {
                auto b = cast(Buffered) stream;
                output = (b ? b.buffer : new Buffer (stream.conduit));
                super (output);
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Consume everything we were given

        ***********************************************************************/

        override uint write (void[] src)
        {
                output.append (src.ptr, src.length);
                return src.length;
        }
}


/*******************************************************************************

        A conduit filter that ensures its input is read in full. Note
        that the filter attaches itself to the associated conduit          

*******************************************************************************/

class BufferedInput : InputFilter, Buffered
{
        private IBuffer input;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                auto b = cast(Buffered) stream;
                input = (b ? b.buffer : new Buffer (stream.conduit));
                super (input);
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Fill the provided array. Returns the number of bytes
                actually read, which will be less that dst.length when
                Eof has been reached and IConduit.Eof thereafter

        ***********************************************************************/

        override uint read (void[] dst)
        {
                return input.fill (dst);
        }
}

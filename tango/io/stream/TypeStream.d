/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        Streams to expose simple native types as discrete elements. I/O
        is buffered and should yield fair performance.

*******************************************************************************/

module tango.io.stream.TypeStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

/*******************************************************************************

        Type T is the target or destination type

*******************************************************************************/

class TypeInput(T) : InputFilter, Buffered
{       
        private IBuffer input;

        /***********************************************************************

        ***********************************************************************/

        this (InputStream stream)
        {
                super (input = Buffer.share (stream));
        }
        
        /***********************************************************************

                Buffered interface 

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Read a value from the stream. Returns false when all 
                content has been consumed

        ***********************************************************************/

        final bool read (inout T x)
        {
                return input.read((&x)[0..1]) is T.sizeof;
        }

        /***********************************************************************

                Iterate over all content

        ***********************************************************************/

        final int opApply (int delegate(ref T x) dg)
        {
                T x;
                int ret;

                while ((input.read((&x)[0..1]) is T.sizeof))
                        if ((ret = dg (x)) != 0)
                             break;
                return ret;
        }
}



/*******************************************************************************
        
        Type T is the target or destination type.

*******************************************************************************/

class TypeOutput (T) : OutputFilter, Buffered
{       
        private IBuffer output;

        /***********************************************************************

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = Buffer.share (stream));
        }

        /***********************************************************************

                Buffered interface 

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************
        
                Append a value to the output stream

        ***********************************************************************/

        final void write (T x)
        {
                output.append (&x, T.sizeof);
        }
}


/*******************************************************************************
        
*******************************************************************************/
        
debug (UnitTest)
{
        import tango.io.Stdout;
        import tango.io.stream.UtfStream;

        unittest
        {
                auto inp = new TypeInput!(char)(new Buffer("hello world"));
                auto oot = new TypeOutput!(char)(new Buffer(20));
                foreach (x; inp)
                         oot.write (x);
                assert (oot.buffer.slice == "hello world");

                auto xx = new TypeInput!(char)(new UtfInput!(char, dchar)(new Buffer("hello world"d)));
                char[] yy;
                foreach (x; xx)
                         yy ~= x;
                assert (yy == "hello world");
        }
}

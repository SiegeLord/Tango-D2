/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.RawFileStream;

public  import tango.io.FileConduit;

private import tango.io.stream.DataStream;

/*******************************************************************************

        Composes a seekable file with buffered binary input. A seek causes
        the input buffer to be cleared

*******************************************************************************/

class RawFileInput : DataInput
{
        private FileConduit conduit;

        public alias FileConduit.Seek.Anchor Anchor;

        /***********************************************************************

                Wrap a Fileconduit instance

        ***********************************************************************/

        this (FileConduit file, uint buffer=uint.max)
        {
                super (conduit = file, buffer);
        }

        /***********************************************************************

                Set the file seek position to the specified offset from 
                the given anchor, and clear the input buffer
        
        ***********************************************************************/

        final long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                host.clear;
                return conduit.seek (offset, anchor);
        }

        /***********************************************************************

                Return the underling conduit

        ***********************************************************************/

        final FileConduit file ()
        {       
                return conduit;
        }
}


/*******************************************************************************
       
        Composes a seekable file with buffered binary output. A seek causes
        the output buffer to be flushed first

*******************************************************************************/

class RawFileOutput : DataOutput
{
        private FileConduit conduit;

        public alias FileConduit.Seek.Anchor Anchor;

        /***********************************************************************

                Wrap a Fileconduit instance

        ***********************************************************************/

        this (FileConduit file, uint buffer=uint.max)
        {
                super (conduit = file, buffer);
        }

        /***********************************************************************

                Set the file seek position to the specified offset from 
                the given anchor, after flushing the output buffer
        
        ***********************************************************************/

        final long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                host.flush;
                return conduit.seek (offset, anchor);
        }

        /***********************************************************************

                Return the underling conduit

        ***********************************************************************/

        final FileConduit file ()
        {       
                return conduit;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
}

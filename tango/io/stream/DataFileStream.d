/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.DataFileStream;

private import tango.io.stream.DataStream;

private import tango.io.device.FileConduit;

/*******************************************************************************

        Composes a seekable file with buffered binary input. A seek causes
        the input buffer to be cleared

*******************************************************************************/

class DataFileInput : DataInput
{
        alias FileConduit.Seek.Anchor Anchor;

        private FileConduit conduit;

        /***********************************************************************

                Wrap a FileConduit instance

        ***********************************************************************/

        this (FileConduit file, uint buffer=uint.max)
        {
                super (conduit = file, buffer);
        }

        /***********************************************************************

                Set the file seek position to the specified offset, and 
                clear the input buffer
        
        ***********************************************************************/

        final long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                host.clear;
                return conduit.seek (offset, anchor);
        }

        /***********************************************************************

                Return the underlying conduit

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

class DataFileOutput : DataOutput
{
        alias FileConduit.Seek.Anchor Anchor;

        private FileConduit conduit;

        /***********************************************************************

                Wrap a FileConduit instance

        ***********************************************************************/

        this (FileConduit file, uint buffer=uint.max)
        {
                super (conduit = file, buffer);
        }

        /***********************************************************************

                Set the file seek position to the specified offset, after 
                flushing the output buffer
        
        ***********************************************************************/

        final long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                host.flush;
                return conduit.seek (offset, anchor);
        }

        /***********************************************************************

                Return the underlying conduit

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

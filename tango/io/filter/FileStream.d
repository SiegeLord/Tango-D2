/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.FileStream;

private import tango.io.FileConduit;

/*******************************************************************************

        Trivial wrapper around a FileConduit

*******************************************************************************/

class FileInput : FileConduit
{
        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.ReadExisting)
        {
                super (path, style);
        }
}


/*******************************************************************************

        Trivial wrapper around a FileConduit

*******************************************************************************/

class FileOutput : FileConduit
{
        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.WriteCreate)
        {
                super (path, style);
        }
}


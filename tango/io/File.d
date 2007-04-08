/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2005: Initial release
        version:        Feb 2007: No longer a proxy subclass
                        
        author:         Kris

*******************************************************************************/

module tango.io.File;

private import  tango.io.FilePath,
                tango.io.FileConduit;

private import  tango.core.Exception;

/*******************************************************************************

        A wrapper atop of FileConduit to expose a simpler API. This one
        returns the entire file content as a void[], and sets the content
        to reflect a given void[].

        Method read() returns the current content of the file, whilst write()
        sets the file content, and file length, to the provided array. Method
        append() adds content to the tail of the file.

        Methods to inspect the file system, check the status of a file or
        directory and other facilities are made available via the associated
        path (exposed via the path() method)
        
*******************************************************************************/

class File
{
        private PathView path_;

        /***********************************************************************
        
                Construct a File from a text string

        ***********************************************************************/

        this (char[] path)
        {
                this (new FilePath (path));
        }

        /***********************************************************************
        
                Construct a File from the provided FilePath

        ***********************************************************************/
                                  
        this (PathView path)
        {
                path_ = path;
        }

        /***********************************************************************

                Return the path for this file instance

        ***********************************************************************/

        final PathView path ()
        {
                return path_;
        }

        /***********************************************************************

                Return the content of the file.

        ***********************************************************************/

        final void[] read ()
        {
                auto conduit = new FileConduit (path_);  
                scope (exit)
                       conduit.close;

                auto content = new ubyte[cast(int) conduit.length];

                // read the entire file into memory and return it
                if (conduit.fill (content) != content.length)
                    throw new IOException ("eof whilst reading");

                return content;
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        final File write (void[] content)
        {
                return write (content, FileConduit.ReadWriteCreate);  
        }

        /***********************************************************************

                Append content to the file.

        ***********************************************************************/

        final File append (void[] content)
        {
                return write (content, FileConduit.WriteAppending);  
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        private File write (void[] content, FileConduit.Style style)
        {      
                auto conduit = new FileConduit (path_, style);  
                scope (exit)
                       conduit.close;

                conduit.flush (content);
                return this;
        }
}
/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2005: Initial release
        version:        Feb 2007: No longer a proxy subclass
                        
        author:         Kris

*******************************************************************************/

module tango.io.File;

private import Conduit = tango.io.device.File;

pragma (msg, "warning - io.File functionality has migrated to static functions within io.device.File");

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
        private char[] path_;

        /***********************************************************************

                Call-site shortcut to create a File instance. This 
                enables the same syntax as struct usage, so may expose
                a migration path

        ***********************************************************************/

        this (char[] path)
        {
                path_ = path;
        }

        /***********************************************************************

                Call-site shortcut to create a File instance. This 
                enables the same syntax as struct usage, so may expose
                a migration path

        ***********************************************************************/

        static File opCall (char[] path)
        {
                return new File (path);
        }

        /***********************************************************************

                Return the content of the file.

        ***********************************************************************/

        final void[] read ()
        {
                scope conduit = new Conduit.File (path_);  
                scope (exit)
                       conduit.close;

                // allocate enough space for the entire file
                auto content = new ubyte [cast(size_t) conduit.length];

                //read the content
                if (conduit.read (content) != content.length)
                    conduit.error ("unexpected eof");

                return content;
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        final File write (void[] content)
        {
                return write (content, Conduit.File.ReadWriteCreate);  
        }

        /***********************************************************************

                Append content to the file.

        ***********************************************************************/

        final File append (void[] content)
        {
                return write (content, Conduit.File.WriteAppending);  
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        private File write (void[] content, Conduit.File.Style style)
        {      
                scope conduit = new Conduit.File (path_, style);  
                scope (exit)
                       conduit.close;

                conduit.write (content);
                return this;
        }
}

/*******************************************************************************

*******************************************************************************/

debug (File)
{
        import tango.io.Stdout;

        void main()
        {
                auto x = new File ("");

                auto content = cast(char[]) File("File.d").read;
                Stdout (content).newline;
        }
}

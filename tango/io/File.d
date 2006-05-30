/*******************************************************************************

        @file File.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version; March 2005      

        @author         Kris

*******************************************************************************/

module tango.io.File;

public  import  tango.io.FilePath;
 
private import  tango.io.FileProxy,
                tango.io.Exception,
                tango.io.FileConduit;

/*******************************************************************************

        A wrapper atop of FileConduit to expose a simpler API. This one
        returns the entire file content as a void[], and sets the content
        to reflect a given void[].

        Method read() returns the current content of the file, whilst write()
        sets the file content, and file length, to the provided array. Method
        append() adds content to the tail of the file.

        Methods to inspect the file system, check the status of a file or
        directory, and other facilities are made available via the FileProxy
        superclass.

*******************************************************************************/

class File : FileProxy
{
        /***********************************************************************
        
                Construct a File from a text string

        ***********************************************************************/

        this (char[] path)
        {
                super (path);
        }

        /***********************************************************************
        
                Construct a File from the provided FilePath

        ***********************************************************************/
                                  
        this (FilePath path)
        {
                super (path);
        }

        /***********************************************************************

                Return the content of the file.

        ***********************************************************************/

        void[] read ()
        {
                ubyte[] content;

                auto conduit = new FileConduit (this);  
                try {
                    content = new ubyte[cast(int) conduit.length];

                    // read the entire file into memory and return it
                    if (conduit.read (content) != content.length)
                        throw new IOException ("eof whilst reading");
                    } finally {
                              conduit.close ();
                              }
                return content;
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        File write (void[] content)
        {
                return write (content, FileStyle.WriteTruncate);  
        }

        /***********************************************************************

                Append content to the file.

        ***********************************************************************/

        File append (void[] content)
        {
                return write (content, FileStyle.WriteAppending);  
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.

        ***********************************************************************/

        private File write (void[] content, FileStyle.Bits style)
        {      
                auto conduit = new FileConduit (this, style);  
                try {
                    conduit.flush (content);
                    } finally {
                              conduit.close ();
                              }
                return this;
        }
}
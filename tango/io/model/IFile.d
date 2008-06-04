/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2005      
        
        author:         Kris

*******************************************************************************/

module tango.io.model.IFile;

/*******************************************************************************

        Generic file-oriented attributes

*******************************************************************************/

interface FileConst
{
        /***********************************************************************
        
                A set of file-system specific constants for file and path
                separators (chars and strings).

                Keep these constants mirrored for each OS

        ***********************************************************************/

        version (Win32)
        {
                enum : char 
                {
                        CurrentDirChar = '.',
                        FileSeparatorChar = '.',
                        PathSeparatorChar = '/',
                        SystemPathChar = ';',
                }

                static const char[] ParentDirString = "..";
                static const char[] CurrentDirString = ".";
                static const char[] FileSeparatorString = ".";
                static const char[] PathSeparatorString = "/";
                static const char[] SystemPathString = ";";

                static const char[] NewlineString = "\r\n";
        }

        version (Posix)
        {
                enum : char 
                {
                        CurrentDirChar = '.',
                        FileSeparatorChar = '.',
                        PathSeparatorChar = '/',
                        SystemPathChar = ':',
                }

                static const char[] ParentDirString = "..";
                static const char[] CurrentDirString = ".";
                static const char[] FileSeparatorString = ".";
                static const char[] PathSeparatorString = "/";
                static const char[] SystemPathString = ":";

                static const char[] NewlineString = "\n";
        }
}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2005

        author:         Kris

*******************************************************************************/

module tango.io.FileConst;

/*******************************************************************************

        A set of file-system specific constants for file and path
        separators (chars and strings).

*******************************************************************************/

struct FileConst
{
        version (Win32)
        {
                static const char PathSeparatorChar = '\\';
                static const char FileSeparatorChar = '.';
                static const char RootSeparatorChar = ':';

                static const char[] PathSeparatorString = "\\";
                static const char[] FileSeparatorString = ".";
                static const char[] RootSeparatorString = ":";

                static const char[] NewlineString = "\r\n"c;
        }

        version (Posix)
        {
                static const char PathSeparatorChar = '/';
                static const char FileSeparatorChar = '.';
                static const char RootSeparatorChar = ':';

                static const char[] PathSeparatorString = "/";
                static const char[] FileSeparatorString = ".";
                static const char[] RootSeparatorString = ":";

                static const char[] NewlineString = "\n";
        }
}
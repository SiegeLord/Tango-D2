/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2005

        author:         Kris

*******************************************************************************/

module tango.io.model.IFile;

/*******************************************************************************

        Generic file-oriented attributes.

*******************************************************************************/

interface FileConst
{
        /***********************************************************************

                A set of file-system specific constants for file and path
                separators (chars and strings).

                Keep these constants mirrored for each OS.

        ***********************************************************************/

        version (Win32)
        {
                ///
                enum : char
                {
                        /// The current directory character.
                        CurrentDirChar = '.',

                        /// The file separator character.
                        FileSeparatorChar = '.',

                        /// The path separator character.
                        PathSeparatorChar = '/',

                        /// The system path character.
                        SystemPathChar = ';',
                }

                /// The parent directory string
                __gshared immutable immutable(char)[] ParentDirString = "..";

                /// The current directory string
                __gshared immutable immutable(char)[] CurrentDirString = ".";

                /// The file separator string
                __gshared immutable immutable(char)[] FileSeparatorString = ".";

                /// The path separator string
                __gshared immutable immutable(char)[] PathSeparatorString = "/";

                /// The system path string
                __gshared immutable immutable(char)[] SystemPathString = ";";

                /// The newline string
                __gshared immutable immutable(char)[] NewlineString = "\r\n";
        }

        version (Posix)
        {
                ///
                enum : char
                {
                        /// The current directory character.
                        CurrentDirChar = '.',

                        /// The file separator character.
                        FileSeparatorChar = '.',

                        /// The path separator character.
                        PathSeparatorChar = '/',

                        /// The system path character.
                        SystemPathChar = ':',
                }

                /// The parent directory string
                __gshared immutable immutable(char)[] ParentDirString = "..";

                /// The current directory string
                __gshared immutable immutable(char)[] CurrentDirString = ".";

                /// The file separator string
                __gshared immutable immutable(char)[] FileSeparatorString = ".";

                /// The path separator string
                __gshared immutable immutable(char)[] PathSeparatorString = "/";

                /// The system path string
                __gshared immutable immutable(char)[] SystemPathString = ":";

                /// The newline string
                __gshared immutable immutable(char)[] NewlineString = "\n";
        }
}

/*******************************************************************************

        Passed around during file-scanning.

*******************************************************************************/

struct FileInfo
{
        const(char)[]   path,
                        name;
        ulong           bytes;
        bool            folder,
                        hidden,
                        system;
}


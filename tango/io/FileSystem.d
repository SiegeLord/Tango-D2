/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
        version:        Feb 2007: Now using mutating paths

        author:         Kris, Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.sys.Common;

private import  tango.io.FilePath;

private import  tango.core.Exception;

version (Win32)
        {
        private import Utf = tango.text.convert.Utf;
        }
     else
        {
        private import tango.stdc.string;
        private import tango.stdc.posix.unistd;
        }


/*******************************************************************************

        Models an OS-specific file-system. Included here are methods to
        manipulate the current working directory, and to convert a path
        to its absolute form.

*******************************************************************************/

class FileSystem
{
        /***********************************************************************

                Convert the provided path to an absolute path, using the
                current working directory. If the given path is already
                an absolute path, return it intact.

                Returns true if the path was adjusted, false otherwise

        ***********************************************************************/

        static bool makeAbsolute (FilePath path)
        {
                assert (path);

                if (! path.isAbsolute)
                   {
                   getDirectory (path.asName (path.toUtf8));
                   return true;
                   }
                return false;
        }

        /***********************************************************************

        ***********************************************************************/

        private static void exception (char[] msg)
        {
                throw new IOException (msg);
        }

        /***********************************************************************

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static FilePath setDirectory (FilePath path)
                {
                        assert (path);

                        version (Win32SansUnicode)
                                {
                                if (! SetCurrentDirectoryA (path.cString.ptr))
                                      exception ("Failed to set current directory");
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp = void;

                                if (! SetCurrentDirectoryW (Utf.toUtf16(path.cString, tmp).ptr))
                                      exception ("Failed to set current directory");
                                }

                        return path;
                }

                /***************************************************************

                        Inject the current working directory into the 
                        provided path segment

                ***************************************************************/

                static FilePath getDirectory (FilePath path)
                {
                        assert (path);

                        version (Win32SansUnicode)
                                {
                                int length = GetCurrentDirectoryA (0, null);
                                if (length)
                                   {
                                   auto dir = new char [length];
                                   GetCurrentDirectoryA (length, dir.ptr);
                                   path.asPath (dir[0 .. $-1]);
                                   }
                                else
                                   exception ("Failed to get current directory");
                                }
                             else
                                {
                                int length = GetCurrentDirectoryW (0, null);
                                if (length)
                                   {
                                   char[MAX_PATH] tmp = void;
                                   auto dir = new wchar [length];

                                   GetCurrentDirectoryW (length, dir.ptr);
                                   path.asPath (Utf.toUtf8 (dir, tmp)[0 .. $-1]);
                                   }
                                else
                                   exception ("Failed to get current directory");
                                }

                        return path;
                }
        }

        /***********************************************************************

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static FilePath setDirectory (FilePath path)
                {
                        assert (path);

                        if (tango.stdc.posix.unistd.chdir (path.cString.ptr))
                            exception ("Failed to set current directory");

                        return path;
                }

                /***************************************************************

                        Inject the current working directory into the 
                        provided path segment

                ***************************************************************/

                static FilePath getDirectory (FilePath path)
                {
                        assert (path);

                        char[512] tmp = void;

                        char *s = tango.stdc.posix.unistd.getcwd (tmp.ptr, tmp.length);
                        if (s is null)
                            exception ("Failed to get current directory");

                        return path.asPath (s[0 .. strlen (s)]);
                }
        }
}


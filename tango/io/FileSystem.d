/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris, Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.sys.Common;

private import  tango.io.FilePath,
                tango.io.Exception;


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
        list the system roots ("C:", "D:", etc) and to manipulate the
        current working directory.

*******************************************************************************/

class FileSystem
{
        /***********************************************************************

                Convert the provided path to an absolute path, using the
                current working directory. If the given path is already
                an absolute path, return it intact.

        ***********************************************************************/

        FilePath absolutePath (FilePath path)
        {
                if (path.isAbsolute)
                    return path;
                
                return path.join (getDirectory);
        }

        /***********************************************************************

        ***********************************************************************/

        package void exception (char[] msg)
        {
                throw new IOException (msg);
        }

        
        version (Win32)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static void setDirectory (FilePath fp)
                {
                        version (Win32SansUnicode)
                                {
                                if (! SetCurrentDirectoryA (fp.cString))
                                       exception ("Failed to set current directory");
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp = void;
                        
                                if (! SetCurrentDirectoryW (Utf.toUtf16(fp.cString, tmp).ptr))
                                      exception ("Failed to set current directory");
                                }
                }

                /***************************************************************

                        Get the current working directory
                
                ***************************************************************/

                static FilePath getDirectory ()
                {
                        version (Win32SansUnicode)
                                {
                                int length = GetCurrentDirectoryA (0, null);
                                if (length)
                                   {
                                   auto dir = new char [length];
                                   GetCurrentDirectoryA (length, dir);
                                   return new FilePath (dir);
                                   }
                                }
                             else
                                {
                                int length = GetCurrentDirectoryW (0, null);
                                if (length)
                                   {
                                   char[MAX_PATH] tmp = void;
                                   auto dir = new wchar [length];
                                   
                                   GetCurrentDirectoryW (length, dir.ptr);
                                   return new FilePath (Utf.toUtf8 (dir, tmp));
                                   }
                                }
                        exception ("Failed to get current directory");
                        return null;
                }
        }
        
        
        version (Posix)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static void setDirectory (FilePath fp)
                {
                        if (tango.stdc.posix.unistd.chdir (fp.cString.ptr))
                            exception ("Failed to set current directory");
                }

                /***************************************************************

                        Get the current working directory
                
                ***************************************************************/

                static FilePath getDirectory ()
                {
                        char *s = tango.stdc.posix.unistd.getcwd (null, 0);
                        if (s) 
                            return new FilePath (s[0..strlen(s)]);

                        exception ("Failed to get current directory");
                }
        }   
}


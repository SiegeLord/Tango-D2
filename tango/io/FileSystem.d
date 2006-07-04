/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris, John Reimer, Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.os.OS;

private import  tango.text.Text;

private import  tango.io.FilePath,
                tango.io.FileConst,
                tango.io.Exception;

private import  tango.text.convert.Unicode;

version (Win32)
        extern (Windows) DWORD GetLogicalDriveStringsA (DWORD, LPTSTR);
     else
    
        extern (C) int strlen (char *);
	version(Posix){
	    private import tango.stdc.posix.unistd;
	}

/*******************************************************************************

        Models an OS-specific file-system. Included here are methods to 
        list the system roots ("C:", "D:", etc) and to manipulate the
        current working directory.

*******************************************************************************/

class FileSystem
{
        version (Win32)
        {
                /***********************************************************************
                        
                        List the set of root devices (C:, D: etc)

                ***********************************************************************/

                static char[][] listRoots ()
                {
                        int             len;
                        char[]          str;
                        char[][]        roots;

                        // acquire drive strings
                        len = GetLogicalDriveStringsA (0, null);
                        if (len)
                           {
                           str = new char [len];
                           GetLogicalDriveStringsA (len, str);

                           // split roots into seperate strings
                           roots = Text.split (str [0..str.length-1], "\0");
                           }
                        return roots;
                }

                /***********************************************************************

                        Set the current working directory

                ***********************************************************************/

                static void setDirectory (FilePath fp)
                {
                        version (Win32SansUnicode)
                                {
                                if (! SetCurrentDirectoryA (fp.toUtf8))
                                       throw new IOException ("Failed to set current directory");
                                }
                             else
                                {
                                if (! SetCurrentDirectoryW (fp.toUtf16(true)))
                                      throw new IOException ("Failed to set current directory");
                                }
                }

                /***********************************************************************

                        Get the current working directory
                
                ***********************************************************************/

                static FilePath getDirectory ()
                {
                        version (Win32SansUnicode)
                                {
                                int length = GetCurrentDirectoryA (0, null);
                                if (length)
                                   {
                                   char[] dir = new char [length];
                                   GetCurrentDirectoryA (length, dir);
                                   return new FilePath (dir, false);
                                   }
                                }
                             else
                                {
                                int length = GetCurrentDirectoryW (0, null);
                                if (length)
                                   {
                                   wchar[] dir = new wchar [length];
                                   GetCurrentDirectoryW (length, dir);
                                   return new FilePath (Unicode.toUtf8 (dir), false);
                                   }
                                }
                        throw new IOException ("Failed to get current directory");
                }
        }
        
        
        version (Posix)
        {
                /***********************************************************************

                        List the set of root devices.

                        @todo not currently implemented.

                ***********************************************************************/

                static char[][] listRoots ()
                {
                        assert(0);
                        return null;
                }

                /***********************************************************************

                        Set the current working directory

                ***********************************************************************/

                static void setDirectory (FilePath fp)
                {
                        if (tango.stdc.posix.unistd.chdir (fp.toUtf8))
                            throw new IOException ("Failed to set current directory");
                }

                /***********************************************************************

                        Get the current working directory
                
                ***********************************************************************/

                static FilePath getDirectory ()
                {
                        char *s = tango.stdc.posix.unistd.getcwd (null, 0);
                        if (s) 
                            return new FilePath (s[0..strlen(s)]);

                        throw new IOException ("Failed to get current directory");
                }
        }   
}

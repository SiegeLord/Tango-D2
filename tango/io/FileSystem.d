/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris, John Reimer, Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.sys.Common;

private import  tango.text.Text;

private import  tango.io.FilePath,
                tango.io.FileConst,
                tango.io.Exception;

private import  tango.text.convert.Utf;

version (Win32)
        private extern (Windows) DWORD GetLogicalDriveStringsA (DWORD, LPTSTR);
     else
        private import tango.stdc.string;
        
version(Posix){
    private import tango.io.File;
    private import tango.stdc.posix.unistd;
    private import tango.text.convert.Atoi;
}

/*******************************************************************************

        Models an OS-specific file-system. Included here are methods to 
        list the system roots ("C:", "D:", etc) and to manipulate the
        current working directory.

*******************************************************************************/

class FileSystem
{
        private alias tango.text.convert.Utf Utf;
        
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

                static void setDirectory (FilePathView fp)
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
                                   return new FilePath (Utf.toUtf8 (dir), false);
                                   }
                                }
                        throw new IOException ("Failed to get current directory");
                }
        }
        
        
        version (Posix)
        {
                /***********************************************************************

                        List the set of root devices.

                 ***********************************************************************/

                static char[][] listRoots ()
                {
                        version(darwin)
                        {
                            assert(0);
                            return null;
                        }
                        else
                        {
                            char[] path = "", content = cast(char[]) (new File("/etc/mtab")).read();
                            char[][] list;
                            int spaces;
   
                            for(int i = 0; i < content.length; i++)
                            {
                                if(content[i] == ' ') spaces++;
                                else if(content[i] == '\n')
                                {
                                    spaces = 0;
                                    list ~= path;
                                    path = "";
                                }
                                else if(spaces == 1)
                                {
                                    if(content[i] == '\\')
                                    {
                                        path ~= Atoi.parse(content[++i..i+3], 8);
                                        i += 2;
                                    }
                                    else path ~= content[i];
                                }
                            }
                            
                            return list;
                        }
                }

                /***********************************************************************

                        Set the current working directory

                ***********************************************************************/

                static void setDirectory (FilePathView fp)
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

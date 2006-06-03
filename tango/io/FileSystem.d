/*******************************************************************************

        @file FileSystem.d
        
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


        @version        Initial version; March 2004      

        @author         Kris
                        John Reimer
                        Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.os.OS;

private import  tango.text.Text;

private import  tango.io.FilePath,
                tango.io.FileConst,
                tango.io.Exception;

private import  tango.convert.Unicode;

version (Win32)
        extern (Windows) DWORD GetLogicalDriveStringsA (DWORD, LPTSTR);
     else
        extern (C) int strlen (char *);

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
                                if (! SetCurrentDirectoryW (fp.toUtf16))
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
                                   return new FilePath (dir);
                                   }
                                }
                             else
                                {
                                int length = GetCurrentDirectoryW (0, null);
                                if (length)
                                   {
                                   wchar[] dir = new wchar [length];
                                   GetCurrentDirectoryW (length, dir);
                                   return new FilePath (Unicode.toUtf8 (dir));
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
                        if (tango.stdc.posix.posix.chdir (fp.toUtf8))
                            throw new IOException ("Failed to set current directory");
                }

                /***********************************************************************

                        Get the current working directory
                
                ***********************************************************************/

                static FilePath getDirectory ()
                {
                        char *s = tango.stdc.posix.posix.getcwd (null, 0);
                        if (s) 
                            // dup the string so we can hang onto it                            
                            return new FilePath (s[0..strlen(s)].dup);

                        throw new IOException ("Failed to get current directory");
                }
        }   

        /***********************************************************************
       
                These have been moved

        ***********************************************************************/

        alias FileConst.PathSeparatorChar PathSeparatorChar; 
        alias FileConst.FileSeparatorChar FileSeparatorChar; 
        alias FileConst.RootSeparatorChar RootSeparatorChar; 
        alias FileConst.PathSeparatorString PathSeparatorString; 
        alias FileConst.FileSeparatorString FileSeparatorString; 
        alias FileConst.RootSeparatorString RootSeparatorString; 
        alias FileConst.NewlineString NewlineString; 
             
        /***********************************************************************
       
                My bogus mispelling of the word Separator ...

        ***********************************************************************/

        alias PathSeparatorChar         PathSeperatorChar;
        alias FileSeparatorChar         FileSeperatorChar;
        alias RootSeparatorChar         RootSeperatorChar;
        alias PathSeparatorString       PathSeperatorString;
        alias FileSeparatorString       FileSeperatorString; 
        alias RootSeparatorString       RootSeperatorString;               
}

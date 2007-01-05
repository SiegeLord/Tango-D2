/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris, FreeEagle

*******************************************************************************/

module tango.io.FileRoots;

private import tango.sys.Common;


version (Win32)
        {
        private import Text = tango.text.Goodies;

        private extern (Windows) DWORD GetLogicalDriveStringsA (DWORD, LPTSTR);
        }
     else
        {
        private import tango.stdc.string;
        private import tango.io.FileConduit;
        private import tango.stdc.posix.unistd;
        private import Integer = tango.text.convert.Integer;
        }
        
/*******************************************************************************

        Models an OS-specific file-system. Included here are methods to 
        list the system roots ("C:", "D:", etc)

*******************************************************************************/

class FileRoots
{
        version (Win32)
        {
                /***************************************************************
                        
                        List the set of root devices (C:, D: etc)

                ***************************************************************/

                static char[][] list ()
                {
                        int             len;
                        char[]          str;
                        char[][]        roots;

                        // acquire drive strings
                        len = GetLogicalDriveStringsA (0, null);
                        if (len)
                           {
                           str = new char [len];
                           GetLogicalDriveStringsA (len, str.ptr);

                           // split roots into seperate strings
                           roots = Text.split (str [0..str.length-1], '\0');
                           }
                        return roots;
                }
        }
        
        
        version (Posix)
        {
                /***************************************************************

                        List the set of root devices.

                 ***************************************************************/

                static char[][] list ()
                {
                        version(darwin)
                        {
                            assert(0);
                            return null;
                        }
                        else
                        {
                            char[] path = "";
                            char[][] list;
                            int spaces;

                            auto fc = new FileConduit("/etc/mtab");
                            scope (exit)
                                   fc.close;
                            
                            auto content = new char[cast(int) fc.length];
                            fc.fill (content);
                            
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
                                        path ~= Integer.parse(content[++i..i+3], 8u);
                                        i += 2;
                                    }
                                    else path ~= content[i];
                                }
                            }
                            
                            return list;
                        }
                }
        }   
}


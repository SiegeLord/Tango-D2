/*******************************************************************************

        @file OS.d
        
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

        
        @version        Initial version; November 2005

        @author         Kris


*******************************************************************************/

module tango.sys.OS;

version (Phobos)
        {
        version (Win32)
                 public import tango.sys.windows.windows;  

        version (linux)
                {
                public import tango.sys.linux.linux;
                alias tango.sys.linux.linux posix;
                }

        version (darwin)
                {
                public import tango.sys.darwin.darwin;
                alias tango.sys.darwin.darwin posix;
                }
        }
     else
        {
        extern (C) int printf (char*, ...);

        version (Win32)
                 public import tango.sys.windows.c.windows;  

        version (linux)
                {
                public import tango.sys.linux.c.linux;
                alias tango.sys.linux.c.linux posix;
                }

        version (darwin)
                {
                public import tango.sys.darwin.c.darwin;
                alias tango.sys.darwin.c.darwin posix;
                }
        }

/*******************************************************************************

        Stuff for sysError(), kindly provided by Regan Heath. 

*******************************************************************************/

version (Win32)
        {
        private const FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
        private const FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200;
        private const FORMAT_MESSAGE_FROM_STRING     = 0x00000400;
        private const FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800;
        private const FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000;
        private const FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000;
        private const FORMAT_MESSAGE_MAX_WIDTH_MASK  = 0x000000FF;

        private DWORD MAKELANGID(WORD p, WORD s)  { return (((cast(WORD)s) << 10) | cast(WORD)p); }

        private alias HGLOBAL HLOCAL;

        private const LANG_NEUTRAL = 0x00;
        private const SUBLANG_DEFAULT = 0x01;

        extern (Windows) 
               {
               DWORD FormatMessageA (DWORD dwFlags,
                                     LPCVOID lpSource,
                                     DWORD dwMessageId,
                                     DWORD dwLanguageId,
                                     LPTSTR lpBuffer,
                                     DWORD nSize,
                                     LPCVOID args
                                     );

               HLOCAL LocalFree(HLOCAL hMem);
               }
        }
else
version (Posix)
        {
        extern (C) char *strerror (int);
        extern (C) int strlen (char *);
        extern (C) int getErrno ();
        extern (C) void usleep(uint);
        }
else
   static assert(0);

/*******************************************************************************

        Some system-specific functionality that doesn't belong anywhere 
        else. This needs some further thought and refinement.

*******************************************************************************/

struct OS
{       
        /***********************************************************************
        
        ***********************************************************************/

        final static char[] error ()
        {
                version (Win32)
                         return error (GetLastError);
                     else
                        return error (getErrno);
        }

        /***********************************************************************
        
        ***********************************************************************/

        final static char[] error (uint errcode)
        {
                char[] text;

                version (Win32)
                        {
                        DWORD  r;
                        LPVOID lpMsgBuf;                        

                        r = FormatMessageA ( 
                                FORMAT_MESSAGE_ALLOCATE_BUFFER | 
                                FORMAT_MESSAGE_FROM_SYSTEM | 
                                FORMAT_MESSAGE_IGNORE_INSERTS,
                                null,
                                errcode,
                                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                                cast(LPTSTR)&lpMsgBuf,
                                0,
                                null);

                        /* Remove \r\n from error string */
                        if (r >= 2) r-= 2;
                        text = (cast(char *)lpMsgBuf)[0..r].dup;
                        LocalFree(cast(HLOCAL)lpMsgBuf);
                        }
                     else
                        {
                        uint  r;
                        char* pemsg;

                        pemsg = strerror(errcode);
                        r = strlen(pemsg);

                        /* Remove \r\n from error string */
                        if (pemsg[r-1] == '\n') r--;
                        if (pemsg[r-1] == '\r') r--;
                        text = pemsg[0..r].dup;
                        }
                
                return text;
        }
}



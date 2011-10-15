/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: November 2005

        author:         Kris

*******************************************************************************/

module tango.sys.Common;

public import core.stdc.errno;
public import core.stdc.string;

version (Win32) {
	public import core.sys.windows.windows;
}

version(Posix) {
	public import core.sys.posix.unistd;
	public import core.sys.posix.fcntl;
	public import core.sys.posix.sys.stat;
	public import core.sys.posix.sys.time;
	public import core.sys.posix.poll;
	public import core.sys.posix.time;
}
   
/*******************************************************************************

*******************************************************************************/

struct SysError
{   
        /***********************************************************************

        ***********************************************************************/

        static uint lastCode ()
        {
                version (Win32) {
                    return GetLastError;
                } else {
                    return errno;
                }
        }

        /***********************************************************************

        ***********************************************************************/

        static char[] lastMsg ()
        {
                return lookup (lastCode);
        }

        /***********************************************************************

        ***********************************************************************/

        static char[] lookup (uint errcode)
        {
                char[] text;

                version (Win32)
                        {
                        DWORD  i;
                        LPWSTR lpMsgBuf;

                        i = FormatMessageW (
                                FORMAT_MESSAGE_ALLOCATE_BUFFER |
                                FORMAT_MESSAGE_FROM_SYSTEM |
                                FORMAT_MESSAGE_IGNORE_INSERTS,
                                null,
                                errcode,
                                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                                cast(LPWSTR)&lpMsgBuf,
                                0,
                                null);

                        /* Remove \r\n from error string */
                        if (i >= 2) i -= 2;
                        text = new char[i * 3];
                        i = WideCharToMultiByte (CP_UTF8, 0, lpMsgBuf, i, 
                                                 cast(PCHAR)text.ptr, text.length, null, null);
                        text = text [0 .. i];
                        LocalFree (cast(HLOCAL) lpMsgBuf);
                        }
                     else
                        {
                        size_t  r;
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

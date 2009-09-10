/*******************************************************************************

        copyright:      Copyright (c) 2004 Tango group. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: July 2006


        Various low-level console oriented utilities

*******************************************************************************/

module rt.util.console;

private import rt.util.string;

version (Win32) {
    private extern (Windows) int GetStdHandle (int);
    private extern (Windows) int WriteFile (int, char*, int, int*, void*);
} else {
    import tango.stdc.stdio;
}

struct Console
{
    Console opCall (char[] s)
    {
        version (Win32) {
            int count;
            WriteFile (GetStdHandle(0xfffffff5), s.ptr, s.length, &count, null);
        } else {
            fprintf(stderr, "%.*s",s.length,s.ptr);
            fflush(stderr);
        }
        return *this;
    }

    // emit an integer to the console
    Console opCall (size_t i)
    {
        char[25] tmp = void;

        return console (ulongToUtf8 (tmp,cast(ulong) i));
    }
}

Console console;

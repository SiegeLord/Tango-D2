/*******************************************************************************

        copyright:      Copyright (c) 2004 Tango group. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: July 2006


        Various low-level console oriented utilities

*******************************************************************************/

module rt.compiler.util.console;

private import rt.compiler.util.string;

version (Win32) 
        {
        private extern (Windows) int GetStdHandle (int);
        private extern (Windows) int WriteFile (int, char*, int, int*, void*);
        } 
else 
version (Posix)
         extern(C) ptrdiff_t write(int, in void*, size_t);


struct Console
{
    alias emit opCall;

    Console emit (char[] s)
    {
            version (Win32)
                    {
                    int count;
                    WriteFile (GetStdHandle(0xfffffff5), s.ptr, s.length, &count, null);
                    }
            else
            version (Posix)
                    {
                    write (2, s.ptr, s.length);
                    }
            return *this;
    }

    // emit an integer to the console
    Console emit (ulong i)
    {
            char[25] tmp = void;

            return emit (ulongToUtf8 (tmp, cast(ulong) i));
    }
}

Console console;


extern(C) void consoleString (char[] str)
{
        console.emit (str);
}

extern(C) void consoleInteger (ulong i)
{
        console.emit (i);
}
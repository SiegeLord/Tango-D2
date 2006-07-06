/*******************************************************************************

        copyright:      Copyright (c) 2004 Tango group. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: July 2006
        

        Various console oriented utilities

*******************************************************************************/

module util.console;

version (Win32)
        {
        private extern (Windows) uint GetStdHandle (uint);
        private extern (Windows) void WriteFile (uint, char*, uint, uint*, void*);
        }

version (linux)
        {
        private extern (C) int write(int, void*, int);
        }

void console (char[] s)
{
        version (Win32)
                {
                uint count;
                WriteFile (GetStdHandle(0xfffffff5), s.ptr, s.length, &count, null);
                }

        version (linux)
                {
                write (2, s.ptr, s.length);
                }
}

void console (uint i)
{
        char[8] tmp = void;
        
        char* p = tmp.ptr+tmp.length;
        do {
           *--p = '0' + (i % 10);
           } while (i /= 10); 

        console (tmp [p-tmp.ptr .. $]);
}
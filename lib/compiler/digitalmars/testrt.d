
// Copyright (c) 1999-2003 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com

// This test program pulls in all the library modules in order
// to run the unit tests on them.
// Then, it prints out the arguments passed to main().

import std.c.complex;
import std.c.ctype;
import std.c.errno;
import std.c.fenv;
import std.c.math;
import std.c.signal;
import std.c.stdarg;
import std.c.stdbool;
import std.c.stddef;
import std.c.stdint;
import std.c.stdio;
import std.c.stdlib;
import std.c.string;
import std.c.time;
import std.c.wctype;


extern (C) void _d_array_bounds( char[] file, uint line )
{
    printf( "Array bounds error: %.*s(%u)\n", file, line );
    exit( 0 );
}

extern (C) void _d_assert( char[] file, uint line )
{
    printf( "Assert error: %.*s(%u)\n", file, line );
    exit( 0 );
}

extern (C) void _d_switch_error( char[] file, uint line )
{
    printf( "Switch error: %.*s(%u)\n", file, line );
    exit( 0 );
}

extern (C) void _d_OutOfMemory()
{
    printf( "Out of memory error\n" );
    exit( 0 );
}


int main(char[][] args)
{
    printf("Success\n!");
    return 0;
}

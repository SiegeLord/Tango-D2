
// Copyright (c) 1999-2003 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com

// This test program pulls in all the library modules in order
// to run the unit tests on them.
// Then, it prints out the arguments passed to main().

import tango.stdc.complex;
import tango.stdc.ctype;
import tango.stdc.errno;
import tango.stdc.fenv;
import tango.stdc.math;
import tango.stdc.signal;
import tango.stdc.stdarg;
import tango.stdc.stdbool;
import tango.stdc.stddef;
import tango.stdc.stdint;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.stdc.string;
import tango.stdc.time;
import tango.stdc.wctype;


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

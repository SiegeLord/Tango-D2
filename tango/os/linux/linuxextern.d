
// Copyright (C) 2003 by Digital Mars, www.digitalmars.com
// All Rights Reserved
// Written by Walter Bright

/* These are all the globals defined by the linux C runtime library.
 * Put them separate so they'll be externed - do not link in linuxextern.o
 */

module tango.os.linux.linuxextern;

extern (C)
{
    extern void* __libc_stack_end;
    extern int   __data_start;
    extern int   _end;
    extern int   timezone;

    extern void* _deh_beg;
    extern void* _deh_end;
}


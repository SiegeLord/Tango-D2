/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.utime;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for time_t

extern (C):

//
// Required
//
/*
struct utimbuf
{
    time_t  actime;
    time_t  modtime;
}

int utime(in char*, in utimbuf*);
*/

version( linux )
{
    struct utimbuf
    {
        time_t  actime;
        time_t  modtime;
    }

    int utime(in char*, in utimbuf*);
}
else version( darwin )
{
    struct utimbuf
    {
        time_t  actime;
        time_t  modtime;
    }

    int utime(in char*, in utimbuf*);
}
else version( FreeBSD )
{
    struct utimbuf
    {
        time_t  actime;
        time_t  modtime;
    }

    int utime(in char*, in utimbuf*);
}
else version( solaris )
{
	struct utimbuf
	{
		time_t actime;		/* access time */
		time_t modtime;		/* modification time */
	}
	
	int utime(in char*, in utimbuf*);
}

/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.config;

public import tango.stdc.config;

extern (C):

version( linux )
{
    version = OPTIONAL_LARGEFILE_SUPPORT;
}
else version( solaris )
{
    version = OPTIONAL_LARGEFILE_SUPPORT;
}

version( OPTIONAL_LARGEFILE_SUPPORT )
{
    version(SMALLFILE)
      enum :bool {__USE_LARGEFILE64 = false}
    else
      enum :bool {__USE_LARGEFILE64 = ((void*).sizeof==4)}
} else {
    enum :bool {__USE_LARGEFILE64 = false}
}

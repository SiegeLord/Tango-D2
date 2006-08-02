/**
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module lib.compiler.config;


version( DigitalMars )
{
    version( Windows )
    {
        const char[] lib = "dmd.lib";
    }
    else version( Posix )
    {
        const char[] lib = "libdmd.a";
    }
    else
    {
        static assert( false );
    }
}
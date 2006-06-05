/**
 * Authors:   Sean Kelly
 * Copyright: Copyright (C) 2006 Sean Kelly
 * License:   See about.d
 */
module lib.common.config;


version( DigitalMars )
{
    version( Windows )
    {
        const char[] lib = "common.lib";
    }
    else version( Posix )
    {
        const char[] lib = "common.a";
    }
    else
    {
        static assert( false );
    }
}
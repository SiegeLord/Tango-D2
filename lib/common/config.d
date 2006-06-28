/**
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
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
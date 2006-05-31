/**
 * Authors:   Sean Kelly
 * Copyright: Copyright (C) 2006 Sean Kelly
 * License:   See about.d
 */
module lib.compiler.config;


version( DigitalMars )
{
    version( Windows )
    {
        pragma( lib, "dmdrt.lib" );
    }
    else version( Posix )
    {
        pragma( lib, "libdmdrt.a" );
    }
    else
    {
        static assert( false );
    }
}
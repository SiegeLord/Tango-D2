/**
 * Authors:   Sean Kelly
 * Copyright: Copyright (C) 2006 Sean Kelly
 * License:   See about.d
 */
module lib.gc.config;


version( Windows )
{
    const char[] lib = "dmdgc.lib";
}
else version( Posix )
{
    const char[] lib = "libdmdgc.a";
}
else
{
    static assert( false );
}
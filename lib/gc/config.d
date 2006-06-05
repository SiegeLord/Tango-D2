/**
 * Authors:   Sean Kelly
 * Copyright: Copyright (C) 2006 Sean Kelly
 * License:   See about.d
 */
module lib.gc.config;


version( Windows )
{
    const char[] lib = "digitalmars.lib";
}
else version( Posix )
{
    const char[] lib = "digitalmars.a";
}
else
{
    static assert( false );
}
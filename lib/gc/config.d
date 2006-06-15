/**
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
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
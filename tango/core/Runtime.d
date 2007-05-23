/**
 * The runtime module exposes information specific to the D run-time code.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Runtime;


private
{
    extern (C) bool cr_isHalting();
}


struct Runtime
{
    bool isHalting()
    {
        return cr_isHalting();
    }
}


Runtime runtime;

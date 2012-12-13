/**
 * The runtime module exposes information specific to the D runtime code.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Author:    Sean Kelly
 */
module tango.core.Runtime;

import druntime = core.runtime;

private
{
    extern(C) void consoleInteger (ulong i);
    extern(C) void consoleString  (in char[] str);
}

struct Runtime
{
    struct Console
    {
        alias stderr opCall;

        Console stderr (in char[] s)
        {
            consoleString (s);
            return this;
        }

        Console stderr (ulong i)
        {
            consoleInteger (i);
            return this;
        }
    }
        

    @property static Console console()
    {
        Console c;
        return c;
    }

    // Export the druntime Runtime functions
    druntime.Runtime _r;
    alias _r this;
}

// // Export the druntime functions
alias druntime.runModuleUnitTests runModuleUnitTests;
alias druntime.defaultTraceHandler defaultTraceHandler;

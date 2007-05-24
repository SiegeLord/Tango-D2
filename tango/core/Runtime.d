/**
 * The runtime module exposes information specific to the D runtime code.
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


/**
 * This struct encapsulates all functionality related to the underlying runtime
 * module for the calling context.
 */
struct Runtime
{
    /**
     * Returns true if the runtime is halting.  Under normal circumstances,
     * this will be set between the time that normal application code has
     * exited and before module dtors are called.
     *
     * Returns:
     *  true if the runtime is halting.
     */
    static bool isHalting()
    {
        return cr_isHalting();
    }
}

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
    bool isHalting()
    {
        return cr_isHalting();
    }
}


/**
 * All Runtime routines are accessed through this variable.  This is done to
 * follow the established D coding style guidelines and to reduce the impact of
 * future design changes.  For all intents and purpsoes, this is a singleton.
 */
Runtime runtime;

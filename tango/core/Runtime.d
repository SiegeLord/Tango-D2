/**
 * The runtime module exposes information specific to the D runtime code.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Author:    Sean Kelly
 */
module tango.core.Runtime;

debug(TangoRuntime) private extern(C) int printf(char*,...);

private
{
    //extern (C) bool rt_isHalting();

    alias bool function() ModuleUnitTester;
    alias bool function(Object) CollectHandler;
    alias Exception.TraceInfo function( void* ptr = null ) TraceHandler;

    extern (C) void rt_setCollectHandler( CollectHandler h );
    extern (C) void rt_setTraceHandler( TraceHandler h );

    alias void delegate( Exception ) ExceptionHandler;
    extern (C) bool rt_init( ExceptionHandler dg = null );
    extern (C) bool rt_term( ExceptionHandler dg = null );

    extern(C) void consoleInteger (ulong i);
    extern(C) void consoleString  (in char[] str);
}


////////////////////////////////////////////////////////////////////////////////
// Runtime
////////////////////////////////////////////////////////////////////////////////


/**
 * This struct encapsulates all functionality related to the underlying runtime
 * module for the calling context.
 */
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

    /**
     * Initializes the runtime.  This call is to be used in instances where the
     * standard program initialization process is not executed.  This is most
     * often in shared libraries or in libraries linked to a C program.
     *
     * Params:
     *  dg = A delegate which will receive any exception thrown during the
     *       initialization process or null if such exceptions should be
     *       discarded.
     *
     * Returns:
     *  true if initialization succeeds and false if initialization fails.
     */
    static bool initialize( void delegate( Exception ) dg = null )
    {
        return rt_init( dg );
    }


    /**
     * Terminates the runtime.  This call is to be used in instances where the
     * standard program termination process will not be not executed.  This is
     * most often in shared libraries or in libraries linked to a C program.
     *
     * Params:
     *  dg = A delegate which will receive any exception thrown during the
     *       termination process or null if such exceptions should be
     *       discarded.
     *
     * Returns:
     *  true if termination succeeds and false if termination fails.
     */
    static bool terminate( void delegate( Exception ) dg = null )
    {
        return rt_term( dg );
    }


    /**
     * Returns true if the runtime is halting.  Under normal circumstances,
     * this will be set between the time that normal application code has
     * exited and before module dtors are called.
     *
     * Returns:
     *  true if the runtime is halting.
     */
    /*@property static bool isHalting()
    {
        return rt_isHalting();
    }*/


    /**
     * Overrides the default trace mechanism with s user-supplied version.  A
     * trace represents the context from which an exception was thrown, and the
     * trace handler will be called when this occurs.  The pointer supplied to
     * this routine indicates the base address from which tracing should occur.
     * If the supplied pointer is null then the trace routine should determine
     * an appropriate calling context from which to begin the trace.
     *
     * Params:
     *  h = The new trace handler.  Set to null to use the default handler.
     */
    @property static void traceHandler( TraceHandler h )
    {
        rt_setTraceHandler( h );
    }


    /**
     * Overrides the default collect hander with a user-supplied version.  This
     * routine will be called for each resource object that is finalized in a
     * non-deterministic manner--typically during a garbage collection cycle.
     * If the supplied routine returns true then the object's dtor will called
     * as normal, but if the routine returns false than the dtor will not be
     * called.  The default behavior is for all object dtors to be called.
     *
     * Params:
     *  h = The new collect handler.  Set to null to use the default handler.
     */
    @property static void collectHandler( CollectHandler h )
    {
        rt_setCollectHandler( h );
    }


    /**
     * Overrides the default module unit tester with a user-supplied version.
     * This routine will be called once on program initialization.  The return
     * value of this routine indicates to the runtime whether the body of the
     * program will be executed.
     *
     * Params:
     *  h = The new unit tester.  Set to null to use the default unit tester.
     */
    @property static void moduleUnitTester( ModuleUnitTester h )
    {
        sm_moduleUnitTester = h;
    }


private:
    static ModuleUnitTester sm_moduleUnitTester = null;
}


////////////////////////////////////////////////////////////////////////////////
// Overridable Callbacks
////////////////////////////////////////////////////////////////////////////////

/**
 * This routine is called by the runtime to run module unit tests on startup.
 * The user-supplied unit tester will be called if one has been supplied,
 * otherwise all unit tests will be run in sequence.
 *
 * Returns:
 *  true if execution should continue after testing is complete and false if
 *  not.  Default behavior is to return true.
 */
extern (C) bool runModuleUnitTests()
{
    if( Runtime.sm_moduleUnitTester is null )
    {
        debug(TangoRuntime) printf("unittest start\n");
        foreach( m; ModuleInfo )
        {
            if( m.unitTest ) {
                const(char)[] name=m.name~"\n\0";
                debug(TangoRuntime) printf(name.ptr);
                m.unitTest();
            }
        }
        debug(TangoRuntime) printf("unittest end\n");
        return true;
    }
    return Runtime.sm_moduleUnitTester();
}

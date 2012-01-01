/**
 *   Stacktracing
 *
 *   Inclusion of this module activates traced exceptions using the tango own tracers if possible
 *
 *  Copyright: 2009 Fawzi
 *  License:   tango license, apache 2.0
 *  Authors:   Fawzi Mohamed
 */
module tango.core.tools.TraceExceptions;


version(D_Version2)
	mixin("private alias const(char[]) cstring;");
else
	private alias char[] cstring;

import tango.core.tools.StackTrace;

extern (C) void  rt_setTraceHandler( TraceHandler h );

static this(){
    rt_setTraceHandler(&basicTracer);
}

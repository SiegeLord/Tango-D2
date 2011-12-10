/**
 *   Stacktracing
 *
 *   Inclusion of this module activates traced exceptions using the tango own tracers if possible.
 *
 *  Copyright: Copyright (C) 2009 Fawzi
 *  License:   Tango License, Apache 2.0
 *  Author:    Fawzi Mohamed
 */
module tango.core.tools.TraceExceptions;
import tango.core.tools.StackTrace;

static this(){
    rt_setTraceHandler(&basicTracer);
    version(noSegfaultTrace){
    } else {
		version(Posix) setupSegfaultTracer();
    }
}

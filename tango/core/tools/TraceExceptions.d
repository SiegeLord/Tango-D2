/**
 *   Stacktracing
 *
 *   Inclusion of this module activates traced exceptions using the tango own tracers if possible
 *
 *  Copyright: 2009 Fawzi
 *  License:   tango license, apache 2.0
 *  Authors:   Fawzi Mohamed
 */
module tango.core.stacktrace.TraceExceptions;
import tango.core.stacktrace.StackTrace;

static this(){
    rt_setTraceHandler(&basicTracer);
}

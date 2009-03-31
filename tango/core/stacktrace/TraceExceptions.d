// inclusion of this module activates traced exceptions if possible
module tango.core.stacktrace.TraceExceptions;
import tango.core.stacktrace.StackTrace;

static this(){
    rt_setTraceHandler(&basicTracer);
}

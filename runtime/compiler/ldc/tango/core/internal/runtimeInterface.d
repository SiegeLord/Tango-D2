/+
 + The C interface exported by the runtime, this is the only interface that should be used
 + from outside the runtime (should me moved to common/*)
 +
 + Fawzi Mohamed
 +/
module tango.core.internal.runtimeInterface;

extern (C) bool rt_isHalting();

alias bool function() ModuleUnitTester;
alias bool function(Object) CollectHandler;
alias Exception.TraceInfo function( void* ptr = null ) TraceHandler;

extern (C) void rt_setCollectHandler( CollectHandler h );
extern (C) void rt_setTraceHandler( TraceHandler h );

alias void delegate( Exception ) ExceptionHandler;
extern (C) bool rt_init( ExceptionHandler dg = null );
extern (C) bool rt_term( ExceptionHandler dg = null );

alias void delegate(Object) DEvent;
extern (C) void rt_attachDisposeEvent(Object h, DEvent e);
extern (C) bool rt_detachDisposeEvent(Object h, DEvent e);

import tango.core.stacktrace.TraceExceptions;

void foo()
{
        assert(false);
}

void main()
{
        foo;
}

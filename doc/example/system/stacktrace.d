import tango.core.tools.TraceExceptions;

void foo()
{
        assert(false);
}

void main()
{
        /* Doesn't work? */
        foo();
}

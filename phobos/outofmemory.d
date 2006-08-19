
module phobos.outofmemory;

class OutOfMemoryException : Exception
{
    static char[] s = "Out of memory";

    this()
    {
	super(s);
    }

    char[] toUtf8()
    {
	return s;
    }
}

extern (C) void _d_OutOfMemory()
{
    throw cast(OutOfMemoryException)
	  cast(void *)
	  OutOfMemoryException.classinfo.init;
}


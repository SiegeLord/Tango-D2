
module phobos.asserterror;

import tango.core.Exception;

alias AssertException AssertError;
/+
import phobos.c.stdio;
import phobos.c.stdlib;

class AssertError : Exception
{
    uint linnum;
    char[] filename;

    this(char[] filename, uint linnum)
    {
	this(filename, linnum, null);
    }

    this(char[] filename, uint linnum, char[] msg)
    {
	this.linnum = linnum;
	this.filename = filename;

	char* buffer;
	size_t len;
	int count;

	/* This code is careful to not use gc allocated memory,
	 * as that may be the source of the problem.
	 * Instead, stick with C functions.
	 */

	len = 23 + filename.length + uint.sizeof * 3 + msg.length + 1;
	buffer = cast(char*)phobos.c.stdlib.malloc(len);
	if (buffer == null)
	    super("AssertError internal failure");
	else
	{
	    version (Win32) alias _snprintf snprintf;
	    count = snprintf(buffer, len, "AssertError Failure %.*s(%u) %.*s",
		filename, linnum, msg);
	    if (count >= len || count == -1)
		super("AssertError internal failure");
	    else
		super(buffer[0 .. count]);
	}
    }

    ~this()
    {
	if (msg.ptr)
	{   phobos.c.stdlib.free(msg.ptr);
	    msg = null;
	}
    }
}

+/



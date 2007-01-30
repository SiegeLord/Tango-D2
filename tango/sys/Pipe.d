/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.sys.Pipe;

private import tango.sys.Common;

private import tango.io.Buffer;
private import tango.io.Conduit;
private import tango.io.DeviceConduit;

private import tango.core.Exception;

version (Windows)
{
    private import tango.sys.Common;
}
else
{
    private import tango.stdc.posix.unistd;
}


/**
 * Conduit for pipes.
 *
 * Each PipeConduit can only read or write, depending on the way it has been
 * created.
 */
class PipeConduit: DeviceConduit
{
    alias DeviceConduit.fileHandle  fileHandle;
    alias DeviceConduit.copy        copy;
    alias DeviceConduit.read        read;
    alias DeviceConduit.write       write;
    alias DeviceConduit.close       close;
    alias DeviceConduit.error       error;

    static const uint DefaultBufferSize = 8 * 1024;

    private uint _bufferSize;


    /**
     * Create a PipeConduit with the provided handle and access permissions.
     *
     * Params:
     * handle       = handle of the operating system pipe we will wrap inside
     *                the PipeConduit.
     * style        = access flags for the pipe (readable, writable, etc.).
     * bufferSize   = buffer size.
     */
    private this(IConduit.Handle handle, Access access,
                 uint bufferSize = DefaultBufferSize)
    {
        super(access, false);

        this.handle = handle;
        _bufferSize = bufferSize;
    }

    /**
     *
     */
    public ~this()
    {
        close();
    }

    /**
     * Returns the buffer size for the PipeConduit.
     */
    public override uint bufferSize()
    {
        return _bufferSize;
    }

    /**
     * Returns the name of the device.
     */
    public override char[] getName()
    {
        return "<pipe>";
    }
}

/**
 * Factory class for Pipes.
 */
class Pipe
{
    private PipeConduit _source;
    private PipeConduit _sink;

    /**
     * Create a Pipe.
     */
    public this(uint bufferSize = PipeConduit.DefaultBufferSize)
    {
        version (Windows)
        {
            this(bufferSize, null);
        }
        else version (Posix)
        {
            int fd[2];

            if (pipe(fd) == 0)
            {
                _source = new PipeConduit(cast(IConduit.Handle) fd[0],
                                          Conduit.Access.Read, bufferSize);
                _sink = new PipeConduit(cast(IConduit.Handle) fd[1],
                                        Conduit.Access.Write, bufferSize);
            }
            else
            {
                error();
            }
        }
        else
        {
            assert(false, "Unknown platform");
        }
    }

    version (Windows)
    {
        /**
         * Helper constructor for pipes on Windows with non-null security
         * attributes.
         */
        package this(uint bufferSize, SECURITY_ATTRIBUTES *sa)
        {
            HANDLE sourceHandle;
            HANDLE sinkHandle;

            if (CreatePipe(&sourceHandle, &sinkHandle, sa, cast(DWORD) bufferSize))
            {
                _source = new PipeConduit(cast(IConduit.Handle) sourceHandle,
                                        Conduit.Access.Read);
                _sink = new PipeConduit(cast(IConduit.Handle) sinkHandle,
                                        Conduit.Access.Write);
            }
            else
            {
                error();
            }
        }
    }

    /**
     * Return the PipeConduit that you can write to.
     */
    public PipeConduit sink()
    {
        return _sink;
    }

    /**
     * Return the PipeConduit that you can read from.
     */
    public PipeConduit source()
    {
        return _source;
    }

    /**
     *
     */
    private final void error ()
    {
        throw new IOException("Pipe error: " ~ SysError.lastMsg);
    }
}


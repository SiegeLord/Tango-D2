/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.sys.Pipe;

private import tango.sys.Common;
private import tango.io.device.Device;

private import tango.core.Exception;

version (Posix)
{
    private import tango.stdc.posix.unistd;
}

debug (PipeConduit)
{
    private import tango.io.Stdout;
}

private enum {DefaultBufferSize = 8 * 1024}


/**
 * Conduit for pipes.
 *
 * Each PipeConduit can only read or write, depending on the way it has been
 * created.
 */

class PipeConduit : Device
{
    version (OLD)
    {
        alias Device.fileHandle  fileHandle;
        alias Device.copy        copy;
        alias Device.read        read;
        alias Device.write       write;
        alias Device.close       close;
        alias Device.error       error;
    }

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
    private this(Handle handle, uint bufferSize = DefaultBufferSize)
    {
        version (Windows)
                 io.handle = handle;
            else
               this.handle = handle;
        _bufferSize = bufferSize;
    }

    /**
     * Destructor.
     */
    public ~this()
    {
        close();
    }

    /**
     * Returns the buffer size for the PipeConduit.
     */
    public override size_t bufferSize()
    {
        return _bufferSize;
    }

    /**
     * Returns the name of the device.
     */
    public override char[] toString()
    {
        return "<pipe>";
    }

    version (OLD)
    {
        /**
         * Read a chunk of bytes from the file into the provided array 
         * (typically that belonging to an IBuffer)
         */
        protected override uint read (void[] dst)
        {
            uint result;
            DWORD read;
            void *p = dst.ptr;

            if (!ReadFile (handle, p, dst.length, &read, null))
            {
                if (SysError.lastCode() == ERROR_BROKEN_PIPE)
                {
                    return Eof;
                }
                else
                {
                    error();
                }
            }

            if (read == 0 && dst.length > 0)
            {
                return Eof;
            }
            return read;
        }

        /**
         * Write a chunk of bytes to the file from the provided array 
         * (typically that belonging to an IBuffer).
         */
        protected override uint write (void[] src)
        {
            DWORD written;

            if (!WriteFile (handle, src.ptr, src.length, &written, null))
            {
                error();
            }
            return written;
        }
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
    public this(uint bufferSize = DefaultBufferSize)
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
                _source = new PipeConduit(cast(ISelectable.Handle) fd[0], bufferSize);
                _sink = new PipeConduit(cast(ISelectable.Handle) fd[1], bufferSize);
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
            HANDLE sinkHandle;
            HANDLE sourceHandle;

            if (CreatePipe(&sourceHandle, &sinkHandle, sa, cast(DWORD) bufferSize))
            {
                _source = new PipeConduit(sourceHandle);
                _sink = new PipeConduit(sinkHandle);
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


/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        May 2005: Initial release

        author:         Kris

*******************************************************************************/

module tango.io.device.Device;

private import  tango.sys.Common;

private import  tango.core.Exception;

public  import  tango.io.device.Conduit;

/*******************************************************************************

        Implements a means of reading and writing a file device. Conduits
        are the primary means of accessing external data, and this one is
        used as a superclass for the console, for files, sockets etc

*******************************************************************************/

class Device : Conduit, ISelectable
{
        /// expose superclass definition also
        public alias Conduit.error error;
            
        /***********************************************************************

                Throw an IOException noting the last error
        
        ***********************************************************************/

        final void error ()
        {
                error (this.toString ~ " :: " ~ SysError.lastMsg);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString ()
        {
                return "<device>";
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        override size_t bufferSize ()
        {
                return 1024 * 16;
        }

        /***********************************************************************

                Windows-specific code

        ***********************************************************************/

        version (Win32)
        {
                protected HANDLE        handle;
                protected OVERLAPPED    overlapped;
                protected long          readOffset,
                                        writeOffset;

                /***************************************************************

                        Allow adjustment of standard IO handles

                ***************************************************************/

                protected void reopen (Handle handle)
                {
                        this.handle = cast(HANDLE) handle;
                        readOffset = writeOffset = 0;
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit

                ***************************************************************/

                final Handle fileHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Release the underlying file. Note that an exception
                        is not thrown on error, as doing so can induce some
                        spaggetti into error handling. Instead, we need to
                        change this to return a bool instead, so the caller
                        can decide what to do.                        

                ***************************************************************/

                override void detach ()
                {
                        if (handle != INVALID_HANDLE_VALUE)
                            CloseHandle (handle);

                        handle = INVALID_HANDLE_VALUE;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array. Returns the number of bytes read, or Eof where 
                        there is no further data.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                override size_t read (void[] dst)
                {
                        DWORD bytes;

                        if (! ReadFile (handle, dst.ptr, dst.length, &bytes, &overlapped))
                              if ((bytes = wait (scheduler.Type.Read, bytes)) is Eof)
                                   return Eof;

                        // synchronous read of zero means Eof
                        if (bytes is 0 && dst.length > 0)
                            return Eof;

                        // update read position ...
                        readOffset += bytes;

                        return bytes;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array. Returns the number of bytes written, or Eof if 
                        the output is no longer available.

                        Operates asynchronously where the hosting thread is
                        configured in that manner.

                ***************************************************************/

                override size_t write (void[] src)
                {
                        DWORD bytes;

                        if (! WriteFile (handle, src.ptr, src.length, &bytes, &overlapped))
                              if ((bytes = wait (scheduler.Type.Write, bytes)) is Eof)
                                   return Eof;

                        // update write position ...
                        writeOffset += bytes;
                        return bytes;
                }

                /***************************************************************

                ***************************************************************/

                protected final size_t wait (scheduler.Type type, uint bytes=0)
                {
                        while (true)
                              {
                              auto code = GetLastError;
                              if (code is ERROR_HANDLE_EOF ||
                                  code is ERROR_BROKEN_PIPE)
                                  return Eof;

                              if (scheduler)
                                 {
                                 if (code is ERROR_SUCCESS || 
                                     code is ERROR_IO_PENDING || 
                                     code is ERROR_IO_INCOMPLETE)
                                    {
                                    if (code is ERROR_IO_INCOMPLETE)
                                        super.error ("timeout"); //Stdout ("+").flush;

                                    scheduler.idle (cast(Handle) handle, type, timeout);
                                    if (GetOverlappedResult (handle, &overlapped, &bytes, false))
                                        return bytes;
                                    }
                                 else
                                    error;
                                 }
                              else
                                 if (code is ERROR_SUCCESS)
                                     return bytes;
                                 else
                                    error;
                              }

                        // should never get here
                        assert(false);
                }
        }


        /***********************************************************************

                 Unix-specific code.

        ***********************************************************************/

        version (Posix)
        {
                protected int handle = -1;

                /***************************************************************

                        Allow adjustment of standard IO handles

                ***************************************************************/

                protected void reopen (Handle handle)
                {
                        this.handle = handle;
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit

                ***************************************************************/

                final Handle fileHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Release the underlying file

                ***************************************************************/

                override void detach ()
                {
                        if (handle >= 0)
                           {
                           if (scheduler)
                               scheduler.close (handle, toString);
                           posix.close (handle);
                           }
                        handle = -1;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array. Returns the number of bytes read, or Eof where 
                        there is no further data.

                ***************************************************************/

                override size_t read (void[] dst)
                {
                        int read = posix.read (handle, dst.ptr, dst.length);
                        if (read is -1)
                            error;
                        else
                           if (read is 0 && dst.length > 0)
                               return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array. Returns the number of bytes written, or Eof if 
                        the output is no longer available.

                ***************************************************************/

                override size_t write (void[] src)
                {
                        int written = posix.write (handle, src.ptr, src.length);
                        if (written is -1)
                            error;
                        return written;
                }
        }
}




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
                super.error (this.toString ~ " :: " ~ SysError.lastMsg);
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
                protected HANDLE handle;

                /***************************************************************

                        Allow adjustment of standard IO handles

                ***************************************************************/

                protected void reopen (Handle handle)
                {
                        this.handle = cast(HANDLE) handle;
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
                        array (typically that belonging to an IBuffer). 

                        Returns the number of bytes read, or Eof when there is
                        no further data

                ***************************************************************/

                override size_t read (void[] dst)
                {
                        DWORD read;
                        void *p = dst.ptr;

                        if (! ReadFile (handle, p, dst.length, &read, null))
                              // make Win32 behave like linux
                              if (SysError.lastCode is ERROR_BROKEN_PIPE)
                                  return Eof;
                              else
                                 error;

                        if (read is 0 && dst.length > 0)
                            return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override size_t write (void[] src)
                {
                        DWORD written;

                        if (! WriteFile (handle, src.ptr, src.length, &written, null))
                              error;

                        return written;
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
                            posix.close (handle);
                        handle = -1;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override size_t read (void[] dst)
                {
                        int read = posix.read (handle, dst.ptr, dst.length);
                        if (read == -1)
                            error;
                        else
                           if (read is 0 && dst.length > 0)
                               return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

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




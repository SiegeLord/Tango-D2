/*******************************************************************************

        @file DeviceConduit.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version; May 2005      

        @author         Kris 

*******************************************************************************/

module tango.io.DeviceConduit;

private import  tango.sys.OS;
                
private import  tango.io.Buffer,
                tango.io.Conduit,
                tango.io.Exception;

/*******************************************************************************

        Implements a means of reading and writing a file device. Conduits
        are the primary means of accessing external data, and are usually 
        routed through a Buffer. 
        
*******************************************************************************/

class DeviceConduit : Conduit
{
        // expose conduit.copy() methods also
        alias Conduit.copy  copy;
        alias Conduit.read  read;
        alias Conduit.write write;

        /***********************************************************************
        
                Construct a conduit with the given style and seek abilities. 
                Conduits are either seekable or non-seekable.

        ***********************************************************************/

        this (ConduitStyle.Bits style, bool seekable)
        {
                super (style, seekable);
        }

        /***********************************************************************

                Create a FileConduit on the provided FileDevice. This is 
                strictly for adapting existing devices such as Stdout and
                friends.
        
        ***********************************************************************/

        this (FileDevice device)
        {
                // say we're not seekable
                super (device.style, false);
                
                // open the file
                reopen (device);
        }    

        /***********************************************************************
                
                Callback to close the file. This is invoked from the Resource
                base-class when the resource is being closed.

        ***********************************************************************/

        override void close ()
        {       
                super.close ();
                _close ();
        }    
                   
        /***********************************************************************
        
                Make a reasonable attempt to clean up

        ***********************************************************************/

        ~this ()
        {
                if (! isHalting)
                      _close ();
        }
                   
        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        uint bufferSize ()
        {
                return 1024 * 16;
        }
                     
        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        protected char[] getName()
        {
                return "<device>";
        }


        /***********************************************************************

                Windows-specific code
        
        ***********************************************************************/

        version (Win32)
        {
                protected HANDLE handle;

                /***************************************************************

                        Throw an IOException noting the last error

                ***************************************************************/

                final void error ()
                {
                        throw new IOException (getName() ~ ": " ~ OS.error);
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit                

                ***************************************************************/

                final Handle getHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Gain access to the standard IO handles (console etc).

                ***************************************************************/

                protected void reopen (FileDevice device)
                {
                        handle = cast(HANDLE) device.id;
                }

                /***************************************************************

                        Close the underlying file

                ***************************************************************/

                protected void _close ()
                {
                        if (handle)
                            if (! CloseHandle (handle))
                                  error ();
                        handle = null;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                protected override uint reader (void[] dst)
                {
                        DWORD read;
                        void *p = dst;

                        if (! ReadFile (handle, p, dst.length, &read, null))
                              error ();

                        if (read == 0 && dst.length > 0)
                            return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                protected override uint writer (void[] src)
                {
                        DWORD written;

                        if (! WriteFile (handle, src, src.length, &written, null))
                              error ();

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

                        Throw an IOException noting the last error

                ***************************************************************/

                final void error ()
                {
                        throw new IOException (getName() ~ ": " ~
                                               OS.error);
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit                

                ***************************************************************/

                final Handle getHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Gain access to the standard IO handles (console etc).

                ***************************************************************/

                protected void reopen (FileDevice device)
                {
                        handle = device.id;
                }

                /***************************************************************

                        Close the underlying file

                ***************************************************************/

                protected void _close ()
                {
                        if (handle)
                            if (posix.close (handle) == -1)
                                error ();
                        handle = 0;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                protected override uint reader (void[] dst)
                {
                        int read = posix.read (handle, dst, dst.length);
                        if (read == -1)
                            error ();
                        else
                           if (read == 0 && dst.length > 0)
                               return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                protected override uint writer (void[] src)
                {
                        int written = posix.write (handle, src, src.length);
                        if (written == -1)
                            error ();
                        return written;
                }
        }
}


/*******************************************************************************

        Class used to wrap an existing file-oriented handle, such as Stdout
        and its cohorts.

*******************************************************************************/

class FileDevice 
{
        private uint                    _id;
        private ConduitStyle.Bits       style;

        this (uint id, ConduitStyle.Bits style)
        {
                this.style = style;
                this._id = id;
        }

        int id()
        {
              return _id;  
        }
}



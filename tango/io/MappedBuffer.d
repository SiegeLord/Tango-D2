/*******************************************************************************

        @file MappedBuffer.d

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

      
        @version        Initial version; March 2004

        @author         Kris


*******************************************************************************/

module tango.io.MappedBuffer;

private import  tango.sys.OS;

private import  tango.io.Buffer,
                tango.io.Exception;

public  import  tango.io.FileConduit;

/*******************************************************************************

        Win32 declarations

*******************************************************************************/

version (Win32)
        {
        private extern (Windows) 
                {
                BOOL   UnmapViewOfFile    (LPCVOID);
                BOOL   FlushViewOfFile    (LPCVOID, DWORD);
                LPVOID MapViewOfFile      (HANDLE, DWORD, DWORD, DWORD, DWORD);
                HANDLE CreateFileMappingA (HANDLE, LPSECURITY_ATTRIBUTES, DWORD, DWORD, DWORD, LPCTSTR);
                }
        }


/*******************************************************************************

        Subclass to treat the buffer as a seekable entity, where all 
        capacity is available for reading and/or writing. To achieve 
        this we must effectively disable the 'limit' watermark, and 
        locate write operations around 'position' instead. 

*******************************************************************************/

class MappedBuffer : Buffer
{
        private FileConduit     host;                   // the hosting file

        version (Win32)
        {
                private void*   base;                   // array pointer
                private HANDLE  mmFile;                 // mapped file

                /***************************************************************

                        Construct a MappedBuffer upon the given FileConduit. 
                        One should set the file size using seek() & truncate() 
                        to setup the available working space.

                ***************************************************************/

                this (FileConduit host)
                {
                        super (0);

                        this.host = host;

                        // can only do 32bit mapping on 32bit platform
                        ulong size = host.length;
                        ConduitStyle.Bits style = host.getStyle;

                        DWORD flags = PAGE_READONLY;
                        if (style.access & ConduitStyle.Access.Write)
                            flags = PAGE_READWRITE;

                        auto handle = cast(HANDLE) host.getHandle();
                        mmFile = CreateFileMappingA (handle, null, flags, 0, 0, null);
                        if (mmFile is null)
                            host.error ();

                        flags = FILE_MAP_READ;
                        if (style.access & ConduitStyle.Access.Write)
                            flags |= FILE_MAP_WRITE;

                        base = MapViewOfFile (mmFile, flags, 0, 0, 0);
                        if (base is null)
                            host.error ();
 
                        void[] mem = base [0 .. cast(int) size];
                        setValidContent (mem);
                }

                /***************************************************************

                        Close this mapped buffer

                ***************************************************************/

                void close ()
                {
                        if (base)
                            UnmapViewOfFile (base);

                        if (mmFile)
                            CloseHandle (mmFile);       

                        mmFile = null;
                        base = null;
                }

                /***************************************************************

                        Flush dirty content out to the drive. This
                        fails with error 33 if the file content is
                        virgin. Opening a file for ReadWriteExists
                        followed by a flush() will cause this.

                ***************************************************************/

                void flush ()
                {
                        // flush all dirty pages
                        if (! FlushViewOfFile (base, 0))
                              host.error ();
                }
        }

        /***********************************************************************
                
        ***********************************************************************/

        version (Posix)
        {               
                // Linux code: not yet tested on other POSIX systems.
                private void*   base;           // array pointer
                private ulong   size;           // length of file

                this (FileConduit host)
                {
                        super(0);

                        this.host = host;
                        size = host.length;
                        
                        // Make sure the mapping attributes are consistant with
                        // the FileConduit attributes.
                        
                        ConduitStyle.Bits style = host.getStyle;
                        
                        int flags = MAP_SHARED;
                        int protection = PROT_READ;
                        
                        if (style.access & ConduitStyle.Access.Write)
                            protection |= PROT_WRITE;
                                
                        base = mmap (null, size, protection, flags, host.getHandle(), 0);
                        if (base is null)
                            host.error();
                                
                        void[] mem = base [0 .. cast(int) size];
                        setValidContent (mem);
                }    

                void close () 
                {
                        // NOTE: When a process ends, all mmaps belonging to that process
                        //       are automatically unmapped by system (Linux).
                        //       On the other hand, this is NOT the case when the related 
                        //       file descriptor is closed.  This function unmaps explicitly.
                        
                        if (base)
                            if (munmap (base, size))
                                host.error();
                        base = null;    
                }

                void flush () 
                {
                        // MS_ASYNC: delayed flush; equivalent to "add-to-queue"
                        // MS_SYNC: function flushes file immediately; no return until flush complete
                        // MS_INVALIDATE: invalidate all mappings of the same file (shared)

                        if (msync (base, size, MS_SYNC | MS_INVALIDATE))
                            host.error();
                }
        }


        /***********************************************************************
                
                Ensure this is closed when GC'd

        ***********************************************************************/
        
        ~this ()
        {
                close ();        
        }

        /***********************************************************************
                
                Set the read/write position

        ***********************************************************************/

        void setPosition (uint position)
        {
                this.position = position;
        }

        /***********************************************************************
        
                Seek to the specified position within the buffer, and return
                the byte offset of the new location (relative to zero).

        ***********************************************************************/

        uint seek (uint offset, ISeekable.SeekAnchor anchor)
        {
                uint pos = capacity;

                if (anchor == ISeekable.SeekAnchor.Begin)
                    pos = offset;
                else
                   if (anchor == ISeekable.SeekAnchor.End)
                       pos -= offset;
                   else
                      pos = position + offset;

                return position = pos;
        }

        /***********************************************************************
        
                Return count of writable bytes available in buffer. This is 
                calculated simply as capacity() - limit()

        ***********************************************************************/

        override uint writable ()
        {
                return capacity - position;
        }               

        /***********************************************************************
        
                Bulk copy of data from 'src'. Position is adjusted by 'size'
                bytes.

        ***********************************************************************/

        override protected void copy (void *src, uint size)
        {
                data[position..position+size] = src[0..size];
                position += size;
        }

        /***********************************************************************

                Exposes the raw data buffer at the current write position, 
                The delegate is provided with a void[] representing space
                available within the buffer at the current write position.

                The delegate should return the appropriate number of bytes 
                if it writes valid content, or IConduit.Eof on error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        override uint write (uint delegate (void[]) dg)
        {
                int count = dg (data [position..capacity]);

                if (count != IConduit.Eof) 
                   {
                   position += count;
                   assert (position <= capacity);
                   }
                return count;
        }               

        /***********************************************************************

                Prohibit compress() from doing anything at all.

        ***********************************************************************/

        override IBuffer compress ()
        {
                return this;
        }               

        /***********************************************************************

                Prohibit clear() from doing anything at all.

        ***********************************************************************/

        override IBuffer clear ()
        {
                return this;
        }               

        /***********************************************************************
        
                Prohibit the setting of another IConduit

        ***********************************************************************/

        override void setConduit (IConduit conduit)
        {
                throw new IOException ("cannot setConduit on memory-mapped buffer");
        }
}

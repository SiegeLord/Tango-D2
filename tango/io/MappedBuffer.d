/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: March 2004
        
        author:         Kris

*******************************************************************************/

module tango.io.MappedBuffer;

private import  tango.sys.Common;

private import  tango.io.Buffer,
                tango.io.Exception;

public  import  tango.io.FileConduit;

/*******************************************************************************

        Win32 declarations

*******************************************************************************/

version (Win32)
         private extern (Windows) 
                        {
                        BOOL   UnmapViewOfFile    (LPCVOID);
                        BOOL   FlushViewOfFile    (LPCVOID, DWORD);
                        LPVOID MapViewOfFile      (HANDLE, DWORD, DWORD, DWORD, DWORD);
                        HANDLE CreateFileMappingA (HANDLE, LPSECURITY_ATTRIBUTES, DWORD, DWORD, DWORD, LPCTSTR);
                        }

version (Posix)
        {               
        private import tango.stdc.posix.sys.mman;
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

                        auto access = host.getAccess();

                        DWORD flags = PAGE_READONLY;
                        if (access & host.Access.Write)
                            flags = PAGE_READWRITE;

                        auto handle = cast(HANDLE) host.fileHandle();
                        mmFile = CreateFileMappingA (handle, null, flags, 0, 0, null);
                        if (mmFile is null)
                            host.error ();

                        flags = FILE_MAP_READ;
                        if (access & host.Access.Write)
                            flags |= FILE_MAP_WRITE;

                        base = MapViewOfFile (mmFile, flags, 0, 0, 0);
                        if (base is null)
                            host.error ();
 
                        void[] mem = base [0 .. cast(int) size];
                        setContent (mem);
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

                IBuffer flush ()
                {
                        // flush all dirty pages
                        if (! FlushViewOfFile (base, 0))
                              host.error ();

                        return this;
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
                        
                        auto access = host.getAccess();
                        
                        int flags = MAP_SHARED;
                        int protection = PROT_READ;
                        
                        if (access & host.Access.Write)
                            protection |= PROT_WRITE;
                                
                        base = mmap (null, size, protection, flags, host.fileHandle(), 0);
                        if (base is null)
                            host.error();
                                
                        void[] mem = base [0 .. cast(int) size];
                        setContent (mem);
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

                IBuffer flush () 
                {
                        // MS_ASYNC: delayed flush; equivalent to "add-to-queue"
                        // MS_SYNC: function flushes file immediately; no return until flush complete
                        // MS_INVALIDATE: invalidate all mappings of the same file (shared)

                        if (msync (base, size, MS_SYNC | MS_INVALIDATE))
                            host.error();

                        return this;
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
        
                Seek to the specified position within the buffer, and return
                the byte offset of the new location (relative to zero).

        ***********************************************************************/

        uint seek (uint offset, IConduit.Seek.Anchor anchor)
        {
                uint pos = capacity_;

                if (anchor is IConduit.Seek.Anchor.Begin)
                    pos = offset;
                else
                   if (anchor is IConduit.Seek.Anchor.End)
                       pos -= offset;
                   else
                      pos = position_ + offset;

                return position_ = pos;
        }

        /***********************************************************************
        
                Return count of writable bytes available in buffer. This is 
                calculated simply as capacity() - limit()

        ***********************************************************************/

        override uint writable ()
        {
                return capacity_ - position_;
        }               

        /***********************************************************************
        
                Bulk copy of data from 'src'. Position is adjusted by 'size'
                bytes.

        ***********************************************************************/

        override protected void copy (void *src, uint size)
        {
                data[position_..position_+size] = src[0..size];
                position_ += size;
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
                int count = dg (data [position_..capacity_]);

                if (count != IConduit.Eof) 
                   {
                   position_ += count;
                   assert (position_ <= capacity_);
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

        override IBuffer setConduit (IConduit conduit)
        {
                throw new IOException ("cannot setConduit on memory-mapped buffer");
        }
}

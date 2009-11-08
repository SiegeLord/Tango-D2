/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: March 2004
        
        author:         Kris

*******************************************************************************/

module tango.io.device.FileMap;

private import tango.sys.Common;

private import tango.io.device.File,
               tango.io.device.Array;

/*******************************************************************************

        External declarations

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
         private import tango.stdc.posix.sys.mman;


/*******************************************************************************

*******************************************************************************/

class FileMap : Array
{
        private MappedFile file;

        /***********************************************************************

                Construct a FileMap upon the given path. 

                You should use resize() to setup the available 
                working space.

        ***********************************************************************/

        this (char[] path, File.Style style = File.ReadWriteOpen)
        {
                file = new MappedFile (path, style);
                super (file.map);
        }

        /***********************************************************************

                Resize the file and return the remapped content. Usage of
                map() is not required following this call

        ***********************************************************************/

        final ubyte[] resize (long size)
        {
                auto ret = file.resize (size);
                super.assign (ret);
                return ret;
        }

        /***********************************************************************

                Release external resources

        ***********************************************************************/

        override void close ()
        {
                super.close;
                if (file)
                    file.close;
                file = null;
        }
}


/*******************************************************************************

*******************************************************************************/

class MappedFile
{
        private File host;

        /***********************************************************************

                Construct a FileMap upon the given path. 

                You should use resize() to setup the available 
                working space.

        ***********************************************************************/

        this (char[] path, File.Style style = File.ReadWriteOpen)
        {
                host = new File (path, style);
        }

        /***********************************************************************

        ***********************************************************************/

        final long length ()
        {
                return host.length;
        }

        /***********************************************************************

        ***********************************************************************/

        final char[] path ()
        {
                return host.toString;
        }

        /***********************************************************************

                Resize the file and return the remapped content. Usage of
                map() is not required following this call

        ***********************************************************************/

        final ubyte[] resize (long size)
        {
                host.truncate (size);
                return map;
        }

        /***********************************************************************

        ***********************************************************************/

        version (Win32)
        {
                private void*   base;            // array pointer
                private HANDLE  mmFile;          // mapped file

                /***************************************************************

                        return a slice representing file content as a 
                        memory-mapped array

                ***************************************************************/

                final ubyte[] map ()
                {
                        DWORD flags;

                        // be wary of redundant references
                        if (base)
                            reset;

                        // can only do 32bit mapping on 32bit platform
                        auto size = cast(size_t) host.length;
                        auto access = host.style.access;

                        flags = PAGE_READONLY;
                        if (access & host.Access.Write)
                            flags = PAGE_READWRITE;
 
                        auto handle = cast(HANDLE) host.fileHandle;
                        mmFile = CreateFileMappingA (handle, null, flags, 0, 0, null);
                        if (mmFile is null)
                            host.error;

                        flags = FILE_MAP_READ;
                        if (access & host.Access.Write)
                            flags |= FILE_MAP_WRITE;

                        base = MapViewOfFile (mmFile, flags, 0, 0, 0);
                        if (base is null)
                            host.error;
  
                        return (cast(ubyte*) base) [0 .. size];
                }

                /***************************************************************

                        Release this mapping without flushing

                ***************************************************************/

                final void close ()
                {
                        reset;
                        if (host)
                            host.close;
                        host = null;
                }

                /***************************************************************

                ***************************************************************/

                private void reset ()
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

                MappedFile flush ()
                {
                        // flush all dirty pages
                        if (! FlushViewOfFile (base, 0))
                              host.error;
                        return this;
                }
        }

        /***********************************************************************
                
        ***********************************************************************/

        version (Posix)
        {               
                // Linux code: not yet tested on other POSIX systems.
                private void*   base;           // array pointer
                private size_t  size;           // length of file

                /***************************************************************

                        return a slice representing file content as a 
                        memory-mapped array. Use this to remap content
                        each time the file size is changed

                ***************************************************************/

                final ubyte[] map ()
                {
                        // be wary of redundant references
                        if (base)
                            reset;

                        // can only do 32bit mapping on 32bit platform
                        size = cast (size_t) host.length;

                        // Make sure the mapping attributes are consistant with
                        // the File attributes.
                        int flags = MAP_SHARED;
                        int protection = PROT_READ;
                        auto access = host.style.access;
                        if (access & host.Access.Write)
                            protection |= PROT_WRITE;
                                
                        base = mmap (null, size, protection, flags, host.fileHandle, 0);
                        if (base is MAP_FAILED)
                           {
                           base = null;
                           host.error;
                           }
                                
                        return (cast(ubyte*) base) [0 .. size];
                }    

                /***************************************************************

                        Release this mapped buffer without flushing

                ***************************************************************/

                final void close ()
                {
                        reset;
                        if (host)
                            host.close;
                        host = null;
                }

                /***************************************************************

                ***************************************************************/

                private void reset ()
                {
                        // NOTE: When a process ends, all mmaps belonging to that process
                        //       are automatically unmapped by system (Linux).
                        //       On the other hand, this is NOT the case when the related 
                        //       file descriptor is closed.  This function unmaps explicitly.
                        if (base)
                            if (munmap (base, size))
                                host.error;

                        base = null;    
                }

                /***************************************************************

                        Flush dirty content out to the drive. 

                ***************************************************************/

                final MappedFile flush () 
                {
                        // MS_ASYNC: delayed flush; equivalent to "add-to-queue"
                        // MS_SYNC: function flushes file immediately; no return until flush complete
                        // MS_INVALIDATE: invalidate all mappings of the same file (shared)

                        if (msync (base, size, MS_SYNC | MS_INVALIDATE))
                            host.error;
                        return this;
                }
        }
}


/*******************************************************************************

*******************************************************************************/

debug (FileMap)
{
        import tango.io.Path;

        void main()
        {
                auto file = new MappedFile ("foo.map");
                auto heap = file.resize (1_000_000);

                auto file1 = new MappedFile ("foo1.map");
                auto heap1 = file1.resize (1_000_000);

                file.close;
                remove ("foo.map");

                file1.close;
                remove ("foo1.map");
        }
}

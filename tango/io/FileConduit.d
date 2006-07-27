/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         $(UL Kris)
                        $(UL John Reimer)
                        $(UL Anders F Bjorklund (Darwin patches))
                        $(UL Chris Sauls (Win95 file support))

*******************************************************************************/

module tango.io.FileConduit;

private import  tango.os.OS;

public  import  tango.io.FileProxy;

private import  tango.io.DeviceConduit;

/*******************************************************************************

        Other O/S functions

*******************************************************************************/

version (Win32)
         private extern (Windows) BOOL SetEndOfFile (HANDLE);
     else
        private extern (C) int ftruncate (int, int);


/*******************************************************************************

        Defines how a file should be opened. You can use the predefined
        instances, or create specializations for your own needs.

*******************************************************************************/

struct FileStyle
{
}


/*******************************************************************************

        Implements a means of reading and writing a generic file. Conduits
        are the primary means of accessing external data, and are usually
        routed through a Buffer. File conduit extends the generic conduit
        by providing file-specific methods to set the file size, seek to a
        specific file position, and so on. Also provided is a class for
        creating a memory-mapped Buffer upon a file.

        Serial input and output is straightforward. In this example we
        copy a file directly to the console:

        ---
        // open a file for reading
        FileConduit from = new FileConduit ("test.txt");

        // stream directly to console
        Stdout.conduit.copy (from);
        ---

        And here we copy one file to another:

        ---
        // open a file for reading
        FileConduit from = new FileConduit ("test.txt");

        // open another for writing
        FileConduit to = new FileConduit ("copy.txt", FileStyle.WriteTruncate);

        // copy file
        to.copy (from);
        ---

        FileConduit can just as easily handle random IO. Here we see how
        a Reader and Writer are used to perform simple input and output:

        ---
        // open a file for reading
        FileConduit fc = new FileConduit ("random.bin", FileStyle.ReadWriteCreate);

        // construct (binary) reader & writer upon this conduit
        Reader read = new Reader (fc);
        Writer write = new Writer (fc);

        int x=10, y=20;

        // write some data, and flush output since IO is buffered
        write (x) (y) ();

        // rewind to file start
        fc.seek (0);

        // read data back again, but swap destinations
        read (y) (x);

        assert (y==10);
        assert (x==20);

        fc.close();
        ---

        FileConduits can also be used directly, without Readers, Writers, or
        Buffers. To load a file directly into local-memory one might do this:

        ---
        // open file for reading
        FileConduit fc = new FileConduit ("test.txt");

        // create an array to house the entire file
        char[] content = new char[fc.length];

        // read the file content. Return value is the number of bytes read
        int bytesRead = fc.read (content);
        ---

        Conversely, one may write directly to a FileConduit, like so:

        ---
        // open file for writing
        FileConduit to = new FileConduit ("text.txt", FileStyle.WriteTruncate);

        // write an array of content to it
        int bytesWritten = fc.write (content);
        ---


        See File, FilePath, FileProxy, FileConst, FileScan, and FileSystem for
        additional functionality related to file manipulation.

        Doxygen has a hard time with D version() statements, so part of this
        class is documented within FileConduit::VersionWin32 instead.

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.

*******************************************************************************/

class FileConduit : DeviceConduit, DeviceConduit.Seek
{
        /***********************************************************************

                Fits into 32 bits ...

        ***********************************************************************/

        struct Style
        {
                align (1):

                Access          access;                 /// access rights
                Open            open;                   /// how to open
                Share           share;                  /// how to share
                Cache           cache;                  /// how to cache
        }

        /***********************************************************************

        ***********************************************************************/

        enum Open : ubyte       {
                                Exists=0,               /// must exist
                                Create,                 /// create always
                                Truncate,               /// must exist
                                Append,                 /// create if necessary
                                };

        /***********************************************************************

        ***********************************************************************/

        enum Share : ubyte      {
                                Read=0,                 /// shared reading
                                Write,                  /// shared writing
                                ReadWrite,              /// both
                                };

        /***********************************************************************

        ***********************************************************************/

        enum Cache : ubyte      {
                                None      = 0x00,       /// don't optimize
                                Random    = 0x01,       /// optimize for random
                                Stream    = 0x02,       /// optimize for stream
                                WriteThru = 0x04,       /// backing-cache flag
                                };

        /***********************************************************************

        ***********************************************************************/

        const Style ReadExisting = {DeviceConduit.Access.Read, Open.Exists};
        const Style WriteTruncate = {DeviceConduit.Access.Write, Open.Truncate};
        const Style WriteAppending = {DeviceConduit.Access.Write, Open.Append};
        const Style ReadWriteCreate = {DeviceConduit.Access.ReadWrite, Open.Create};
        const Style ReadWriteExisting = {DeviceConduit.Access.ReadWrite, Open.Exists};


        // the file we're working with
        private FilePath path;

        // expose deviceconduit.copy() methods also
        alias DeviceConduit.copy      copy;
        alias DeviceConduit.read      read;
        alias DeviceConduit.write     write;

        /***********************************************************************

                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (char[] name, Style style = ReadExisting)
        {
                this (new FilePath(name), style);
        }

        /***********************************************************************

                Create a FileConduit from the provided proxy and style.

        ***********************************************************************/

        this (FileProxy proxy, Style style = ReadExisting)
        {
                this (proxy.getPath(), style);
        }

        /***********************************************************************

                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (FilePath path, Style style = ReadExisting)
        {
                // say we're seekable
                super (style.access, true);

                // remember who we are
                this.path = path;

                // open the file
                open (style);
        }

        /***********************************************************************

                Return the FilePath used by this file.

        ***********************************************************************/

        FilePath getPath ()
        {
                return path;
        }

        /***********************************************************************

                Return the name of the FilePath used by this file.

        ***********************************************************************/

        override char[] toString ()
        {
                return path.toString;
        }

        /***********************************************************************

                Return the current file position.

        ***********************************************************************/

        ulong getPosition ()
        {
                return seek (0, Seek.Anchor.Current);
        }

        /***********************************************************************

                Return the total length of this file.

        ***********************************************************************/

        ulong length ()
        {
                ulong   pos,
                        ret;

                pos = getPosition ();
                ret = seek (0, Seek.Anchor.End);
                seek (pos);
                return ret;
        }

        /***********************************************************************

                Transfer the content of another file to this one. Returns a
                reference to this class on success, or throws an IOException
                upon failure.

        ***********************************************************************/

        FileConduit copy (FilePath source)
        {
                auto fc = new FileConduit (source);
                scope (exit)
                       fc.close;

                super.copy (fc);
                return this;
        }

        /***********************************************************************

                Return the name used by this file.

        ***********************************************************************/

        protected override char[] getName ()
        {
                return path.toString;
        }


        /***********************************************************************

                Windows-specific code

        ***********************************************************************/

        version(Win32)
        {
                private bool appending;

                /***************************************************************

                        Open a file with the provided style.

                ***************************************************************/

                protected void open (Style style)
                {
                        DWORD   attr,
                                share,
                                access,
                                create;

                        alias DWORD[] Flags;

                        static const Flags Access =
                                        [
                                        0,                      // invalid
                                        GENERIC_READ,
                                        GENERIC_WRITE,
                                        GENERIC_READ | GENERIC_WRITE,
                                        ];

                        static const Flags Create =
                                        [
                                        OPEN_EXISTING,          // must exist
                                        CREATE_ALWAYS,          // create always
                                        TRUNCATE_EXISTING,      // must exist
                                        OPEN_ALWAYS,            // (for appending)
                                        ];

                        static const Flags Share =
                                        [
                                        FILE_SHARE_READ,
                                        FILE_SHARE_WRITE,
                                        FILE_SHARE_READ | FILE_SHARE_WRITE,
                                        ];

                        static const Flags Attr =
                                        [
                                        0,
                                        FILE_FLAG_RANDOM_ACCESS,
                                        FILE_FLAG_SEQUENTIAL_SCAN,
                                        0,
                                        FILE_FLAG_WRITE_THROUGH,
                                        ];

                        attr = Attr[style.cache];
                        share = Share[style.share];
                        create = Create[style.open];
                        access = Access[style.access];

                        version (Win32SansUnicode)
                                 handle = CreateFileA (path.toUtf8, access, share,
                                                       null, create,
                                                       attr | FILE_ATTRIBUTE_NORMAL,
                                                       cast(HANDLE) null);
                             else
                                handle = CreateFileW (path.toUtf16(true), access,
                                                      share, null, create,
                                                      attr | FILE_ATTRIBUTE_NORMAL,
                                                      cast(HANDLE) null);

                        if (handle is INVALID_HANDLE_VALUE)
                            error ();

                        // move to end of file?
                        if (style.open is Open.Append)
                            appending = true;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                protected override uint writer (void[] src)
                {
                        DWORD written;

                        // try to emulate the Unix O_APPEND mode
                        if (appending)
                            SetFilePointer (handle, 0, null, Seek.Anchor.End);

                        return super.writer (src);
                }

                /***************************************************************

                        Set the file size to be that of the current seek
                        position. The file must be writable for this to
                        succeed.

                ***************************************************************/

                void truncate ()
                {
                        // must have Generic_Write access
                        if (! SetEndOfFile (handle))
                              error ();
                }

                /***************************************************************

                        Set the file seek position to the specified offset
                        from the given anchor.

                ***************************************************************/

                ulong seek (ulong offset, Seek.Anchor anchor = Seek.Anchor.Begin)
                {
                        LONG high = cast(LONG) (offset >> 32);
                        ulong result = SetFilePointer (handle, cast(LONG) offset,
                                                       &high, anchor);

                        if (result is -1 &&
                            GetLastError() != ERROR_SUCCESS)
                            error ();

                        return result + (cast(ulong) high << 32);
                }
        }


        /***********************************************************************

                 Unix-specific code. Note that some methods are 32bit only

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Open a file with the provided style.

                ***************************************************************/

                protected void open (Style style)
                {
                        int     share,
                                access;

                        alias int[] Flags;

                        static const Flags Access =
                                        [
                                        0,              // invalid
                                        O_RDONLY,
                                        O_WRONLY,
                                        O_RDWR,
                                        ];

                        static const Flags Create =
                                        [
                                        0,              // open existing
                                        O_CREAT,        // create always
                                        O_TRUNC,        // must exist
                                        O_APPEND | O_CREAT,
                                        ];

                        // this is not the same as Windows sharing,
                        // but it's perhaps a reasonable approximation
                        static const Flags Share =
                                        [
                                        0640,           // read access
                                        0620,           // write access
                                        0660,           // read & write
                                        ];

                        share = Share[style.share];
                        access = Access[style.access] | Create[style.open];

                        handle = posix.open (path.toUtf8, access, share);
                        if (handle is -1)
                            error ();
                }

                /***************************************************************

                        32bit only ...

                        Set the file size to be that of the current seek
                        position. The file must be writable for this to
                        succeed.

                ***************************************************************/

                void truncate ()
                {
                        // set filesize to be current seek-position
                        if (ftruncate (handle, getPosition()) is -1)
                            error ();
                }

                /***************************************************************

                        32bit only ...

                        Set the file seek position to the specified offset
                        from the given anchor.

                ***************************************************************/

                ulong seek (ulong offset, Seek.Anchor anchor = Seek.Anchor.Begin)
                {
                        uint result = posix.lseek (handle, offset, anchor);
                        if (result is -1)
                            error ();
                        return result;
                }
        }
}


/*******************************************************************************

        Open a text-oriented FileConduit

*******************************************************************************/

class TextFileConduit : FileConduit
{
        /***********************************************************************

                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (char[] name, Style style = ReadExisting)
        {
                super (name, style);
        }

        /***********************************************************************

                Create a FileConduit from the provided proxy and style.

        ***********************************************************************/

        this (FileProxy proxy, Style style = ReadExisting)
        {
                super (proxy, style);
        }

        /***********************************************************************

                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (FilePath path, Style style = ReadExisting)
        {
                super (path, style);
        }

        /***********************************************************************

                Returns true if this conduit is text-based

        ***********************************************************************/

        override bool isTextual ()
        {
                return true;
        }
}


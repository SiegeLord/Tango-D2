/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
        version:        Feb 2007: Subclass of FilePath

        author:         $(UL Kris)
                        $(UL Brad Anderson)
                        $(UL teqdruid)
                        $(UL Anders (Darwin support))
                        $(UL Chris Sauls (Win95 file support))

*******************************************************************************/

module tango.io.FileProxy;

private import  tango.sys.Common;

public  import  tango.io.FilePath,
                tango.io.FileConst;

private import  tango.util.time.Utc;

private import  tango.core.Exception;

/*******************************************************************************

*******************************************************************************/

version (Win32)
        {
        private import Utf = tango.text.convert.Utf;

        extern (Windows) BOOL   MoveFileExA (LPCSTR,LPCSTR,DWORD);
        extern (Windows) BOOL   MoveFileExW (LPCWSTR,LPCWSTR,DWORD);

        private enum : DWORD 
        {
                REPLACE_EXISTING   = 1,
                COPY_ALLOWED       = 2,
                DELAY_UNTIL_REBOOT = 4,
                WRITE_THROUGH      = 8,
        }

        version (Win32SansUnicode)
                {
                alias char T;
                private extern (C) int strlen (char *s);
                private alias WIN32_FIND_DATA FIND_DATA;
                }
             else
                {
                alias wchar T;
                private extern (C) int wcslen (wchar *s);
                private alias WIN32_FIND_DATAW FIND_DATA;
                }
        }

version (Posix)
        {
        private import tango.stdc.stdio;
        private import tango.stdc.string;
        private import tango.stdc.posix.dirent;
        }


/*******************************************************************************

        Models a generic file. Use this to manipulate files and directories
        in conjunction with FilePath, FileSystem and FileConduit.

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.

*******************************************************************************/

class FileProxy : FilePath
{
        /***********************************************************************

                TimeStamp information. Accurate to whatever the OS supports

        ***********************************************************************/

        struct Stamps
        {
                Time    created,        /// time created
                        accessed,       /// last time accessed
                        modified;       /// last time modified
        }

        /***********************************************************************

                Construct a FileProxy from a text string

        ***********************************************************************/

        this (char[] path, bool isDir=false)
        {
                super (path, isDir);
        }

        /***********************************************************************

                Simple constructor form. This can be convenient, and 
                avoids ctor setup at the callsite:
                ---
                FileProxy proxy = "myPath";
                ---

        ***********************************************************************/

        static FileProxy opAssign (char[] path)
        {
                return new FileProxy (path);
        }

        /***********************************************************************

                Does this path currently exist?

        ***********************************************************************/

        final bool exists ()
        {
                try {
                    getSize();
                    return true;
                    } catch (IOException){}
                return false;
        }

        /***********************************************************************

        ***********************************************************************/

        final FileProxy asPath (char[] other)
        {
                super.asPath (other);
                return this;
        }

        /***********************************************************************

                Returns the time of the last modification. Accurate 
                to whatever the OS supports
                
        ***********************************************************************/

        final Time modified ()
        {
                return timeStamps.modified;
        }

        /***********************************************************************

                Returns the time of the last access. Accurate to 
                whatever the OS supports

        ***********************************************************************/

        final Time accessed ()
        {
                return timeStamps.accessed;
        }

        /***********************************************************************
        
                Returns the time of file creation. Accurate to 
                whatever the OS supports
        
        ***********************************************************************/
        
        final Time created ()
        {
                return timeStamps.created;
        }

        /***********************************************************************

                Create an entire path consisting of this folder along with 
                all parent folders. The path must not contain '.' or '..'
                segments. Related methods include PathUtil.normalize() and
                FileSystem.absolutePath()

                Returns: a chaining reference (this)

                Throws: IOException upon systen errors

                Throws: IllegalArgumentException if the path contains invalid
                        path segment names (such as '.' or '..') or a segment
                        exists but as a file instead of a folder

        ***********************************************************************/

        final FileProxy createPath ()
        { 
                if (this.exists)
                    if (this.isFolder)
                        return this;
                    else
                       badArg ("FileProxy.createPath :: file/folder conflict: ");

                FileProxy parent = this.parent;

                char[] name = parent.name;
                if (name.length is 0                   ||
                    name == FileConst.CurrentDirString ||
                    name == FileConst.ParentDirString)
                    badArg ("FileProxy.createPath :: invalid path: ");

                parent.createPath;
                return createFolder;
        }

        /***********************************************************************

                List the set of filenames within this directory. All
                filenames are null terminated, though the null itself
                is hidden at the end of each name (not exposed by the
                length property)

                Each filename optionally includes the parent prefix,
                dictated by whether argument prefixed is enabled or
                not; default behaviour is to eschew the prefix                

        ***********************************************************************/

        final char[][] toList (bool prefixed = false)
        {
                int      i;
                char[][] list;

                void add (char[] prefix, char[] name, bool dir)
                {
                        if (i >= list.length)
                            list.length = list.length * 2;

                        // duplicate the path, including the null. Note that
                        // the saved length *excludes* the terminator
                        list[i++] = prefixed ? (prefix~name) : name.dup;
                }

                list = new char[][512];
                toList (&add);
                return list [0 .. i];
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        private void exception ()
        {
                throw new IOException (toUtf8 ~ ": " ~ SysError.lastMsg);
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        private void badArg (char[] msg)
        {
                throw new IllegalArgumentException (msg ~ toUtf8);
        }

        /***********************************************************************

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        Cache a wchar[] instance of the path

                ***************************************************************/

                private wchar[] name16 (wchar[] tmp, bool withNull=true)
                {
                        int offset = withNull ? 0 : 1;
                        return Utf.toUtf16 (this.cString[0..$-offset], tmp);
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private DWORD getInfo (inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        version (Win32SansUnicode)
                                {
                                if (! GetFileAttributesExA (this.cString.ptr, GetFileInfoLevelStandard, &info))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! GetFileAttributesExW (name16(tmp).ptr, GetFileInfoLevelStandard, &info))
                                      exception;
                                }

                        return info.dwFileAttributes;
                }

                /***************************************************************

                        Get flags for this path

                ***************************************************************/

                private DWORD getFlags ()
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return getInfo (info);
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                final ulong getSize ()
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        getInfo (info);
                        return (cast(ulong) info.nFileSizeHigh << 32) +
                                            info.nFileSizeLow;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                final bool isWritable ()
                {
                        return (getFlags & FILE_ATTRIBUTE_READONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                final bool isFolder ()
                {
                        return (getFlags & FILE_ATTRIBUTE_DIRECTORY) != 0;
                }

                /***************************************************************

                        Return timestamp information

                ***************************************************************/

                final Stamps timeStamps ()
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;
                        Stamps                    time = void;

                        getInfo (info);                        
                        time.modified = Utc.convert (info.ftLastWriteTime);
                        time.accessed = Utc.convert (info.ftLastAccessTime);  
                        time.created  = Utc.convert (info.ftCreationTime);
                        return time;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FileProxy remove ()
                {
                        if (isFolder)
                           {
                           version (Win32SansUnicode)
                                   {
                                   if (! RemoveDirectoryA (this.cString.ptr))
                                         exception;
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! RemoveDirectoryW (name16(tmp).ptr))
                                         exception;
                                   }
                           }
                        else
                           version (Win32SansUnicode)
                                   {
                                   if (! DeleteFileA (this.cString.ptr))
                                         exception;
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! DeleteFileW (name16(tmp).ptr))
                                         exception;
                                   }

                        return this;
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided Path

                ***************************************************************/

                final FileProxy rename (FilePath dst)
                {
                        const int Typical = REPLACE_EXISTING + 
                                            COPY_ALLOWED     +
                                            WRITE_THROUGH;

                        int result;

                        version (Win32SansUnicode)
                                 result = MoveFileExA (this.cString.ptr, dst.cString.ptr, Typical);
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                result = MoveFileExW (name16(tmp).ptr, Utf.toUtf16(dst.cString).ptr, Typical);
                                }

                        if (! result)
                              exception;

                        this.set (dst);
                        return this;
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                final FileProxy createFile ()
                {
                        HANDLE h;

                        version (Win32SansUnicode)
                                 h = CreateFileA (this.cString.ptr, GENERIC_WRITE,
                                                  0, null, CREATE_ALWAYS,
                                                  FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                h = CreateFileW (name16(tmp).ptr, GENERIC_WRITE,
                                                 0, null, CREATE_ALWAYS,
                                                 FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                                }

                        if (h == INVALID_HANDLE_VALUE)
                            exception;

                        if (! CloseHandle (h))
                              exception;

                        return this;
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                final FileProxy createFolder ()
                {
                        version (Win32SansUnicode)
                                {
                                if (! CreateDirectoryA (this.cString.ptr, null))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! CreateDirectoryW (name16(tmp).ptr, null))
                                      exception;
                                }
                        return this;
                }

                /***************************************************************

                        List the set of filenames within this directory.

                        All filenames are null terminated and are passed
                        to the provided delegate as such, along with the
                        path prefix and whether the entry is a directory
                        or not.

                ***************************************************************/

                final void toList (void delegate (char[], char[], bool) dg)
                {
                        HANDLE                  h;
                        char[]                  prefix;
                        char[MAX_PATH+1]        tmp = void;
                        FIND_DATA               fileinfo = void;

                        int next()
                        {
                                version (Win32SansUnicode)
                                         return FindNextFileA (h, &fileinfo);
                                   else
                                      return FindNextFileW (h, &fileinfo);
                        }

                        static T[] padded (T[] s, T[] ext)
                        {
                                if (s.length is 0 || s[$-1] != '\\')
                                    return s ~ "\\" ~ ext;
                                return s ~ ext;
                        }

                        version (Win32SansUnicode)
                                 h = FindFirstFileA (padded(this.toUtf8, "*\0").ptr, &fileinfo);
                             else
                                {
                                wchar[MAX_PATH] host = void;
                                h = FindFirstFileW (padded(name16(host, false), "*\0").ptr, &fileinfo);
                                }

                        if (h is INVALID_HANDLE_VALUE)
                            exception;

                        scope (exit)
                               FindClose (h);

                        prefix = FilePath.padded (this.toUtf8);
                        do {
                           version (Win32SansUnicode)
                                   {
                                   // ensure we include the null
                                   auto len = strlen (fileinfo.cFileName.ptr);
                                   auto str = fileinfo.cFileName.ptr [0 .. len];
                                   }
                                else
                                   {
                                   // ensure we include the null
                                   auto len = wcslen (fileinfo.cFileName.ptr);
                                   auto str = Utf.toUtf8 (fileinfo.cFileName [0 .. len], tmp);
                                   }

                           // skip hidden/system files
                           if ((fileinfo.dwFileAttributes & (FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN)) is 0)
                                dg (prefix, str, (fileinfo.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0);

                           } while (next);
                }
        }


        /***********************************************************************

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private uint getInfo (inout stat_t stats)
                {
                        if (posix.stat (this.cString.ptr, &stats))
                            exception;

                        return stats.st_mode;
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                final ulong getSize ()
                {
                        stat_t stats = void;

                        getInfo (stats);
                        return cast(ulong) stats.st_size;    // 32 bits only
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                final bool isWritable ()
                {
                        stat_t stats = void;

                        return (getInfo(stats) & O_RDONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                final bool isFolder ()
                {
                        stat_t stats = void;

                        return (getInfo(stats) & S_IFDIR) != 0;
                }

                /***************************************************************

                        Return timestamp information

                ***************************************************************/

                final Stamps timeStamps ()
                {
                        stat_t stats = void;
                        Stamps time  = void;

                        getInfo (stats);

                        time.modified = Utc.convert (*cast(timeval*) &stats.st_mtime);                      
                        time.accessed = Utc.convert (*cast(timeval*) &stats.st_atime);  
                        time.created  = Utc.convert (*cast(timeval*) &stats.st_ctime);
                        return time;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FileProxy remove ()
                {
                        if (isFolder)
                           {
                           if (posix.rmdir (this.cString.ptr))
                               exception;
                           }
                        else
                           if (tango.stdc.stdio.remove (this.cString.ptr) == -1)
                               exception;

                        return this;
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                final FileProxy rename (FilePath dst)
                {
                        if (tango.stdc.stdio.rename (this.cString.ptr, dst.cString.ptr) == -1)
                            exception;

                        this.set (dst);
                        return this;
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                final FileProxy createFile ()
                {
                        int fd;

                        fd = posix.open (this.cString.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0660);
                        if (fd == -1)
                            exception;

                        if (posix.close(fd) == -1)
                            exception;

                        return this;
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                final FileProxy createFolder ()
                {
                        if (posix.mkdir (this.cString.ptr, 0777))
                            exception;

                        return this;
                }

                /***************************************************************

                        List the set of filenames within this directory.

                        All filenames are null terminated and are passed
                        to the provided delegate as such, along with the
                        path prefix and whether the entry is a directory
                        or not.

                ***************************************************************/

                final void toList (void delegate (char[], char[], bool) dg)
                {
                        DIR*            dir;
                        dirent*         entry;
                        char[]          prefix;

                        dir = tango.stdc.posix.dirent.opendir (this.cString.ptr);
                        if (! dir)
                              exception;

                        scope (exit)
                               tango.stdc.posix.dirent.closedir (dir);

                        prefix = FilePath.padded (this.toUtf8);

                        while ((entry = tango.stdc.posix.dirent.readdir(dir)) != null)
                              {
                              // ensure we include the terminating null ...
                              auto len = tango.stdc.string.strlen (entry.d_name.ptr);
                              auto str = entry.d_name.ptr [0 .. len];

                              dg (prefix, str, (entry.d_type & DT_DIR) != 0);
                              }
                }
        }
}


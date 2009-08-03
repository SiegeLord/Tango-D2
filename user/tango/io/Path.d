/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2008: Initial version

        author:         Kris

        A more direct route to the file-system than FilePath. Use this 
        if you don't need path editing features. For example, if all you 
        want is to check some path exists, using this module would likely 
        be more convenient than FilePath. For example:
        ---
        if (exists ("some/file/path")) 
            ...
        ---

        These functions may be less efficient than FilePath because they 
        generally attach a null to the filename for each underlying O/S
        call. Use Path when you need pedestrian access to the file-system, 
        and are not manipulating the path components. Use FilePath where
        path editing or mutation is desired.

        We encourage the use of "scoped import" with this module, such as
        ---
        import Path = tango.io.Path;

        if (Path.exists ("some/file/path")) 
            ...
        ---

        Also residing here is a lightweight path-parser, which splits a 
        filepath into constituent components. See PathParser below:
        ---
        auto p = Path.parse ("some/file/path");
        auto path = p.path;
        auto name = p.name;
        auto suffix = p.suffix;
        ...
        ...
        ---

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s 
        file support.

*******************************************************************************/

module tango.io.Path;

private import  tango.sys.Common;

private import  tango.io.model.IFile : FileConst;

public  import  tango.time.Time : Time, TimeSpan;

public  import  tango.core.Exception : IOException, IllegalArgumentException;


/*******************************************************************************

        Various imports

*******************************************************************************/

version (Win32)
        {
        version (Win32SansUnicode)
                {
                private extern (C) int strlen (char *s);
                private alias WIN32_FIND_DATA FIND_DATA;
                }
             else
                {
                private extern (C) int wcslen (wchar *s);
                private alias WIN32_FIND_DATAW FIND_DATA;
                }
        }

version (Posix)
        {
        private import tango.stdc.stdio;
        private import tango.stdc.string;
        private import tango.stdc.posix.utime;
        private import tango.stdc.posix.dirent;
        }


/*******************************************************************************

        Wraps the O/S specific calls with a D API. Note that these accept
        null-terminated strings only, which is why it's not public. We need 
        this declared first to avoid forward-reference issues

*******************************************************************************/

package struct FS
{
        /***********************************************************************

                TimeStamp information. Accurate to whatever the F/S supports

        ***********************************************************************/

        struct Stamps
        {
                Time    created,        /// time created
                        accessed,       /// last time accessed
                        modified;       /// last time modified
        }

        /***********************************************************************

                Passed around during file-scanning

        ***********************************************************************/

        struct FileInfo
        {
                char[]  path,
                        name;
                ulong   bytes;
                bool    folder;
        }

        /***********************************************************************

                Some fruct glue for directory listings

        ***********************************************************************/

        struct Listing
        {
                char[] folder;

                int opApply (int delegate(ref FileInfo) dg)
                {
                        char[256] tmp = void;
                        auto path = strz (folder, tmp);

                        // sanity check on Win32 ...
                        version (Win32)
                                {
                                bool kosher(){foreach (c; path) if (c is '\\') return false; return true;};
                                assert (kosher, "attempting to use non-standard '\\' in a path for a folder listing");
                                }

                        return list (path, dg);
                }
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        static void exception (char[] filename)
        {
                exception (filename[0..$-1] ~ ": ", SysError.lastMsg);
        }

        /***********************************************************************

                Throw an IO exception 

        ***********************************************************************/

        static void exception (char[] prefix, char[] error)
        {
                throw new IOException (prefix ~ error);
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a trailing separator

        ***********************************************************************/

        static char[] padded (char[] path, char c = '/')
        {
                if (path.length && path[$-1] != c)
                    path = path ~ c;
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances do not
                have a trailing separator

        ***********************************************************************/

        static char[] stripped (char[] path, char c = '/')
        {
                if (path.length && path[$-1] is c)
                    path = path [0 .. $-1];
                return path;
        }

        /***********************************************************************

                Join a set of path specs together. A path separator is
                potentially inserted between each of the segments.

        ***********************************************************************/

        static char[] join (char[][] paths...)
        {
                char[] result;

                foreach (path; paths)
                         result ~= padded (path);

                return result.length ? result [0 .. $-1] : "";
        }

        /***********************************************************************

                Append a terminating null onto a string, cheaply where 
                feasible

        ***********************************************************************/

        static char[] strz (char[] src, char[] dst)
        {
                auto i = src.length + 1;
                if (dst.length < i)
                    dst.length = i;
                dst [0 .. i-1] = src;
                dst[i-1] = 0;
                return dst [0 .. i];
        }

        /***********************************************************************

                Win32 API code

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        return a wchar[] instance of the path

                ***************************************************************/

                private static wchar[] toString16 (wchar[] tmp, char[] path)
                {
                        auto i = MultiByteToWideChar (CP_UTF8, 0,
                                                      cast(PCHAR)path.ptr, path.length,
                                                      tmp.ptr, tmp.length);
                        return tmp [0..i];
                }

                /***************************************************************

                        return a char[] instance of the path

                ***************************************************************/

                private static char[] toString (char[] tmp, wchar[] path)
                {
                        auto i = WideCharToMultiByte (CP_UTF8, 0, path.ptr, path.length,
                                                      cast(PCHAR)tmp.ptr, tmp.length, null, null);
                        return tmp [0..i];
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static bool fileInfo (char[] name, inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        version (Win32SansUnicode)
                                {
                                if (! GetFileAttributesExA (name.ptr, GetFileInfoLevelStandard, &info))
                                      return false;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! GetFileAttributesExW (toString16(tmp, name).ptr, GetFileInfoLevelStandard, &info))
                                      return false;
                                }

                        return true;
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static DWORD getInfo (char[] name, inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        if (! fileInfo (name, info))
                              exception (name);
                        return info.dwFileAttributes;
                }

                /***************************************************************

                        Get flags for this path

                ***************************************************************/

                private static DWORD getFlags (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return getInfo (name, info);
                }

                /***************************************************************

                        Return whether the file or path exists

                ***************************************************************/

                static bool exists (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return fileInfo (name, info);
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                static ulong fileSize (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        getInfo (name, info);
                        return (cast(ulong) info.nFileSizeHigh << 32) +
                                            info.nFileSizeLow;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                static bool isWritable (char[] name)
                {
                        return (getFlags(name) & FILE_ATTRIBUTE_READONLY) is 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                static bool isFolder (char[] name)
                {
                        return (getFlags(name) & FILE_ATTRIBUTE_DIRECTORY) != 0;
                }

                /***************************************************************

                        Is this a normal file?

                ***************************************************************/

                static bool isFile (char[] name)
                {
                        return (getFlags(name) & FILE_ATTRIBUTE_DIRECTORY) == 0;
                }

                /***************************************************************

                        Return timestamp information

                        Timstamps are returns in a format dictated by the 
                        file-system. For example NTFS keeps UTC time, 
                        while FAT timestamps are based on the local time

                ***************************************************************/

                static Stamps timeStamps (char[] name)
                {
                        static Time convert (FILETIME time)
                        {
                                return Time (TimeSpan.Epoch1601 + *cast(long*) &time);
                        }

                        WIN32_FILE_ATTRIBUTE_DATA info = void;
                        Stamps                    time = void;

                        getInfo (name, info);
                        time.modified = convert (info.ftLastWriteTime);
                        time.accessed = convert (info.ftLastAccessTime);
                        time.created  = convert (info.ftCreationTime);
                        return time;
                }

                /***************************************************************

                        Transfer the content of another file to this one. 
                        Returns a reference to this class on success, or 
                        throws an IOException upon failure.

                ***************************************************************/

                static void copy (char[] src, char[] dst)
                {
                        version (Win32SansUnicode)
                                {
                                if (! CopyFileA (src.ptr, dst.ptr, false))
                                      exception (src);
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp1 = void;
                                wchar[MAX_PATH+1] tmp2 = void;

                                if (! CopyFileW (toString16(tmp1, src).ptr, toString16(tmp2, dst).ptr, false))
                                      exception (src);
                                }
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                static void remove (char[] name)
                {
                        if (isFolder(name))
                           {
                           version (Win32SansUnicode)
                                   {
                                   if (! RemoveDirectoryA (name.ptr))
                                         exception (name);
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! RemoveDirectoryW (toString16(tmp, name).ptr))
                                         exception (name);
                                   }
                           }
                        else
                           version (Win32SansUnicode)
                                   {
                                   if (! DeleteFileA (name.ptr))
                                         exception (name);
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! DeleteFileW (toString16(tmp, name).ptr))
                                         exception (name);
                                   }
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided Path

                ***************************************************************/

                static void rename (char[] src, char[] dst)
                {
                        const int Typical = MOVEFILE_REPLACE_EXISTING +
                                            MOVEFILE_COPY_ALLOWED     +
                                            MOVEFILE_WRITE_THROUGH;

                        int result;
                        version (Win32SansUnicode)
                                 result = MoveFileExA (src.ptr, dst.ptr, Typical);
                             else
                                {
                                wchar[MAX_PATH] tmp1 = void;
                                wchar[MAX_PATH] tmp2 = void;
                                result = MoveFileExW (toString16(tmp1, src).ptr, toString16(tmp2, dst).ptr, Typical);
                                }

                        if (! result)
                              exception (src);
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                static void createFile (char[] name)
                {
                        HANDLE h;

                        version (Win32SansUnicode)
                                 h = CreateFileA (name.ptr, GENERIC_WRITE,
                                                  0, null, CREATE_ALWAYS,
                                                  FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                h = CreateFileW (toString16(tmp, name).ptr, GENERIC_WRITE,
                                                 0, null, CREATE_ALWAYS,
                                                 FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                                }

                        if (h is INVALID_HANDLE_VALUE)
                            exception (name);

                        if (! CloseHandle (h))
                              exception (name);
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                static void createFolder (char[] name)
                {
                        version (Win32SansUnicode)
                                {
                                if (! CreateDirectoryA (name.ptr, null))
                                      exception (name);
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! CreateDirectoryW (toString16(tmp, name).ptr, null))
                                      exception (name);
                                }
                }

                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                static int list (char[] folder, int delegate(ref FileInfo) dg)
                {
                        HANDLE                  h;
                        int                     ret;
                        char[]                  prefix;
                        char[MAX_PATH+1]        tmp = void;
                        FIND_DATA               fileinfo = void;
                        
                        version (Win32SansUnicode)
                                 alias char T;
                              else
                                 alias wchar T;

                        int next()
                        {
                                version (Win32SansUnicode)
                                         return FindNextFileA (h, &fileinfo);
                                   else
                                      return FindNextFileW (h, &fileinfo);
                        }

                        static T[] padded (T[] s, T[] ext)
                        {
                                if (s.length && s[$-1] is '/')
                                    return s ~ ext;
                                return s ~ "/" ~ ext;
                        }

                        version (Win32SansUnicode)
                                 h = FindFirstFileA (padded(folder[0..$-1], "*\0").ptr, &fileinfo);
                             else
                                {
                                wchar[MAX_PATH] host = void;
                                h = FindFirstFileW (padded(toString16(host, folder[0..$-1]), "*\0").ptr, &fileinfo);
                                }

                        if (h is INVALID_HANDLE_VALUE)
                            return ret; //exception (folder);

                        scope (exit)
                               FindClose (h);

                        prefix = FS.padded (folder[0..$-1]);
                        do {
                           version (Win32SansUnicode)
                                   {
                                   auto len = strlen (fileinfo.cFileName.ptr);
                                   auto str = fileinfo.cFileName.ptr [0 .. len];
                                   }
                                else
                                   {
                                   auto len = wcslen (fileinfo.cFileName.ptr);
                                   auto str = toString (tmp, fileinfo.cFileName [0 .. len]);
                                   }

                           // skip hidden/system files
                           if ((fileinfo.dwFileAttributes & (FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN)) is 0)
                              {
                              FileInfo info = void;
                              info.name   = str;
                              info.path   = prefix;
                              info.bytes  = (cast(ulong) fileinfo.nFileSizeHigh << 32) + fileinfo.nFileSizeLow;
                              info.folder = (fileinfo.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;

                              // skip "..." names
                              if (str.length > 3 || str != "..."[0 .. str.length])
                                  if ((ret = dg(info)) != 0)
                                       break;
                              }
                           } while (next);

                        return ret;
                }
        }

        /***********************************************************************

                Posix-specific code

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static uint getInfo (char[] name, inout stat_t stats)
                {
                        if (posix.stat (name.ptr, &stats))
                            exception (name);

                        return stats.st_mode;
                }

                /***************************************************************

                        Return whether the file or path exists

                ***************************************************************/

                static bool exists (char[] name)
                {
                        stat_t stats = void;
                        return posix.stat (name.ptr, &stats) is 0;
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                static ulong fileSize (char[] name)
                {
                        stat_t stats = void;

                        getInfo (name, stats);
                        return cast(ulong) stats.st_size;    // 32 bits only
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                static bool isWritable (char[] name)
                {
                        stat_t stats = void;

                        return (getInfo(name, stats) & O_RDONLY) is 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                static bool isFolder (char[] name)
                {
                        stat_t stats = void;

                        return (getInfo(name, stats) & S_IFMT) is S_IFDIR;
                }

                /***************************************************************

                        Is this a normal file?

                ***************************************************************/

                static bool isFile (char[] name)
                {
                        stat_t stats = void;

                        return (getInfo(name, stats) & S_IFMT) is S_IFREG;
                }

                /***************************************************************

                        Return timestamp information

                        Timstamps are returns in a format dictated by the 
                        file-system. For example NTFS keeps UTC time, 
                        while FAT timestamps are based on the local time

                ***************************************************************/

                static Stamps timeStamps (char[] name)
                {
                        static Time convert (typeof(stat_t.st_mtime) secs)
                        {
                                return Time.epoch1970 +
                                       TimeSpan.fromSeconds(secs);
                        }

                        stat_t stats = void;
                        Stamps time  = void;

                        getInfo (name, stats);

                        time.modified = convert (stats.st_mtime);
                        time.accessed = convert (stats.st_atime);
                        time.created  = convert (stats.st_ctime);
                        return time;
                }

                /***********************************************************************

                        Transfer the content of another file to this one. Returns a
                        reference to this class on success, or throws an IOException
                        upon failure.

                ***********************************************************************/

                static void copy (char[] source, char[] dest)
                {
                        auto src = posix.open (source.ptr, O_RDONLY, 0640);
                        scope (exit)
                               if (src != -1)
                                   posix.close (src);

                        auto dst = posix.open (dest.ptr, O_CREAT | O_RDWR, 0660);
                        scope (exit)
                               if (dst != -1)
                                   posix.close (dst);

                        if (src is -1 || dst is -1)
                            exception (source);

                        // copy content
                        ubyte[] buf = new ubyte [16 * 1024];
                        int read = posix.read (src, buf.ptr, buf.length);
                        while (read > 0)
                              {
                              auto p = buf.ptr;
                              do {
                                 int written = posix.write (dst, p, read);
                                 p += written;
                                 read -= written;
                                 if (written is -1)
                                     exception (dest);
                                 } while (read > 0);
                              read = posix.read (src, buf.ptr, buf.length);
                              }
                        if (read is -1)
                            exception (source);

                        // copy timestamps
                        stat_t stats;
                        if (posix.stat (source.ptr, &stats))
                            exception (source);

                        utimbuf utim;
                        utim.actime = stats.st_atime;
                        utim.modtime = stats.st_mtime;
                        if (utime (dest.ptr, &utim) is -1)
                            exception (dest);
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                static void remove (char[] name)
                {
                        if (tango.stdc.stdio.remove (name.ptr) is -1)
                            exception (name);
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                static void rename (char[] src, char[] dst)
                {
                        if (tango.stdc.stdio.rename (src.ptr, dst.ptr) is -1)
                            exception (src);
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                static void createFile (char[] name)
                {
                        int fd;

                        fd = posix.open (name.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0660);
                        if (fd is -1)
                            exception (name);

                        if (posix.close(fd) is -1)
                            exception (name);
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                static void createFolder (char[] name)
                {
                        if (posix.mkdir (name.ptr, 0777))
                            exception (name);
                }
                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                static int list (char[] folder, int delegate(ref FileInfo) dg)
                {
                        int             ret;
                        DIR*            dir;
                        dirent          entry;
                        dirent*         pentry;
                        stat_t          sbuf;
                        char[]          prefix;
                        char[]          sfnbuf;

                        dir = tango.stdc.posix.dirent.opendir (folder.ptr);
                        if (! dir)
                              return ret; //exception (folder);

                        scope (exit)
                               tango.stdc.posix.dirent.closedir (dir);

                        // ensure a trailing '/' is present
                        prefix = FS.padded (folder[0..$-1]);

                        // prepare our filename buffer
                        sfnbuf = prefix.dup;
                        
                        // pentry is null at end of listing, or on an error 
                        while (readdir_r (dir, &entry, &pentry), pentry !is null)
                              {
                              auto len = tango.stdc.string.strlen (entry.d_name.ptr);
                              auto str = entry.d_name.ptr [0 .. len];
                              ++len;  // include the null

                              // resize the buffer as necessary ...
                              if (sfnbuf.length < prefix.length + len)
                                  sfnbuf.length = prefix.length + len;

                              sfnbuf [prefix.length .. prefix.length + len]
                                      = entry.d_name.ptr [0 .. len];

                              // skip "..." names
                              if (str.length > 3 || str != "..."[0 .. str.length])
                                 {
                                 FileInfo info = void;
                                 info.bytes  = 0;
                                 info.folder = false;
                                 info.name   = str;
                                 info.path   = prefix;
                                 
                                 if (! stat (sfnbuf.ptr, &sbuf))
                                    {
                                    info.folder = (sbuf.st_mode & S_IFDIR) != 0;
                                    if ((sbuf.st_mode & S_IFREG) != 0)
                                         info.bytes = cast(ulong) sbuf.st_size;
                                    }

                                 if ((ret = dg(info)) != 0)
                                      break;
                                 }
                              }
                        return ret;
                }
        }
}


/*******************************************************************************

        Parse a file path

        File paths containing non-ansi characters should be UTF-8 encoded.
        Supporting Unicode in this manner was deemed to be more suitable
        than providing a wchar version of PathParser, and is both consistent
        & compatible with the approach taken with the Uri class.

        Note that patterns of adjacent '.' separators are treated specially
        in that they will be assigned to the name where there is no distinct
        suffix. In addition, a '.' at the start of a name signifies it does 
        not belong to the suffix i.e. ".file" is a name rather than a suffix.
        Patterns of intermediate '.' characters will otherwise be assigned
        to the suffix, such that "file....suffix" includes the dots within
        the suffix itself. See method ext() for a suffix without dots.

        Note also that normalization of path-separators does *not* occur by 
        default. This means that usage of '\' characters should be explicitly
        converted beforehand into '/' instead (an exception is thrown in those
        cases where '\' is present). On-the-fly conversion is avoided because
        (a) the provided path is considered immutable and (b) we avoid taking
        a copy of the original path. Module FilePath exists at a higher level, 
        without such contraints.

*******************************************************************************/

struct PathParser
{       
        package char[]  fp;                     // filepath with trailing
        package int     end_,                   // before any trailing 0
                        ext_,                   // after rightmost '.'
                        name_,                  // file/dir name
                        folder_,                // path before name
                        suffix_;                // including leftmost '.'

        /***********************************************************************

                Parse the path spec

        ***********************************************************************/

        PathParser parse (char[] path)
        {
                return parse (path, path.length);
        }

        /***********************************************************************

                Duplicate this path

        ***********************************************************************/

        PathParser dup ()
        {
                auto ret = *this;
                ret.fp = fp.dup;
                return ret;
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        char[] toString ()
        {
                return fp [0 .. end_];
        }

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        char[] root ()
        {
                return fp [0 .. folder_];
        }

        /***********************************************************************

                Return the file path. Paths may start and end with a "/".
                The root path is "/" and an unspecified path is returned as
                an empty string. Directory paths may be split such that the
                directory name is placed into the 'name' member; directory
                paths are treated no differently than file paths

        ***********************************************************************/

        char[] folder ()
        {
                return fp [folder_ .. name_];
        }

        /***********************************************************************

                Returns a path representing the parent of this one. This
                will typically return the current path component, though
                with a special case where the name component is empty. In 
                such cases, the path is scanned for a prior segment:
                ---
                normal:  /x/y/z => /x/y
                special: /x/y/  => /x
                ---

                Note that this returns a path suitable for splitting into
                path and name components (there's no trailing separator).

        ***********************************************************************/

        char[] parent ()
        {
                auto p = path;
                if (name.length is 0)
                    for (int i=p.length-1; --i > 0;)
                         if (p[i] is FileConst.PathSeparatorChar)
                            {
                            p = p[0 .. i];
                            break;
                            }
                return FS.stripped (p);
        }

        /***********************************************************************

                Return the name of this file, or directory.

        ***********************************************************************/

        char[] name ()
        {
                return fp [name_ .. suffix_];
        }

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator e.g. path "foo.bar" has ext "bar". Note that
                patterns of adjacent separators are treated specially - for
                example, ".." will wind up with no ext at all

        ***********************************************************************/

        char[] ext ()
        {
                auto x = suffix;
                if (x.length)
                   {
                   if (ext_ is 0)
                       foreach (c; x)
                                if (c is '.')
                                    ++ext_;
                                else
                                   break;
                   x = x [ext_ .. $];
                   }
                return x;
        }

        /***********************************************************************

                Suffix is like ext, but includes the separator e.g. path
                "foo.bar" has suffix ".bar"

        ***********************************************************************/

        char[] suffix ()
        {
                return fp [suffix_ .. end_];
        }

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        char[] path ()
        {
                return fp [0 .. name_];
        }

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        char[] file ()
        {
                return fp [name_ .. end_];
        }

        /***********************************************************************

                Returns true if this path is *not* relative to the
                current working directory

        ***********************************************************************/

        bool isAbsolute ()
        {
                return (folder_ > 0) ||
                       (folder_ < end_ && fp[folder_] is FileConst.PathSeparatorChar);
        }

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        bool isEmpty ()
        {
                return end_ is 0;
        }

        /***********************************************************************

                Returns true if this path has a parent. Note that a
                parent is defined by the presence of a path-separator in
                the path. This means 'foo' within "/foo" is considered a
                child of the root

        ***********************************************************************/

        bool isChild ()
        {
                return folder.length > 0;
        }

        /***********************************************************************

                Does this path equate to the given text?

        ***********************************************************************/

        int opEquals (char[] s)
        {
                return toString == s;
        }

        /***********************************************************************

                Parse the path spec with explicit end point. A '\' is 
                considered illegal in the path.

        ***********************************************************************/

        package PathParser parse (char[] path, size_t end)
        {
                end_ = end;
                fp = path;
                folder_ = 0;
                name_ = suffix_ = -1;

                for (int i=end_; --i >= 0;)
                     switch (fp[i])
                            {
                            case FileConst.FileSeparatorChar:
                                 if (name_ < 0)
                                     if (suffix_ < 0 && i && fp[i-1] != '.')
                                         suffix_ = i;
                                 break;

                            case FileConst.PathSeparatorChar:
                                 if (name_ < 0)
                                     name_ = i + 1;
                                 break;

                            // Windows file separators are illegal. Use
                            // standard() or equivalent to convert first
                            case '\\':
                                 FS.exception ("unexpected '\\' character in path: ", path[0..end]);

                            version (Win32)
                            {
                            case ':':
                                 folder_ = i + 1;
                                 break;
                            }

                            default:
                                 break;
                            }

                if (name_ < 0)
                    name_ = folder_;

                if (suffix_ < 0 || suffix_ is name_)
                    suffix_ = end_;

                return *this;
        }
}


/*******************************************************************************

        Does this path currently exist?

*******************************************************************************/

bool exists (char[] name)
{
        char[512] tmp = void;
        return FS.exists (FS.strz(name, tmp));
}

/*******************************************************************************

        Returns the time of the last modification. Accurate
        to whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time. 

*******************************************************************************/

Time modified (char[] name)
{       
        return timeStamps(name).modified;
}

/*******************************************************************************

        Returns the time of the last access. Accurate to
        whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time.

*******************************************************************************/

Time accessed (char[] name)
{
        return timeStamps(name).accessed;
}

/*******************************************************************************

        Returns the time of file creation. Accurate to
        whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time,  
        while FAT timestamps are based on the local time.

*******************************************************************************/

Time created (char[] name)
{
        return timeStamps(name).created;
}

/*******************************************************************************

        Return the file length (in bytes)

*******************************************************************************/

ulong fileSize (char[] name)
{
        char[512] tmp = void;
        return FS.fileSize (FS.strz(name, tmp));
}

/*******************************************************************************

        Is this file writable?

*******************************************************************************/

bool isWritable (char[] name)
{
        char[512] tmp = void;
        return FS.isWritable (FS.strz(name, tmp));
}

/*******************************************************************************

        Is this file actually a folder/directory?

*******************************************************************************/

bool isFolder (char[] name)
{
        char[512] tmp = void;
        return FS.isFolder (FS.strz(name, tmp));
}

/*******************************************************************************

        Is this file actually a normal file?
        Not a directory or (on unix) a device file or link.

*******************************************************************************/

bool isFile (char[] name)
{
        char[512] tmp = void;
        return FS.isFile (FS.strz(name, tmp));
}

/*******************************************************************************

        Return timestamp information

        Timstamps are returns in a format dictated by the 
        file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time

*******************************************************************************/

FS.Stamps timeStamps (char[] name)
{
        char[512] tmp = void;
        return FS.timeStamps (FS.strz(name, tmp));
}

/*******************************************************************************

        Remove the file/directory from the file-system

*******************************************************************************/

void remove (char[] name)
{      
        char[512] tmp = void;
        FS.remove (FS.strz(name, tmp));
}

/*******************************************************************************

        Create a new file

*******************************************************************************/

void createFile (char[] name)
{
        char[512] tmp = void;
        FS.createFile (FS.strz(name, tmp));
}

/*******************************************************************************

        Create a new directory

*******************************************************************************/

void createFolder (char[] name)
{
        char[512] tmp = void;
        FS.createFolder (FS.strz(name, tmp));
}

/*******************************************************************************

        Create an entire path consisting of this folder along with
        all parent folders. The path must not contain '.' or '..'
        segments. Related methods include PathUtil.normalize() and
        FilePath.absolute()

        Note that each segment is created as a folder, including the
        trailing segment.

        Throws: IOException upon system errors

        Throws: IllegalArgumentException if a segment exists but as a 
        file instead of a folder

*******************************************************************************/

void createPath (char[] path)
{
        void test (char[] segment)
        {
                if (segment.length)
                    if (! exists (segment))
                          createFolder (segment);
                    else
                       if (! isFolder (segment))
                             throw new IllegalArgumentException ("Path.createPath :: file/folder conflict: " ~ segment);
        }

        foreach (i, char c; path)
                 if (c is '/')
                     test (path [0 .. i]);
        test (path);
}

/*******************************************************************************

       change the name or location of a file/directory

*******************************************************************************/

void rename (char[] src, char[] dst)
{
        char[512] tmp1 = void;
        char[512] tmp2 = void;
        FS.rename (FS.strz(src, tmp1), FS.strz(dst, tmp2));
}

/*******************************************************************************

        Transfer the content of one file to another. Throws 
        an IOException upon failure.

*******************************************************************************/

void copy (char[] src, char[] dst)
{
        char[512] tmp1 = void;
        char[512] tmp2 = void;
        FS.copy (FS.strz(src, tmp1), FS.strz(dst, tmp2));
}

/*******************************************************************************

        Provides foreach support via a fruct, as in
        ---
        foreach (info; children("myfolder"))
                 ...
        ---

        Each path and filename is passed to the foreach
        delegate, along with the path prefix and whether
        the entry is a folder or not. The info construct
        exposes the following attributes:
        ---
        char[]  path
        char[]  name
        ulong   bytes
        bool    folder
        ---

*******************************************************************************/

FS.Listing children (char[] path)
{
        return FS.Listing (path);
}

/*******************************************************************************

        Join a set of path specs together. A path separator is
        potentially inserted between each of the segments.

*******************************************************************************/

char[] join (char[][] paths...)
{
        return FS.join (paths);
}

/*******************************************************************************

        Convert path separators to a standard format, using '/' as
        the path separator. This is compatible with Uri and all of 
        the contemporary O/S which Tango supports. Known exceptions
        include the Windows command-line processor, which considers
        '/' characters to be switches instead. Use the native()
        method to support that.

        Note: mutates the provided path.

*******************************************************************************/

char[] standard (char[] path)
{
        return replace (path, '\\', '/');
}

/*******************************************************************************

        Convert to native O/S path separators where that is required,
        such as when dealing with the Windows command-line. 
        
        Note: mutates the provided path. Use this pattern to obtain a 
        copy instead: native(path.dup);

*******************************************************************************/

char[] native (char[] path)
{
        version (Win32)
                 replace (path, '/', '\\');
        return path;
}

/*******************************************************************************

        Returns a path representing the parent of this one, with a special 
        case concerning a trailing '/':
        ---
        normal:  /x/y/z => /x/y
        special: /x/y/  => /x
        final:   /x     => empty
        ---

*******************************************************************************/

char[] pop (char[] path)
{
        path = FS.stripped (path);
        int i = path.length;
        while (i && path[--i] != '/') {}
        return path [0..i];
}

/*******************************************************************************

        Break a path into "head" and "tail" components. For example: 
        ---
        "/a/b/c" -> "/a","b/c" 
        "a/b/c" -> "a","b/c" 
        ---

*******************************************************************************/

char[] split (char[] path, out char[] head, out char[] tail)
{
        head = path;
        if (path.length > 1)
            foreach (i, char c; path[1..$])
                     if (c is '/')
                        {
                        head = path [0 .. i+1];
                        tail = path [i+2 .. $];
                        break;
                        }
        return path;
}

/*******************************************************************************

        Replace all path 'from' instances with 'to', in place (overwrites
        the provided path)

*******************************************************************************/

char[] replace (char[] path, char from, char to)
{
        foreach (inout char c; path)
                 if (c is from)
                     c = to;
        return path;
}

/*******************************************************************************

        Parse a path into its constituent components. 
        
        Note that the provided path is not duplicated

*******************************************************************************/

PathParser parse (char[] path)
{
        PathParser p;
        
        p.parse (path);
        return p;
}


/*******************************************************************************

*******************************************************************************/

debug(Path)
{
        import tango.io.Stdout;

        void main()
        {
                exists ("path.d");
                assert(exists("Path.d"));
                    
                auto p = parse ("d:/foo/bar/file.ext");
                Stdout.formatln ("string '{}'", p);
                Stdout.formatln ("root '{}'", p.root);
                Stdout.formatln ("folder '{}'", p.folder);
                Stdout.formatln ("path '{}'", p.path);
                Stdout.formatln ("file '{}'", p.file);
                Stdout.formatln ("name '{}'", p.name);
                Stdout.formatln ("suffix '{}'", p.suffix);
                Stdout.formatln ("ext '{}'", p.ext);
                Stdout.formatln ("isChild: {}", p.isChild);
                Stdout.formatln ("isEmpty: {}", p.isEmpty);
                Stdout.formatln ("isAbsolute: {}", p.isAbsolute);
        }
}

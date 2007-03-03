/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2004: Initial version
        version:        Nov 2006: Australian version
        version:        Feb 2007: Mutating version
        version:        Mar 2007: Folded FileProxy in

        author:         Kris

*******************************************************************************/

module tango.io.FilePath;

private import  tango.sys.Common;

private import  tango.io.FileConst;

private import  tango.util.time.Utc;

private import  tango.core.Exception;

/*******************************************************************************

*******************************************************************************/

version (Win32)
        {
        private import Utf = tango.text.convert.Utf;

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
        private import tango.stdc.posix.utime;
        private import tango.stdc.posix.dirent;
        }

/*******************************************************************************

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);

/*******************************************************************************

        Models a file path. These are expected to be used as the constructor
        argument to various file classes. The intention is that they easily
        convert to other representations such as absolute, canonical, or Url.

        File paths containing non-ansi characters should be UTF-8 encoded.
        Supporting Unicode in this manner was deemed to be more suitable
        than providing a wchar version of FilePath, and is both consistent
        & compatible with the approach taken with the Uri class.

        FilePath is designed to be transformed, thus each mutating method
        modifies the internal content. There is a read-only base-class
        called PathView, which can be used to provide a view into the
        content as desired.

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.

*******************************************************************************/

class FilePath : PathView
{
        private char[]  fp;                     // filepath with trailing 0

        private bool    dir_;                   // this represents a dir?

        private int     end_,                   // before the trailing 0
                        ext_,                   // after rightmost '.'
                        name_,                  // file/dir name
                        folder_,                // path before name
                        suffix_;                // inclusive of leftmost '.'

        /***********************************************************************

                Create a FilePath from a copy of the provided string.

                FilePath assumes both path & name are present, and therefore
                may split what is otherwise a logically valid path. That is,
                the 'name' of a file is typically the path segment following
                a rightmost path-separator. The intent is to treat files and
                directories in the same manner; as a name with an optional
                ancestral structure. It is possible to bias the interpretation
                by adding a trailing path-separator to the argument. Doing so
                will result in an empty name attribute.

                With regard to the filepath copy, we found the common case to
                be an explicit .dup, whereas aliasing appeared to be rare by
                comparison. We also noted a large proportion interacting with
                C-oriented OS calls, implying the postfix of a null terminator.
                Thus, FilePath combines both as a single operation.

        ***********************************************************************/

        this (char[] filepath, bool isDir=false)
        {
                set (filepath, isDir);
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        final char[] toUtf8 ()
        {
                return fp [0 .. end_];
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        final char[] cString ()
        {
                return fp [0 .. end_+1];
        }

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        final char[] root ()
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

        final char[] folder ()
        {
                return fp [folder_ .. name_];
        }

        /***********************************************************************

                Returns a path representing the parent of this one.

                Note that this returns a path suitable for splitting into
                path and name components (there's no trailing separator).

        ***********************************************************************/

        final char[] parent ()
        {
                return stripped (path);
        }

        /***********************************************************************

                Return the name of this file, or directory.

        ***********************************************************************/

        final char[] name ()
        {
                return fp [name_ .. suffix_];
        }

        /***********************************************************************

                Suffix is like an extension, except it may include multiple
                '.' sequences and the dot-prefix is included in the suffix.
                For example, "wumpus.foo.bar" has suffix ".foo.bar"

        ***********************************************************************/

        final char[] suffix ()
        {
                return fp [suffix_ .. end_];
        }

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator e.g. path "wumpus.foo.bar" has ext ".bar"

        ***********************************************************************/

        final char[] ext ()
        {
                auto x = ext_;
                if (x < end_)
                    --x;
                return fp [x .. end_];
        }

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        final char[] path ()
        {
                return fp [0 .. name_];
        }

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        final char[] file ()
        {
                return fp [name_ .. end_];
        }

        /***********************************************************************

                Returns true if all fields are equal.

        ***********************************************************************/

        final override int opEquals (Object o)
        {
                return (this is o) || (o != null && toUtf8 == o.toUtf8);
        }

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory

        ***********************************************************************/

        final bool isAbsolute ()
        {
                return (folder_ > 0) ||
                       (folder_ < end_ && fp[folder_] is FileConst.PathSeparatorChar);
        }

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        final bool isEmpty ()
        {
                return end_ is 0;
        }

        /***********************************************************************

                Returns true if this FilePath has a parent

        ***********************************************************************/

        final bool isChild ()
        {
                auto s = folder ();
                for (int i=s.length; --i > 0;)
                     if (s[i] is FileConst.PathSeparatorChar)
                         return true;
                return false;
        }

        /***********************************************************************

                Returns true if this FilePath has been marked as a directory,
                via the constructor or method set()

        ***********************************************************************/

        final bool isDir ()
        {
                return dir_;
        }

        /***********************************************************************

                Replace all 'from' instances in the provided path with 'to'

        ***********************************************************************/

        final FilePath replace (char from, char to)
        {
                foreach (inout char c; fp [0 .. end_])
                         if (c is from)
                             c = to;
                return this;
        }

        /***********************************************************************

                Convert path separators to the correct format according to
                the current platform

        ***********************************************************************/

        final FilePath normalize ()
        {
                version (Win32)
                         return replace ('/', '\\');
                     else
                        return replace ('\\', '/');
        }

        /***********************************************************************

                Append text to this path; no separators are added

        ***********************************************************************/

        final FilePath append (char[][] others...)
        {
                foreach (other; others)
                        {
                        auto len = end_ + other.length;
                        expand (len);
                        fp [end_ .. len] = other;
                        fp [len] = 0;
                        end_ = len;
                        }
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        FilePath set (FilePath path)
        {
                return set (path.toUtf8, path.dir_);
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath set (char[] path, bool dir = false)
        {
                dir_ = dir;
                end_ = path.length;

                expand (end_);
                fp[0 .. end_] = path;
                fp[end_] = '\0';
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath root (char[] other)
        {
                auto x = adjust (0, folder_, folder_, padded (other, ':'));
                suffix_ += x;
                folder_ += x;
                name_ += x;
                ext_ += x;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath folder (char[] other)
        {
                auto x = adjust (folder_, name_, name_ - folder_, padded (other));
                suffix_ += x;
                name_ += x;
                ext_ += x;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath name (char[] other)
        {
                auto x = adjust (name_, suffix_, suffix_ - name_, other);
                suffix_ += x;
                ext_ += x;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath suffix (char[] other)
        {
                adjust (suffix_, end_, end_ - suffix_, prefixed (other, '.'));
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath ext (char[] other)
        {
                auto len = ext.length;
                adjust (end_ - len, end_, len, prefixed (other, '.'));
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath path (char[] other)
        {
                adjust (0, name_, name_, other);
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath file (char[] other)
        {
                adjust (name_, end_, end_ - name_, other);
                return parse;
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

                return result.length ? result [0 .. $-1] : null;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances do not
                have a trailing separator

        ***********************************************************************/

        static char[] stripped (char[] path, char c = FileConst.PathSeparatorChar)
        {
                if (path.length && path[$-1] is c)
                    path = path [0 .. $-1];
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a trailing separator

        ***********************************************************************/

        static char[] padded (char[] path, char c = FileConst.PathSeparatorChar)
        {
                if (path.length && path[$-1] != c)
                    path ~= c;
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a prefixed separator

        ***********************************************************************/

        static char[] prefixed (char[] s, char c)
        {
                if (s.length && s[0] != c)
                    s = c ~ s;
                return s;
        }


        /**********************************************************************/
        /**************************  proxy methods ****************************/
        /**********************************************************************/


        /***********************************************************************

                Does this path currently exist?

        ***********************************************************************/

        final bool exists ()
        {
                try {
                    fileSize();
                    return true;
                    } catch (IOException){}
                return false;
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

        final FilePath create ()
        {
                if (this.exists)
                    if (this.isFolder)
                        return this;
                    else
                       badArg ("FilePath.createPath :: file/folder conflict: ");

                auto parent = new FilePath (this.parent);
                char[] name = parent.name;

                if (name.length is 0                   ||
                    name == FileConst.CurrentDirString ||
                    name == FileConst.ParentDirString)
                    badArg ("FilePath.createPath :: invalid path: ");

                parent.create;
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

        ***********************************************************************/

        private final FilePath parse ()
        {
                folder_ = 0;
                name_ = suffix_ = ext_ = -1;

                for (int i=end_; --i >= 0;)
                     switch (fp[i])
                            {
                            case FileConst.FileSeparatorChar:
                                 if (name_ < 0)
                                    {
                                    suffix_ = i;
                                    if (ext_ < 0)
                                        ext_ = i + 1;
                                    }
                                 break;

                            case FileConst.PathSeparatorChar:
                                 if (name_ < 0)
                                     name_ = i + 1;
                                 break;

                            version (Win32)
                            {
                            case FileConst.RootSeparatorChar:
                                 folder_ = i + 1;
                                 break;
                            }

                            default:
                                 break;
                            }

                if (name_ < 0)
                    name_ = folder_;

                if (suffix_ < 0)
                    suffix_ = end_;

                if (ext_ < 0)
                    ext_ = end_;

                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        private final void expand (uint size)
        {
                ++size;
                if (fp.length < size)
                    fp.length = (size + 63) & ~63;
        }

        /***********************************************************************

        ***********************************************************************/

        private final int adjust (int head, int tail, int len, char[] sub)
        {
                len = sub.length - len;

                if (len > 0)
                   {
                   expand (len + end_);
                   memmove (fp.ptr+head+len, fp.ptr+head, end_+1 - head);
                   }
                else
                   memmove (fp.ptr+tail+len, fp.ptr+tail, end_+1 - tail);

                memmove (fp.ptr + head, sub.ptr, tail + len - head);
                end_ += len;
                return len;
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

                        return a wchar[] instance of the path

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

                final ulong fileSize ()
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

                /***********************************************************************

                        Transfer the content of another file to this one. Returns a
                        reference to this class on success, or throws an IOException
                        upon failure.

                ***********************************************************************/

                final FilePath copy (char[] source)
                {
                        auto src = new FilePath (source);

                        version (Win32SansUnicode)
                                {
                                if (! CopyFileA (src.cString.ptr, this.cString.ptr, false))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp1 = void;
                                wchar[MAX_PATH+1] tmp2 = void;

                                if (! CopyFileW (Utf.toUtf16(src.cString, tmp1).ptr, name16(tmp2).ptr, false))
                                      exception;
                                }

                        return this;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FilePath remove ()
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

                final FilePath rename (FilePath dst)
                {
                        const int Typical = MOVEFILE_REPLACE_EXISTING +
                                            MOVEFILE_COPY_ALLOWED     +
                                            MOVEFILE_WRITE_THROUGH;

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

                final FilePath createFile ()
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

                final FilePath createFolder ()
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

                final ulong fileSize ()
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

                /***********************************************************************

                        Transfer the content of another file to this one. Returns a
                        reference to this class on success, or throws an IOException
                        upon failure.

                ***********************************************************************/

                final FilePath copy (char[] source)
                {
                        auto from = new FilePath (source);

                        auto src = posix.open (from.cString.ptr, O_RDONLY, 0640);
                        scope (exit)
                               if (src != -1)
                                   posix.close (src);

                        auto dst = posix.open (this.cString.ptr, O_CREAT | O_RDWR, 0660);
                        scope (exit)
                               if (dst != -1)
                                   posix.close (dst);

                        if (src is -1 || dst is -1)
                            exception;

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
                                     exception;
                                 } while (read > 0);
                              read = posix.read (src, buf.ptr, buf.length);
                              }
                        if (read is -1)
                            exception;

                        // copy timestamps
                        stat_t stats;
                        if (posix.stat (from.cString.ptr, &stats))
                            exception;

                        utimbuf utim;
                        utim.actime = stats.st_atime;
                        utim.modtime = stats.st_mtime;
                        if (utime (this.cString.ptr, &utim) is -1)
                            exception;

                        return this;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FilePath remove ()
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

                final FilePath rename (FilePath dst)
                {
                        if (tango.stdc.stdio.rename (this.cString.ptr, dst.cString.ptr) == -1)
                            exception;

                        this.set (dst);
                        return this;
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                final FilePath createFile ()
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

                final FilePath createFolder ()
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
                        stat_t          sbuf;
                        char[]          prefix;
                        char[]          sfnbuf;

                        dir = tango.stdc.posix.dirent.opendir (this.cString.ptr);
                        if (! dir)
                              exception;

                        scope (exit)
                               tango.stdc.posix.dirent.closedir (dir);

                        // ensure a trailing '/' is present
                        prefix = FilePath.padded (this.toUtf8);

                        // prepare our filename buffer
                        sfnbuf = prefix.dup;

                        while ((entry = tango.stdc.posix.dirent.readdir(dir)) != null)
                              {
                              auto len = tango.stdc.string.strlen (entry.d_name.ptr);
                              auto str = entry.d_name.ptr [0 .. len];
                              ++len;  // include the null

                              // resize the buffer as necessary ...
                              if (sfnbuf.length < prefix.length + len)
                                  sfnbuf.length = prefix.length + len;

                              sfnbuf [prefix.length .. prefix.length + len]
                                      = entry.d_name.ptr [0 .. len];

                              bool isDir = stat (sfnbuf.ptr, &sbuf)
                                                 ? false
                                                 : (sbuf.st_mode & S_IFDIR) != 0;
                              dg (prefix, str, isDir);
                              }
                }
        }
}



/*******************************************************************************

*******************************************************************************/

interface PathView
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

                Return the complete text of this filepath

        ***********************************************************************/

        final char[] toUtf8 ();

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        final char[] cString ();

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        final char[] root ();

        /***********************************************************************

                Return the file path. Paths may start and end with a "/".
                The root path is "/" and an unspecified path is returned as
                an empty string. Directory paths may be split such that the
                directory name is placed into the 'name' member; directory
                paths are treated no differently than file paths

        ***********************************************************************/

        final char[] folder ();

        /***********************************************************************

                Return the name of this file, or directory.

        ***********************************************************************/

        final char[] name ();

        /***********************************************************************

                Suffix is like an extension, except it may include multiple
                '.' sequences and the dot-prefix is included in the suffix.
                For example, "wumpus.foo.bar" has suffix ".foo.bar"

        ***********************************************************************/

        final char[] suffix ();

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator. For example, "wumpus.foo.bar" has ext "bar"

        ***********************************************************************/

        final char[] ext ();

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        final char[] path ();

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        final char[] file ();

        /***********************************************************************

                Returns true if all fields are equal.

        ***********************************************************************/

        final int opEquals (Object o);

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory.

        ***********************************************************************/

        final bool isAbsolute ();

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        final bool isEmpty ();

        /***********************************************************************

                Returns true if this FilePath has a parent

        ***********************************************************************/

        final bool isChild ();

        /***********************************************************************

                Returns true if this FilePath has been marked as a
                directory, via the constructor

        ***********************************************************************/

        final bool isDir ();

        /***********************************************************************

                Does this path currently exist?

        ***********************************************************************/

        final bool exists ();

        /***********************************************************************

                Returns the time of the last modification. Accurate
                to whatever the OS supports

        ***********************************************************************/

        final Time modified ();

        /***********************************************************************

                Returns the time of the last access. Accurate to
                whatever the OS supports

        ***********************************************************************/

        final Time accessed ();

        /***********************************************************************

                Returns the time of file creation. Accurate to
                whatever the OS supports

        ***********************************************************************/

        final Time created ();

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

        final FilePath create ();

        /***********************************************************************

                Create a new file

        ***********************************************************************/

        final FilePath createFile ();

        /***********************************************************************

                Create a new directory

        ***********************************************************************/

        final FilePath createFolder ();

        /***********************************************************************

                Return the file length (in bytes)

        ***********************************************************************/

        final ulong fileSize ();

        /***********************************************************************

                Is this file writable?

        ***********************************************************************/

        final bool isWritable ();

        /***********************************************************************

                Is this file actually a folder/directory?

        ***********************************************************************/

        final bool isFolder ();

        /***********************************************************************

                Return timestamp information

        ***********************************************************************/

        final Stamps timeStamps ();
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        void main() {}

        unittest
        {
        version (Win32)
                {
                auto fp = new FilePath(r"C:\home\foo\bar\john\");
                assert (fp.isAbsolute);
                assert (fp.name == "");
                assert (fp.folder == r"\home\foo\bar\john\");
                assert (fp.toUtf8 == r"C:\home\foo\bar\john\");
                assert (fp.path == r"C:\home\foo\bar\john\");
                assert (fp.file == r"");
                assert (fp.suffix == r"");
                assert (fp.root == r"C:");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(r"C:\home\foo\bar\john");
                assert (fp.isAbsolute);
                assert (fp.name == "john");
                assert (fp.folder == r"\home\foo\bar\");
                assert (fp.toUtf8 == r"C:\home\foo\bar\john");
                assert (fp.path == r"C:\home\foo\bar\");
                assert (fp.file == r"john");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(fp.parent);
                assert (fp.isAbsolute);
                assert (fp.name == "bar");
                assert (fp.folder == r"\home\foo\");
                assert (fp.toUtf8 == r"C:\home\foo\bar");
                assert (fp.path == r"C:\home\foo\");
                assert (fp.file == r"bar");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(fp.parent);
                assert (fp.isAbsolute);
                assert (fp.name == "foo");
                assert (fp.folder == r"\home\");
                assert (fp.toUtf8 == r"C:\home\foo");
                assert (fp.path == r"C:\home\");
                assert (fp.file == r"foo");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(fp.parent);
                assert (fp.isAbsolute);
                assert (fp.name == "home");
                assert (fp.folder == r"\");
                assert (fp.toUtf8 == r"C:\home");
                assert (fp.path == r"C:\");
                assert (fp.file == r"home");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"foo\bar\john.doe");
                assert (!fp.isAbsolute);
                assert (fp.name == "john");
                assert (fp.folder == r"foo\bar\");
                assert (fp.suffix == r".doe");
                assert (fp.file == r"john.doe");
                assert (fp.toUtf8 == r"foo\bar\john.doe");
                assert (fp.ext == ".doe");
                assert (fp.isChild);

                fp = new FilePath(r"c:doe");
                assert (fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp.toUtf8 == r"c:doe");
                assert (fp.folder == r"");
                assert (fp.name == "doe");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"\doe");
                assert (fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp.toUtf8 == r"\doe");
                assert (fp.name == "doe");
                assert (fp.folder == r"\");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"john.doe.foo");
                assert (!fp.isAbsolute);
                assert (fp.name == "john");
                assert (fp.folder == r"");
                assert (fp.suffix == r".doe.foo");
                assert (fp.toUtf8 == r"john.doe.foo");
                assert (fp.file == r"john.doe.foo");
                assert (fp.ext == ".foo");
                assert (!fp.isChild);

                fp = new FilePath(r".doe");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r".doe");
                assert (fp.toUtf8 == r".doe");
                assert (fp.name == "");
                assert (fp.folder == r"");
                assert (fp.file == r".doe");
                assert (fp.ext == ".doe");
                assert (!fp.isChild);

                fp = new FilePath(r"doe");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp.toUtf8 == r"doe");
                assert (fp.name == "doe");
                assert (fp.folder == r"");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r".");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r".");
                assert (fp.toUtf8 == r".");
                assert (fp.name == "");
                assert (fp.folder == r"");
                assert (fp.file == r".");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"..");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"..");
                assert (fp.toUtf8 == r"..");
                assert (fp.name == "");
                assert (fp.folder == r"");
                assert (fp.file == r"..");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"c:\a\b\c\d\e\foo.bar");
                assert (fp.isAbsolute);
                fp.folder (r"\a\b\c\");
                assert (fp.suffix == r".bar");
                assert (fp.toUtf8 == r"c:\a\b\c\foo.bar");
                assert (fp.name == "foo");
                assert (fp.folder == r"\a\b\c\");
                assert (fp.file == r"foo.bar");
                assert (fp.ext == ".bar");
                assert (fp.isChild);

                fp = new FilePath(r"c:\a\b\c\d\e\foo.bar");
                assert (fp.isAbsolute);
                fp.folder (r"\a\b\c\d\e\f\g\");
                assert (fp.suffix == r".bar");
                assert (fp.toUtf8 == r"c:\a\b\c\d\e\f\g\foo.bar");
                assert (fp.name == "foo");
                assert (fp.folder == r"\a\b\c\d\e\f\g\");
                assert (fp.file == r"foo.bar");
                assert (fp.ext == ".bar");
                assert (fp.isChild);

/+
                fp = new FilePath(r"C:\foo\bar\test.bar");
                fp = new FilePath(fp.asPath ("foo"));
                assert (fp.name == r"test");
                assert (fp.folder == r"foo\");
                assert (fp.path == r"C:foo\");
                assert (fp.ext == ".bar");

                fp = new FilePath(fp.asPath (""));
                assert (fp.name == r"test");
                assert (fp.folder == r"");
                assert (fp.path == r"C:");
                assert (fp.ext == ".bar");
+/
                fp = new FilePath("");
                assert (fp.isEmpty);
                assert (!fp.isChild);
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp.toUtf8 == r"");
                assert (fp.name == "");
                assert (fp.folder == r"");
                assert (fp.file == r"");
                assert (fp.ext == "");
/+
                fp = new FilePath(r"c:\joe\bar");
                assert(fp.append(r"foo\bar\") == r"c:\joe\bar\foo\bar\");
                assert(fp.append(new FilePath(r"foo\bar")).toUtf8 == r"c:\joe\bar\foo\bar");

                assert (FilePath.join (r"a\b\c\d", r"e\f\" r"g") == r"a\b\c\d\e\f\g");

                fp = new FilePath(r"C:\foo\bar\test.bar");
                assert (fp.asExt(null) == r"C:\foo\bar\test");
                assert (fp.asExt("foo") == r"C:\foo\bar\test.foo");
+/
                }


        version (Posix)
                {
                }
        }
}

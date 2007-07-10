/*******************************************************************************

        copyright:      Copyright (c) 2007 Lars Ivar Igesund, Kris Bell
                        All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jul 2007: Initial version

        author:         Lars Ivar, Kris

*******************************************************************************/


module tango.io.vfs.VFS;

private import tango.io.vfs.Folder,
               tango.io.vfs.LocalFolder;
private import tango.io.model.IConduit;
private import tango.net.Uri;
private import tango.net.model.UriView;

/*******************************************************************************

*******************************************************************************/

class VFS : Folder 
{
    /*************************************************************************

    *************************************************************************/
    alias Folder delegate(UriView) ProtocolHandler;

    private ProtocolHandler[char[]] handlers;
    private Folder[char[]] mountPoints;

    private Folder _tempFolder = null;

    /*************************************************************************

    *************************************************************************/
 
    this (char[] tempPath = null)
    {
        if (tempPath !is null)
            _tempFolder = new LocalFolder(tempPath);
    }

    /*************************************************************************

    *************************************************************************/
 
    Folder mount(UriView remotePath, char[] mountpoint) 
    {
        Folder folder = null;
        if (auto handler = *(remotePath.getScheme() in handlers)) {
            folder = handler(remotePath);
        }

        if (folder !is null) {
            return mount(folder, mountpoint);
        }
        return folder;
    }

    /*************************************************************************

    *************************************************************************/
 
    Folder mount(Folder virtualFolder, char[] mountpoint) 
    {
        if (mountpoint in mountPoints)
            throw new Exception("Mountpoint already exists in VFS");

        mountPoints[mountpoint] = virtualFolder;
        return this;
    }

    /*************************************************************************

    *************************************************************************/
 
    Folder unmount(char[] mountpoint)
    {
        if (mountpoint in mountPoints)
            mountPoints.remove(mountpoint);
            
        return this;
    }

    /*************************************************************************

    *************************************************************************/
 
    void registerProtocol(char[] protocol, ProtocolHandler handler) 
    {
        handlers[protocol] = handler;    
    }

    /*************************************************************************

    *************************************************************************/
  
    char[][] toList(bool prefixed = false)
    {
        // TODO revisit
        char[][] list;

        foreach (folder; mountPoints) {
            list ~= folder.toList(prefixed);
        }
        return list;
    }

    /*************************************************************************

    *************************************************************************/
 
    Folder toList(void delegate(char[], char[], bool) dg)
    {
        foreach (folder; mountPoints) {
            folder.toList(dg);
        }
        return this;
    }

    /**********************************************************************

        The VFS checks if the given path exists within it's bounds,
        returning true if so. The path must be relative to the root
        of this VFS, e.g. "mydir/myfile" will check for myfile in the
        mountpoint mydir.

        As one may not know the complexity, IO capacity or similar, to
        do this check, it can be potentially slow operation.

        false will be returned if an exception is thrown.

    **********************************************************************/

    bool exists(char[] path)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            return false;

        if (auto folder = (vfspath.segment(0) in mountPoints))
            return folder.exists(vfspath.removeFirstSegments(1).toUtf8);

        return false;
    }

    /*************************************************************************

    *************************************************************************/
 
    InputStream read(char[] path)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            throw new Exception("VFS :: read :: Empty path provided");

        if (vfspath.segmentCount == 1 && 
            _tempFolder.exists(vfspath.segment(0)))
            return _tempFolder.read(vfspath.segment(0));

        if (auto folder = (vfspath.segment(0) in mountPoints))
            return folder.read(vfspath.removeFirstSegments(1).toUtf8);

        throw new Exception("VFS :: read :: No file with path " ~ path);
    }

    /*************************************************************************

    *************************************************************************/
 
    ulong fileCount(bool recurse = true)
    {
        ulong count;
        if (_tempFolder !is null)
            count = _tempFolder.fileCount(false);

        if (recurse) {
            foreach (folder; mountPoints) {
                count += folder.fileCount(recurse);
            }
        }

        return count; 
    }

    /*************************************************************************

    *************************************************************************/
 
    /+
    ulong folderCount(bool recurse = true)
    {
        ulong count;
        foreach (folder; mountPoints) {
            count++;
            if (recurse)
                count += folder.folderCount(recurse);
        }

        return count;
    }
    +/


    /*************************************************************************

    *************************************************************************/
 
    ulong contentSize(bool recurse = true)
    {
        ulong size;
        if (_tempFolder !is null)
            size = _tempFolder.contentSize(false);

        if (recurse) {
            foreach (folder; mountPoints) {
                size += folder.contentSize(false);
            }
        }

        return size;
    }

    /**********************************************************************

        Returns true if the VFS was constructed with a writable temporary 
        folder, otherwise false.

        Note that this property makes no statement on the writability of
        mounted folders, neither does it guarantee that the written data
        are persisted.

    **********************************************************************/

    bool isWritable() 
    { 
        return _tempFolder !is null; 
    }

    /*************************************************************************

    *************************************************************************/
 
    UriView uri()
    {
        // TODO : Hmm, not really sure what this should return yet
        // and if it should be accessible via an Uri
        // Maybe if the VFS is persisted, and network enabled
        return new Uri("vfs", "", _tempFolder.toUtf8);
    }

    /*************************************************************************

        Creates a folder relative to the root of this VFS.

        If the path describes a folder on the root of the VFS, the folder
        will be created in the VFS' temp folder, and mounted in the VFS
        with that name. If the VFS is readonly, an exception will be thrown
        instead.

        If the path describes a folder in a mounted folder, the creation
        will be delegated to that folder.

        Returns:
            The created folder

        Throws:
            An exception will be thrown when the creation of the folder
            fails, or if the folder already exists.

    *************************************************************************/
 
    Folder createFolder(char[] path)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            throw new Exception("VFS :: createFolder :: Empty path provided");

        if (vfspath.segmentCount == 1 &&
            _tempFolder !is null &&
            !_tempFolder.exists(vfspath.segment(0))) {
            auto folder = _tempFolder.createFolder(vfspath.segment(0));
            mount(folder, vfspath.segment(0));
            return folder;
        }

        if (auto folder = (vfspath.segment(0) in mountPoints))
            return folder.createFolder(vfspath.removeFirstSegments(1).toUtf8);

        throw new Exception("VFS :: createFolder :: Couldn't create " ~ path);
    }

    /*************************************************************************

        Opens a folder relative to the root of this VFS.

        Returns:
            A reference to the opened folder, or null if it don't exist.

    *************************************************************************/
 
    Folder openFolder(char[] path)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            return null;

        if (auto folder = *(vfspath.segment(0) in mountPoints)) {
            if (vfspath.segmentCount == 1)
                return folder;
            else
                return folder.openFolder(vfspath.removeFirstSegments(1).toUtf8);
        }

        return null;
    }

    /*************************************************************************

    *************************************************************************/
 
    Folder write(char[] path, InputStream stream)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            throw new Exception("VFS :: write :: Empty path provided");

        if (vfspath.segmentCount == 1) {
            if (_tempFolder !is null)
                _tempFolder.write(path, stream);
            else
                throw new Exception("VFS :: write :: Folder is not writable");
        }

        if (auto folder = (vfspath.segment(0) in mountPoints))
            folder.write(vfspath.removeFirstSegments(1).toUtf8, stream);

        return this;
    }

    /*************************************************************************

 
    Folder remove(char[] path)
    {
        scope VfsPath vfspath = new VfsPath(path);

        if (vfspath.segmentCount == 0)
            throw new Exception("VFS :: remove :: Empty path provided");


        // TODO
        return null;
    }

    *************************************************************************/
}

version (Win32)
        {
        version (Win32SansUnicode)
                {
                private extern (C) int strlen (char *s);
                }
             else
                {
                private extern (C) int wcslen (wchar *s);
                }
        }


version (Posix)
        {
        private import tango.stdc.string;
        }

class VfsPath
{

        enum : char
        {
                FileSeparatorChar = '.',
                PathSeparatorChar = '/'
        }

        private bool    dir_;                   // this represents a dir?

        private char[]  fp;                     // filepath with trailing 0
        private int     end_,                   // before the trailing 0
                        name_,                  // file/dir name
                        folder_,                // path before name
                        suffix_;                // after rightmost '.'
        private uint    segments_;              // segments in path

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

        this(char[] filepath, bool isDir=false)
        {
                set (filepath);
                dir_ = isDir;
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

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator e.g. path "foo.bar" has ext "bar". Note that
                patterns of adjacent separators are treated specially; for
                example, ".." will wind up with no ext at all

        ***********************************************************************/

        final char[] ext ()
        {
                auto x = suffix;
                if (x.length)
                    x = x [1..$];
                return x;
        }

        /***********************************************************************

                Suffix is like ext, but includes the separator e.g. path 
                "foo.bar" has suffix ".bar"

        ***********************************************************************/

        final char[] suffix ()
        {
                return fp [suffix_ .. end_];
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
                return (this is o) || (o !is null && toUtf8 == o.toUtf8);
        }

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory

        ***********************************************************************/

        final bool isAbsolute ()
        {
                return (fp[0] is PathSeparatorChar);
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
                     if (s[i] is PathSeparatorChar)
                         return true;
                return false;
        }

        /***********************************************************************

                Replace all 'from' instances in the provided path with 'to'

        ***********************************************************************/

        final VfsPath replace (char from, char to)
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

        final VfsPath normalize ()
        {
                version (Win32)
                         return replace ('/', '\\');
                     else
                        return replace ('\\', '/');
        }

        /***********************************************************************

                Append text to this path; no separators are added

        ***********************************************************************/

        final VfsPath append (char[][] others...)
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

                Prepend text to this path; no separators are added

        ***********************************************************************/

        final VfsPath prepend (char[] other)
        {
                adjust (0, folder_, folder_, padded (other));
                return parse;
        }

        /***********************************************************************

                Reset the content of this path to that of another and
                reparse

        ***********************************************************************/

        final VfsPath set (VfsPath path)
        {
                return set (path.toUtf8);
        }

        /***********************************************************************

                Reset the content of this path, and reparse

        ***********************************************************************/

        final VfsPath set (char[] path)
        {
                end_ = path.length;

                expand (end_);
                fp[0 .. end_] = path;
                fp[end_] = '\0';
                return parse;
        }

        /***********************************************************************

                Replace the folder portion of this path. The folder will be 
                padded with a path-separator as required

        ***********************************************************************/

        final VfsPath folder (char[] other)
        {
                auto x = adjust (folder_, name_, name_ - folder_, padded (other));
                suffix_ += x;
                name_ += x;
                return this;
        }

        /***********************************************************************

                Replace the name portion of this path

        ***********************************************************************/

        final VfsPath name (char[] other)
        {
                auto x = adjust (name_, suffix_, suffix_ - name_, other);
                suffix_ += x;
                return this;
        }

        /***********************************************************************

                Replace the suffix portion of this path. The suffix will be 
                prefixed with a file-separator as required

        ***********************************************************************/

        final VfsPath suffix (char[] other)
        {
                adjust (suffix_, end_, end_ - suffix_, prefixed (other, '.'));
                return this;
        }

        /***********************************************************************

                Replace the root and folder portions of this path and 
                reparse. The replacement will be padded with a path
                separator as required
        
        ***********************************************************************/

        final VfsPath path (char[] other)
        {
                adjust (0, name_, name_, padded (other));
                return parse;
        }

        /***********************************************************************

                Replace the file and suffix portions of this path and 
                reparse. The replacement will be prefixed with a suffix
                separator as required
        
        ***********************************************************************/

        final VfsPath file (char[] other)
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

        static char[] stripped (char[] path)
        {
                if (path.length && path[$-1] is PathSeparatorChar)
                    path = path [0 .. $-1];
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a trailing separator

        ***********************************************************************/

        static char[] padded (char[] path, char c = PathSeparatorChar)
        {
                if (path.length && path[$-1] != c)
                    path = path ~ c;
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

        /***********************************************************************

                Potentially make room for more content

        ***********************************************************************/

        private  void expand (uint size)
        {
                ++size;
                if (fp.length < size)
                    fp.length = (size + 63) & ~63;
        }

        /***********************************************************************

                Insert/delete internal content 

        ***********************************************************************/

        private  int adjust (int head, int tail, int len, char[] sub)
        {
                len = sub.length - len;

                // don't destroy self-references!
                if (len && sub.ptr >= fp.ptr+head+len && sub.ptr < fp.ptr+fp.length)
                   {
                   char[512] tmp = void;
                   assert (sub.length < tmp.length);
                   sub = tmp[0..sub.length] = sub;
                   }

                // make some room if necessary
                expand  (len + end_);

                // slide tail around to insert or remove space
                memmove (fp.ptr+tail+len, fp.ptr+tail, end_ +1 - tail);

                // copy replacement
                memmove (fp.ptr + head, sub.ptr, sub.length);

                // adjust length
                end_ += len;
                return len;
        }

        /***********************************************************************

        ***********************************************************************/

        final VfsPath removeFirstSegments(uint count)
        in {
            assert (count <= segments_);
        }
        body {
            if (count > segments_)
                return this;
            if (count == segments_)
                return null;

            uint found;
            foreach(i, c; fp[0..end_]) {
                if (i > 0 && c == PathSeparatorChar) {
                    found++;
                    if (found == count)
                        return set(fp[i + 1..end_].dup);
                }
            }

            return null;
        }

        /***********************************************************************

        ***********************************************************************/

        final VfsPath removeLastSegments(uint count)
        in {
            assert (count <= segments_);
        }
        body {
            if (count > segments_)
                return this;
            if (count == segments_)
                return null;

            uint found;
            foreach_reverse(i, c; fp[0..end_]) {
                if (c == PathSeparatorChar) {
                    found++;
                    if (found == count)
                        return set(fp[0..i].dup);
                }
            }

            return null;
        }

        /***********************************************************************

        ***********************************************************************/

        final char[] segment(uint idx)
        in {
            assert (idx < segments_);
        }
        body {
            if (idx >= segments_)
                return null;
            if (idx == segments_ -1)
                return file;

            uint start = folder_;
            uint count;
            foreach (i, c; fp[folder_..end_]) {
                if (c == PathSeparatorChar) {
                    count++;
                    if (count -1 == idx)
                        return fp[start..i+1];
                    else
                        start = i + 2;
                }
            }
            return null;
        }

        /***********************************************************************

        ***********************************************************************/

        final uint segmentCount()
        {
            return segments_;
        }

        /***********************************************************************

                Parse the path spec

        ***********************************************************************/

        private VfsPath parse ()
        {
                folder_ = segments_ = 0;
                name_ = suffix_ = -1;

                for (int i=end_; --i >= 0;)
                     switch (fp[i])
                            {
                            case FileSeparatorChar:
                                 if (name_ < 0)
                                     if (suffix_ < 0 && i && fp[i-1] != '.')
                                         suffix_ = i;
                                 break;

                            case PathSeparatorChar:
                                 if (name_ < 0)
                                     name_ = i + 1;
                                 segments_++;
                                 break;

                            default:
                                 if (segments_ == 0) segments_++;
                                 break;
                            }

                if (name_ < 0)
                    name_ = folder_;

                if (suffix_ < 0 || suffix_ is name_)
                    suffix_ = end_;

                if (isDir) segments_--;
                if (isAbsolute) {
                    folder_ = 1;
                    segments_--;
                }

                return this;
        }

        /***********************************************************************

                Returns true if this FilePath has been marked as a directory,
                via the constructor or method set()

        ***********************************************************************/

        final bool isDir ()
        {
                return dir_;
        }

}

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2004: Initial version
        version:        Nov 2006: Australian version
        version:        Feb 2007: Mutating version

        author:         Kris

*******************************************************************************/

module tango.io.FilePath;

private import tango.io.FileConst;

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

                To ascertain if a FilePath exists on a system, or to access
                various other physical attributes, use methods exposed via
                tango.io.FileProxy and tango.io.File

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

                Simple constructor form. This can be convenient, and 
                avoids ctor setup at the callsite:
                ---
                FilePath path = "mypath";
                ---

        ***********************************************************************/

        static FilePath opAssign (char[] path)
        {
                return new FilePath (path);
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        final override char[] toUtf8 ()
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

        FilePath set (char[] path, bool dir = false)
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

        final FilePath asRoot (char[] other)
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

        final FilePath asFolder (char[] other)
        {
                auto x = adjust (folder_, name_, name_ - folder_, padded (other));
                suffix_ += x;
                name_ += x;
                ext_ += x;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath asName (char[] other)
        {
                auto x = adjust (name_, suffix_, suffix_ - name_, other);
                suffix_ += x;
                ext_ += x;
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath asSuffix (char[] other)
        {
                adjust (suffix_, end_, end_ - suffix_, prefixed (other, '.'));
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath asExt (char[] other)
        {       
                auto len = ext.length;
                adjust (end_ - len, end_, len, prefixed (other, '.'));
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath asPath (char[] other)
        {
                adjust (0, name_, name_, other);
                return parse;
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath asFile (char[] other)
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

        /***********************************************************************

        ***********************************************************************/

        private FilePath parse ()
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

                fp [head .. tail+len] = sub;
                end_ += len;
                return len;
        }
}



/*******************************************************************************

*******************************************************************************/

abstract class PathView
{
        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        abstract char[] toUtf8 ();

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        abstract char[] cString ();

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        abstract char[] root ();

        /***********************************************************************

                Return the file path. Paths may start and end with a "/".
                The root path is "/" and an unspecified path is returned as
                an empty string. Directory paths may be split such that the
                directory name is placed into the 'name' member; directory
                paths are treated no differently than file paths

        ***********************************************************************/

        abstract char[] folder ();

        /***********************************************************************

                Return the name of this file, or directory.

        ***********************************************************************/

        abstract char[] name ();

        /***********************************************************************

                Suffix is like an extension, except it may include multiple
                '.' sequences and the dot-prefix is included in the suffix.
                For example, "wumpus.foo.bar" has suffix ".foo.bar"

        ***********************************************************************/

        abstract char[] suffix ();

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator. For example, "wumpus.foo.bar" has ext "bar"

        ***********************************************************************/

        abstract char[] ext ();

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        abstract char[] path ();

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        abstract char[] file ();

        /***********************************************************************

                Returns true if all fields are equal.

        ***********************************************************************/

        abstract int opEquals (Object o);

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory.

        ***********************************************************************/

        abstract bool isAbsolute ();

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        abstract bool isEmpty ();

        /***********************************************************************

                Returns true if this FilePath has a parent

        ***********************************************************************/

        abstract bool isChild ();

        /***********************************************************************

                Returns true if this FilePath has been marked as a
                directory, via the constructor

        ***********************************************************************/

        abstract bool isDir ();
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        void main() {}

        unittest
        {
        FilePath path = "mypath";

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
                fp.asFolder (r"\a\b\c\");
                assert (fp.suffix == r".bar");
                assert (fp.toUtf8 == r"c:\a\b\c\foo.bar");
                assert (fp.name == "foo");
                assert (fp.folder == r"\a\b\c\");
                assert (fp.file == r"foo.bar");
                assert (fp.ext == ".bar");
                assert (fp.isChild);

                fp = new FilePath(r"c:\a\b\c\d\e\foo.bar");
                assert (fp.isAbsolute);
                fp.asFolder (r"\a\b\c\d\e\f\g\");
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

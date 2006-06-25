/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.FilePath;

private import  tango.io.Exception,
                tango.io.FileConst;

private import  tango.convert.Unicode;

/*******************************************************************************

        Models a file name. These are expected to be used as the constructor 
        argument to File implementations. The intention is that they easily
        convert to other representations such as absolute, canonical, or Url.
        Note that this class is immutable. Use MutableFilePath if you wish
        to alter specific attributes.

        File paths containing non-ansi characters should be UTF-8 encoded. 
        Supporting Unicode in this manner was deemed to be more suitable 
        than providing a wchar version of FilePath, and is both consistent 
        & compatible with the approach taken with the Uri class.

*******************************************************************************/

class FilePath
{       
        private char[]  fp,                     // utf8 filepath with trailing 0
                        ext,                    // file extension
                        name,                   // file name
                        path,                   // path before name
                        root,                   // C: D: etc
                        suffix;                 // from first '.'

        private wchar[] fpWide;                 // utf 16 with trailing 0

        private alias void delegate (void[]) Consumer;  // simplistic string appender

        /***********************************************************************
        
                Create an empty FilePath. This is strictly for subclass
                use.

        ***********************************************************************/

        protected this ()
        {
        }

        /***********************************************************************
        
                Create a FilePath through reference to another.

        ***********************************************************************/

        this (FilePath other)
        in {
           assert (other);
           }
        body
        {
                fp = other.fp;
                ext = other.ext;
                name = other.name;
                path = other.path;
                root = other.root;
                suffix = other.suffix;
                fpWide = other.fpWide;
        }

        /***********************************************************************
        
                Create a FilePath from the given string. Note the path string
                is usually duplicated here, though you may specify that it be
                aliased instead via the second argument. When aliased, you are 
                expected to provide an immutable copy for the lifetime of this 
                object. If you are not certain, ignore the second argument.

        ***********************************************************************/

        this (char[] filepath, bool copy = true)
        in {
           assert (filepath);
           assert(filepath.length > 0);
           }
        out {
            if (root)
                assert (root.length > 0);
            }
        body
        {
                int ext = -1,
                    path = -1,
                    root = -1,
                    suffix = -1;
                
                // mark path segments
                for (int i=filepath.length; i > 0; --i)
                     switch (filepath[i-1])
                            {
                            case FileConst.FileSeparatorChar:
                                 if (path < 0)
                                    {
                                    if (ext < 0)
                                       {
                                       // check for '..' sequence
                                       if (i > 1 && filepath[i-2] != FileConst.FileSeparatorChar)
                                           ext = i;
                                       }
                                    suffix = i;
                                    }
                                 break;

                            case FileConst.PathSeparatorChar:
                                 if (path < 0)
                                     path = i;
                                 break;

                            case FileConst.RootSeparatorChar:
                                 root = i;
                            default:
                                 break;
                            }

                // hang onto original length ...
                int i = filepath.length;

                // copy the filepath? Add a null if so
                if (copy)
                    fp = filepath = filepath ~ '\0';
                        
                // slice each path segment
                if (ext >= 0)
                   {
                   this.ext = filepath [ext..i];
                   this.suffix = filepath [suffix..i];
                   --ext;
                   }
                else
                   ext = i;

                if (root >= 1)
                    this.root = filepath [0..root-1];
                else
                   root = 0;

                if (path >= root)
                    this.path = filepath [root..path];
                else
                   path = root;

                this.name = filepath [path..ext];
        }


                             
/+
        alias Consume delegate(char[]) Bar;
        typedef Bar delegate (char[]) Consume;

        Consume emit (Consume consume)
        {
                return consume ("1") ("2") ("3") ("4");
        }

        void other ()
        {
                Bar t (char[] v)
                {
                        return cast(Bar) &t;
                }

                emit (&t);
        }


        /***********************************************************************
        
                Create a FilePath from a Uri. Note that the Uri authority
                is used to house an optional root (device, drive-letter ...)

        ***********************************************************************/

        this (Uri uri)
        {
                char[] path = uri.getPath();

                if (uri.getHost.length)
                    path = uri.getHost ~ FileConst.RootSeparatorString ~ path;
                
                this (path);
        }

        /***********************************************************************

                Convert this FilePath to a Uri. Note that a root (such as a
                drive-letter, or device) is placed into the Uri authority
        
        ***********************************************************************/

        MutableUri toUri ()
        {
                MutableUri uri = new MutableUri();

                if (isAbsolute)
                    uri.setScheme ("file");

                if (root.length)
                    uri.setHost (root);

                char[] s = path~name;
                if (ext.length)
                    s ~= FileConst.FileSeparatorString ~ ext;

                version (Win32)
                         Text.replace (s, FileConst.PathSeparatorChar, '/');
                uri.setPath (s);
                return uri;
        }
+/
        /***********************************************************************
        
                Convert path separators to the correct format. This mutates
                the provided 'path' content, so .dup it as necessary.

        ***********************************************************************/

        static char[] normalize (char[] path)
        {
                version (Win32)
                         return replace (path, '/', '\\');
                     else
                         return replace (path, '\\', '/');
        }

        /***********************************************************************
        
                Replace all 'from' instances in the provided path with 'to'
                  
        ***********************************************************************/

        static char[] replace (char[] path, char from, char to)
        {
                foreach (inout char c; path)
                         if (c is from)
                             c = to;
                return path;
        }

        /***********************************************************************
        
                Clear any cached information in this FilePath

        ***********************************************************************/

        protected void reset ()
        {
                fp.length = fpWide.length = 0;
        }

        /***********************************************************************
        
                Returns true if this FilePath is *not* relative to the 
                current working directory.

        ***********************************************************************/

        bool isAbsolute ()
        {
                return cast(bool) (root.length || 
                       (path.length && path[0] is FileConst.PathSeparatorChar)
                       );
        }               

        /***********************************************************************
        
                Returns true  if this FilePath is empty

        ***********************************************************************/

        bool isEmpty ()
        {
                return (path.length + name.length + ext.length) is 0;
        }

        /***********************************************************************
                
                Return the root of this path. Roots are constructs such as
                "c:".

        ***********************************************************************/

        char[] getRoot ()
        {
                return root;
        }               

        /***********************************************************************
        
                Return the file path. Paths start with a '/' but do not
                end with one. The root path is empty. Directory paths 
                are split such that the directory name is placed into
                the 'name' member.

        ***********************************************************************/

        char[] getPath ()
        {
                return path;
        }             

        /***********************************************************************
        
                Return the name of this file, or directory.

        ***********************************************************************/

        char[] getName ()
        {
                return name;
        }               

        /***********************************************************************
        
                Return the file-extension, sans seperator

        ***********************************************************************/

        char[] getExtension ()
        {
                return ext;
        }              

        /***********************************************************************
        
                Suffix is like extension, except it can include multiple
                '.' sequences. For example, "wumpus1.foo.bar" has suffix
                "foo.bar" and extension "bar".

        ***********************************************************************/

        char[] getSuffix ()
        {
                return suffix;
        }              

        /***********************************************************************

                Convert this FilePath to a char[] via the provided Consumer

        ***********************************************************************/

        Consumer produce (Consumer consume)
        {
                if (root.length)
                    consume (root), consume (FileConst.RootSeparatorString);

                if (path.length)
                    consume (path);

                if (name.length)
                    consume (name);

                if (ext.length)
                    consume (FileConst.FileSeparatorString), consume (ext);

                return consume;
        }               

        /***********************************************************************

                Convert this FilePath to a char[]

        ***********************************************************************/

        override char[] toString ()
        {
                return toUtf8 ();
        }               

        /***********************************************************************
        
                Return a zero terminated UTF8 version of this file path

        ***********************************************************************/

        char[] toUtf8 (bool withNull = false)
        {
                if (fp.length is 0)
                   {
                   // preallocate some space
                   fp.length = 256, fp.length = 0;

                   // concatenate segments
                   produce ((void[] v){fp ~= cast(char[]) v;}) ("\0");
                   }

                // return with or without trailing null
                return fp [0 .. $ - (withNull ? 0 : 1)];
        }

        /***********************************************************************
        
                Return a zero terminated UTF16 version of this file path

        ***********************************************************************/

        wchar[] toUtf16 ()
        {
                if (fpWide is null)
                    // convert trailing null also ...
                    fpWide = Unicode.toUtf16 (toUtf8 (true));

                return fpWide;
        }

        /***********************************************************************
        
                Splice this FilePath onto the end of the provided base path.
                Output is return as a char[].

        ***********************************************************************/

        char[] splice (FilePath base)
        {      
                char[] s;
                s.length = 256, s.length = 0;
                splice (base, (void[] v){s ~= cast(char[]) v;});
                return s;
        }               

        /***********************************************************************
        
                Splice this FilePath onto the end of the provided base path.
                Output is handled via the provided Consumer

        ***********************************************************************/

        Consumer splice (FilePath base, Consumer consume)
        {      
                base.produce (consume);

                if (! base.isEmpty)
                      consume (FileConst.PathSeparatorString);

                if (path.length)
                    consume (path);
                       
                if (name.length)
                    consume (name);

                if (ext.length)
                    consume (FileConst.FileSeparatorString), consume (ext);

                return consume;
        }               

        /***********************************************************************
        
                Find the next parent of the FilePath. Returns a valid index
                to the seperator when present, -1 otherwise.

        ***********************************************************************/

        private int locateParent ()
        {
                int i = path.length;

                // set new path to rightmost PathSeparator
                if (--i > 0)
                    while (--i >= 0)
                           if (path[i] is FileConst.PathSeparatorChar)
                               return i;
                return -1;
        }               

        /***********************************************************************
        
                Returns a FilePath representing the parent of this one. An
                exception is thrown if there is not parent (at the root).

        ***********************************************************************/

        FilePath toParent ()
        {
                // set new path to rightmost PathSeparator
                int i = locateParent();

                if (i >= 0)
                   {
                   FilePath parent = new FilePath (this);

                   // slice path subsection
                   parent.path = path [0..i+1];
                   parent.reset ();
                   return parent;
                   }

                // return null? throw exception? return null? Hmmmm ...
                throw new IOException ("Cannot create parent path for an orphan file");
        }               

        /***********************************************************************
                
                Returns true if this FilePath has a parent.

        ***********************************************************************/

        bool isChild ()
        {
                return cast (bool) (locateParent() >= 0);
        }               

        /***********************************************************************
        
                Return a cloned FilePath with a different name.

        ***********************************************************************/

        FilePath toSibling (char[] name)
        {
                return toSibling (name, ext, suffix);
        }

        /***********************************************************************
        
                Return a cloned FilePath with a different name and extension.
                Note that the suffix is destroyed.

        ***********************************************************************/

        FilePath toSibling (char[] name, char[] ext)
        {
                return toSibling (name, ext, suffix);
        }

        /***********************************************************************
        
                Return a cloned FilePath with a different name, extension,
                and suffix.

        ***********************************************************************/

        FilePath toSibling (char[] name, char[] ext, char[] suffix) 
        {
                // don't copy ... we can alias instead
                FilePath sibling = new FilePath (this);

                sibling.suffix = suffix;
                sibling.name = name;
                sibling.ext = ext;
                sibling.reset ();

                return sibling;
        }
}


/*******************************************************************************

        Mutable version of FilePath, which allows one to change individual
        attributes. A change to any attribute will cause method toString() 
        to rebuild the output.

*******************************************************************************/

class MutableFilePath : FilePath
{       
        /***********************************************************************
        
                Create an empty MutableFilePath

        ***********************************************************************/

        this ()
        {
        }

        /***********************************************************************
        
                Create a MutableFilePath through reference to another.

        ***********************************************************************/

        this (FilePath other)
        {
                super (other);
        }

        /***********************************************************************
        
                Create a MutableFilePath via a filename.

        ***********************************************************************/

        this (char[] name)
        {
                super (name);
        }

        /***********************************************************************
        
                Set the extension of this FilePath.

        ***********************************************************************/

        private final MutableFilePath set (char[]* x, char[]* v)
        {       
                *x = *v;
                reset ();
                return this;
        }

        /***********************************************************************
        
                Set the extension of this FilePath.

        ***********************************************************************/

        MutableFilePath setExt (char[] ext)
        {
                return set (&this.ext, &ext);
        }

        /***********************************************************************
        
                Set the name of this FilePath.

        ***********************************************************************/

        MutableFilePath setName (char[] name)
        {
                return set (&this.name, &name);
        }

        /***********************************************************************
        
                Set the path of this FilePath.

        ***********************************************************************/

        MutableFilePath setPath (char[] path)
        {
                return set (&this.path, &path);
        }

        /***********************************************************************
        
                Set the root of this FilePath (such as "c:")

        ***********************************************************************/

        MutableFilePath setRoot (char[] root)
        {
                return set (&this.root, &root);
        }

        /***********************************************************************
        
                Set the suffix of this FilePath.

        ***********************************************************************/

        MutableFilePath setSuffix (char[] suffix)
        {
                return set (&this.suffix, &suffix);
        }
}

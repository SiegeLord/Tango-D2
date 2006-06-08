/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: June 2004      

        author:         Chris Sauls, Kris

*******************************************************************************/

module tango.io.FileScan;

public import   tango.io.File,
                tango.io.FilePath;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. This can be used to produce a list
        of subdirectories and the files contained therein. Usage example:

        @code
        void files (File file)
        {
                Stdout (file.getPath) (CR);
        }

        void dirs (FilePath path)
        {
                Stdout (path) (CR);
        }

        FileScan scan = new FileScan;

        // find all files with a 'd' extension
        scan ((args.length == 2) ? args[1] : ".", "d");

        Stdout ("directories:") (CR);
        scan.directories (&dirs);

        Stdout (CR) ("files:") (CR);
        scan.files (&files);       
        @endcode
        
*******************************************************************************/

class FileScan
{       
        alias read opCall;

        private char[]          ext;
        private Dependencies    deps;
        private Filter          filter;

        typedef bool delegate (FilePath) Filter;

        /***********************************************************************

                The list of files and sub-directories found.

        ***********************************************************************/
        
        private struct Dependencies 
        {
                File[]          mods;
                FilePath[]      pkgs;
        }

        /***********************************************************************

                Read a set of files and directories from the given parent
                path, where the files are filtered by the given extension.

        ***********************************************************************/
        
        FileScan read (char[] path, char[] ext)
        {
                return read (new FilePath(path), ext);
        }

        /***********************************************************************

                Read a set of files and directories from the given parent
                path, where the files are filtered by the given extension.
        
        ***********************************************************************/
        
        FileScan read (FilePath path, char[] ext)
        {
                this.ext = ext;
                return read (path, &simpleFilter);
        }

        /***********************************************************************

                Read a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate.

        ***********************************************************************/
        
        FileScan read (FilePath path, Filter filter)
        {
                deps.mods = null;
                deps.pkgs = null;
                this.filter = filter;
                scanFiles (deps, path);
                return this;
        }

        /***********************************************************************

                Visit all the files found in the last scan. The delegate
                should return false to terminate early.

        ***********************************************************************/

        public FileScan files (void delegate (File) visit)
        {
                foreach (File file; deps.mods)
                         visit (file);
                return this;
        }

        /***********************************************************************

                Visit all directories found in the last scan. The delegate
                should return false to terminate early.

        ***********************************************************************/

        public FileScan directories (void delegate (FilePath) visit)
        {
                foreach (FilePath path; deps.pkgs)
                         visit (path);
                return this;
        }

        /***********************************************************************

                Local delegate for filtering files based upon a provided
                extension

        ***********************************************************************/

        private bool simpleFilter (FilePath fp) 
        {
                char[]  sbuf = fp.getExtension;

                if (fp.getName[0] != '.')                       
                    if (sbuf.length == 0 || sbuf == ext)
                        return true;

                return false;
        }

        /***********************************************************************

                Recursive routine to locate files and sub-directories.

        ***********************************************************************/

        private void scanFiles (inout Dependencies deps, FilePath base) 
        {
                File file = new File (base);
                FilePath[] paths = file.toList (filter);

                // add packages only if there's something in them
                if (paths.length)
                    deps.pkgs ~= base;

                foreach (FilePath x; paths) 
                        {
                        // combine base path with listed file
                        FilePath spliced = new FilePath (x.splice (base));

                        // recurse if this is a directory ...
                        file = new File (spliced);
                        if (file.isDirectory) 
                            scanFiles (deps, spliced);
                        else 
                           deps.mods ~= file;
                        }
        }
}


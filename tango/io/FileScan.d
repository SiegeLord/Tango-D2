/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

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

        ---
        void files (File file)
        {
                Cout (file).newline;
        }

        void dirs (FilePath path)
        {
                Cout (path).newline;
        }

        auto scan = new FileScan;

        // find all files with a 'd' extension
        scan ((args.length is 2) ? args[1] : ".", "d");

        Cout ("directories:").newline;
        scan.directories (&dirs);

        Cout ("files:").newline;
        scan.files (&files);   
        ---
        

        Using D implicit-delegate syntax, this can be also be written as

        ---
        auto scan = new FileScan;
        
        // find all files with a 'd' extension
        scan ((args.length is 2) ? args[1] : ".", "d");

        Cout ("Directories:").newline;
        scan.directories ((FilePath path) {Cout (path).newline;});

        Cout ("Files:").newline;
        scan.files ((File file) {Cout (file).newline;});
        ---
        
*******************************************************************************/

class FileScan
{       
        alias sweep opCall;

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

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given extension.

        ***********************************************************************/
        
        FileScan sweep (char[] path, char[] suffix)
        {
                return sweep (new FilePath(path), suffix);
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given extension.
        
        ***********************************************************************/
        
        FileScan sweep (FilePath path, char[] match)
        {
                bool filter (FilePath fp) 
                {
                        auto suffix = fp.getSuffix ();

                        if (fp.getName.length)                       
                            if (suffix.length == 0 || suffix == match)
                                return true;

                        return false;
                }

                return sweep (path, &filter);
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate.

        ***********************************************************************/
        
        FileScan sweep (FilePath path, Filter filter)
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

                Recursive routine to locate files and sub-directories.

        ***********************************************************************/

        private void scanFiles (inout Dependencies deps, FilePath base) 
        {
                auto file = new File (base);
                auto paths = file.toList (filter);

                // add packages only if there's something in them
                if (paths.length)
                    deps.pkgs ~= base;

                foreach (FilePath x; paths) 
                        {
                        // combine base path with listed file
                        auto spliced = x.join (base.toUtf8);

                        // recurse if this is a directory ...
                        file = new File (spliced);
                        if (file.isDirectory) 
                            scanFiles (deps, file.getPath);
                        else 
                           deps.mods ~= file;
                        }
        }
}


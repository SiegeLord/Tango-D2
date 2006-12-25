/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004: Initial release
        version:        Dec 2006: South Pacific rewrite

        author:         Kris

*******************************************************************************/

module tango.io.FileScan;

public import   tango.io.File,
                tango.io.FilePath,
                tango.io.FileProxy;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. This can be used to produce a list
        of subdirectories and the files contained therein. The following
        example lists all files with suffix ".d" located via the current
        directory, along with the folders containing them:

        ---
        auto root = new FilePath (".");
        auto scan = (new FileScan)(root, ".d");

        Stdout.formatln ("{0} Folders", scan.folders.length);
        foreach (file; scan.folders)
                 Stdout.formatln ("{0}", file);

        Stdout.formatln ("\n{0} Files", scan.files.length);
        foreach (file; scan.files)
                 Stdout.formatln ("{0}", file);
        ---

        This is not the most efficient method to scan a large number of
        files, but operates in a convenient manner
        
*******************************************************************************/

class FileScan
{       
        alias sweep opCall;

        private Dependencies deps;

        /***********************************************************************

            alias for Filter delegate. Takes a File as argument and returns
            a bool

        ***********************************************************************/

        alias bool delegate (File, bool) Filter;

        /***********************************************************************

                The list of files and sub-directories found

        ***********************************************************************/
        
        private struct Dependencies 
        {
                int             total;
                File[]          files,
                                folders;
        }

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public int inspected ()
        {
                return deps.total;
        }

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public File[] files ()
        {
                return deps.files;
        }

        /***********************************************************************
        
                Return all directories found in the last scan

        ***********************************************************************/

        public FileProxy[] folders ()
        {
                return deps.folders;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate

        ***********************************************************************/
        
        FileScan sweep (FilePath path, Filter filter)
        {
                deps.files = deps.folders = null;
                scanFiles (new File(path), filter);
                return this;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given extension.
        
        ***********************************************************************/
        
        FileScan sweep (FilePath path, char[] match)
        {
                bool filter (File fp, bool isDir) 
                {
                        if (isDir)
                            return true;
                        
                        auto path = fp.getPath ();
                        return path.getName.length && path.getSuffix == match;
                }

                return sweep (path, &filter);
        }

        /***********************************************************************

                Internal routine to locate files and sub-directories. We
                skip system files, plus folders composed only of '.' chars
                        
        ***********************************************************************/

        private void scanFiles (File folder, Filter filter) 
        {
                bool isDir;
                auto paths = folder.toList();
                auto count = deps.files.length;
                deps.total += paths.length;
                
                foreach (entry; paths) 
                        {
                        // temporaries, allocated on stack 
                        scope auto x = new FilePath (entry, entry.length+1);
                        scope auto f = new File (x);

                        // skip system files
                        if (f.isVisible && filter(f, isDir = f.isDirectory))
                           {
                           // create persistent instance for returning. We
                           // map onto the previously allocated filepath
                           auto file = new File (new FilePath (entry, entry.length+1));

                           if (isDir)
                              {
                              auto path = file.getPath();

                              // skip dirs composed only of '.'
                              auto suffix = path.getSuffix();
                              if (path.getName.length is 0 &&
                                  suffix.length <= 3       &&
                                  suffix == "..."[0..suffix.length])
                                  continue;

                              // recurse directories
                              scanFiles (file, filter);
                              }
                           else
                              deps.files ~= file;
                           }
                        }
                
                // add packages only if there's something in them
                if (deps.files.length > count)
                    deps.folders ~= folder;
        }
}

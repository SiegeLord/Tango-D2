/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004: Initial release
        version:        Dec 2006: Pacific release

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
        auto scan = new FileScan;

        scan (new FilePath ("."), ".d");

        Stdout.formatln ("{0} Folders", scan.folders.length);
        foreach (file; scan.folders)
                 Stdout.formatln ("{0}", file);

        Stdout.formatln ("\n{0} Files", scan.files.length);
        foreach (file; scan.files)
                 Stdout.formatln ("{0}", file);
        ---

        This is unlikely the most efficient method to scan a vast number of
        files, but operates in a convenient manner
        
*******************************************************************************/

class FileScan
{       
        alias sweep opCall;

        uint            total_;
        File[]          files_,
                        folders_;
        
        /***********************************************************************

            alias for Filter delegate. Takes a File as argument and returns
            a bool

        ***********************************************************************/

        alias bool delegate (FileProxy, bool) Filter;

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public uint inspected ()
        {
                return total_;
        }

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public File[] files ()
        {
                return files_;
        }

        /***********************************************************************
        
                Return all directories found in the last scan

        ***********************************************************************/

        public FileProxy[] folders ()
        {
                return folders_;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate

        ***********************************************************************/
        
        FileScan sweep (FilePath path, Filter filter)
        {
                total_ = 0;
                files_ = folders_ = null;
                scan (new File(path), filter);
                return this;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given suffix
        
        ***********************************************************************/
        
        FileScan sweep (FilePath path, char[] match)
        {
                return sweep (path, (FileProxy fp, bool isDir)
                             {return isDir || fp.getPath.getSuffix == match;});
        }

        /***********************************************************************

                Internal routine to locate files and sub-directories. We
                skip system files, plus folders composed only of '.' chars
                        
        ***********************************************************************/

        private void scan (File folder, Filter filter) 
        {
                auto paths = folder.toList();
                auto count = files_.length;
                total_ += paths.length;
                
                foreach (entry; paths) 
                        {
                        // temporaries, allocated on stack 
                        scope auto x = new FilePath (entry.ptr, entry.length+1);
                        scope auto p = new FileProxy (x);

                        // skip system files
                        bool isDir = p.isDirectory;
                        if (p.isVisible && filter (p, isDir))
                           {
                           // create persistent instance for returning. We
                           // map onto the filepath allocated via toList()
                           auto file = new File (new FilePath (x));

                           if (isDir)
                              {
                              auto path = file.getPath();

                              // skip dirs composed only of '.'
                              auto suffix = path.getSuffix();
                              if (path.getName.length is 0 && suffix.length <= 3 &&
                                  suffix == "..."[0..suffix.length])
                                  continue;

                              // recurse directories
                              scan (file, filter);
                              }
                           else
                              files_ ~= file;
                           }
                        }
                
                // add packages only if there's something in them
                if (files_.length > count)
                    folders_ ~= folder;
        }
}

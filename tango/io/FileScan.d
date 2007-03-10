/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004: Initial release
        version:        Dec 2006: Pacific release

        author:         Kris

*******************************************************************************/

module tango.io.FileScan;

public import tango.io.FilePath;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. This can be used to produce a list
        of subdirectories and the files contained therein. The following
        example lists all files with suffix ".d" located via the current
        directory, along with the folders containing them:

        ---
        auto scan = new FileScan;

        scan (".", ".d");

        Stdout.formatln ("{0} Folders", scan.folders.length);
        foreach (folder; scan.folders)
                 Stdout.formatln ("{0}", folder);

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
        FilePath[]      files_,
                        folders_;
        
        /***********************************************************************

            Alias for Filter delegate. Accepts a FilePath & a bool as 
            arguments and returns a bool.

            The FilePath argument represents a file found by the scan, 
            and the bool whether the FilePath represents a folder.

            The filter should return true, if matched by the filter. Note
            that returning false where the path is a folder will result 
            in all files contained being ignored. To always recurse folders, 
            do something like this:
            ---
            return (isDir || match (fp.name));
            ---

        ***********************************************************************/

        alias bool delegate (FilePath, bool) Filter;

        /***********************************************************************

                Return the number of files found in the last scan

        ***********************************************************************/

        public uint inspected ()
        {
                return total_;
        }

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public FilePath[] files ()
        {
                return files_;
        }

        /***********************************************************************
        
                Return all directories found in the last scan

        ***********************************************************************/

        public FilePath[] folders ()
        {
                return folders_;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given suffix
        
        ***********************************************************************/
        
        FileScan sweep (char[] path, char[] match)
        {
                return sweep (path, (FilePath fp, bool isDir)
                             {return isDir || fp.suffix == match;});
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate

        ***********************************************************************/
        
        FileScan sweep (char[] path, Filter filter)
        {
                total_ = 0;
                files_ = folders_ = null;
                return scan (new FilePath(path), filter);
        }

        /***********************************************************************

                Internal routine to locate files and sub-directories. We
                skip folders composed only of '.' chars. 

        ***********************************************************************/

        private FileScan scan (FilePath folder, Filter filter) 
        {
                FilePath[] paths;

                void add (char[] prefix, char[] name, bool isDir)
                { 
                        char[512] tmp;

                        int len = prefix.length + name.length;
                        assert (len < tmp.length);
                        ++total_;

                        // construct full pathname
                        tmp[0..prefix.length] = prefix;
                        tmp[prefix.length..len] = name;
                        
                        auto p = new FilePath (tmp[0 .. len], isDir);

                        // test this entry for inclusion
                        if (filter (p, isDir))
                           {
                           // skip dirs composed only of '.'
                           if (name.length > 3 || name != "..."[0 .. name.length])
                               paths ~= p;                                                   
                           }
                        else
                           delete p;
                }

                folder.toList (&add);
                auto count = files_.length;
                
                foreach (path; paths)
                         if (path.isDir)
                             scan (path, filter);
                         else
                            files_ ~= path;
                
                // add packages only if there's something in them
                if (files_.length > count)
                    folders_ ~= folder;

                return this;
        }
}
